import 'package:equatable/equatable.dart';

enum DashboardPeriodType {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
  custom,
}

/// Detailed financial performance for a specific sales channel (Online App vs In-Store POS vs Combined)
class ChannelFinancialMetrics extends Equatable {
  final double revenue;
  final double cost;
  final double netProfit;
  final double profitMargin;
  final int count;
  final double averageTicket;

  final double refundedAmount;
  final int returnedCount;

  const ChannelFinancialMetrics({
    required this.revenue,
    required this.cost,
    required this.netProfit,
    required this.profitMargin,
    required this.count,
    required this.averageTicket,
    this.refundedAmount = 0.0,
    this.returnedCount = 0,
  });

  const ChannelFinancialMetrics.zero()
      : revenue = 0.0,
        cost = 0.0,
        netProfit = 0.0,
        profitMargin = 0.0,
        count = 0,
        averageTicket = 0.0,
        refundedAmount = 0.0,
        returnedCount = 0;

  @override
  List<Object?> get props => [
        revenue,
        cost,
        netProfit,
        profitMargin,
        count,
        averageTicket,
        refundedAmount,
        returnedCount,
      ];
}

class RevenuePoint extends Equatable {
  final String label;
  final double revenue;
  final int ordersCount;

  const RevenuePoint({
    required this.label,
    required this.revenue,
    required this.ordersCount,
  });

  @override
  List<Object?> get props => [label, revenue, ordersCount];
}

class CategorySalesData extends Equatable {
  final String categoryName;
  final double salesAmount;
  final int unitsSold;
  final double percentage;

  const CategorySalesData({
    required this.categoryName,
    required this.salesAmount,
    required this.unitsSold,
    required this.percentage,
  });

  @override
  List<Object?> get props => [categoryName, salesAmount, unitsSold, percentage];
}

class BrandShareData extends Equatable {
  final String brandName;
  final double sharePercentage;
  final int totalSold;

  const BrandShareData({
    required this.brandName,
    required this.sharePercentage,
    required this.totalSold,
  });

  @override
  List<Object?> get props => [brandName, sharePercentage, totalSold];
}

class SupplierDueSummary extends Equatable {
  final String id;
  final String name;
  final double totalPurchases;
  final double totalPaid;
  final double balanceDue;
  final String phone;

  const SupplierDueSummary({
    required this.id,
    required this.name,
    required this.totalPurchases,
    required this.totalPaid,
    required this.balanceDue,
    this.phone = '',
  });

  @override
  List<Object?> get props => [id, name, totalPurchases, totalPaid, balanceDue, phone];
}

class ProductSalesItemMetrics extends Equatable {
  final String productId;
  final String productTitle;
  final String productImage;
  final String categoryName;
  final String brandName;
  final String sku;
  final int onlineQuantity;
  final int posQuantity;
  final int totalQuantity;
  final double avgUnitPrice;
  final double avgUnitCost;
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double profitMargin;
  final int ordersCount;
  final List<String> orderIds;

  const ProductSalesItemMetrics({
    required this.productId,
    required this.productTitle,
    this.productImage = '',
    this.categoryName = '',
    this.brandName = '',
    this.sku = '',
    this.onlineQuantity = 0,
    this.posQuantity = 0,
    required this.totalQuantity,
    this.avgUnitPrice = 0.0,
    this.avgUnitCost = 0.0,
    required this.totalRevenue,
    this.totalCost = 0.0,
    required this.netProfit,
    this.profitMargin = 0.0,
    this.ordersCount = 0,
    this.orderIds = const [],
  });

  @override
  List<Object?> get props => [
        productId,
        productTitle,
        sku,
        totalQuantity,
        totalRevenue,
        netProfit,
        onlineQuantity,
        posQuantity,
      ];
}

class DashboardAnalyticsModel extends Equatable {
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double profitMargin;
  final int todayOrders;
  final int activeCustomers;
  final double avgOrderValue;
  final int lowStockAlertsCount;
  final int pendingOrdersCount;
  final List<RevenuePoint> weeklyTrend;
  final List<CategorySalesData> categorySales;
  final List<BrandShareData> brandShares;

  // Channel Profit & Revenue Metrics
  final ChannelFinancialMetrics onlineMetrics;
  final ChannelFinancialMetrics posMetrics;
  final ChannelFinancialMetrics combinedMetrics;

  // Detailed Product Sales Breakdown
  final List<ProductSalesItemMetrics> productSales;

  // Active Time Period Filter metadata
  final DashboardPeriodType periodType;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String periodLabel;

  // Supplier & Purchases Financials
  final double totalSupplierPurchases;
  final double totalSupplierPaid;
  final double totalSupplierBalanceDue;
  final int activeSuppliersCount;
  final List<SupplierDueSummary> topSuppliersDue;

  // General Operational Expenses in period
  final double totalExpenses;
  final int periodExpensesCount;
  final String topExpenseCategory;

  // Inventory Waste & Damaged Goods Loss in period
  final double totalDamagedLoss;
  final int periodDamagedUnitsCount;
  final int periodDamagedCount;
  final String topDamageReason;

  // HR, Employees & Payroll in period
  final int activeEmployeesCount;
  final double monthlySalariesPool;
  final double periodAdvancesTotal;
  final double periodPaidSalariesTotal;

