import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/brand_model.dart';
import '../../data/repositories/brand_repository.dart';
import 'brand_state.dart';

export 'brand_state.dart';

class BrandCubit extends Cubit<BrandState> {
  final BrandRepository brandRepository;
  final Duration reorderDebounceDuration;
  Timer? _reorderDebounceTimer;
  Map<String, int> _baselineOrders = {};

  BrandCubit(
    this.brandRepository, {
    this.reorderDebounceDuration = const Duration(seconds: 5),
  }) : super(BrandInitial());

  Future<void> loadBrands({bool silent = false}) async {
    if (_reorderDebounceTimer?.isActive ?? false) {
      await flushPendingReorder();
    }
    final currentField = state is BrandLoaded
        ? (state as BrandLoaded).sortField
        : BrandSortField.sortOrder;
    final currentAsc = state is BrandLoaded
        ? (state as BrandLoaded).sortAscending
        : true;
    final currentQuery = state is BrandLoaded
        ? (state as BrandLoaded).brandQuery
        : '';

    if (!silent && state is! BrandLoaded) {
      emit(const BrandLoading());
    }
    try {
      final brands = await brandRepository.getBrands();
      _baselineOrders = {for (final b in brands) b.id: b.sortOrder};
      final filtered = _applySortAndFilter(
        brands: brands,
        query: currentQuery,
        sortField: currentField,
        sortAscending: currentAsc,
      );
      emit(
        BrandLoaded(
          brands: brands,
          filteredBrands: filtered,
          brandQuery: currentQuery,
          sortField: currentField,
          sortAscending: currentAsc,
        ),
      );
    } catch (e) {
      if (state is! BrandLoaded) {
        emit(BrandError(e.toString()));
      }
    }
  }

  void filterBrands(String query) {
    if (state is! BrandLoaded) return;
    final currentState = state as BrandLoaded;

    final filtered = _applySortAndFilter(
      brands: currentState.brands,
      query: query,
      sortField: currentState.sortField,
      sortAscending: currentState.sortAscending,
    );

    emit(
      currentState.copyWith(filteredBrands: filtered, brandQuery: query.trim()),
    );
  }

  void sortBrands(BrandSortField field, {bool? ascending}) {
    if (state is! BrandLoaded) return;
    final currentState = state as BrandLoaded;

    final newAsc =
        ascending ??
        (currentState.sortField == field ? !currentState.sortAscending : true);

    final sorted = _applySortAndFilter(
      brands: currentState.brands,
      query: currentState.brandQuery,
      sortField: field,
      sortAscending: newAsc,
    );

    emit(
      currentState.copyWith(
        filteredBrands: sorted,
        sortField: field,
        sortAscending: newAsc,
      ),
    );
  }

  List<BrandModel> _applySortAndFilter({
    required List<BrandModel> brands,
    required String query,
    required BrandSortField sortField,
    required bool sortAscending,
  }) {
    final q = query.trim().toLowerCase();
    final list = brands.where((b) {
      return q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      int comparison = 0;
      switch (sortField) {
        case BrandSortField.sortOrder:
          comparison = a.sortOrder.compareTo(b.sortOrder);
          break;
        case BrandSortField.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case BrandSortField.productsCount:
          comparison = a.productsCount.compareTo(b.productsCount);
          break;
        case BrandSortField.status:
          // Featured (true) comes first in ascending order
          final aVal = a.isFeatured ? 1 : 0;
          final bVal = b.isFeatured ? 1 : 0;
          comparison = bVal.compareTo(aVal);
          break;
      }

      // If primary comparison is equal, break tie with name
      if (comparison == 0 && sortField != BrandSortField.name) {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }

      return sortAscending ? comparison : -comparison;
    });

    return list;
  }

