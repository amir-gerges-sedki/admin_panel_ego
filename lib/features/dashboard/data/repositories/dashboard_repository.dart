import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/dashboard_analytics_model.dart';

abstract class DashboardRepository {
  Future<DashboardAnalyticsModel> getDashboardAnalytics();
}

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardAnalyticsModel> getDashboardAnalytics() async {
    try {
      // 1. Fetch Orders from Firestore
      final ordersDocs = await FirebaseService.getMultipleCollectionsDocs(['Orders', 'orders']);
      double totalRevenue = 0.0;
      int todayOrders = 0;
      int pendingOrders = 0;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Map for weekly trend (last 7 days)
      final Map<String, ({double revenue, int count})> weeklyMap = {};
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final label = DateFormat('E').format(d);
        weeklyMap[label] = (revenue: 0.0, count: 0);
      }

      final Map<String, int> brandCountMap = {};

      for (final doc in ordersDocs) {
        final data = doc.data();
        final total = (data['totalAmount'] ?? data['TotalAmount'] ?? data['total'] as num?)?.toDouble() ?? 0.0;
        final status = (data['status'] ?? data['Status'] as String?)?.toLowerCase() ?? '';
        final dateRaw = data['orderDate'] ?? data['OrderDate'] ?? data['createdAt'];
        
        DateTime date = now;
        if (dateRaw is DateTime) {
          date = dateRaw;
        } else if (dateRaw is Timestamp) {
          date = dateRaw.toDate();
        } else if (dateRaw is String) {
          date = DateTime.tryParse(dateRaw) ?? now;
        }

        totalRevenue += total;
        if (status == 'pending') pendingOrders++;
        if (date.isAfter(todayStart)) todayOrders++;

        // Weekly trend
        final dayLabel = DateFormat('E').format(date);
        if (weeklyMap.containsKey(dayLabel)) {
          final current = weeklyMap[dayLabel]!;
          weeklyMap[dayLabel] = (revenue: current.revenue + total, count: current.count + 1);
        }
      }

      // 2. Fetch Users from Firestore
      final usersDocs = await FirebaseService.getMultipleCollectionsDocs(['Users', 'users', 'Customers', 'customers']);
      final activeCustomers = usersDocs.length;

      // 3. Fetch Products from Firestore
      final productsDocs = await FirebaseService.getMultipleCollectionsDocs([
        'Products',
        'products',
        'liquids',
        'Liquids',
      ]);
      int lowStockCount = 0;
      for (final doc in productsDocs) {
        final data = doc.data();
        final stock = (data['stock'] ?? data['Stock'] ?? data['quantity'] as num?)?.toInt() ?? 0;
        if (stock <= 10) lowStockCount++;

        final brandData = data['brand'] ?? data['Brand'] ?? data['line'] ?? data['Line'] ?? data['lineName'];
        String brandName = 'Other';
        if (brandData is Map) {
          brandName = (brandData['name'] ?? brandData['Name'] ?? brandData['lineName'] as String?) ?? 'Other';
        } else if (brandData is String && brandData.isNotEmpty) {
          brandName = brandData;
        }
        brandCountMap[brandName] = (brandCountMap[brandName] ?? 0) + 1;
      }

      final weeklyTrend = weeklyMap.entries.map((e) {
        return RevenuePoint(
          label: e.key,
          revenue: e.value.revenue,
          ordersCount: e.value.count,
        );
      }).toList();

      final totalProducts = productsDocs.isEmpty ? 1 : productsDocs.length;
      final brandShares = brandCountMap.entries.map((e) {
        return BrandShareData(
          brandName: e.key,
          sharePercentage: (e.value / totalProducts) * 100,
          totalSold: e.value,
        );
      }).toList();

      return DashboardAnalyticsModel(
        totalRevenue: totalRevenue,
        todayOrders: todayOrders,
        activeCustomers: activeCustomers,
        avgOrderValue: ordersDocs.isNotEmpty ? (totalRevenue / ordersDocs.length) : 0.0,
        lowStockAlertsCount: lowStockCount,
        pendingOrdersCount: pendingOrders,
        weeklyTrend: weeklyTrend,
        categorySales: const [],
        brandShares: brandShares,
      );
    } catch (_) {
      return DashboardAnalyticsModel.empty();
    }
  }
}
