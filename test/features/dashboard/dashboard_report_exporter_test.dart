import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/dashboard/data/models/dashboard_analytics_model.dart';
import 'package:admin_panel_ego/features/dashboard/utils/dashboard_report_exporter.dart';
import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

void main() {
  group('DashboardReportExporter CSV Unit Tests', () {
    final sampleAnalytics = DashboardAnalyticsModel(
      totalRevenue: 15450.0,
      todayOrders: 5,
      activeCustomers: 42,
      avgOrderValue: 750.0,
      lowStockAlertsCount: 3,
      pendingOrdersCount: 2,
      weeklyTrend: const [
        RevenuePoint(label: 'Sat', revenue: 2500, ordersCount: 2),
        RevenuePoint(label: 'Sun', revenue: 3200, ordersCount: 3),
      ],
      categorySales: const [],
      brandShares: const [
        BrandShareData(brandName: 'Vaporesso', sharePercentage: 60.0, totalSold: 12),
        BrandShareData(brandName: 'Oxva', sharePercentage: 40.0, totalSold: 8),
      ],
    );

    final sampleOrders = [
      OrderModel(
        id: 'ord_101',
        userId: 'user_1',
        shippingAddress: const ShippingAddressModel(
          name: 'Ahmed Ali',
          street: '15 Tahrir St, Apt 4',
          city: 'Cairo',
          postalCode: '11511',
          phoneNumber: '01012345678',
        ),
        items: const [
          OrderItemModel(
            productId: 'p1',
            title: 'XROS 4 Pod System',
            price: 1500,
            quantity: 2,
            selectedVariation: {'Color': 'Space Grey'},
          ),
        ],
        subTotal: 3000,
        shippingCost: 50,
        discount: 100,
        totalAmount: 2950,
        orderDate: DateTime(2026, 9, 20, 14, 30),
        status: 'shipped',
        paymentStatus: 'paid',
        paymentMethod: 'Credit Card',
        orderNotes: 'Call before delivery',
      ),
    ];

    final sampleProducts = [
      const ProductModel(
        id: 'p1',
        title: 'Vaporesso XROS 4',
        brand: ProductBrand(id: 'b1', name: 'Vaporesso'),
        categoryId: 'c1',
        price: 1500,
        salePrice: 1400,
        stock: 4,
        description: 'Premium pod system',
      ),
      const ProductModel(
        id: 'p2',
        title: 'Oxva Xlim Pro 2',
        brand: ProductBrand(id: 'b2', name: 'Oxva'),
        categoryId: 'c1',
        price: 1600,
        salePrice: 0,
        stock: 25,
        description: 'Popular pod device',
      ),
    ];

    test('generateExecutiveSummaryCsv produces valid CSV with KPI, trend and brand metrics', () {
      final csv = DashboardReportExporter.generateExecutiveSummaryCsv(
        analytics: sampleAnalytics,
        lowStockThreshold: 10,
      );

      expect(csv, contains('EXECUTIVE OVERVIEW REPORT'));
      expect(csv, contains('"Total Revenue","15450.00",EGP'));
      expect(csv, contains('"Low Stock Threshold","10",Units'));
      expect(csv, contains('"Sat","2500.00","2"'));
      expect(csv, contains('"Vaporesso","60.0"%,"12"'));
    });

    test('generateOrdersReportCsv formats order rows with customer address, financials and notes', () {
      final csv = DashboardReportExporter.generateOrdersReportCsv(
        orders: sampleOrders,
      );

      expect(csv, contains('ORDERS & SALES MANIFEST'));
      expect(csv, contains('Total Orders Count,1'));
      expect(csv, contains('"ord_101"'));
      expect(csv, contains('"Ahmed Ali"'));
      expect(csv, contains('"Cairo"'));
      expect(csv, contains('"SHIPPED"'));
      expect(csv, contains('"PAID"'));
      expect(csv, contains('"2950.00"'));
      expect(csv, contains('"Call before delivery"'));
    });

    test('generateInventoryReportCsv correctly tags URGENT LOW STOCK vs OPTIMAL items', () {
      final csv = DashboardReportExporter.generateInventoryReportCsv(
        products: sampleProducts,
        lowStockThreshold: 10,
      );

      expect(csv, contains('INVENTORY & STOCK HEALTH REPORT'));
      expect(csv, contains('"Vaporesso XROS 4"'));
      expect(csv, contains('"URGENT LOW STOCK"'));
      expect(csv, contains('"Oxva Xlim Pro 2"'));
      expect(csv, contains('"OPTIMAL"'));
    });

    test('generateMasterReportCsv aggregates executive, order and inventory sections', () {
      final csv = DashboardReportExporter.generateMasterReportCsv(
        analytics: sampleAnalytics,
        orders: sampleOrders,
        products: sampleProducts,
        lowStockThreshold: 10,
      );

      expect(csv, contains('EXECUTIVE OVERVIEW REPORT'));
      expect(csv, contains('ORDERS & SALES MANIFEST'));
      expect(csv, contains('INVENTORY & STOCK HEALTH REPORT'));
    });
  });
}
