import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/models/damaged_stock_model.dart';

abstract class DamagedStockState extends Equatable {
  const DamagedStockState();

  @override
  List<Object?> get props => [];
}

class DamagedStockInitial extends DamagedStockState {
  const DamagedStockInitial();
}

class DamagedStockLoading extends DamagedStockState {
  const DamagedStockLoading();
}

class DamagedStockLoaded extends DamagedStockState {
  final List<DamagedStockModel> allDamaged;
  final List<DamagedStockModel> filteredDamaged;
  final String searchQuery;
  final DamagedReason? selectedReason;
  final DateTimeRange? selectedDateRange;

  const DamagedStockLoaded({
    required this.allDamaged,
    required this.filteredDamaged,
    this.searchQuery = '',
    this.selectedReason,
    this.selectedDateRange,
  });

  /// Total Financial Loss based on Cost Price (for filtered items)
  double get totalFilteredLoss =>
      filteredDamaged.fold(0.0, (sum, item) => sum + item.totalLoss);

  /// Total units damaged (for filtered items)
  int get totalFilteredUnits =>
      filteredDamaged.fold(0, (sum, item) => sum + item.quantity);

  /// Total Financial Loss in current month
  double get thisMonthLoss {
    final now = DateTime.now();
    return allDamaged.where((item) {
      return item.createdAt.year == now.year && item.createdAt.month == now.month;
    }).fold(0.0, (sum, item) => sum + item.totalLoss);
  }

  /// Total Financial Loss today
  double get todayLoss {
    final now = DateTime.now();
    return allDamaged.where((item) {
      return item.createdAt.year == now.year &&
          item.createdAt.month == now.month &&
          item.createdAt.day == now.day;
    }).fold(0.0, (sum, item) => sum + item.totalLoss);
  }

  /// Most frequent reason for damage / waste
  DamagedReason? get topReason {
    if (filteredDamaged.isEmpty) return null;
    final Map<DamagedReason, double> lossByReason = {};
    for (final item in filteredDamaged) {
      lossByReason[item.reason] = (lossByReason[item.reason] ?? 0.0) + item.totalLoss;
    }
    DamagedReason? top;
    double maxLoss = -1;
    lossByReason.forEach((reason, loss) {
      if (loss > maxLoss) {
        maxLoss = loss;
        top = reason;
      }
    });
    return top;
  }

  DamagedStockLoaded copyWith({
    List<DamagedStockModel>? allDamaged,
    List<DamagedStockModel>? filteredDamaged,
    String? searchQuery,
    DamagedReason? selectedReason,
    bool clearReason = false,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
  }) {
    return DamagedStockLoaded(
      allDamaged: allDamaged ?? this.allDamaged,
      filteredDamaged: filteredDamaged ?? this.filteredDamaged,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedReason: clearReason ? null : (selectedReason ?? this.selectedReason),
      selectedDateRange:
          clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
    );
  }

  @override
  List<Object?> get props => [
        allDamaged,
        filteredDamaged,
        searchQuery,
        selectedReason,
        selectedDateRange,
      ];
}

class DamagedStockError extends DamagedStockState {
  final String message;

  const DamagedStockError(this.message);

  @override
  List<Object?> get props => [message];
}
