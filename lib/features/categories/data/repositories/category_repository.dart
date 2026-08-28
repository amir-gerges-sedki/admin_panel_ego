import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../products/data/models/product_model.dart';
import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<BrandModel>> getBrands();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> addBrand(BrandModel brand);
  Future<void> updateBrand(BrandModel brand);
  Future<void> deleteBrand(String id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final docs = await FirebaseService.getMultipleCollectionsDocs([
        'Categories',
        'categories',
        'Types',
        'types',
      ]);
      final List<CategoryModel> categories = docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();

      // Include standard 5 core Vape Categories if not explicitly present
      final Set<String> seenCatIds = categories
          .map((c) => c.id.toLowerCase().trim())
          .toSet();
      final Set<String> seenCatNames = categories
          .map((c) => c.name.toLowerCase().trim())
          .toSet();

      for (final type in ProductCategoryType.values) {
        final idKey = type.name.toLowerCase();
        if (!seenCatIds.contains(idKey) &&
            !seenCatIds.contains(type.id.toLowerCase()) &&
            !seenCatNames.contains(type.displayName.toLowerCase())) {
          categories.add(
            CategoryModel(
              id: type.id,
              name: '${type.displayName} (${type.arabicName})',
              isFeatured: true,
              productsCount: 0,
            ),
          );
        }
      }

      // Compute live product counts per category
      try {
        final prodDocs = await FirebaseService.getMultipleCollectionsDocs([
          'Products',
          'products',
          'Items',
          'items',
          'liquids',
          'Liquids',
        ]);

        final Map<String, int> catCounts = {};
        for (final pDoc in prodDocs) {
          final pData = pDoc.data();
          final catId =
              (pData['categoryId'] ??
                      pData['CategoryId'] ??
                      pData['category'] ??
                      pData['Category'] ??
                      '')
                  .toString()
                  .trim()
                  .toLowerCase();
          final catType = (pData['categoryType'] ?? pData['CategoryType'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          if (catId.isNotEmpty) {
            catCounts[catId] = (catCounts[catId] ?? 0) + 1;
          }
          if (catType.isNotEmpty && catType != catId) {
            catCounts[catType] = (catCounts[catType] ?? 0) + 1;
          }
        }

        return categories.map((cat) {
          int count =
              catCounts[cat.id.toLowerCase()] ??
              catCounts[cat.name.toLowerCase()] ??
              0;

          if (count == 0) {
            for (final type in ProductCategoryType.values) {
              if (cat.id.toLowerCase() == type.name.toLowerCase() ||
                  cat.id.toLowerCase() == type.id.toLowerCase() ||
                  cat.name.toLowerCase().contains(
                    type.displayName.toLowerCase(),
                  ) ||
                  cat.name.toLowerCase().contains(
                    type.arabicName.toLowerCase(),
                  )) {
                count =
                    (catCounts[type.name.toLowerCase()] ?? 0) +
                    (catCounts[type.id.toLowerCase()] ?? 0);
                break;
              }
            }
          }

          return cat.copyWith(
            productsCount: count > 0
                ? count
                : (cat.productsCount > 0 ? cat.productsCount : 0),
          );
        }).toList();
      } catch (e) {
        debugPrint('Note calculating category live product counts: $e');
        return categories;
      }
    } catch (e) {
      debugPrint('Firestore Categories fetch note: $e');
      return [];
    }
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final List<BrandModel> results = [];
      final Set<String> seenNames = {};

      // 1. Fetch from explicit Brand / Line collections in Firestore
      final docs = await FirebaseService.getMultipleCollectionsDocs([
        'Brands',
        'brands',
        'Lines',
        'lines',
        'ProductBrands',
        'product_brands',
      ]);

      for (final doc in docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final brand = BrandModel.fromJson(data);
        final name = brand.name.trim();
        if (name.isNotEmpty && !seenNames.contains(name.toLowerCase())) {
          seenNames.add(name.toLowerCase());
          results.add(brand);
        }
      }

      // 2. Discover brand names and count products per brand from existing products
      final Map<String, int> brandCounts = {};
      try {
        final prodDocs = await FirebaseService.getMultipleCollectionsDocs([
          'Products',
          'products',
          'Items',
          'items',
          'liquids',
          'Liquids',
        ]);

        for (final doc in prodDocs) {
          final data = doc.data();
          final rawBrand =
              data['brandName'] ??
              data['BrandName'] ??
              data['brand'] ??
              data['Brand'] ??
              data['line'] ??
              data['Line'] ??
              data['lineName'] ??
              data['LineName'];

          String bName = '';
          if (rawBrand is Map) {
            bName = (rawBrand['name'] ?? rawBrand['Name'] ?? '')
                .toString()
                .trim();
          } else if (rawBrand != null) {
            bName = rawBrand.toString().trim();
          }

          if (bName.isNotEmpty) {
            final key = bName.toLowerCase();
            brandCounts[key] = (brandCounts[key] ?? 0) + 1;

            if (!seenNames.contains(key)) {
              seenNames.add(key);
              results.add(
                BrandModel(
                  id: 'BRAND_${bName.replaceAll(' ', '_').toUpperCase()}',
                  name: bName,
                  productsCount: 0,
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Note extracting brands & counting products: $e');
      }

      // 3. Attach computed productsCount to each brand
      final List<BrandModel> updatedResults = results.map((b) {
        final count =
            brandCounts[b.name.trim().toLowerCase()] ??
            (b.productsCount > 0 ? b.productsCount : 0);
        return b.copyWith(productsCount: count);
      }).toList();

      updatedResults.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return updatedResults;
    } catch (e) {
      debugPrint('Firestore Brands/Lines fetch note: $e');
      return [];
    }
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await FirebaseService.categoriesCollection
        .doc(category.id)
        .set(category.toJson());
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await FirebaseService.categoriesCollection
        .doc(category.id)
        .set(category.toJson());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await FirebaseService.categoriesCollection.doc(id).delete();
  }

  @override
  Future<void> addBrand(BrandModel brand) async {
    await FirebaseService.brandsCollection.doc(brand.id).set(brand.toJson());
    await FirebaseService.linesCollection.doc(brand.id).set(brand.toJson());
  }

  @override
  Future<void> updateBrand(BrandModel brand) async {
    await FirebaseService.brandsCollection.doc(brand.id).set(brand.toJson());
    await FirebaseService.linesCollection.doc(brand.id).set(brand.toJson());
  }

  @override
  Future<void> deleteBrand(String id) async {
    await FirebaseService.brandsCollection.doc(id).delete();
    await FirebaseService.linesCollection.doc(id).delete();
  }
}
