import 'package:equatable/equatable.dart';

class ProductSalesPerformanceModel extends Equatable {
  final String productId;
  final String productTitle;
  final String brandName;
  final String categoryName;
  final int quantitySold;
  final double totalRevenue;
  final double totalCogs;
  final double grossProfit;

  const ProductSalesPerformanceModel({
    required this.productId,
    required this.productTitle,
    this.brandName = '',
    this.categoryName = '',
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCogs,
    required this.grossProfit,
  });

  double get profitMargin =>
      totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

  @override
  List<Object?> get props => [
        productId,
        productTitle,
        brandName,
        categoryName,
        quantitySold,
        totalRevenue,
        totalCogs,
        grossProfit,
      ];
}

class InventoryValuationModel extends Equatable {
  final int totalProductsCount;
  final int totalSkusCount;
  final int totalUnitsInStock;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalCostValue;
  final double totalRetailValue;

  const InventoryValuationModel({
    this.totalProductsCount = 0,
    this.totalSkusCount = 0,
    this.totalUnitsInStock = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalCostValue = 0.0,
    this.totalRetailValue = 0.0,
  });

  double get potentialGrossProfit => totalRetailValue - totalCostValue;
  double get potentialMargin =>
      totalRetailValue > 0 ? (potentialGrossProfit / totalRetailValue) * 100 : 0.0;

  @override
  List<Object?> get props => [
        totalProductsCount,
        totalSkusCount,
        totalUnitsInStock,
        lowStockCount,
        outOfStockCount,
        totalCostValue,
        totalRetailValue,
      ];
}

class SupplierPurchasesReportModel extends Equatable {
  final String supplierId;
  final String supplierName;
  final int invoiceCount;
  final double totalPurchases;
  final double totalPaid;
  final double balanceDue;

  const SupplierPurchasesReportModel({
    required this.supplierId,
    required this.supplierName,
    this.invoiceCount = 0,
    this.totalPurchases = 0.0,
    this.totalPaid = 0.0,
    this.balanceDue = 0.0,
  });

  @override
  List<Object?> get props => [
        supplierId,
        supplierName,
        invoiceCount,
        totalPurchases,
        totalPaid,
        balanceDue,
      ];
}

class ExpenseCategoryReportModel extends Equatable {
  final String category;
  final double totalAmount;
  final int count;
  final double percentage;

  const ExpenseCategoryReportModel({
    required this.category,
    required this.totalAmount,
    required this.count,
    this.percentage = 0.0,
  });

  @override
  List<Object?> get props => [category, totalAmount, count, percentage];
}

class DailySalesTrendModel extends Equatable {
  final DateTime date;
  final double revenue;
  final double profit;
  final int ordersCount;

  const DailySalesTrendModel({
    required this.date,
    required this.revenue,
    required this.profit,
    required this.ordersCount,
  });

  @override
  List<Object?> get props => [date, revenue, profit, ordersCount];
}

class ComprehensiveErpReportModel extends Equatable {
  final List<ProductSalesPerformanceModel> topProducts;
  final InventoryValuationModel inventoryValuation;
  final List<SupplierPurchasesReportModel> supplierPurchases;
  final List<ExpenseCategoryReportModel> expenseCategories;
  final List<DailySalesTrendModel> dailyTrends;
  final DateTime startDate;
  final DateTime endDate;

  const ComprehensiveErpReportModel({
    this.topProducts = const [],
    this.inventoryValuation = const InventoryValuationModel(),
    this.supplierPurchases = const [],
    this.expenseCategories = const [],
    this.dailyTrends = const [],
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        topProducts,
        inventoryValuation,
        supplierPurchases,
        expenseCategories,
        dailyTrends,
        startDate,
        endDate,
      ];
}
