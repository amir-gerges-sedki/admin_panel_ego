import 'package:flutter/material.dart';
import '../../../../common/widgets/cards/kpi_metric_card.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/dashboard_analytics_model.dart';

class DashboardKpiGrid extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final bool isDesktop;

  const DashboardKpiGrid({
    super.key,
    required this.analytics,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final revenueSparkline = analytics.weeklyTrend.map((e) => e.revenue).toList();
    final ordersSparkline = analytics.weeklyTrend.map((e) => e.ordersCount.toDouble()).toList();

    final cards = [
      KpiMetricCard(
        title: 'kpi_total_revenue'.tr,
        value: AppFormatters.formatCompactEGP(analytics.totalRevenue),
        delta: analytics.totalRevenue > 0 ? 'Active' : '0 EGP',
        isPositive: true,
        icon: Icons.account_balance_wallet_outlined,
        accentColor: AppColor.primary,
        sparklineData: revenueSparkline.any((v) => v > 0) ? revenueSparkline : null,
      ),
      KpiMetricCard(
        title: 'kpi_net_profit'.tr,
        value: AppFormatters.formatCompactEGP(analytics.netProfit),
        delta: analytics.totalRevenue > 0
            ? '${analytics.profitMargin.toStringAsFixed(1)}% ${"profit_margin".tr}'
            : '0.0%',
        isPositive: analytics.netProfit >= 0,
        icon: Icons.trending_up_rounded,
        accentColor: const Color(0xFF10B981),
      ),
      KpiMetricCard(
        title: 'kpi_supplier_payables'.tr,
        value: AppFormatters.formatCompactEGP(analytics.totalSupplierBalanceDue),
        delta: analytics.totalSupplierBalanceDue > 0
            ? '${AppFormatters.formatCompactEGP(analytics.totalSupplierBalanceDue)} Due'
            : 'Settled',
        isPositive: analytics.totalSupplierBalanceDue == 0,
        icon: Icons.business_center_rounded,
        accentColor: analytics.totalSupplierBalanceDue > 0
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
      ),
      KpiMetricCard(
        title: 'kpi_today_orders'.tr,
        value: '${analytics.todayOrders} Orders',
        delta: '${analytics.todayOrders} today',
        isPositive: analytics.todayOrders > 0,
        icon: Icons.shopping_bag_outlined,
        accentColor: AppColor.secondary,
        sparklineData: ordersSparkline.any((v) => v > 0) ? ordersSparkline : null,
      ),
      KpiMetricCard(
        title: 'kpi_low_stock_alerts'.tr,
        value: '${analytics.lowStockAlertsCount} Items',
        delta: analytics.lowStockAlertsCount > 0 ? '${analytics.lowStockAlertsCount} urgent' : 'Healthy',
        isPositive: analytics.lowStockAlertsCount == 0,
        icon: Icons.warning_amber_rounded,
        accentColor: analytics.lowStockAlertsCount > 0 ? AppColor.warning : AppColor.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 1100) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else if (width >= 650) {
          return Column(
            children: [
              Row(
                children: cards
                    .sublist(0, 3)
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: c,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: cards
                    .sublist(3, 5)
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: c,
                          ),
                        ))
                    .toList(),
              ),
            ],
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: c,
                    ))
                .toList(),
          );
        }
      },
    );
  }
}
