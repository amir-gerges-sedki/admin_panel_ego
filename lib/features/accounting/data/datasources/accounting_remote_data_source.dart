import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/profit_loss_model.dart';
import '../models/treasury_summary_model.dart';
import '../models/treasury_transaction_model.dart';

abstract class AccountingRemoteDataSource {
  Future<TreasurySummaryModel> getTreasurySummary({String? branchId});
  Future<ProfitLossModel> getProfitAndLoss({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  });
  Future<List<TreasuryTransactionModel>> getTreasuryTransactions({
    int limit = 100,
    String? branchId,
  });
  Future<TreasuryTransactionModel> recordTreasuryTransaction(
      TreasuryTransactionModel transaction);
  Future<void> updateTreasuryTransaction(
      TreasuryTransactionModel transaction);
  Future<void> deleteTreasuryTransaction(String id);
}

class AccountingRemoteDataSourceImpl implements AccountingRemoteDataSource {
  final FirebaseFirestore _firestore;

  AccountingRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  // --------------------------------------------------------------------------
  // 1. Live Treasury & Working Capital Balances
  // --------------------------------------------------------------------------
  @override
  Future<TreasurySummaryModel> getTreasurySummary({String? branchId}) async {
    try {
      // 1. Sum up all completed Orders by Payment Method
      double cashInFromSales = 0.0;
      double cardInFromSales = 0.0;
      double instapayInFromSales = 0.0;
      double vodafoneInFromSales = 0.0;

      final ordersSnap = await _firestore
          .collection('Orders')
          .where('paymentStatus', whereIn: ['paid', 'completed', 'delivered'])
          .get();

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        if (branchId != null &&
            branchId.isNotEmpty &&
            data['branchId'] != null &&
            data['branchId'] != branchId) {
          continue;
        }

        final amount = (data['totalAmount'] as num?)?.toDouble() ??
            (data['totalPrice'] as num?)?.toDouble() ??
            0.0;
        final method = (data['paymentMethod'] ?? 'cash').toString().toLowerCase();

        if (method.contains('card') || method.contains('visa') || method.contains('pos')) {
          cardInFromSales += amount;
        } else if (method.contains('insta')) {
          instapayInFromSales += amount;
        } else if (method.contains('voda') || method.contains('wallet')) {
          vodafoneInFromSales += amount;
        } else {
          cashInFromSales += amount;
        }
      }

      // 2. Track all recorded Expenses & Deductions
      double cashExpenses = 0.0;
      double cardExpenses = 0.0;
      double instapayExpenses = 0.0;
      double vodafoneExpenses = 0.0;
      final Set<String> linkedTreasuryTxIds = {};

      final expenseSnap = await _firestore.collection('expenses').get();
      for (final doc in expenseSnap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final method = (data['paymentMethod'] ?? 'cash').toString().toLowerCase();
        final txId = data['treasuryTransactionId']?.toString();
        if (txId != null && txId.isNotEmpty) {
          linkedTreasuryTxIds.add(txId);
        }

        if (method.contains('card') || method.contains('visa') || method.contains('pos') || method.contains('bank')) {
          cardExpenses += amount;
        } else if (method.contains('insta')) {
          instapayExpenses += amount;
        } else if (method.contains('voda') || method.contains('wallet')) {
          vodafoneExpenses += amount;
        } else {
          cashExpenses += amount;
        }
      }

      // 3. Subtract Supplier Payments
      double cashSupplierPayments = 0.0;
      final supPaySnap = await _firestore.collection('supplier_payments').get();
      for (final doc in supPaySnap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        cashSupplierPayments += amount;
      }

      // 4. Calculate Supplier Payables (Total Unpaid Debts)
      double totalSupplierPayables = 0.0;
      try {
        final suppliersSnap = await _firestore.collection('suppliers').get();
        for (final doc in suppliersSnap.docs) {
          final data = doc.data();
          final balance = (data['balanceDue'] as num?)?.toDouble() ?? 0.0;
          if (balance > 0) {
            totalSupplierPayables += balance;
          }
        }
      } catch (_) {}

      // 5. Calculate Total Inventory Cost Value
      double totalInventoryCost = 0.0;
      try {
        final prodSnap = await _firestore.collection('Products').get();
        for (final doc in prodSnap.docs) {
          final data = doc.data();
          final stock = (data['stock'] as num?)?.toInt() ?? 0;
          final cost = (data['costPrice'] as num?)?.toDouble() ??
              ((data['price'] as num?)?.toDouble() ?? 0.0) * 0.7; // default 70% if no cost
          totalInventoryCost += (stock * cost);
        }
      } catch (_) {}

      // 6. Incorporate Manual Treasury Transactions (Deposits / Withdrawals / Transfers)
      double manualCashNet = 0.0;
      double manualCardNet = 0.0;
      double manualInstapayNet = 0.0;
      double manualVodafoneNet = 0.0;

      try {
        final transSnap = await _firestore.collection('treasury_transactions').get();
        for (final doc in transSnap.docs) {
          // If this treasury transaction was already counted from expenses collection, skip to prevent double subtraction
          if (linkedTreasuryTxIds.contains(doc.id)) continue;

          final t = TreasuryTransactionModel.fromJson(doc.data(), doc.id);
          final sign = (t.type == TreasuryTransactionType.cashIn ||
                  t.type == TreasuryTransactionType.capitalInjection)
              ? 1.0
              : -1.0;

          switch (t.channel) {
            case PaymentChannelType.cash:
              manualCashNet += (sign * t.amount);
              break;
            case PaymentChannelType.card:
              manualCardNet += (sign * t.amount);
              break;
            case PaymentChannelType.instapay:
              manualInstapayNet += (sign * t.amount);
              break;
            case PaymentChannelType.vodafoneCash:
              manualVodafoneNet += (sign * t.amount);
              break;
          }
        }
      } catch (_) {}

      final netCash = (cashInFromSales - cashExpenses - cashSupplierPayments + manualCashNet);
      final netCard = (cardInFromSales - cardExpenses + manualCardNet);
      final netInstapay = (instapayInFromSales - instapayExpenses + manualInstapayNet);
      final netVodafone = (vodafoneInFromSales - vodafoneExpenses + manualVodafoneNet);

      return TreasurySummaryModel(
        cashBalance: netCash,
        cardBalance: netCard,
        instapayBalance: netInstapay,
        vodafoneCashBalance: netVodafone,
        supplierPayables: totalSupplierPayables,
        customerReceivables: 0.0,
        inventoryCostValue: totalInventoryCost,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Firestore getTreasurySummary error: $e');
      return TreasurySummaryModel(lastUpdated: DateTime.now());
    }
  }

