import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_state.dart';

export 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository expenseRepository;
  StreamSubscription<List<ExpenseModel>>? _streamSubscription;

  ExpenseCubit([ExpenseRepository? repository])
      : expenseRepository = repository ?? ExpenseRepositoryImpl(),
        super(const ExpenseInitial());

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }

  void loadExpenses() {
    emit(const ExpenseLoading());
    _streamSubscription?.cancel();
    _streamSubscription = expenseRepository.getExpensesStream().listen(
      (expenses) {
        final currentQuery = (state is ExpenseLoaded) ? (state as ExpenseLoaded).searchQuery : '';
        final currentCat = (state is ExpenseLoaded) ? (state as ExpenseLoaded).selectedCategory : null;
        final currentDateRange = (state is ExpenseLoaded) ? (state as ExpenseLoaded).selectedDateRange : null;

        final filtered = _applyFilters(
          expenses,
          query: currentQuery,
          category: currentCat,
          dateRange: currentDateRange,
        );

        emit(ExpenseLoaded(
          expenses: expenses,
          filteredExpenses: filtered,
          searchQuery: currentQuery,
          selectedCategory: currentCat,
          selectedDateRange: currentDateRange,
        ));
      },
      onError: (e) {
        emit(ExpenseError(e.toString()));
      },
    );
  }

  void filterExpenses({
    String? query,
    ExpenseCategory? category,
    bool clearCategory = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    if (state is! ExpenseLoaded) return;
    final currentState = state as ExpenseLoaded;

    final effectiveQuery = query ?? currentState.searchQuery;
    final effectiveCategory = clearCategory ? null : (category ?? currentState.selectedCategory);
    final effectiveDateRange = clearDateRange ? null : (dateRange ?? currentState.selectedDateRange);

    final filtered = _applyFilters(
      currentState.expenses,
      query: effectiveQuery,
      category: effectiveCategory,
      dateRange: effectiveDateRange,
    );

    emit(currentState.copyWith(
      filteredExpenses: filtered,
      searchQuery: effectiveQuery,
      selectedCategory: effectiveCategory,
      clearCategory: clearCategory,
      selectedDateRange: effectiveDateRange,
      clearDateRange: clearDateRange,
    ));
  }

  List<ExpenseModel> _applyFilters(
    List<ExpenseModel> list, {
    String query = '',
    ExpenseCategory? category,
    DateTimeRange? dateRange,
  }) {
    var result = list;

    // 1. Category Filter
    if (category != null) {
      result = result.where((e) => e.category == category).toList();
    }

    // 2. Date Range Filter
    if (dateRange != null) {
      final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
      result = result.where((e) {
        return e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    // 3. Search Query Filter
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.notes.toLowerCase().contains(q) ||
            e.recordedBy.toLowerCase().contains(q) ||
            e.paymentMethod.toLowerCase().contains(q) ||
            e.amount.toString().contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await expenseRepository.addExpense(expense);
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await expenseRepository.updateExpense(expense);
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await expenseRepository.deleteExpense(id);
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}
