import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/dashboard/data/models/dashboard_analytics_model.dart';
import 'package:admin_panel_ego/features/dashboard/presentation/widgets/dashboard_date_filter_bar.dart';
import 'package:admin_panel_ego/features/dashboard/presentation/widgets/sales_channel_profit_card.dart';

void main() {
  group('DashboardDateFilterBar & SalesChannelProfitCard Widget Tests', () {
    testWidgets('Renders simplified filter bar with Today, All, and Dual Date Pickers', (tester) async {
      const analytics = DashboardAnalyticsModel(
        totalRevenue: 25000,
        totalCost: 15000,
        netProfit: 10000,
        profitMargin: 40.0,
        todayOrders: 12,
        activeCustomers: 50,
        avgOrderValue: 714.28,
        lowStockAlertsCount: 2,
        pendingOrdersCount: 3,
        weeklyTrend: [],
        categorySales: [],
        brandShares: [],
        onlineMetrics: ChannelFinancialMetrics(
          revenue: 15000,
          cost: 9000,
          netProfit: 6000,
          profitMargin: 40.0,
          count: 20,
          averageTicket: 750,
        ),
        posMetrics: ChannelFinancialMetrics(
          revenue: 10000,
          cost: 6000,
          netProfit: 4000,
          profitMargin: 40.0,
          count: 15,
          averageTicket: 666.67,
        ),
        combinedMetrics: ChannelFinancialMetrics(
          revenue: 25000,
          cost: 15000,
          netProfit: 10000,
          profitMargin: 40.0,
          count: 35,
          averageTicket: 714.28,
        ),
        periodType: DashboardPeriodType.today,
        periodLabel: 'اليوم (2026/09/27)',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DashboardDateFilterBar(analytics: analytics),
                  SalesChannelProfitCard(analytics: analytics),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify Today & All buttons are visible
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('كافة الفترات'), findsOneWidget);

      // Verify Dual Date Pickers are visible (من & إلى)
      expect(find.text('من:'), findsOneWidget);
      expect(find.text('إلى:'), findsOneWidget);

      // Verify Sales Channel comparison cards
      expect(find.text('مقارنة المبيعات وصافي الأرباح (القنوات)'), findsOneWidget);
      expect(find.text('تطبيق الأونلاين (App)'), findsOneWidget);
      expect(find.text('كاشير الفرع (POS)'), findsOneWidget);
      expect(find.text('الإجمالي المجمّع (Total)'), findsOneWidget);

      // Verify Product Sales Breakdown Banner Button
      expect(find.text('عرض تفاصيل مبيعات المنتجات والأصناف'), findsOneWidget);
    });
  });
}
