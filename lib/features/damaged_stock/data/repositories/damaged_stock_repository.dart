import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../products/data/datasources/stock_movement_remote_data_source.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../datasources/damaged_stock_remote_data_source.dart';
import '../models/damaged_stock_model.dart';

abstract class DamagedStockRepository {
  Stream<List<DamagedStockModel>> watchDamagedStock();
  Future<List<DamagedStockModel>> getDamagedStock();

  Future<void> recordDamage({
    required ProductModel product,
    String? variationSku,
    required int quantity,
    required DamagedReason reason,
    double? customCostPrice,
    String? notes,
    String? recordedBy,
    List<String>? images,
  });

  Future<void> deleteDamagedStock(
    DamagedStockModel record, {
    bool restoreProductStock = false,
  });
}

class DamagedStockRepositoryImpl implements DamagedStockRepository {
  final DamagedStockRemoteDataSource remoteDataSource;
  final ProductRepository _productRepository;
  final StockMovementRemoteDataSource _movementDataSource;

  DamagedStockRepositoryImpl({
    DamagedStockRemoteDataSource? remoteDataSource,
    ProductRepository? productRepository,
    StockMovementRemoteDataSource? movementDataSource,
  })  : remoteDataSource =
            remoteDataSource ?? DamagedStockRemoteDataSourceImpl(),
        _productRepository = productRepository ??
            (sl.isRegistered<ProductRepository>()
                ? sl<ProductRepository>()
                : ProductRepositoryImpl()),
        _movementDataSource = movementDataSource ??
            (sl.isRegistered<StockMovementRemoteDataSource>()
                ? sl<StockMovementRemoteDataSource>()
                : StockMovementRemoteDataSourceImpl());

  @override
  Stream<List<DamagedStockModel>> watchDamagedStock() =>
      remoteDataSource.watchDamagedStock();

  @override
  Future<List<DamagedStockModel>> getDamagedStock() =>
      remoteDataSource.getDamagedStock();

  @override
  Future<void> recordDamage({
    required ProductModel product,
    String? variationSku,
    required int quantity,
    required DamagedReason reason,
    double? customCostPrice,
    String? notes,
    String? recordedBy,
    List<String>? images,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero');
    }

    ProductModel updatedProduct;
    StockMovementModel movement;
    double unitCost = 0.0;
    double unitSelling = 0.0;
    Map<String, String> varAttrs = const {};
    String targetSku = '';

    // Handle Variable Product
    if (variationSku != null &&
        variationSku.isNotEmpty &&
        product.productVariations.isNotEmpty) {
      final varIndex = product.productVariations.indexWhere(
        (v) => v.sku.toLowerCase() == variationSku.toLowerCase(),
      );

      if (varIndex == -1) {
        throw Exception(
            'Variation with SKU "$variationSku" not found in product "${product.displayTitle}"');
      }

      final currentVar = product.productVariations[varIndex];
      targetSku = currentVar.sku;
      varAttrs = currentVar.attributeValues;
      unitCost = (customCostPrice != null && customCostPrice > 0)
          ? customCostPrice
          : currentVar.costPrice;
      unitSelling = currentVar.effectivePrice;

      final previousStock = currentVar.stock;
      final newVarStock = (previousStock - quantity).clamp(0, 999999);

      final updatedVariations =
          List<ProductVariationModel>.from(product.productVariations);
      updatedVariations[varIndex] = currentVar.copyWith(stock: newVarStock);

      final newTotalStock =
          updatedVariations.fold<int>(0, (sum, v) => sum + v.stock);

      updatedProduct = product.copyWith(
        productVariations: updatedVariations,
        stock: newTotalStock,
      );

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: targetSku,
        variationAttributes: varAttrs,
        type: StockMovementType.damage,
        quantity: -quantity,
        previousStock: previousStock,
        newStock: newVarStock,
        costPricePerUnit: unitCost,
        totalCost: quantity * unitCost,
        supplierName: '',
        invoiceNumber: '',
        notes: '[هالك: ${reason.labelKey}] ${notes ?? ""}'.trim(),
        performedBy: recordedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    } else {
      // Handle Simple Product
      targetSku = '';
      unitCost = (customCostPrice != null && customCostPrice > 0)
          ? customCostPrice
          : product.costPrice;
      unitSelling = product.effectivePrice;

      final previousStock = product.stock;
      final newStock = (previousStock - quantity).clamp(0, 999999);

      updatedProduct = product.copyWith(stock: newStock);

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: '',
        variationAttributes: const {},
        type: StockMovementType.damage,
        quantity: -quantity,
        previousStock: previousStock,
        newStock: newStock,
        costPricePerUnit: unitCost,
        totalCost: quantity * unitCost,
        supplierName: '',
        invoiceNumber: '',
        notes: '[هالك: ${reason.labelKey}] ${notes ?? ""}'.trim(),
        performedBy: recordedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    }

    final damagedRecord = DamagedStockModel(
      id: '',
      productId: product.id,
      productTitle: product.displayTitle,
      productCategory: product.categoryType.displayName,
      variationSku: targetSku,
      variationAttributes: varAttrs,
      quantity: quantity,
      costPrice: unitCost,
      sellingPrice: unitSelling,
      totalLoss: quantity * unitCost,
      reason: reason,
      notes: notes ?? '',
      recordedBy: recordedBy ?? 'Admin',
      createdAt: DateTime.now(),
      images: images ?? const [],
    );

    // 1. Deduct stock from Product catalog
    await _productRepository.updateProduct(updatedProduct);

    // 2. Record audit stock movement log
    await _movementDataSource.recordStockMovement(movement);

    // 3. Save damaged stock entry
    await remoteDataSource.addDamagedStock(damagedRecord);
  }

