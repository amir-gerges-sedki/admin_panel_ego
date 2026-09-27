import '../../../../core/di/injection_container.dart';
import '../datasources/stock_movement_remote_data_source.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

abstract class StockMovementRepository {
  Future<List<StockMovementModel>> getStockMovements({
    int limit = 100,
    String? productId,
    StockMovementType? type,
  });

  Future<void> recordStockMovement(StockMovementModel movement);

  Future<ProductModel> executeRestock({
    required ProductModel product,
    String? variationSku,
    required int quantityAdded,
    required double costPrice,
    String? supplier,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
  });

  Future<ProductModel> executeBatchRestock({
    required ProductModel product,
    required Map<String, int> skuQuantities,
    required Map<String, double> skuCostPrices,
    String? supplier,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
  });

  Future<ProductModel> executeStockAdjustment({
    required ProductModel product,
    String? variationSku,
    required int newExactStock,
    required StockMovementType type,
    String? reason,
    String? notes,
    String? performedBy,
  });
}

class StockMovementRepositoryImpl implements StockMovementRepository {
  final StockMovementRemoteDataSource remoteDataSource;
  final ProductRepository _productRepository;

  StockMovementRepositoryImpl({
    StockMovementRemoteDataSource? remoteDataSource,
    ProductRepository? productRepository,
  })  : remoteDataSource =
            remoteDataSource ?? StockMovementRemoteDataSourceImpl(),
        _productRepository = productRepository ??
            (sl.isRegistered<ProductRepository>()
                ? sl<ProductRepository>()
                : ProductRepositoryImpl());

  @override
  Future<List<StockMovementModel>> getStockMovements({
    int limit = 100,
    String? productId,
    StockMovementType? type,
  }) {
    return remoteDataSource.getStockMovements(
      limit: limit,
      productId: productId,
      type: type,
    );
  }

  @override
  Future<void> recordStockMovement(StockMovementModel movement) {
    return remoteDataSource.recordStockMovement(movement);
  }

  @override
  Future<ProductModel> executeRestock({
    required ProductModel product,
    String? variationSku,
    required int quantityAdded,
    required double costPrice,
    String? supplier,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
  }) async {
    if (quantityAdded <= 0) return product;

    ProductModel updatedProduct;
    StockMovementModel movement;

    if (variationSku != null && variationSku.isNotEmpty && product.productVariations.isNotEmpty) {
      final variationIndex = product.productVariations.indexWhere(
        (v) => v.sku.toLowerCase() == variationSku.toLowerCase(),
      );

      if (variationIndex == -1) {
        throw Exception('Variation with SKU "$variationSku" not found in product "${product.displayTitle}"');
      }

      final currentVar = product.productVariations[variationIndex];
      final previousStock = currentVar.stock;
      final newVarStock = previousStock + quantityAdded;
      final newVarCost = costPrice > 0 ? costPrice : currentVar.costPrice;

      final updatedVariations = List<ProductVariationModel>.from(product.productVariations);
      updatedVariations[variationIndex] = currentVar.copyWith(
        stock: newVarStock,
        costPrice: newVarCost,
      );

      final newTotalStock = updatedVariations.fold<int>(0, (sum, v) => sum + v.stock);

      updatedProduct = product.copyWith(
        productVariations: updatedVariations,
        stock: newTotalStock,
      );

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: currentVar.sku,
        variationAttributes: currentVar.attributeValues,
        type: StockMovementType.restock,
        quantity: quantityAdded,
        previousStock: previousStock,
        newStock: newVarStock,
        costPricePerUnit: newVarCost,
        totalCost: quantityAdded * newVarCost,
        supplierName: supplier ?? '',
        invoiceNumber: invoiceNumber ?? '',
        notes: notes ?? '',
        performedBy: performedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    } else {
      final previousStock = product.stock;
      final newStock = previousStock + quantityAdded;
      final newCost = costPrice > 0 ? costPrice : product.costPrice;

      updatedProduct = product.copyWith(
        stock: newStock,
        costPrice: newCost,
      );

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: '',
        variationAttributes: const {},
        type: StockMovementType.restock,
        quantity: quantityAdded,
        previousStock: previousStock,
        newStock: newStock,
        costPricePerUnit: newCost,
        totalCost: quantityAdded * newCost,
        supplierName: supplier ?? '',
        invoiceNumber: invoiceNumber ?? '',
        notes: notes ?? '',
        performedBy: performedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    }

    await _productRepository.updateProduct(updatedProduct);
    await remoteDataSource.recordStockMovement(movement);

    return updatedProduct;
  }

