import 'package:equatable/equatable.dart';

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

class DashboardAnalyticsModel extends Equatable {
  final double totalRevenue;
  final int todayOrders;
  final int activeCustomers;
  final double avgOrderValue;
  final int lowStockAlertsCount;
  final int pendingOrdersCount;
  final List<RevenuePoint> weeklyTrend;
  final List<CategorySalesData> categorySales;
  final List<BrandShareData> brandShares;

  const DashboardAnalyticsModel({
    required this.totalRevenue,
    required this.todayOrders,
    required this.activeCustomers,
    required this.avgOrderValue,
    required this.lowStockAlertsCount,
    required this.pendingOrdersCount,
    required this.weeklyTrend,
    required this.categorySales,
    required this.brandShares,
  });

  factory DashboardAnalyticsModel.empty() {
    return const DashboardAnalyticsModel(
      totalRevenue: 0.0,
      todayOrders: 0,
      activeCustomers: 0,
      avgOrderValue: 0.0,
      lowStockAlertsCount: 0,
      pendingOrdersCount: 0,
      weeklyTrend: [],
      categorySales: [],
      brandShares: [],
    );
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        todayOrders,
        activeCustomers,
        avgOrderValue,
        lowStockAlertsCount,
        pendingOrdersCount,
        weeklyTrend,
        categorySales,
        brandShares,
      ];
}
