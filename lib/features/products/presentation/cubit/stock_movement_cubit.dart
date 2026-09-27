import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/stock_movement_repository.dart';
import 'stock_movement_state.dart';

class StockMovementCubit extends Cubit<StockMovementState> {
  final StockMovementRepository repository;

  StockMovementCubit(this.repository) : super(StockMovementInitial());

  List<StockMovementModel> _cachedMovements = [];

  Future<void> loadStockMovements({String? productId, StockMovementType? type}) async {
    emit(StockMovementLoading());
    try {
      final list = await repository.getStockMovements(
        productId: productId,
        type: type,
      );
      _cachedMovements = list;
      emit(StockMovementLoaded(
        allMovements: list,
        filteredMovements: list,
        selectedProductId: productId,
        selectedType: type,
      ));
    } catch (e) {
      emit(StockMovementError(e.toString()));
    }
  }

  void filterMovements({String? query, StockMovementType? type, bool clearType = false, String? productId, bool clearProduct = false}) {
    if (state is! StockMovementLoaded) return;
    final current = state as StockMovementLoaded;

    final targetQuery = query ?? current.searchQuery;
    final targetType = clearType ? null : (type ?? current.selectedType);
    final targetProduct = clearProduct ? null : (productId ?? current.selectedProductId);

    final filtered = _cachedMovements.where((m) {
      final matchesQuery = targetQuery.isEmpty ||
          m.productTitle.toLowerCase().contains(targetQuery.toLowerCase()) ||
          m.variationSku.toLowerCase().contains(targetQuery.toLowerCase()) ||
          m.supplierName.toLowerCase().contains(targetQuery.toLowerCase()) ||
          m.invoiceNumber.toLowerCase().contains(targetQuery.toLowerCase()) ||
          m.notes.toLowerCase().contains(targetQuery.toLowerCase());

      final matchesType = targetType == null || m.type == targetType;
      final matchesProduct = targetProduct == null || m.productId == targetProduct;

      return matchesQuery && matchesType && matchesProduct;
    }).toList();

    emit(current.copyWith(
      filteredMovements: filtered,
      searchQuery: targetQuery,
      selectedType: targetType,
      clearType: clearType,
      selectedProductId: targetProduct,
      clearProduct: clearProduct,
    ));
  }

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
    try {
      final updatedProduct = await repository.executeRestock(
        product: product,
        variationSku: variationSku,
        quantityAdded: quantityAdded,
        costPrice: costPrice,
        supplier: supplier,
        invoiceNumber: invoiceNumber,
        notes: notes,
        performedBy: performedBy,
      );

      // Refresh cached movements in background
      loadStockMovements();
      return updatedProduct;
    } catch (e) {
      emit(StockMovementError(e.toString()));
      rethrow;
    }
  }

  Future<ProductModel> executeBatchRestock({
    required ProductModel product,
    required Map<String, int> skuQuantities,
    required Map<String, double> skuCostPrices,
    String? supplier,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
  }) async {
    try {
      final updatedProduct = await repository.executeBatchRestock(
        product: product,
        skuQuantities: skuQuantities,
        skuCostPrices: skuCostPrices,
        supplier: supplier,
        invoiceNumber: invoiceNumber,
        notes: notes,
        performedBy: performedBy,
      );

      loadStockMovements();
      return updatedProduct;
    } catch (e) {
      emit(StockMovementError(e.toString()));
      rethrow;
    }
  }

  Future<ProductModel> executeStockAdjustment({
    required ProductModel product,
    String? variationSku,
    required int newExactStock,
    required StockMovementType type,
    String? reason,
    String? notes,
    String? performedBy,
  }) async {
    try {
      final updatedProduct = await repository.executeStockAdjustment(
        product: product,
        variationSku: variationSku,
        newExactStock: newExactStock,
        type: type,
        reason: reason,
        notes: notes,
        performedBy: performedBy,
      );

      loadStockMovements();
      return updatedProduct;
    } catch (e) {
      emit(StockMovementError(e.toString()));
      rethrow;
    }
  }
}
