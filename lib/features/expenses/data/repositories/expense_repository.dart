import 'package:flutter/foundation.dart';
import '../datasources/expense_remote_data_source.dart';
import '../models/expense_model.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseModel>> getExpenses();
  Stream<List<ExpenseModel>> getExpensesStream();
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({ExpenseRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? ExpenseRemoteDataSourceImpl();

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      return await remoteDataSource.getExpenses();
    } catch (e) {
      debugPrint('Firestore Expenses fetch note: $e');
      return [];
    }
  }

  @override
  Stream<List<ExpenseModel>> getExpensesStream() {
    return remoteDataSource.getExpensesStream();
  }

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) =>
      remoteDataSource.addExpense(expense);

  @override
  Future<void> updateExpense(ExpenseModel expense) =>
      remoteDataSource.updateExpense(expense);

  @override
  Future<void> deleteExpense(String id) =>
      remoteDataSource.deleteExpense(id);
}
