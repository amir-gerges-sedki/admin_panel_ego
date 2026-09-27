import 'package:flutter/foundation.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../../suppliers/data/models/supplier_model.dart';
import '../../../suppliers/data/repositories/supplier_repository.dart';
import '../../domain/calculators/catalog_analytics_calculator.dart';
import '../../domain/calculators/order_analytics_calculator.dart';
import '../models/dashboard_analytics_model.dart';

abstract class DashboardRepository {
  Future<DashboardAnalyticsModel> getDashboardAnalytics({
    DashboardPeriodType periodType = DashboardPeriodType.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
  });
}

class DashboardRepositoryImpl implements DashboardRepository {
  final OrderRepository orderRepository;
  final CustomerRepository customerRepository;
  final ProductRepository productRepository;
  final SupplierRepository? supplierRepository;
  final SettingsRepository? settingsRepository;
  final OrderAnalyticsCalculator orderCalculator;
  final CatalogAnalyticsCalculator catalogCalculator;

  DashboardRepositoryImpl({
    required this.orderRepository,
    required this.customerRepository,
    required this.productRepository,
    this.supplierRepository,
    this.settingsRepository,
    this.orderCalculator = const OrderAnalyticsCalculator(),
    this.catalogCalculator = const CatalogAnalyticsCalculator(),
  });

  @override
  Future<DashboardAnalyticsModel> getDashboardAnalytics({
    DashboardPeriodType periodType = DashboardPeriodType.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      // 1. Fetch data directly from domain repositories in parallel
      final results = await Future.wait([
        orderRepository.getOrders(),
        customerRepository.getCustomers(),
        productRepository.getProducts(),
        if (settingsRepository != null)
          settingsRepository!.getSettings()
        else
          Future.value(null),
        if (supplierRepository != null)
          supplierRepository!.getSuppliers()
        else
          Future.value(<SupplierModel>[]),
      ]);

      final orders = results[0] as List<OrderModel>;
      final customers = results[1] as List<CustomerModel>;
      final products = results[2] as List<ProductModel>;
      final settings = results[3];
      final suppliers = results[4] as List<SupplierModel>;

      final int threshold = (settings != null && (settings as dynamic).lowStockThreshold is int)
          ? (settings as dynamic).lowStockThreshold as int
          : 10;

      // 2. Compute metrics cleanly via type-safe calculators with selected date period
      final orderMetrics = orderCalculator.calculate(
        orders: orders,
        products: products,
        periodType: periodType,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );
      final productMetrics = catalogCalculator.calculate(
        products: products,
        lowStockThreshold: threshold,
      );

      final totalRevenue = orderMetrics.totalRevenue;
      final int activeCount = orderMetrics.combinedMetrics.count;
      final avgOrderValue = activeCount > 0 ? (totalRevenue / activeCount) : 0.0;

      // 3. Compute Supplier Financial Metrics (Purchases Cost, Paid, Balance Due / Accounts Payable)
      final double totalSupplierPurchases =
          suppliers.fold(0.0, (acc, s) => acc + s.totalPurchases);
      final double totalSupplierPaid =
          suppliers.fold(0.0, (acc, s) => acc + s.totalPaid);
      final double totalSupplierBalanceDue =
          suppliers.fold(0.0, (acc, s) => acc + s.balanceDue);
      final int activeSuppliersCount =
          suppliers.where((s) => s.isActive).length;

      final dueList = suppliers
          .where((s) => s.balanceDue > 0)
          .toList()
        ..sort((a, b) => b.balanceDue.compareTo(a.balanceDue));

      final topSuppliersDue = dueList
          .take(5)
          .map((s) => SupplierDueSummary(
                id: s.id,
                name: s.name,
                totalPurchases: s.totalPurchases,
                totalPaid: s.totalPaid,
                balanceDue: s.balanceDue,
                phone: s.phone,
              ))
          .toList();

      return DashboardAnalyticsModel(
        totalRevenue: totalRevenue,
        totalCost: orderMetrics.totalCost,
        netProfit: orderMetrics.netProfit,
        profitMargin: orderMetrics.profitMargin,
        todayOrders: orderMetrics.todayOrders,
        activeCustomers: customers.length,
        avgOrderValue: avgOrderValue,
        lowStockAlertsCount: productMetrics.lowStockAlertsCount,
        pendingOrdersCount: orderMetrics.pendingOrders,
        weeklyTrend: orderMetrics.weeklyTrend,
        categorySales: const [],
        brandShares: productMetrics.brandShares,
        onlineMetrics: orderMetrics.onlineMetrics,
        posMetrics: orderMetrics.posMetrics,
        combinedMetrics: orderMetrics.combinedMetrics,
        productSales: orderMetrics.productSales,
        periodType: orderMetrics.periodType,
        filterStartDate: orderMetrics.filterStartDate,
        filterEndDate: orderMetrics.filterEndDate,
        periodLabel: orderMetrics.periodLabel,
        totalSupplierPurchases: totalSupplierPurchases,
        totalSupplierPaid: totalSupplierPaid,
        totalSupplierBalanceDue: totalSupplierBalanceDue,
        activeSuppliersCount: activeSuppliersCount,
        topSuppliersDue: topSuppliersDue,
      );
    } catch (e) {
      debugPrint('DashboardRepositoryImpl getDashboardAnalytics error: $e');
      return DashboardAnalyticsModel.empty();
    }
  }
}
