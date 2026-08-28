import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/cards/kpi_metric_card.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/widgets/order_details_drawer.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/brand_share_donut_chart.dart';
import '../widgets/live_orders_stream_widget.dart';
import '../widgets/low_stock_alert_card.dart';
import '../widgets/revenue_line_chart.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DashboardLoaded) {
          final data = state.analytics;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'executive_overview'.tr,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: HelperFun.isDarkMode(context)
                                  ? AppColor.textPrimaryDark
                                  : AppColor.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'executive_overview_sub'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: HelperFun.isDarkMode(context)
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    ElevatedButton.icon(
                      onPressed: () {
                        HelperFun.successSnackbar('export_csv'.tr, 'CSV summary generated successfully!');
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text('export_csv'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // KPI Metric Cards Grid
                _buildKpiGrid(context, data, isDesktop),
                const SizedBox(height: AppSizes.lg),

                // Charts Row
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: RevenueLineChart(weeklyTrend: data.weeklyTrend),
                      ),
                      const SizedBox(width: AppSizes.lg),
                      Expanded(
                        flex: 4,
                        child: BrandShareDonutChart(brandShares: data.brandShares),
                      ),
                    ],
                  )
                else ...[
                  RevenueLineChart(weeklyTrend: data.weeklyTrend),
                  const SizedBox(height: AppSizes.lg),
                  BrandShareDonutChart(brandShares: data.brandShares),
                ],
                const SizedBox(height: AppSizes.lg),

                // Bottom Section: Low Stock Warnings & Live Order Dispatch
                BlocBuilder<OrderCubit, OrderState>(
                  builder: (context, orderState) {
                    final List<OrderModel> orders = orderState is OrderLoaded ? orderState.orders : <OrderModel>[];
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 5,
                            child: LowStockAlertCard(),
                          ),
                          const SizedBox(width: AppSizes.lg),
                          Expanded(
                            flex: 5,
                            child: LiveOrdersStreamWidget(
                              recentOrders: orders,
                              onOrderTapped: (order) {
                                OrderDetailsDrawer.show(
                                  context,
                                  order,
                                  onStatusChanged: (newStatus) {
                                    context.read<OrderCubit>().updateStatus(order.id, newStatus);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const LowStockAlertCard(),
                          const SizedBox(height: AppSizes.lg),
                          LiveOrdersStreamWidget(
                            recentOrders: orders,
                            onOrderTapped: (order) {
                              OrderDetailsDrawer.show(
                                context,
                                order,
                                onStatusChanged: (newStatus) {
                                  context.read<OrderCubit>().updateStatus(order.id, newStatus);
                                },
                              );
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<DashboardCubit>().loadDashboard(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, DashboardAnalyticsModel data, bool isDesktop) {
    final revenueSparkline = data.weeklyTrend.map((e) => e.revenue).toList();
    final ordersSparkline = data.weeklyTrend.map((e) => e.ordersCount.toDouble()).toList();

    final cards = [
      KpiMetricCard(
        title: 'kpi_total_revenue'.tr,
        value: AppFormatters.formatCompactEGP(data.totalRevenue),
        delta: data.totalRevenue > 0 ? 'Active' : '0 EGP',
        isPositive: true,
        icon: Icons.account_balance_wallet_outlined,
        accentColor: AppColor.primary,
        sparklineData: revenueSparkline.any((v) => v > 0) ? revenueSparkline : null,
      ),
      KpiMetricCard(
        title: 'kpi_today_orders'.tr,
        value: '${data.todayOrders} Orders',
        delta: '${data.todayOrders} today',
        isPositive: data.todayOrders > 0,
        icon: Icons.shopping_bag_outlined,
        accentColor: AppColor.secondary,
        sparklineData: ordersSparkline.any((v) => v > 0) ? ordersSparkline : null,
      ),
      KpiMetricCard(
        title: 'kpi_active_customers'.tr,
        value: '${data.activeCustomers}',
        delta: '${data.activeCustomers} users',
        isPositive: data.activeCustomers > 0,
        icon: Icons.people_outline_rounded,
        accentColor: AppColor.statusShipped,
      ),
      KpiMetricCard(
        title: 'kpi_low_stock_alerts'.tr,
        value: '${data.lowStockAlertsCount} Items',
        delta: data.lowStockAlertsCount > 0 ? '${data.lowStockAlertsCount} urgent' : 'Healthy',
        isPositive: data.lowStockAlertsCount == 0,
        icon: Icons.warning_amber_rounded,
        accentColor: data.lowStockAlertsCount > 0 ? AppColor.warning : AppColor.success,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
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
  }
}