  // --------------------------------------------------------------------------
  // 2. Accurate Profit & Loss (P&L) within Date Range
  // --------------------------------------------------------------------------
  @override
  Future<ProfitLossModel> getProfitAndLoss({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      final startStamp = Timestamp.fromDate(startDate);
      final endStamp = Timestamp.fromDate(endDate);

      // 1. Fetch Orders within date range
      double grossSales = 0.0;
      double discounts = 0.0;
      double netRevenue = 0.0;
      double totalCogs = 0.0;
      int ordersCount = 0;
      int itemsSold = 0;

      Query<Map<String, dynamic>> orderQuery = _firestore
          .collection('Orders')
          .where('orderDate', isGreaterThanOrEqualTo: startStamp)
          .where('orderDate', isLessThanOrEqualTo: endStamp);

      final orderSnap = await orderQuery.get();
      for (final doc in orderSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled' || status == 'returned') continue;

        ordersCount++;
        final totalAmount = (data['totalAmount'] as num?)?.toDouble() ??
            (data['totalPrice'] as num?)?.toDouble() ??
            0.0;
        final discountVal = (data['discount'] as num?)?.toDouble() ?? 0.0;
        final subTotal = (data['subTotal'] as num?)?.toDouble() ?? (totalAmount + discountVal);

        grossSales += subTotal;
        discounts += discountVal;
        netRevenue += totalAmount;

        // Calculate COGS per item sold
        final items = data['items'];
        if (items is List) {
          for (final raw in items) {
            if (raw is Map) {
              final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
              itemsSold += qty;
              final unitPrice = (raw['price'] as num?)?.toDouble() ?? 0.0;
              // If unit cost is explicitly snapshotted on item:
              final unitCost = (raw['costPrice'] as num?)?.toDouble() ??
                  (unitPrice * 0.7); // Fallback: estimated 70% cost
              totalCogs += (unitCost * qty);
            }
          }
        }
      }

      // 2. Fetch Operating Expenses within date range (from expenses collection & unmirrored treasury transactions)
      double operatingExpenses = 0.0;
      final Set<String> processedTreasuryIds = {};

      try {
        final expenseSnap = await _firestore
            .collection('expenses')
            .where('date', isGreaterThanOrEqualTo: startStamp)
            .where('date', isLessThanOrEqualTo: endStamp)
            .get();

        for (final doc in expenseSnap.docs) {
          final data = doc.data();
          operatingExpenses += (data['amount'] as num?)?.toDouble() ?? 0.0;
          final txId = data['treasuryTransactionId']?.toString();
          if (txId != null && txId.isNotEmpty) {
            processedTreasuryIds.add(txId);
          }
        }
      } catch (_) {
        // Fallback without server filter
        final allExpenses = await _firestore.collection('expenses').get();
        for (final doc in allExpenses.docs) {
          final data = doc.data();
          final rawDate = data['date'];
          DateTime expDate = DateTime.now();
          if (rawDate is Timestamp) expDate = rawDate.toDate();
          if (expDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              expDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
            operatingExpenses += (data['amount'] as num?)?.toDouble() ?? 0.0;
            final txId = data['treasuryTransactionId']?.toString();
            if (txId != null && txId.isNotEmpty) {
              processedTreasuryIds.add(txId);
            }
          }
        }
      }

      // Also include any expense/withdrawal from treasury_transactions not recorded in expenses collection
      try {
        final txSnap = await _firestore.collection('treasury_transactions').get();
        for (final doc in txSnap.docs) {
          if (processedTreasuryIds.contains(doc.id)) continue;
          final data = doc.data();
          final typeStr = (data['type'] ?? '').toString().toLowerCase();
          if (typeStr == 'expense' || typeStr == 'cashout' || typeStr == 'withdrawal') {
            final rawDate = data['createdAt'];
            DateTime txDate = DateTime.now();
            if (rawDate is Timestamp) txDate = rawDate.toDate();
            if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
              final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
              operatingExpenses += amt;
            }
          }
        }
      } catch (_) {}

      // 3. Fetch Damaged Stock Loss within date range
      double damagedLoss = 0.0;
      try {
        final dmgSnap = await _firestore
            .collection('damaged_stock')
            .where('createdAt', isGreaterThanOrEqualTo: startStamp)
            .where('createdAt', isLessThanOrEqualTo: endStamp)
            .get();

        for (final doc in dmgSnap.docs) {
          final data = doc.data();
          final loss = (data['costLoss'] as num?)?.toDouble() ??
              (((data['costPrice'] as num?)?.toDouble() ?? 0.0) *
                  ((data['quantity'] as num?)?.toInt() ?? 1));
          damagedLoss += loss;
        }
      } catch (_) {}

      // 4. Fetch Payroll / Salaries paid within date range
      double payrollExpenses = 0.0;
      try {
        final paySnap = await _firestore
            .collection('payroll_slips')
            .where('paidDate', isGreaterThanOrEqualTo: startStamp)
            .where('paidDate', isLessThanOrEqualTo: endStamp)
            .get();

        for (final doc in paySnap.docs) {
          final data = doc.data();
          payrollExpenses += (data['netSalary'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}

      return ProfitLossModel(
        grossSales: grossSales,
        discountsGiven: discounts,
        netRevenue: netRevenue,
        totalCogs: totalCogs,
        operatingExpenses: operatingExpenses,
        payrollExpenses: payrollExpenses,
        damagedStockLoss: damagedLoss,
        totalOrders: ordersCount,
        totalItemsSold: itemsSold,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Firestore getProfitAndLoss error: $e');
      return ProfitLossModel(startDate: startDate, endDate: endDate);
    }
  }

  // --------------------------------------------------------------------------
  // 3. Manual Treasury Transactions
  // --------------------------------------------------------------------------
  @override
  Future<List<TreasuryTransactionModel>> getTreasuryTransactions({
    int limit = 100,
    String? branchId,
  }) async {
    try {
      final snap = await _firestore
          .collection('treasury_transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((doc) => TreasuryTransactionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Firestore getTreasuryTransactions error: $e');
      try {
        final snap = await _firestore
            .collection('treasury_transactions')
            .limit(limit)
            .get();
        final list = snap.docs
            .map((doc) => TreasuryTransactionModel.fromJson(doc.data(), doc.id))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<TreasuryTransactionModel> recordTreasuryTransaction(
      TreasuryTransactionModel transaction) async {
    try {
      final docRef = transaction.id.isNotEmpty
          ? _firestore.collection('treasury_transactions').doc(transaction.id)
          : _firestore.collection('treasury_transactions').doc();

      final json = transaction.toJson();
      json['id'] = docRef.id;
      json['createdAt'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(docRef, json);

      // If it's an expense or withdrawal, simultaneously create/sync to expenses collection
      if (transaction.type == TreasuryTransactionType.cashOut ||
          transaction.type == TreasuryTransactionType.ownerWithdrawal) {
        final expRef = _firestore.collection('expenses').doc();
        final title = transaction.reason.isNotEmpty
            ? transaction.reason
            : 'سحب ومصروف من الخزينة';
        final desc = transaction.referenceNumber.isNotEmpty
            ? 'رقم الإيصال: ${transaction.referenceNumber}'
            : 'مسجل عبر الخزينة';

        final expData = <String, dynamic>{
          'title': title,
          'amount': transaction.amount,
          'category': transaction.reason,
          'date': Timestamp.fromDate(transaction.createdAt),
          'paymentMethod': transaction.channel.name,
          'recordedBy': transaction.performedBy.isNotEmpty
              ? transaction.performedBy
              : 'Admin',
          'notes': desc,
          'treasuryTransactionId': docRef.id,
          'createdAt': Timestamp.fromDate(transaction.createdAt),
        };
        if (transaction.branchId.isNotEmpty) {
          expData['branchId'] = transaction.branchId;
        }
        batch.set(expRef, expData);
      }

      await batch.commit();
      return transaction.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Firestore recordTreasuryTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTreasuryTransaction(TreasuryTransactionModel transaction) async {
    try {
      final docRef = _firestore.collection('treasury_transactions').doc(transaction.id);
      final txSnap = await docRef.get();
      final data = txSnap.data() ?? {};
      final linkedExpenseId = data['expenseId']?.toString();

      final batch = _firestore.batch();
      batch.update(docRef, transaction.toJson());

      // If linked to an expense doc in expenses collection, update it too
      if (linkedExpenseId != null && linkedExpenseId.isNotEmpty) {
        final expRef = _firestore.collection('expenses').doc(linkedExpenseId);
        batch.update(expRef, {
          'title': transaction.reason,
          'amount': transaction.amount,
          'category': transaction.reason,
          'paymentMethod': transaction.channel.code,
        });
      } else {
        // Also check if any expense has treasuryTransactionId == transaction.id
        final expQuery = await _firestore.collection('expenses')
            .where('treasuryTransactionId', isEqualTo: transaction.id)
            .get();
        for (final doc in expQuery.docs) {
          batch.update(doc.reference, {
            'title': transaction.reason,
            'amount': transaction.amount,
            'category': transaction.reason,
            'paymentMethod': transaction.channel.code,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore updateTreasuryTransaction error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTreasuryTransaction(String id) async {
    try {
      final docRef = _firestore.collection('treasury_transactions').doc(id);
      final txSnap = await docRef.get();
      final data = txSnap.data() ?? {};
      final linkedExpenseId = data['expenseId']?.toString();

      final batch = _firestore.batch();
      batch.delete(docRef);

      // If linked to an expense doc in expenses collection, delete it too
      if (linkedExpenseId != null && linkedExpenseId.isNotEmpty) {
        final expRef = _firestore.collection('expenses').doc(linkedExpenseId);
        batch.delete(expRef);
      } else {
        // Also check if any expense has treasuryTransactionId == id
        final expQuery = await _firestore.collection('expenses')
            .where('treasuryTransactionId', isEqualTo: id)
            .get();
        for (final doc in expQuery.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore deleteTreasuryTransaction error: $e');
      rethrow;
    }
  }
}
