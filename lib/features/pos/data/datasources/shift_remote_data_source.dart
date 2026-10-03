import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../models/cashier_shift_model.dart';
import '../models/shift_transaction_model.dart';

abstract class ShiftRemoteDataSource {
  Future<CashierShiftModel> openShift(CashierShiftModel shift);
  Future<CashierShiftModel?> getActiveShift({String? cashierId, String? branchId});
  Stream<CashierShiftModel?> getActiveShiftStream({String? cashierId, String? branchId});
  Future<void> recordShiftSale({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  });
  Future<void> recordCashIn({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  });
  Future<void> recordCashOut({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  });
  Future<void> recordShiftReturn({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  });
  Future<CashierShiftModel> closeShift({
    required String shiftId,
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  });
  Future<CashierShiftModel?> getLastClosedShift({String? branchId});
  Future<List<CashierShiftModel>> getShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  });
  Future<List<ShiftTransactionModel>> getShiftTransactions(String shiftId);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final FirebaseFirestore _firestore;

  ShiftRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference get _shiftsCol => _firestore.collection('cashier_shifts');
  CollectionReference get _shiftTxCol => _firestore.collection('shift_transactions');

  @override
  Future<CashierShiftModel> openShift(CashierShiftModel shift) async {
    try {
      final docRef = _shiftsCol.doc();
      final newShift = shift.copyWith(
        id: docRef.id,
        expectedCash: shift.openingCash,
        status: 'open',
      );
      await docRef.set(newShift.toJson());
      return newShift;
    } catch (e) {
      debugPrint('Error opening cashier shift: $e');
      rethrow;
    }
  }

  @override
  Future<CashierShiftModel?> getActiveShift({String? cashierId, String? branchId}) async {
    try {
      Query query = _shiftsCol.where('status', isEqualTo: 'open');
      if (branchId != null && branchId.isNotEmpty) {
        query = query.where('branchId', isEqualTo: branchId);
      }
      if (cashierId != null && cashierId.isNotEmpty) {
        query = query.where('cashierId', isEqualTo: cashierId);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return CashierShiftModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active shift: $e');
      return null;
    }
  }

  @override
  Stream<CashierShiftModel?> getActiveShiftStream({String? cashierId, String? branchId}) {
    Query query = _shiftsCol.where('status', isEqualTo: 'open');
    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }

    return query.limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return CashierShiftModel.fromJson(data);
      }
      return null;
    });
  }

  @override
  Future<void> recordShiftSale({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (shiftId.isEmpty || amount <= 0) return;
    try {
      final docRef = _shiftsCol.doc(shiftId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = Map<String, dynamic>.from(snapshot.data() as Map);
        final currentShift = CashierShiftModel.fromJson(data);

        double cashS = currentShift.cashSales;
        double cardS = currentShift.cardSales;
        double instaS = currentShift.instapaySales;
        double vfS = currentShift.vodafoneCashSales;

        final method = paymentMethod.toLowerCase();
        if (method == 'card' || method == 'visa') {
          cardS += amount;
        } else if (method == 'instapay') {
          instaS += amount;
        } else if (method == 'vodafone' || method == 'vodafone_cash' || method == 'wallet') {
          vfS += amount;
        } else {
          cashS += amount;
        }

        final newTotalSales = currentShift.totalSales + amount;
        final newOrdersCount = currentShift.ordersCount + 1;
        final newExpectedCash = currentShift.openingCash + cashS + currentShift.cashIns - currentShift.cashOuts - currentShift.cashRefunds;

        transaction.update(docRef, {
          'cashSales': cashS,
          'cardSales': cardS,
          'instapaySales': instaS,
          'vodafoneCashSales': vfS,
          'totalSales': newTotalSales,
          'ordersCount': newOrdersCount,
          'expectedCash': newExpectedCash,
        });
      });
    } catch (e) {
      debugPrint('Error recording shift sale: $e');
    }
  }

  @override
  Future<void> recordCashIn({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    if (shiftId.isEmpty || amount <= 0) return;
    try {
      final shiftSnap = await _shiftsCol.doc(shiftId).get();
      String branchId = '';
      if (shiftSnap.exists) {
        branchId = (shiftSnap.data() as Map<String, dynamic>?)?['branchId']?.toString() ?? '';
      }

      final txRef = _shiftTxCol.doc();
      final treasuryRef = _firestore.collection('treasury_transactions').doc();
      final now = DateTime.now();

      final tx = ShiftTransactionModel(
        id: txRef.id,
        shiftId: shiftId,
        type: ShiftTransactionType.cashIn,
        amount: amount,
        reason: reason,
        createdAt: now,
        performedBy: performedBy,
      );

      final shiftRef = _shiftsCol.doc(shiftId);
      final batch = _firestore.batch();
      batch.set(txRef, tx.toJson());
      batch.update(shiftRef, {
        'cashIns': FieldValue.increment(amount),
        'expectedCash': FieldValue.increment(amount),
      });

      // Sync to Treasury Transactions
      batch.set(treasuryRef, {
        'id': treasuryRef.id,
        'type': 'cashIn',
        'channel': 'cash',
        'amount': amount,
        'reason': reason.isNotEmpty ? reason : 'إيداع نقدية في وردية الكاشير',
        'shiftId': shiftId,
        'branchId': branchId,
        'performedBy': performedBy,
        'createdAt': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error recording shift cash-in: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordCashOut({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    if (shiftId.isEmpty || amount <= 0) return;
    try {
      final shiftSnap = await _shiftsCol.doc(shiftId).get();
      String branchId = '';
      if (shiftSnap.exists) {
        branchId = (shiftSnap.data() as Map<String, dynamic>?)?['branchId']?.toString() ?? '';
      }

      final txRef = _shiftTxCol.doc();
      final treasuryRef = _firestore.collection('treasury_transactions').doc();
      final expRef = _firestore.collection('expenses').doc();
      final now = DateTime.now();

      final tx = ShiftTransactionModel(
        id: txRef.id,
        shiftId: shiftId,
        type: ShiftTransactionType.cashOut,
        amount: amount,
        reason: reason,
        createdAt: now,
        performedBy: performedBy,
      );

      final shiftRef = _shiftsCol.doc(shiftId);
      final batch = _firestore.batch();
      batch.set(txRef, tx.toJson());
      batch.update(shiftRef, {
        'cashOuts': FieldValue.increment(amount),
        'expectedCash': FieldValue.increment(-amount),
      });

      // Sync to Treasury Transactions
      batch.set(treasuryRef, {
        'id': treasuryRef.id,
        'type': 'expense',
        'channel': 'cash',
        'amount': amount,
        'reason': reason.isNotEmpty ? reason : 'صرف نقدية من وردية الكاشير',
        'shiftId': shiftId,
        'branchId': branchId,
        'performedBy': performedBy,
        'expenseId': expRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      // Sync to Expenses Collection
      final cat = ExpenseCategory.fromString(reason);
      batch.set(expRef, {
        'title': reason.isNotEmpty ? reason : 'صرف من درج الكاشير',
        'amount': amount,
        'category': cat.id,
        'date': Timestamp.fromDate(now),
        'paymentMethod': 'cash',
        'recordedBy': performedBy.isNotEmpty ? performedBy : 'Cashier',
        'notes': 'صرف من وردية الكاشير',
        'shiftId': shiftId,
        'branchId': branchId,
        'treasuryTransactionId': treasuryRef.id,
        'createdAt': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error recording shift cash-out: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordShiftReturn({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (shiftId.isEmpty || amount <= 0) return;
    try {
      final shiftRef = _shiftsCol.doc(shiftId);
      final isCash = paymentMethod.toLowerCase() == 'cash';
      if (isCash) {
        await shiftRef.update({
          'cashRefunds': FieldValue.increment(amount),
          'expectedCash': FieldValue.increment(-amount),
        });
      } else {
        await shiftRef.update({
          'cashRefunds': FieldValue.increment(amount),
        });
      }
    } catch (e) {
      debugPrint('Error recording shift return: $e');
    }
  }

  @override
  Future<CashierShiftModel> closeShift({
    required String shiftId,
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  }) async {
    try {
      final docRef = _shiftsCol.doc(shiftId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('Shift not found');
      }

      final data = Map<String, dynamic>.from(snapshot.data() as Map);
      final currentShift = CashierShiftModel.fromJson(data);

      final expCash = currentShift.calculatedExpectedCash;
      final diff = actualCountedCash - expCash;
      final now = DateTime.now();

      final updatedData = <String, dynamic>{
        'status': 'closed',
        'closedAt': Timestamp.fromDate(now),
        'expectedCash': expCash,
        'actualCountedCash': actualCountedCash,
        'difference': diff,
        'closingNotes': closingNotes,
        'closedBy': closedBy,
      };

      await docRef.update(updatedData);

      // Auto-Reconcile Cash Discrepancy in Treasury & Accounting
      if (diff.abs() >= 0.01) {
        try {
          final treasuryRef = _firestore.collection('treasury_transactions').doc();
          final isShortage = diff < 0;
          final absDiff = diff.abs();

          await treasuryRef.set({
            'id': treasuryRef.id,
            'type': isShortage ? 'expense' : 'cashIn',
            'channel': 'cash',
            'amount': absDiff,
            'reason': isShortage
                ? 'تسوية عجز نقدية درج وردية كاشير (${currentShift.cashierName} - ${currentShift.branchName})'
                : 'تسوية زيادة نقدية درج وردية كاشير (${currentShift.cashierName} - ${currentShift.branchName})',
            'referenceNumber': 'SHIFT-SETTLE-$shiftId',
            'shiftId': shiftId,
            'branchId': currentShift.branchId,
            'performedBy': closedBy.isNotEmpty ? closedBy : currentShift.cashierName,
            'createdAt': Timestamp.fromDate(now),
          });

          // If it is a deficit/loss, also record in expenses under operational loss for clean accounting
          if (isShortage) {
            final expRef = _firestore.collection('expenses').doc();
            await expRef.set({
              'title': 'عجز نقدية درج كاشير (${currentShift.cashierName})',
              'amount': absDiff,
              'category': 'operational',
              'date': Timestamp.fromDate(now),
              'paymentMethod': 'cash',
              'recordedBy': closedBy.isNotEmpty ? closedBy : currentShift.cashierName,
              'notes': 'تسوية عجز نقدية وردية ${currentShift.branchName}',
              'shiftId': shiftId,
              'branchId': currentShift.branchId,
              'treasuryTransactionId': treasuryRef.id,
              'createdAt': Timestamp.fromDate(now),
            });
          }
        } catch (err) {
          debugPrint('⚠️ Error auto-reconciling shift cash discrepancy: $err');
        }
      }

      return currentShift.copyWith(
        status: 'closed',
        closedAt: now,
        expectedCash: expCash,
        actualCountedCash: actualCountedCash,
        difference: diff,
        closingNotes: closingNotes,
        closedBy: closedBy,
      );
    } catch (e) {
      debugPrint('Error closing shift: $e');
      rethrow;
    }
  }

  @override
  Future<CashierShiftModel?> getLastClosedShift({String? branchId}) async {
    try {
      Query query = _shiftsCol.where('status', isEqualTo: 'closed');
      if (branchId != null && branchId.isNotEmpty && branchId != 'ALL') {
        query = query.where('branchId', isEqualTo: branchId);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          return CashierShiftModel.fromJson(data);
        }).toList();
        docs.sort((a, b) => (b.closedAt ?? b.openedAt).compareTo(a.closedAt ?? a.openedAt));
        return docs.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last closed shift: $e');
      return null;
    }
  }

  @override
  Future<List<CashierShiftModel>> getShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  }) async {
    try {
      Query query = _shiftsCol.orderBy('openedAt', descending: true);

      if (startDate != null) {
        query = query.where('openedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('openedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (branchId != null && branchId.isNotEmpty && branchId != 'ALL') {
        query = query.where('branchId', isEqualTo: branchId);
      }
      if (cashierId != null && cashierId.isNotEmpty && cashierId != 'ALL') {
        query = query.where('cashierId', isEqualTo: cashierId);
      }

      final snapshot = await query.limit(100).get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return CashierShiftModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting shifts history: $e');
      return [];
    }
  }

  @override
  Future<List<ShiftTransactionModel>> getShiftTransactions(String shiftId) async {
    try {
      final snapshot = await _shiftTxCol
          .where('shiftId', isEqualTo: shiftId)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return ShiftTransactionModel.fromJson(data);
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('Error getting shift transactions: $e');
      return [];
    }
  }
}