  @override
  Future<ProductModel> executeBatchRestock({
    required ProductModel product,
    required Map<String, int> skuQuantities,
    required Map<String, double> skuCostPrices,
    String? supplier,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
  }) async {
    if (skuQuantities.isEmpty) return product;

    final updatedVariations = List<ProductVariationModel>.from(product.productVariations);
    final List<StockMovementModel> movements = [];

    for (int i = 0; i < updatedVariations.length; i++) {
      final v = updatedVariations[i];
      final qtyAdded = skuQuantities[v.sku] ?? 0;
      if (qtyAdded > 0) {
        final newCost = (skuCostPrices[v.sku] ?? 0.0) > 0
            ? skuCostPrices[v.sku]!
            : v.costPrice;
        final prevStock = v.stock;
        final newStock = prevStock + qtyAdded;

        updatedVariations[i] = v.copyWith(
          stock: newStock,
          costPrice: newCost,
        );

        movements.add(
          StockMovementModel(
            id: '',
            productId: product.id,
            productTitle: product.displayTitle,
            productCategory: product.categoryType.displayName,
            variationSku: v.sku,
            variationAttributes: v.attributeValues,
            type: StockMovementType.restock,
            quantity: qtyAdded,
            previousStock: prevStock,
            newStock: newStock,
            costPricePerUnit: newCost,
            totalCost: qtyAdded * newCost,
            supplierName: supplier ?? '',
            invoiceNumber: invoiceNumber ?? '',
            notes: notes ?? '',
            performedBy: performedBy ?? 'Admin',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (movements.isEmpty) return product;

    final newTotalStock = updatedVariations.fold<int>(0, (sum, v) => sum + v.stock);
    final updatedProduct = product.copyWith(
      productVariations: updatedVariations,
      stock: newTotalStock,
    );

    await _productRepository.updateProduct(updatedProduct);
    await remoteDataSource.recordBatchStockMovements(movements);

    return updatedProduct;
  }

  @override
  Future<ProductModel> executeStockAdjustment({
    required ProductModel product,
    String? variationSku,
    required int newExactStock,
    required StockMovementType type,
    String? reason,
    String? notes,
    String? performedBy,
  }) async {
    ProductModel updatedProduct;
    StockMovementModel movement;

    if (variationSku != null && variationSku.isNotEmpty && product.productVariations.isNotEmpty) {
      final variationIndex = product.productVariations.indexWhere(
        (v) => v.sku.toLowerCase() == variationSku.toLowerCase(),
      );

      if (variationIndex == -1) {
        throw Exception('Variation with SKU "$variationSku" not found in product "${product.displayTitle}"');
      }

      final currentVar = product.productVariations[variationIndex];
      final previousStock = currentVar.stock;
      final diff = newExactStock - previousStock;

      final updatedVariations = List<ProductVariationModel>.from(product.productVariations);
      updatedVariations[variationIndex] = currentVar.copyWith(
        stock: newExactStock,
      );

      final newTotalStock = updatedVariations.fold<int>(0, (sum, v) => sum + v.stock);

      updatedProduct = product.copyWith(
        productVariations: updatedVariations,
        stock: newTotalStock,
      );

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: currentVar.sku,
        variationAttributes: currentVar.attributeValues,
        type: type,
        quantity: diff,
        previousStock: previousStock,
        newStock: newExactStock,
        costPricePerUnit: currentVar.costPrice,
        totalCost: diff.abs() * currentVar.costPrice,
        supplierName: '',
        invoiceNumber: '',
        notes: reason ?? notes ?? '',
        performedBy: performedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    } else {
      final previousStock = product.stock;
      final diff = newExactStock - previousStock;

      updatedProduct = product.copyWith(
        stock: newExactStock,
      );

      movement = StockMovementModel(
        id: '',
        productId: product.id,
        productTitle: product.displayTitle,
        productCategory: product.categoryType.displayName,
        variationSku: '',
        variationAttributes: const {},
        type: type,
        quantity: diff,
        previousStock: previousStock,
        newStock: newExactStock,
        costPricePerUnit: product.costPrice,
        totalCost: diff.abs() * product.costPrice,
        supplierName: '',
        invoiceNumber: '',
        notes: reason ?? notes ?? '',
        performedBy: performedBy ?? 'Admin',
        createdAt: DateTime.now(),
      );
    }

    await _productRepository.updateProduct(updatedProduct);
    await remoteDataSource.recordStockMovement(movement);

    return updatedProduct;
  }
}