  Future<void> moveBrandUp(int index) async {
    if (state is! BrandLoaded) return;
    final currentState = state as BrandLoaded;
    final list = currentState.filteredBrands;
    if (index <= 0 || index >= list.length) return;

    final current = list[index];
    final previous = list[index - 1];

    int newCurrentOrder;
    int newPrevOrder;

    if (current.sortOrder > previous.sortOrder) {
      newCurrentOrder = previous.sortOrder;
      newPrevOrder = current.sortOrder;
    } else if (current.sortOrder == previous.sortOrder) {
      newCurrentOrder = previous.sortOrder;
      newPrevOrder = previous.sortOrder + 1;
    } else {
      newCurrentOrder = previous.sortOrder <= 1 ? 0 : previous.sortOrder - 1;
      newPrevOrder = previous.sortOrder;
    }

    try {
      await brandRepository.updateBrandOrdersBatch({
        current.id: newCurrentOrder,
        previous.id: newPrevOrder,
      });
      await loadBrands(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> moveBrandDown(int index) async {
    if (state is! BrandLoaded) return;
    final currentState = state as BrandLoaded;
    final list = currentState.filteredBrands;
    if (index < 0 || index >= list.length - 1) return;

    final current = list[index];
    final next = list[index + 1];

    int newCurrentOrder;
    int newNextOrder;

    if (current.sortOrder < next.sortOrder) {
      newCurrentOrder = next.sortOrder;
      newNextOrder = current.sortOrder;
    } else if (current.sortOrder == next.sortOrder) {
      newCurrentOrder = next.sortOrder + 1;
      newNextOrder = next.sortOrder;
    } else {
      newCurrentOrder = next.sortOrder + 1;
      newNextOrder = next.sortOrder;
    }

    try {
      await brandRepository.updateBrandOrdersBatch({
        current.id: newCurrentOrder,
        next.id: newNextOrder,
      });
      await loadBrands(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderBrands(int oldIndex, int newIndex) async {
    if (state is! BrandLoaded) return;
    final currentState = state as BrandLoaded;
    final list = List<BrandModel>.from(currentState.filteredBrands);

    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return;
    }

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final Map<String, int> updates = {};
    for (int i = 0; i < list.length; i++) {
      final updatedOrder = i + 1;
      if (list[i].sortOrder != updatedOrder) {
        list[i] = list[i].copyWith(sortOrder: updatedOrder);
        updates[list[i].id] = updatedOrder;
      }
    }

    // Also update all brands in state
    final updatedAllBrands = List<BrandModel>.from(currentState.brands);
    for (int i = 0; i < updatedAllBrands.length; i++) {
      if (updates.containsKey(updatedAllBrands[i].id)) {
        updatedAllBrands[i] = updatedAllBrands[i].copyWith(
          sortOrder: updates[updatedAllBrands[i].id],
        );
      }
    }

    // Optimistically update state
    emit(currentState.copyWith(brands: updatedAllBrands, filteredBrands: list));

    if (updates.isNotEmpty) {
      if (reorderDebounceDuration == Duration.zero) {
        await flushPendingReorder();
      } else {
        _reorderDebounceTimer?.cancel();
        _reorderDebounceTimer = Timer(reorderDebounceDuration, () {
          flushPendingReorder();
        });
      }
    }
  }

  /// Flushes any pending reorder updates in a single batch to Firestore,
  /// strictly committing only items whose order actually differs from the database baseline.
  Future<void> flushPendingReorder() async {
    _reorderDebounceTimer?.cancel();
    _reorderDebounceTimer = null;
    if (state is! BrandLoaded) return;

    final currentBrands = (state as BrandLoaded).brands;
    final Map<String, int> updatesToCommit = {};

    for (final b in currentBrands) {
      final baseline = _baselineOrders[b.id];
      if (baseline != null && b.sortOrder != baseline) {
        updatesToCommit[b.id] = b.sortOrder;
      }
    }

    if (updatesToCommit.isEmpty) return;

    try {
      await brandRepository.updateBrandOrdersBatch(updatesToCommit);
      _baselineOrders.addAll(updatesToCommit);
      await loadBrands(silent: true);
    } catch (e) {
      await loadBrands(silent: true);
      rethrow;
    }
  }

  Future<void> addBrand(BrandModel brand) async {
    await flushPendingReorder();
    try {
      var brandToAdd = brand;
      if (brand.sortOrder == 0 && state is BrandLoaded) {
        final currentBrands = (state as BrandLoaded).brands;
        final maxOrder = currentBrands.isEmpty
            ? 0
            : currentBrands
                  .map((b) => b.sortOrder)
                  .fold<int>(0, (max, val) => val > max ? val : max);
        brandToAdd = brand.copyWith(sortOrder: maxOrder + 1);
      }
      await brandRepository.addBrand(brandToAdd);
      await loadBrands(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBrand(BrandModel brand) async {
    await flushPendingReorder();
    try {
      await brandRepository.updateBrand(brand);
      await loadBrands(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBrand(String brandId) async {
    await flushPendingReorder();
    try {
      await brandRepository.deleteBrand(brandId);
      await loadBrands(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_reorderDebounceTimer?.isActive ?? false) {
      await flushPendingReorder();
    }
    _reorderDebounceTimer?.cancel();
    return super.close();
  }
}
