import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/dashboard/data/models/dashboard_analytics_model.dart';
import 'package:admin_panel_ego/features/dashboard/domain/calculators/catalog_analytics_calculator.dart';
import 'package:admin_panel_ego/features/dashboard/domain/calculators/order_analytics_calculator.dart';
import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

void main() {
  group('Dashboard Analytics Calculators Tests', () {
    test('OrderAnalyticsCalculator computes revenue, pending count, and weekly trend in single pass', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final rawOrders = [
        {
          'id': 'o1',
          'totalAmount': 500.0,
          'status': 'pending',
          'orderDate': now,
        },
        {
          'id': 'o2',
          'totalAmount': 1000.0,
          'status': 'shipped',
          'orderDate': now.subtract(const Duration(days: 1)),
        },
        {
          'id': 'o3',
          'totalAmount': 250.0,
          'status': 'delivered',
          'orderDate': now.subtract(const Duration(days: 2)),
        },
        {
          'id': 'o4',
          'totalAmount': 100.0,
          'status': 'pending',
          'orderDate': now.subtract(const Duration(days: 3)),
        },
      ];

      final orders = rawOrders.map((e) => OrderModel.fromJson(e)).toList();

      const calculator = OrderAnalyticsCalculator();
      final metrics = calculator.calculate(
        orders: orders,
        referenceNow: now,
      );

      expect(metrics.totalRevenue, equals(250.0));
      expect(metrics.todayOrders, equals(1));
      expect(metrics.pendingOrders, equals(2));
      expect(metrics.weeklyTrend.length, equals(7));
    });

    test('OrderAnalyticsCalculator calculates separate online vs pos channel profits correctly', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final List<ProductModel> products = [
        const ProductModel(
          id: 'prod1',
          title: 'Vape Device',
          description: '',
          price: 500,
          costPrice: 300, // profit = 200 per unit
          salePrice: 500,
          stock: 10,
          brand: ProductBrand(id: 'b1', name: 'Brand1'),
          categoryId: 'c1',
        ),
      ];

      final rawOrders = [
        // 1. Online Order (delivered)
        {
          'id': 'ord-online-1',
          'isPosSale': false,
          'totalAmount': 500.0,
          'status': 'delivered',
          'orderDate': now,
          'items': [
            {
              'productId': 'prod1',
              'productTitle': 'Vape Device',
              'quantity': 1,
              'price': 500.0,
              'costPrice': 300.0,
            }
          ],
        },
        // 2. POS Order (completed)
        {
          'id': 'ord-pos-1',
          'isPosSale': true,
          'paymentMethod': 'pos_cash',
          'totalAmount': 1000.0,
          'status': 'delivered',
          'orderDate': now,
          'items': [
            {
              'productId': 'prod1',
              'productTitle': 'Vape Device',
              'quantity': 2,
              'price': 500.0,
              'costPrice': 300.0,
            }
          ],
        },
      ];

      final orders = rawOrders.map((e) => OrderModel.fromJson(e)).toList();

      const calculator = OrderAnalyticsCalculator();
      final metrics = calculator.calculate(
        orders: orders,
        products: products,
        referenceNow: now,
      );

      // Online: 500 revenue, 300 cost, 200 profit (40% margin), 1 order
      expect(metrics.onlineMetrics.revenue, equals(500.0));
      expect(metrics.onlineMetrics.cost, equals(300.0));
      expect(metrics.onlineMetrics.netProfit, equals(200.0));
      expect(metrics.onlineMetrics.profitMargin, equals(40.0));
      expect(metrics.onlineMetrics.count, equals(1));

      // POS: 1000 revenue, 600 cost, 400 profit (40% margin), 1 order
      expect(metrics.posMetrics.revenue, equals(1000.0));
      expect(metrics.posMetrics.cost, equals(600.0));
      expect(metrics.posMetrics.netProfit, equals(400.0));
      expect(metrics.posMetrics.profitMargin, equals(40.0));
      expect(metrics.posMetrics.count, equals(1));

      // Combined: 1500 revenue, 900 cost, 600 profit (40% margin), 2 orders
      expect(metrics.combinedMetrics.revenue, equals(1500.0));
      expect(metrics.combinedMetrics.cost, equals(900.0));
      expect(metrics.combinedMetrics.netProfit, equals(600.0));
      expect(metrics.combinedMetrics.profitMargin, equals(40.0));
      expect(metrics.combinedMetrics.count, equals(2));

      // Itemized Product Sales Breakdown
      expect(metrics.productSales.length, equals(1));
      final prodMetrics = metrics.productSales.first;
      expect(prodMetrics.productId, equals('prod1'));
      expect(prodMetrics.onlineQuantity, equals(1));
      expect(prodMetrics.posQuantity, equals(2));
      expect(prodMetrics.totalQuantity, equals(3));
      expect(prodMetrics.totalRevenue, equals(1500.0));
      expect(prodMetrics.totalCost, equals(900.0));
      expect(prodMetrics.netProfit, equals(600.0));
      expect(prodMetrics.ordersCount, equals(2));
    });

    test('OrderAnalyticsCalculator filters by period type correctly', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final rawOrders = [
        // Today
        {
          'id': 'o-today',
          'totalAmount': 200.0,
          'status': 'delivered',
          'orderDate': now,
        },
        // 5 days ago (in this week)
        {
          'id': 'o-week',
          'totalAmount': 300.0,
          'status': 'delivered',
          'orderDate': now.subtract(const Duration(days: 5)),
        },
        // 20 days ago (in this month)
        {
          'id': 'o-month',
          'totalAmount': 400.0,
          'status': 'delivered',
          'orderDate': now.subtract(const Duration(days: 20)),
        },
        // 100 days ago (in this year)
        {
          'id': 'o-year',
          'totalAmount': 500.0,
          'status': 'delivered',
          'orderDate': now.subtract(const Duration(days: 100)),
        },
      ];

      final orders = rawOrders.map((e) => OrderModel.fromJson(e)).toList();
      const calculator = OrderAnalyticsCalculator();

      // Today filter
      final todayMetrics = calculator.calculate(
        orders: orders,
        referenceNow: now,
        periodType: DashboardPeriodType.today,
      );
      expect(todayMetrics.totalRevenue, equals(200.0));
      expect(todayMetrics.periodLabel, startsWith('اليوم'));

      // This Week filter (today + 5 days ago = 200 + 300 = 500)
      final weekMetrics = calculator.calculate(
        orders: orders,
        referenceNow: now,
        periodType: DashboardPeriodType.thisWeek,
      );
      expect(weekMetrics.totalRevenue, equals(500.0));
      expect(weekMetrics.periodLabel, equals('آخر 7 أيام'));

      // This Month filter (today + 5 days ago + 20 days ago = 200 + 300 + 400 = 900)
      final monthMetrics = calculator.calculate(
        orders: orders,
        referenceNow: now,
        periodType: DashboardPeriodType.thisMonth,
      );
      expect(monthMetrics.totalRevenue, equals(900.0));

      // All Time filter (200 + 300 + 400 + 500 = 1400)
      final allTimeMetrics = calculator.calculate(
        orders: orders,
        referenceNow: now,
        periodType: DashboardPeriodType.allTime,
      );
      expect(allTimeMetrics.totalRevenue, equals(1400.0));
    });

    test('CatalogAnalyticsCalculator tallies low-stock alerts and brand distribution in single pass', () {
      final products = [
        const ProductModel(
          id: '1',
          title: 'P1',
          description: '',
          price: 100,
          salePrice: 100,
          stock: 5,
          brand: ProductBrand(id: '1', name: 'Vaporesso'),
          categoryId: 'c1',
        ),
        const ProductModel(
          id: '2',
          title: 'P2',
          description: '',
          price: 100,
          salePrice: 100,
          stock: 20,
          brand: ProductBrand(id: '1', name: 'Vaporesso'),
          categoryId: 'c1',
        ),
        const ProductModel(
          id: '3',
          title: 'P3',
          description: '',
          price: 100,
          salePrice: 100,
          stock: 2,
          brand: ProductBrand(id: '2', name: 'Oxva'),
          categoryId: 'c1',
        ),
        const ProductModel(
          id: '4',
          title: 'P4',
          description: '',
          price: 100,
          salePrice: 100,
          stock: 50,
          brand: ProductBrand(id: '3', name: 'Geekvape'),
          categoryId: 'c1',
        ),
      ];

      const calculator = CatalogAnalyticsCalculator();
      final metrics = calculator.calculate(
        products: products,
        lowStockThreshold: 10,
      );

      // Low stock: 5 and 2 (2 products)
      expect(metrics.lowStockAlertsCount, equals(2));

      // Brand shares: Vaporesso (2/4 = 50%), Oxva (1/4 = 25%), Geekvape (1/4 = 25%)
      expect(metrics.brandShares.length, equals(3));
      final vaporesso = metrics.brandShares.firstWhere((b) => b.brandName == 'Vaporesso');
      expect(vaporesso.totalSold, equals(2));
      expect(vaporesso.sharePercentage, equals(50.0));
    });

    test('OrderAnalyticsCalculator properly deducts fully returned and partially refunded orders from revenue and profit', () {
      final now = DateTime(2026, 8, 29, 12, 0);
      final List<ProductModel> products = [
        const ProductModel(
          id: 'prod1',
          title: 'Vape Device',
          description: '',
          price: 500,
          costPrice: 300, // profit = 200 per unit
          salePrice: 500,
          stock: 10,
          brand: ProductBrand(id: 'b1', name: 'Brand1'),
          categoryId: 'c1',
        ),
        const ProductModel(
          id: 'prod2',
          title: 'Vape Liquid',
          description: '',
          price: 200,
          costPrice: 100, // profit = 100 per unit
          salePrice: 200,
          stock: 20,
          brand: ProductBrand(id: 'b1', name: 'Brand1'),
          categoryId: 'c1',
        ),
      ];

      final rawOrders = [
        // 1. Regular delivered POS order: 2x Vape Device = 1000 EGP (Cost = 600 EGP, Profit = 400 EGP)
        {
          'id': 'ord-pos-1',
          'isPosSale': true,
          'totalAmount': 1000.0,
          'status': 'delivered',
          'orderDate': now,
          'items': [
            {
              'productId': 'prod1',
              'title': 'Vape Device',
              'quantity': 2,
              'price': 500.0,
            }
          ],
        },
        // 2. Fully returned Online order: 1x Vape Device (was 500 EGP, status 'returned') -> MUST NOT contribute to revenue/profit
        {
          'id': 'ord-online-returned',
          'isPosSale': false,
          'totalAmount': 500.0,
          'refundedAmount': 500.0,
          'status': 'returned',
          'orderDate': now,
          'items': [
            {
              'productId': 'prod1',
              'title': 'Vape Device',
              'quantity': 1,
              'price': 500.0,
            }
          ],
        },
        // 3. Partially returned POS order: 1x Vape Device (500 EGP) + 2x Vape Liquid (400 EGP) = 900 EGP
        // Customer returned 1x Vape Liquid (200 EGP refunded, 1 unit returned in returnHistory)
        // Net revenue should be: 900 - 200 = 700 EGP. Net cost should be: 300 (Device) + 100 (1 remaining Liquid) = 400 EGP.
        // Net profit should be: 700 - 400 = 300 EGP.
        {
          'id': 'ord-pos-partial',
          'isPosSale': true,
          'totalAmount': 900.0,
          'refundedAmount': 200.0,
          'status': 'delivered',
          'orderDate': now,
          'returnHistory': [
            {
              'refundAmount': 200.0,
              'reason': 'Changed mind',
              'items': [
                {
                  'productId': 'prod2',
                  'title': 'Vape Liquid',
                  'quantity': 1,
                  'price': 200.0,
                }
              ]
            }
          ],
          'items': [
            {
              'productId': 'prod1',
              'title': 'Vape Device',
              'quantity': 1,
              'price': 500.0,
            },
            {
              'productId': 'prod2',
              'title': 'Vape Liquid',
              'quantity': 2,
              'price': 200.0,
            }
          ],
        },
      ];

      final orders = rawOrders.map((e) => OrderModel.fromJson(e)).toList();
      const calculator = OrderAnalyticsCalculator();
      final metrics = calculator.calculate(
        orders: orders,
        products: products,
        referenceNow: now,
      );

      // POS Channel:
      // Order 1: 1000 rev, 600 cost, 400 profit
      // Order 3: 700 rev (900-200), 400 cost, 300 profit
      // POS Total: 1700 rev, 1000 cost, 700 profit (41.17% margin), 2 active orders, 200 refunded
      expect(metrics.posMetrics.revenue, equals(1700.0));
      expect(metrics.posMetrics.cost, equals(1000.0));
      expect(metrics.posMetrics.netProfit, equals(700.0));
      expect(metrics.posMetrics.count, equals(2));
      expect(metrics.posMetrics.refundedAmount, equals(200.0));

      // Online Channel: (only the fully returned order, so 0 revenue, 0 cost, 0 profit)
      expect(metrics.onlineMetrics.revenue, equals(0.0));
      expect(metrics.onlineMetrics.cost, equals(0.0));
      expect(metrics.onlineMetrics.netProfit, equals(0.0));
      expect(metrics.onlineMetrics.count, equals(0));
      expect(metrics.onlineMetrics.refundedAmount, equals(500.0));

      // Combined Metrics: 1700 rev, 1000 cost, 700 profit
      expect(metrics.combinedMetrics.revenue, equals(1700.0));
      expect(metrics.combinedMetrics.cost, equals(1000.0));
      expect(metrics.combinedMetrics.netProfit, equals(700.0));
      expect(metrics.combinedMetrics.count, equals(2));

      // Itemized Product Sales Breakdown:
      // prod1 (Vape Device):
      // - ord-pos-1: 2 sold
      // - ord-online-returned: 0 sold (was returned)
      // - ord-pos-partial: 1 sold
      // Total prod1 = 3 units sold, 1500 revenue, 900 cost, 600 net profit
      final prod1Metrics = metrics.productSales.firstWhere((p) => p.productId == 'prod1');
      expect(prod1Metrics.totalQuantity, equals(3));
      expect(prod1Metrics.totalRevenue, equals(1500.0));
      expect(prod1Metrics.totalCost, equals(900.0));
      expect(prod1Metrics.netProfit, equals(600.0));

      // prod2 (Vape Liquid):
      // - ord-pos-partial: 2 originally, 1 returned -> net 1 sold, 200 revenue, 100 cost, 100 net profit
      final prod2Metrics = metrics.productSales.firstWhere((p) => p.productId == 'prod2');
      expect(prod2Metrics.totalQuantity, equals(1));
      expect(prod2Metrics.totalRevenue, equals(200.0));
      expect(prod2Metrics.totalCost, equals(100.0));
      expect(prod2Metrics.netProfit, equals(100.0));
    });
  });
}
