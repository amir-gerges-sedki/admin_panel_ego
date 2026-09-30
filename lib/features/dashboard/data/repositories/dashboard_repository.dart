import 'package:flutter/foundation.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../damaged_stock/data/models/damaged_stock_model.dart';
import '../../../damaged_stock/data/repositories/damaged_stock_repository.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/models/payroll_slip_model.dart';
import '../../../employees/data/models/salary_advance_model.dart';
import '../../../employees/data/repositories/employees_repository.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/data/repositories/expense_repository.dart';
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
  final ExpenseRepository? expenseRepository;
  final DamagedStockRepository? damagedStockRepository;
  final EmployeesRepository? employeesRepository;
  final SettingsRepository? settingsRepository;
  final OrderAnalyticsCalculator orderCalculator;
  final CatalogAnalyticsCalculator catalogCalculator;

  DashboardRepositoryImpl({
    required this.orderRepository,
    required this.customerRepository,
    required this.productRepository,
    this.supplierRepository,
    this.expenseRepository,
    this.damagedStockRepository,
    this.employeesRepository,
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
        if (expenseRepository != null)
          expenseRepository!.getExpenses()
        else
          Future.value(<ExpenseModel>[]),
        if (damagedStockRepository != null)
          damagedStockRepository!.getDamagedStock()
        else
          Future.value(<DamagedStockModel>[]),
        if (employeesRepository != null)
          employeesRepository!.getEmployees()
        else
          Future.value(<EmployeeModel>[]),
        if (employeesRepository != null)
          employeesRepository!.getAdvances()
        else
          Future.value(<SalaryAdvanceModel>[]),
        if (employeesRepository != null)
          employeesRepository!.getPayrollSlips()
        else
          Future.value(<PayrollSlipModel>[]),
      ]);

      final orders = results[0] as List<OrderModel>;
      final customers = results[1] as List<CustomerModel>;
      final products = results[2] as List<ProductModel>;
      final settings = results[3];
      final suppliers = results[4] as List<SupplierModel>;
      final expenses = results[5] as List<ExpenseModel>;
      final damagedList = results[6] as List<DamagedStockModel>;
      final employeesList = results[7] as List<EmployeeModel>;
      final advancesList = results[8] as List<SalaryAdvanceModel>;
      final payrollList = results[9] as List<PayrollSlipModel>;

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

      // 4. Compute Operational Expenses in selected period
      final periodExpenses = expenses.where((exp) {
        final start = orderMetrics.filterStartDate;
        final end = orderMetrics.filterEndDate;
        if (start != null && exp.date.isBefore(start)) return false;
        if (end != null && exp.date.isAfter(end)) return false;
        return true;
      }).toList();

      final double totalExpenses = periodExpenses.fold(0.0, (acc, exp) => acc + exp.amount);
      final int periodExpensesCount = periodExpenses.length;

      final Map<ExpenseCategory, double> catTotals = {};
      for (final exp in periodExpenses) {
        catTotals[exp.category] = (catTotals[exp.category] ?? 0.0) + exp.amount;
      }
      ExpenseCategory? topCat;
      double topCatAmount = 0.0;
      catTotals.forEach((cat, amt) {
        if (amt > topCatAmount) {
          topCatAmount = amt;
          topCat = cat;
        }
      });
      final String topExpenseCategory = topCat != null ? topCat!.labelKey : '';

      // 5. Compute Damaged Goods / Inventory Waste Loss in selected period
      final periodDamaged = damagedList.where((dmg) {
        final start = orderMetrics.filterStartDate;
        final end = orderMetrics.filterEndDate;
        if (start != null && dmg.createdAt.isBefore(start)) return false;
        if (end != null && dmg.createdAt.isAfter(end)) return false;
        return true;
      }).toList();

      final double totalDamagedLoss = periodDamaged.fold(0.0, (acc, dmg) => acc + dmg.totalLoss);
      final int periodDamagedUnitsCount = periodDamaged.fold(0, (acc, dmg) => acc + dmg.quantity);
      final int periodDamagedCount = periodDamaged.length;

      final Map<DamagedReason, int> reasonCounts = {};
      for (final dmg in periodDamaged) {
        reasonCounts[dmg.reason] = (reasonCounts[dmg.reason] ?? 0) + dmg.quantity;
      }
      DamagedReason? topRsn;
      int topRsnCount = 0;
      reasonCounts.forEach((rsn, count) {
        if (count > topRsnCount) {
          topRsnCount = count;
          topRsn = rsn;
        }
      });
      final String topDamageReason = topRsn != null ? topRsn!.labelKey : '';

      // 6. Compute HR, Employees & Payroll in selected period
      final activeStaff = employeesList.where((e) => e.isActive).toList();
      final int activeEmployeesCount = activeStaff.length;
      final double monthlySalariesPool =
          activeStaff.fold(0.0, (acc, e) => acc + e.baseSalary);

      final double periodAdvancesTotal = advancesList.where((adv) {
        final start = orderMetrics.filterStartDate;
        final end = orderMetrics.filterEndDate;
        if (start != null && adv.date.isBefore(start)) return false;
        if (end != null && adv.date.isAfter(end)) return false;
        return true;
      }).fold(0.0, (acc, adv) => acc + adv.amount);

      final double periodPaidSalariesTotal = payrollList.where((slip) {
        final start = orderMetrics.filterStartDate;
        final end = orderMetrics.filterEndDate;
        if (start != null && slip.paymentDate.isBefore(start)) return false;
        if (end != null && slip.paymentDate.isAfter(end)) return false;
        return true;
      }).fold(0.0, (acc, slip) => acc + slip.netSalary);

      // Real Net Profit = Profit from Orders (Revenue - Cost of goods) - General Operational Expenses - Inventory Waste Losses
      final double realNetProfit = orderMetrics.netProfit - totalExpenses - totalDamagedLoss;
      final double realProfitMargin = totalRevenue > 0
          ? ((realNetProfit / totalRevenue) * 100)
          : 0.0;

      return DashboardAnalyticsModel(
        totalRevenue: totalRevenue,
        totalCost: orderMetrics.totalCost,
        netProfit: realNetProfit,
        profitMargin: realProfitMargin,
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
        totalExpenses: totalExpenses,
        periodExpensesCount: periodExpensesCount,
        topExpenseCategory: topExpenseCategory,
        totalDamagedLoss: totalDamagedLoss,
        periodDamagedUnitsCount: periodDamagedUnitsCount,
        periodDamagedCount: periodDamagedCount,
        topDamageReason: topDamageReason,
        activeEmployeesCount: activeEmployeesCount,
        monthlySalariesPool: monthlySalariesPool,
        periodAdvancesTotal: periodAdvancesTotal,
        periodPaidSalariesTotal: periodPaidSalariesTotal,
      );
    } catch (e) {
      debugPrint('DashboardRepositoryImpl getDashboardAnalytics error: $e');
      return DashboardAnalyticsModel.empty();
    }
  }
}

