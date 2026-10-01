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
    try {
      final expenseDocRef = _firestore.collection('expenses').doc();
      final txDocRef = _firestore.collection('treasury_transactions').doc();

      // Map payment method to PaymentChannelType
      String channelStr = 'cash';
      final method = expense.paymentMethod.toLowerCase();
      if (method.contains('card') || method.contains('visa') || method.contains('pos') || method.contains('bank')) {
        channelStr = 'card';
      } else if (method.contains('insta')) {
        channelStr = 'instapay';
      } else if (method.contains('voda') || method.contains('wallet')) {
        channelStr = 'vodafoneCash';
      }

      final fullExpense = expense.copyWith(
        id: expenseDocRef.id,
        treasuryTransactionId: txDocRef.id,
      );

      final batch = _firestore.batch();
      batch.set(expenseDocRef, fullExpense.toMap());

      final reasonStr = expense.title.isNotEmpty
          ? '${expense.title}${expense.notes.isNotEmpty ? ' - ${expense.notes}' : ''}'
          : 'مصروف تشغيلي';

      final txData = <String, dynamic>{
        'id': txDocRef.id,
        'type': 'expense',
        'channel': channelStr,
        'amount': expense.amount,
        'reason': reasonStr,
        'performedBy': expense.recordedBy.isNotEmpty ? expense.recordedBy : 'Admin',
        'expenseId': expenseDocRef.id,
        'createdAt': Timestamp.fromDate(expense.date),
      };
      if (expense.branchId != null && expense.branchId!.isNotEmpty) {
        txData['branchId'] = expense.branchId;
      }
      if (expense.shiftId != null && expense.shiftId!.isNotEmpty) {
        txData['shiftId'] = expense.shiftId;
      }

      batch.set(txDocRef, txData);
      await batch.commit();

      return fullExpense;
    } catch (e) {
      debugPrint('Firestore addExpense error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final batch = _firestore.batch();
      final expDocRef = _firestore.collection('expenses').doc(expense.id);
      batch.update(expDocRef, expense.toMap());

      if (expense.treasuryTransactionId != null && expense.treasuryTransactionId!.isNotEmpty) {
        final txDocRef = _firestore.collection('treasury_transactions').doc(expense.treasuryTransactionId);
        batch.update(txDocRef, {
          'amount': expense.amount,
          'reason': '${expense.title}${expense.notes.isNotEmpty ? ' - ${expense.notes}' : ''}',
          'performedBy': expense.recordedBy,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore updateExpense error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final doc = await _firestore.collection('expenses').doc(id).get();
      final txId = doc.data()?['treasuryTransactionId']?.toString();

      final batch = _firestore.batch();
      batch.delete(_firestore.collection('expenses').doc(id));

      if (txId != null && txId.isNotEmpty) {
        batch.delete(_firestore.collection('treasury_transactions').doc(txId));
      } else {
        final linkedSnap = await _firestore
            .collection('treasury_transactions')
            .where('expenseId', isEqualTo: id)
            .get();
        for (final d in linkedSnap.docs) {
          batch.delete(d.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore deleteExpense error: $e');
      rethrow;
    }
  }
}
