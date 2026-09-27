import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/widgets/order_details_drawer.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/brand_share_donut_chart.dart';
import '../widgets/dashboard_date_filter_bar.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/export_report_dialog.dart';
import '../widgets/live_orders_stream_widget.dart';
import '../widgets/low_stock_alert_card.dart';
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                DashboardHeader(
                  onExportPressed: () => ExportReportDialog.show(
                    context,
                    analytics: data,
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Interactive Period & Calendar Filter Bar
                DashboardDateFilterBar(analytics: data),
                const SizedBox(height: AppSizes.lg),

                // Sales & Net Profit by Channel (Online App vs Branch POS vs Total)
                SalesChannelProfitCard(analytics: data),
                const SizedBox(height: AppSizes.lg),

                // KPI Metric Cards Grid
                DashboardKpiGrid(analytics: data, isDesktop: isDesktop),
                const SizedBox(height: AppSizes.lg),

                // Supplier Financials & Accounts Payable Overview
                SupplierFinancialsCard(
                  analytics: data,
                  onNavigateTab: onNavigateTab,
                ),
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
                    final List<OrderModel> orders =
                        orderState is OrderLoaded ? orderState.orders : <OrderModel>[];
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
}
