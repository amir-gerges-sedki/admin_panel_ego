import 'package:flutter/foundation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../datasources/brand_remote_data_source.dart';
import '../models/brand_model.dart';

abstract class BrandRepository {
  Future<List<BrandModel>> getBrands();
  Future<BrandModel?> getBrandById(String id);
  Future<BrandModel?> getBrandByName(String name);
  Future<BrandModel> ensureBrandExists({required String name, String? id});
  Future<void> addBrand(BrandModel brand);
  Future<void> updateBrand(BrandModel brand);
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders);
  Future<void> deleteBrand(String id);
}

class BrandRepositoryImpl implements BrandRepository {
  final BrandRemoteDataSource remoteDataSource;

  BrandRepositoryImpl({BrandRemoteDataSource? remoteDataSource})
    : remoteDataSource = remoteDataSource ?? BrandRemoteDataSourceImpl();

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final brands = await remoteDataSource.getBrands();
      final counts = await remoteDataSource.getProductCountsPerBrand();

      final enrichedBrands = brands.map((b) {
        final idKey = b.id.trim().toLowerCase();
        final nameKey = b.name.trim().toLowerCase();
        final realCount = counts[idKey] ?? counts[nameKey] ?? b.productsCount;
        return b.copyWith(productsCount: realCount);
      }).toList();

      return _sortBrands(enrichedBrands);
    } catch (e) {
      debugPrint('Firestore Brands fetch note: $e');
      return [];
    }
  }

  @override
  Future<BrandModel?> getBrandById(String id) async {
    try {
      final brand = await remoteDataSource.getBrandById(id);
      if (brand != null) {
        final counts = await remoteDataSource.getProductCountsPerBrand();
        final idKey = brand.id.trim().toLowerCase();
        final nameKey = brand.name.trim().toLowerCase();
        final realCount = counts[idKey] ?? counts[nameKey] ?? brand.productsCount;
        return brand.copyWith(productsCount: realCount);
      }
      return null;
    } catch (e) {
      debugPrint('Firestore getBrandById error: $e');
      return null;
    }
  }

  @override
  Future<BrandModel?> getBrandByName(String name) async {
    try {
      return await remoteDataSource.getBrandByName(name);
    } catch (e) {
      debugPrint('Firestore getBrandByName error: $e');
      return null;
    }
  }

  @override
  Future<BrandModel> ensureBrandExists({
    required String name,
    String? id,
  }) async {
    final cleanName = name.trim();
    final cleanId = (id ?? '').trim();

    // 1. If explicit ID was provided, check directly by ID (1 document read)
    if (cleanId.isNotEmpty) {
      final existing = await getBrandById(cleanId);
      if (existing != null) return existing;
    }

    // 2. Derive canonical ID from name (e.g. BRAND_NASTY)
    final canonicalId = cleanName.isNotEmpty
        ? 'BRAND_${cleanName.replaceAll(RegExp(r'\s+'), '_').toUpperCase()}'
        : cleanId;

    // Check canonical ID only if it wasn't already checked as cleanId
    if (canonicalId.isNotEmpty &&
        canonicalId.toLowerCase() != cleanId.toLowerCase()) {
      final existingByCanonical = await getBrandById(canonicalId);
      if (existingByCanonical != null) return existingByCanonical;
    }

    // 3. Check by exact name match in Firestore (1 document query read)
    if (cleanName.isNotEmpty) {
      final existingByName = await getBrandByName(cleanName);
      if (existingByName != null) return existingByName;
    }

    // 4. Brand does NOT exist -> Create it directly in Brands collection
    final targetId = cleanId.isNotEmpty ? cleanId : canonicalId;
    final newBrand = BrandModel(
      id: targetId,
      name: cleanName.isNotEmpty ? cleanName : targetId,
      image: '',
      isFeatured: true,
      productsCount: 1,
    );

    await addBrand(newBrand);
    return newBrand;
  }

  /// Sorts brands by sortOrder ascending
  List<BrandModel> _sortBrands(List<BrandModel> brands) {
    return brands..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> addBrand(BrandModel brand) async {
    final cleanName = brand.name.trim();

    // Check if a brand with this Name already exists
    if (cleanName.isNotEmpty) {
      final existingByName = await getBrandByName(cleanName);
      if (existingByName != null) {
        throw BrandException('brand_name_exists', {'name': cleanName});
      }
    }

    await remoteDataSource.addBrand(brand);
  }

  @override
  Future<void> updateBrand(BrandModel brand) async {
    final cleanId = brand.id.trim();
    final cleanName = brand.name.trim();

    // Prevent renaming to an existing brand name that belongs to another brand
    if (cleanName.isNotEmpty) {
      final existingByName = await getBrandByName(cleanName);
      if (existingByName != null &&
          existingByName.id.trim().toLowerCase() != cleanId.toLowerCase()) {
        throw BrandException('brand_name_used', {'name': cleanName});
      }
    }

    await remoteDataSource.updateBrand(brand);
  }

  @override
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders) async {
    await remoteDataSource.updateBrandOrdersBatch(brandOrders);
  }

  @override
  Future<void> deleteBrand(String id) async {
    await remoteDataSource.deleteBrand(id);
  }
}

/// Custom exception for brand business rules that supports live localization.
class BrandException implements Exception {
  final String key;
  final Map<String, String>? params;

  const BrandException(this.key, [this.params]);

  @override
  String toString() => key.trParams(params);
}
