import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/damaged_stock_model.dart';
import '../../data/repositories/damaged_stock_repository.dart';
import 'damaged_stock_state.dart';

class DamagedStockCubit extends Cubit<DamagedStockState> {
  final DamagedStockRepository damagedStockRepository;
  StreamSubscription<List<DamagedStockModel>>? _damagedSubscription;

  DamagedStockCubit([DamagedStockRepository? repository])
      : damagedStockRepository = repository ??
            (sl.isRegistered<DamagedStockRepository>()
                ? sl<DamagedStockRepository>()
                : DamagedStockRepositoryImpl()),
        super(const DamagedStockInitial());

  void loadDamagedStock() {
    emit(const DamagedStockLoading());
    _damagedSubscription?.cancel();
    _damagedSubscription = damagedStockRepository.watchDamagedStock().listen(
      (damagedList) {
        if (state is DamagedStockLoaded) {
          final currentState = state as DamagedStockLoaded;
          final filtered = _applyFilters(
            damagedList,
            currentState.searchQuery,
            currentState.selectedReason,
            currentState.selectedDateRange,
          );
          emit(currentState.copyWith(
            allDamaged: damagedList,
            filteredDamaged: filtered,
          ));
        } else {
          emit(DamagedStockLoaded(
            allDamaged: damagedList,
            filteredDamaged: damagedList,
          ));
        }
      },
      onError: (error) {
        emit(DamagedStockError(error.toString()));
      },
    );
  }

  void filterDamagedStock({
    String? query,
    DamagedReason? reason,
    bool clearReason = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    if (state is! DamagedStockLoaded) return;
    final currentState = state as DamagedStockLoaded;

    final newQuery = query ?? currentState.searchQuery;
    final newReason = clearReason ? null : (reason ?? currentState.selectedReason);
    final newDateRange = clearDateRange ? null : (dateRange ?? currentState.selectedDateRange);

    final filtered = _applyFilters(
      currentState.allDamaged,
      newQuery,
      newReason,
      newDateRange,
    );

    emit(currentState.copyWith(
      filteredDamaged: filtered,
      searchQuery: newQuery,
      selectedReason: newReason,
      clearReason: clearReason,
      selectedDateRange: newDateRange,
      clearDateRange: clearDateRange,
    ));
  }

  List<DamagedStockModel> _applyFilters(
    List<DamagedStockModel> all,
    String query,
    DamagedReason? reason,
    DateTimeRange? dateRange,
  ) {
    return all.where((item) {
      // 1. Search filter (product title, SKU, notes, recordedBy)
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchesTitle = item.productTitle.toLowerCase().contains(q);
        final matchesSku = item.variationSku.toLowerCase().contains(q);
        final matchesNotes = item.notes.toLowerCase().contains(q);
        final matchesUser = item.recordedBy.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSku && !matchesNotes && !matchesUser) {
          return false;
        }
      }

      // 2. Reason filter
      if (reason != null && item.reason != reason) {
        return false;
      }

      // 3. Date range filter
      if (dateRange != null) {
        final start = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final end = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
          23,
          59,
          59,
        );
        if (item.createdAt.isBefore(start) || item.createdAt.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

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
    try {
      await damagedStockRepository.recordDamage(
        product: product,
        variationSku: variationSku,
        quantity: quantity,
        reason: reason,
        customCostPrice: customCostPrice,
        notes: notes,
        recordedBy: recordedBy,
        images: images,
      );
    } catch (e) {
      emit(DamagedStockError(e.toString()));
    }
  }

  Future<void> deleteDamage(
    DamagedStockModel record, {
    bool restoreProductStock = true,
  }) async {
    try {
      await damagedStockRepository.deleteDamagedStock(
        record,
        restoreProductStock: restoreProductStock,
      );
    } catch (e) {
      emit(DamagedStockError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _damagedSubscription?.cancel();
    return super.close();
  }
}