  @override
  Future<void> deleteDamagedStock(
    DamagedStockModel record, {
    bool restoreProductStock = false,
  }) async {
    try {
      if (restoreProductStock) {
        final products = await _productRepository.getProducts();
        final prodIndex =
            products.indexWhere((p) => p.id == record.productId);

        if (prodIndex != -1) {
          final product = products[prodIndex];
          ProductModel updatedProduct;

          if (record.variationSku.isNotEmpty &&
              product.productVariations.isNotEmpty) {
            final varIndex = product.productVariations.indexWhere((v) =>
                v.sku.toLowerCase() == record.variationSku.toLowerCase());

            if (varIndex != -1) {
              final v = product.productVariations[varIndex];
              final updatedVariations =
                  List<ProductVariationModel>.from(product.productVariations);
              updatedVariations[varIndex] =
                  v.copyWith(stock: v.stock + record.quantity);

              final newTotalStock = updatedVariations.fold<int>(
                  0, (sum, item) => sum + item.stock);
              updatedProduct = product.copyWith(
                productVariations: updatedVariations,
                stock: newTotalStock,
              );
            } else {
              updatedProduct =
                  product.copyWith(stock: product.stock + record.quantity);
            }
          } else {
            updatedProduct =
                product.copyWith(stock: product.stock + record.quantity);
          }

          await _productRepository.updateProduct(updatedProduct);

          final adjustmentMovement = StockMovementModel(
            id: '',
            productId: product.id,
            productTitle: product.displayTitle,
            productCategory: product.categoryType.displayName,
            variationSku: record.variationSku,
            variationAttributes: record.variationAttributes,
            type: StockMovementType.adjustment,
            quantity: record.quantity,
            previousStock: product.stock,
            newStock: updatedProduct.stock,
            costPricePerUnit: record.costPrice,
            totalCost: record.quantity * record.costPrice,
            supplierName: '',
            invoiceNumber: '',
            notes: 'إلغاء تسجيل تالف واسترجاع للمخزن (${record.productTitle})',
            performedBy: 'Admin',
            createdAt: DateTime.now(),
          );
          await _movementDataSource.recordStockMovement(adjustmentMovement);
        }
      }

      await remoteDataSource.deleteDamagedStock(record.id);
    } catch (e) {
      debugPrint('DamagedStockRepository delete error: $e');
      rethrow;
    }
  }
}
