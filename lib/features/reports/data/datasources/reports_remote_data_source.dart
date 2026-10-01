import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../models/erp_report_models.dart';

abstract class ReportsRemoteDataSource {
  Future<ComprehensiveErpReportModel> getComprehensiveReport({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReportsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<ComprehensiveErpReportModel> getComprehensiveReport({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      final startStamp = Timestamp.fromDate(startDate);
      final endStamp = Timestamp.fromDate(endDate);

      // 1. Fetch Orders within date range
      final Map<String, _ProductAggregator> productAggMap = {};
      final Map<String, _DailyAggregator> dailyAggMap = {};

      final orderSnap = await _firestore
          .collection('Orders')
          .where('orderDate', isGreaterThanOrEqualTo: startStamp)
          .where('orderDate', isLessThanOrEqualTo: endStamp)
          .get();

      for (final doc in orderSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled' || status == 'returned') continue;

        final rawDate = data['orderDate'];
        DateTime orderDate = DateTime.now();
        if (rawDate is Timestamp) orderDate = rawDate.toDate();

        final dateKey = DateFormat('yyyy-MM-dd').format(orderDate);
        final orderAmount = (data['totalAmount'] as num?)?.toDouble() ??
            (data['totalPrice'] as num?)?.toDouble() ??
            0.0;

        final dailyAgg = dailyAggMap.putIfAbsent(
          dateKey,
          () => _DailyAggregator(
            date: DateTime(orderDate.year, orderDate.month, orderDate.day),
          ),
        );
        dailyAgg.ordersCount++;
        dailyAgg.revenue += orderAmount;

        final items = data['items'];
        if (items is List) {
          for (final raw in items) {
            if (raw is Map) {
              final pId = (raw['productId'] ?? raw['id'] ?? '').toString();
              final title = (raw['title'] ?? raw['name'] ?? 'Product').toString();
              final brand = (raw['brand'] ?? '').toString();
              final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
              final price = (raw['price'] as num?)?.toDouble() ?? 0.0;
              final lineTotal = (raw['totalItemPrice'] as num?)?.toDouble() ?? (price * qty);
              final unitCost = (raw['costPrice'] as num?)?.toDouble() ?? (price * 0.7);
              final lineCogs = unitCost * qty;

              final agg = productAggMap.putIfAbsent(
                pId,
                () => _ProductAggregator(
                  productId: pId,
                  productTitle: title,
                  brandName: brand,
                ),
              );
              agg.quantitySold += qty;
              agg.totalRevenue += lineTotal;
              agg.totalCogs += lineCogs;
              dailyAgg.cogs += lineCogs;
            }
          }
        }
      }

      final List<ProductSalesPerformanceModel> topProducts = productAggMap.values.map((a) {
        return ProductSalesPerformanceModel(
          productId: a.productId,
          productTitle: a.productTitle,
          brandName: a.brandName,
          quantitySold: a.quantitySold,
          totalRevenue: a.totalRevenue,
          totalCogs: a.totalCogs,
          grossProfit: a.totalRevenue - a.totalCogs,
        );
      }).toList();
      topProducts.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      final List<DailySalesTrendModel> dailyTrends = dailyAggMap.values.map((d) {
        return DailySalesTrendModel(
          date: d.date,
          revenue: d.revenue,
          profit: d.revenue - d.cogs,
          ordersCount: d.ordersCount,
        );
      }).toList();
      dailyTrends.sort((a, b) => a.date.compareTo(b.date));

      // 2. Compute Inventory Valuation from Products
      int totalProductsCount = 0;
      int totalSkusCount = 0;
      int totalUnits = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      double totalCostVal = 0.0;
      double totalRetailVal = 0.0;

      try {
        final prodSnap = await _firestore.collection('Products').get();
        totalProductsCount = prodSnap.docs.length;

        for (final doc in prodSnap.docs) {
          final data = doc.data();
          final stock = (data['stock'] as num?)?.toInt() ?? 0;
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          final cost = (data['costPrice'] as num?)?.toDouble() ?? (price * 0.7);

          totalUnits += stock;
          if (stock <= 0) {
            outOfStockCount++;
          } else if (stock <= 5) {
            lowStockCount++;
          }

          final vars = data['productVariations'] ?? data['variations'];
          if (vars is List && vars.isNotEmpty) {
            totalSkusCount += vars.length;
            for (final v in vars) {
              if (v is Map) {
                final vStock = (v['stock'] as num?)?.toInt() ?? 0;
                final vPrice = (v['price'] as num?)?.toDouble() ?? price;
                final vCost = (v['costPrice'] as num?)?.toDouble() ?? (vPrice * 0.7);
                totalCostVal += (vStock * vCost);
                totalRetailVal += (vStock * vPrice);
              }
            }
          } else {
            totalSkusCount++;
            totalCostVal += (stock * cost);
            totalRetailVal += (stock * price);
          }
        }
      } catch (_) {}

      final inventoryValuation = InventoryValuationModel(
        totalProductsCount: totalProductsCount,
        totalSkusCount: totalSkusCount,
        totalUnitsInStock: totalUnits,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        totalCostValue: totalCostVal,
        totalRetailValue: totalRetailVal,
      );

      // 3. Compute Supplier Purchases Report
      final List<SupplierPurchasesReportModel> supplierPurchases = [];
      try {
        final supSnap = await _firestore.collection('suppliers').get();
        for (final doc in supSnap.docs) {
          final data = doc.data();
          supplierPurchases.add(SupplierPurchasesReportModel(
            supplierId: doc.id,
            supplierName: (data['name'] ?? 'Supplier').toString(),
            invoiceCount: (data['invoicesCount'] as num?)?.toInt() ?? 0,
            totalPurchases: (data['totalPurchases'] as num?)?.toDouble() ?? 0.0,
            totalPaid: (data['totalPaid'] as num?)?.toDouble() ?? 0.0,
            balanceDue: (data['balanceDue'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        supplierPurchases.sort((a, b) => b.totalPurchases.compareTo(a.totalPurchases));
      } catch (_) {}

      // 4. Compute Expense Categories Report
      final Map<String, _ExpenseCategoryAggregator> expenseCatMap = {};
      double totalExpensesSum = 0.0;
      final Set<String> reportTxIds = {};

      try {
        final expSnap = await _firestore
            .collection('expenses')
            .where('date', isGreaterThanOrEqualTo: startStamp)
            .where('date', isLessThanOrEqualTo: endStamp)
            .get();

        for (final doc in expSnap.docs) {
          final data = doc.data();
          final rawCat = data['category']?.toString() ?? data['title']?.toString();
          final parsedCat = ExpenseCategory.fromString(rawCat);
          final catLabel = parsedCat.labelKey;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          totalExpensesSum += amount;

          final txId = data['treasuryTransactionId']?.toString();
          if (txId != null && txId.isNotEmpty) {
            reportTxIds.add(txId);
          }

          final agg = expenseCatMap.putIfAbsent(
            catLabel,
            () => _ExpenseCategoryAggregator(category: catLabel),
          );
          agg.totalAmount += amount;
          agg.count++;
        }
      } catch (_) {
        // Fallback without server index filter
        final allExp = await _firestore.collection('expenses').get();
        for (final doc in allExp.docs) {
          final data = doc.data();
          final rawDate = data['date'];
          DateTime expDate = DateTime.now();
          if (rawDate is Timestamp) expDate = rawDate.toDate();
          if (expDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              expDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
            final rawCat = data['category']?.toString() ?? data['title']?.toString();
            final parsedCat = ExpenseCategory.fromString(rawCat);
            final catLabel = parsedCat.labelKey;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            totalExpensesSum += amount;

            final txId = data['treasuryTransactionId']?.toString();
            if (txId != null && txId.isNotEmpty) {
              reportTxIds.add(txId);
            }

            final agg = expenseCatMap.putIfAbsent(
              catLabel,
              () => _ExpenseCategoryAggregator(category: catLabel),
            );
            agg.totalAmount += amount;
            agg.count++;
          }
        }
      }

      // Also include any unmirrored treasury transactions (like 500 EGP water bill)
      try {
        final txSnap = await _firestore.collection('treasury_transactions').get();
        for (final doc in txSnap.docs) {
          if (reportTxIds.contains(doc.id)) continue;
          final data = doc.data();
          final typeStr = (data['type'] ?? '').toString().toLowerCase();
          if (typeStr == 'expense' || typeStr == 'cashout' || typeStr == 'withdrawal') {
            final rawDate = data['createdAt'];
            DateTime txDate = DateTime.now();
            if (rawDate is Timestamp) txDate = rawDate.toDate();
            if (txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
              final reason = (data['reason'] ?? 'المرافق والخدمات').toString();
              final parsedCat = ExpenseCategory.fromString(reason);
              final catLabel = parsedCat.labelKey;
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              totalExpensesSum += amount;

              final agg = expenseCatMap.putIfAbsent(
                catLabel,
                () => _ExpenseCategoryAggregator(category: catLabel),
              );
              agg.totalAmount += amount;
              agg.count++;
            }
          }
        }
      } catch (_) {}

      final List<ExpenseCategoryReportModel> expenseCategories = expenseCatMap.values.map((e) {
        return ExpenseCategoryReportModel(
          category: e.category,
          totalAmount: e.totalAmount,
          count: e.count,
          percentage: totalExpensesSum > 0 ? (e.totalAmount / totalExpensesSum) * 100 : 0.0,
        );
      }).toList();
      expenseCategories.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return ComprehensiveErpReportModel(
        topProducts: topProducts,
        inventoryValuation: inventoryValuation,
        supplierPurchases: supplierPurchases,
        expenseCategories: expenseCategories,
        dailyTrends: dailyTrends,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Firestore getComprehensiveReport error: $e');
      return ComprehensiveErpReportModel(startDate: startDate, endDate: endDate);
    }
  }
}

class _ProductAggregator {
  final String productId;
  final String productTitle;
  final String brandName;
  int quantitySold = 0;
  double totalRevenue = 0.0;
  double totalCogs = 0.0;

  _ProductAggregator({
    required this.productId,
    required this.productTitle,
    required this.brandName,
  });
}

class _DailyAggregator {
  final DateTime date;
  int ordersCount = 0;
  double revenue = 0.0;
  double cogs = 0.0;

  _DailyAggregator({required this.date});
}

class _ExpenseCategoryAggregator {
  final String category;
  double totalAmount = 0.0;
  int count = 0;

  _ExpenseCategoryAggregator({required this.category});
}
