import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/widgets/order_details_drawer.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/brand_share_donut_chart.dart';
import '../widgets/damaged_goods_summary_card.dart';
import '../widgets/dashboard_attention_banner.dart';
import '../widgets/dashboard_date_filter_bar.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/dashboard_quick_actions_bar.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/expenses_summary_card.dart';
import '../widgets/export_report_dialog.dart';
import '../widgets/live_orders_stream_widget.dart';
import '../widgets/low_stock_alert_card.dart';
import '../widgets/payroll_hr_summary_card.dart';
import '../widgets/revenue_line_chart.dart';
import '../widgets/sales_channel_profit_card.dart';
import '../widgets/supplier_financials_card.dart';

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
          return BlocBuilder<OrderCubit, OrderState>(
            builder: (context, orderState) {
              final List<OrderModel> orders =
                  orderState is OrderLoaded ? orderState.orders : <OrderModel>[];
              final int pendingOrdersCount = orders
                  .where((o) => o.status.toLowerCase() == 'pending')
                  .length;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSizes.lg : AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Compact Header with Date Filter & Export
                    DashboardHeader(
                      onNavigateTab: onNavigateTab,
                      onExportPressed: () => ExportReportDialog.show(
                        context,
                        analytics: data,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm + 2),

                    // 2. Attention Banner (inline, minimal)
                    DashboardAttentionBanner(
                      analytics: data,
                      pendingOrdersCount: pendingOrdersCount,
                      onNavigateTab: onNavigateTab,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 3. Quick Actions (compact inline)
                    DashboardQuickActionsBar(onNavigateTab: onNavigateTab),
                    const SizedBox(height: AppSizes.md),

                    // 4. Date Filter Bar
                    DashboardDateFilterBar(analytics: data),
                    const SizedBox(height: AppSizes.md + 4),

                    // ═══ COLLAPSIBLE SECTIONS ═══

                    // 5. Sales & Revenue Section
                    DashboardSection(
                      title: 'sales_channel_title'.tr,
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF10B981),
                      child: Column(
                        children: [
                          SalesChannelProfitCard(analytics: data),
                          const SizedBox(height: AppSizes.md),
                          DashboardKpiGrid(analytics: data, isDesktop: isDesktop),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 6. Supply Chain & HR Section
                    DashboardSection(
                      title: 'supplier_financials_title'.tr,
                      icon: Icons.business_center_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      initiallyExpanded: false,
                      child: Column(
                        children: [
                          SupplierFinancialsCard(
                            analytics: data,
                            onNavigateTab: onNavigateTab,
                          ),
                          const SizedBox(height: AppSizes.md),
                          PayrollHrSummaryCard(
                            analytics: data,
                            onNavigateTab: onNavigateTab,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 7. Expenses & Damaged Goods Section
                    DashboardSection(
                      title: 'kpi_status_opex'.tr,
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      initiallyExpanded: false,
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ExpensesSummaryCard(
                                    analytics: data,
                                    onNavigateTab: onNavigateTab,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: DamagedGoodsSummaryCard(
                                    analytics: data,
                                    onNavigateTab: onNavigateTab,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                ExpensesSummaryCard(
                                  analytics: data,
                                  onNavigateTab: onNavigateTab,
                                ),
                                const SizedBox(height: AppSizes.md),
                                DamagedGoodsSummaryCard(
                                  analytics: data,
                                  onNavigateTab: onNavigateTab,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 8. Charts Section
                    DashboardSection(
                      title: 'revenue_analytics'.tr,
                      icon: Icons.bar_chart_rounded,
                      iconColor: AppColor.primary,
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: RevenueLineChart(weeklyTrend: data.weeklyTrend),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  flex: 4,
                                  child: BrandShareDonutChart(brandShares: data.brandShares),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                RevenueLineChart(weeklyTrend: data.weeklyTrend),
                                const SizedBox(height: AppSizes.md),
                                BrandShareDonutChart(brandShares: data.brandShares),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 9. Operations Section (Low Stock & Live Orders)
                    DashboardSection(
                      title: 'live_orders_feed_title'.tr,
                      icon: Icons.dynamic_feed_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 5,
                                  child: LowStockAlertCard(),
                                ),
                                const SizedBox(width: AppSizes.md),
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
                            )
                          : Column(
                              children: [
                                const LowStockAlertCard(),
                                const SizedBox(height: AppSizes.md),
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
                            ),
                    ),

                    // Bottom padding
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              );
            },
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
}