  const DashboardAnalyticsModel({
    double? totalRevenue,
    double? totalCost,
    double? netProfit,
    double? profitMargin,
    int? todayOrders,
    int? activeCustomers,
    double? avgOrderValue,
    int? lowStockAlertsCount,
    int? pendingOrdersCount,
    List<RevenuePoint>? weeklyTrend,
    List<CategorySalesData>? categorySales,
    List<BrandShareData>? brandShares,
    this.onlineMetrics = const ChannelFinancialMetrics.zero(),
    this.posMetrics = const ChannelFinancialMetrics.zero(),
    this.combinedMetrics = const ChannelFinancialMetrics.zero(),
    this.productSales = const [],
    this.periodType = DashboardPeriodType.allTime,
    this.filterStartDate,
    this.filterEndDate,
    this.periodLabel = 'كافة الفترات',
    double? totalSupplierPurchases,
    double? totalSupplierPaid,
    double? totalSupplierBalanceDue,
    int? activeSuppliersCount,
    this.topSuppliersDue = const [],
    double? totalExpenses,
    int? periodExpensesCount,
    String? topExpenseCategory,
    double? totalDamagedLoss,
    int? periodDamagedUnitsCount,
    int? periodDamagedCount,
    String? topDamageReason,
    int? activeEmployeesCount,
    double? monthlySalariesPool,
    double? periodAdvancesTotal,
    double? periodPaidSalariesTotal,
  })  : totalRevenue = totalRevenue ?? 0.0,
        totalCost = totalCost ?? 0.0,
        netProfit = netProfit ?? 0.0,
        profitMargin = profitMargin ?? 0.0,
        todayOrders = todayOrders ?? 0,
        activeCustomers = activeCustomers ?? 0,
        avgOrderValue = avgOrderValue ?? 0.0,
        lowStockAlertsCount = lowStockAlertsCount ?? 0,
        pendingOrdersCount = pendingOrdersCount ?? 0,
        weeklyTrend = weeklyTrend ?? const [],
        categorySales = categorySales ?? const [],
        brandShares = brandShares ?? const [],
        totalSupplierPurchases = totalSupplierPurchases ?? 0.0,
        totalSupplierPaid = totalSupplierPaid ?? 0.0,
        totalSupplierBalanceDue = totalSupplierBalanceDue ?? 0.0,
        activeSuppliersCount = activeSuppliersCount ?? 0,
        totalExpenses = totalExpenses ?? 0.0,
        periodExpensesCount = periodExpensesCount ?? 0,
        topExpenseCategory = topExpenseCategory ?? '',
        totalDamagedLoss = totalDamagedLoss ?? 0.0,
        periodDamagedUnitsCount = periodDamagedUnitsCount ?? 0,
        periodDamagedCount = periodDamagedCount ?? 0,
        topDamageReason = topDamageReason ?? '',
        activeEmployeesCount = activeEmployeesCount ?? 0,
        monthlySalariesPool = monthlySalariesPool ?? 0.0,
        periodAdvancesTotal = periodAdvancesTotal ?? 0.0,
        periodPaidSalariesTotal = periodPaidSalariesTotal ?? 0.0;

  const DashboardAnalyticsModel.empty()
      : totalRevenue = 0.0,
        totalCost = 0.0,
        netProfit = 0.0,
        profitMargin = 0.0,
        todayOrders = 0,
        activeCustomers = 0,
        avgOrderValue = 0.0,
        lowStockAlertsCount = 0,
        pendingOrdersCount = 0,
        weeklyTrend = const [],
        categorySales = const [],
        brandShares = const [],
        onlineMetrics = const ChannelFinancialMetrics.zero(),
        posMetrics = const ChannelFinancialMetrics.zero(),
        combinedMetrics = const ChannelFinancialMetrics.zero(),
        productSales = const [],
        periodType = DashboardPeriodType.allTime,
        filterStartDate = null,
        filterEndDate = null,
        periodLabel = 'كافة الفترات',
        totalSupplierPurchases = 0.0,
        totalSupplierPaid = 0.0,
        totalSupplierBalanceDue = 0.0,
        activeSuppliersCount = 0,
        topSuppliersDue = const [],
        totalExpenses = 0.0,
        periodExpensesCount = 0,
        topExpenseCategory = '',
        totalDamagedLoss = 0.0,
        periodDamagedUnitsCount = 0,
        periodDamagedCount = 0,
        topDamageReason = '',
        activeEmployeesCount = 0,
        monthlySalariesPool = 0.0,
        periodAdvancesTotal = 0.0,
        periodPaidSalariesTotal = 0.0;

  @override
  List<Object?> get props => [
        totalRevenue,
        totalCost,
        netProfit,
        profitMargin,
        todayOrders,
        activeCustomers,
        avgOrderValue,
        lowStockAlertsCount,
        pendingOrdersCount,
        weeklyTrend,
        categorySales,
        brandShares,
        onlineMetrics,
        posMetrics,
        combinedMetrics,
        productSales,
        periodType,
        filterStartDate,
        filterEndDate,
        periodLabel,
        totalSupplierPurchases,
        totalSupplierPaid,
        totalSupplierBalanceDue,
        activeSuppliersCount,
        topSuppliersDue,
        totalExpenses,
        periodExpensesCount,
        topExpenseCategory,
        totalDamagedLoss,
        periodDamagedUnitsCount,
        periodDamagedCount,
        topDamageReason,
        activeEmployeesCount,
        monthlySalariesPool,
        periodAdvancesTotal,
        periodPaidSalariesTotal,
      ];
}

