import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Stream<List<ExpenseModel>> getExpensesStream();
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore;

  ExpenseRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final snapshot = await _firestore
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Firestore getExpenses error: $e');
      // Fallback without ordering if composite index is pending
      final snapshot = await _firestore.collection('expenses').get();
      final list = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  @override
  Stream<List<ExpenseModel>> getExpensesStream() {
    return _firestore
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final docRef = await _firestore.collection('expenses').add(expense.toMap());
    return expense.copyWith(id: docRef.id);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }
}
