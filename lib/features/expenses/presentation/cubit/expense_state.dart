import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/models/expense_model.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final List<ExpenseModel> filteredExpenses;
  final String searchQuery;
  final ExpenseCategory? selectedCategory;
  final DateTimeRange? selectedDateRange;

  const ExpenseLoaded({
    required this.expenses,
    required this.filteredExpenses,
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedDateRange,
  });

  /// Total sum of all expenses currently filtered
  double get totalFilteredAmount =>
      filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  /// Total sum of all expenses in database
  double get totalAllAmount =>
      expenses.fold(0.0, (sum, item) => sum + item.amount);

  /// Total sum of today's expenses
  double get todayAmount {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Total sum of current month's expenses
  double get thisMonthAmount {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Category breakdown: map from ExpenseCategory to total amount spent
  Map<ExpenseCategory, double> get categoryBreakdown {
    final map = <ExpenseCategory, double>{};
    for (final exp in filteredExpenses) {
      map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
    }
    return map;
  }

  /// Category with the highest spending
  ExpenseCategory? get topCategory {
    final breakdown = categoryBreakdown;
    if (breakdown.isEmpty) return null;
    var maxEntry = breakdown.entries.first;
    for (final entry in breakdown.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  ExpenseLoaded copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseModel>? filteredExpenses,
    String? searchQuery,
    ExpenseCategory? selectedCategory,
    bool clearCategory = false,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedDateRange:
          clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        filteredExpenses,
        searchQuery,
        selectedCategory,
        selectedDateRange,
      ];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
