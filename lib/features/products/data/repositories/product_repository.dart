import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../brands/data/repositories/brand_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final BrandRepository _brandRepository;

  ProductRepositoryImpl({
    ProductRemoteDataSource? remoteDataSource,
    BrandRepository? brandRepository,
  })  : remoteDataSource =
            remoteDataSource ?? ProductRemoteDataSourceImpl(),
        _brandRepository = brandRepository ??
            (sl.isRegistered<BrandRepository>()
                ? sl<BrandRepository>()
                : BrandRepositoryImpl());

  @override
  Future<List<ProductModel>> getProducts() => remoteDataSource.getProducts();

  @override
  Future<void> addProduct(ProductModel product) async {
    try {
      ProductModel productToSave = product;

      // Ensure brand exists in Brands collection before saving product
      final brandName = product.brand.name.trim();
      final brandId = product.brand.id.trim();
      if (brandName.isNotEmpty || brandId.isNotEmpty) {
        final resolvedBrand = await _brandRepository.ensureBrandExists(
          name: brandName,
          id: brandId,
        );

        productToSave = productToSave.copyWith(
          brand: ProductBrand(
            id: resolvedBrand.id,
            name: resolvedBrand.name,
          ),
        );
      }

      await remoteDataSource.saveProduct(productToSave);
    } catch (e) {
      debugPrint('Firestore addProduct error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      ProductModel productToSave = product;

      // Ensure brand exists in Brands collection before updating product
      final brandName = product.brand.name.trim();
      final brandId = product.brand.id.trim();
      if (brandName.isNotEmpty || brandId.isNotEmpty) {
        final resolvedBrand = await _brandRepository.ensureBrandExists(
          name: brandName,
          id: brandId,
        );

        productToSave = productToSave.copyWith(
          brand: ProductBrand(
            id: resolvedBrand.id,
            name: resolvedBrand.name,
          ),
        );
      }

      await remoteDataSource.saveProduct(productToSave);
    } catch (e) {
      debugPrint('Firestore updateProduct error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
    } catch (e) {
      debugPrint('Firestore deleteProduct error: $e');
      rethrow;
    }
  }
}
