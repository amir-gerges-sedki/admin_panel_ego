import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/order_cubit.dart';
import '../widgets/order_details_drawer.dart';
import '../widgets/order_share_dialog.dart';


class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderLoaded) {
          final orders = state.filteredOrders;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Filter Segmented Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(context, 'ALL', 'status_all'.tr, state.statusFilter),
                      _buildStatusFilterChip(context, 'Pending', 'status_pending'.tr, state.statusFilter, color: AppColor.statusPending),
                      _buildStatusFilterChip(context, 'Processing', 'status_processing'.tr, state.statusFilter, color: AppColor.statusProcessing),
                      _buildStatusFilterChip(context, 'Shipped', 'status_shipped'.tr, state.statusFilter, color: AppColor.statusShipped),
                      _buildStatusFilterChip(context, 'Delivered', 'status_delivered'.tr, state.statusFilter, color: AppColor.statusDelivered),
                      _buildStatusFilterChip(context, 'Cancelled', 'status_cancelled'.tr, state.statusFilter, color: AppColor.statusCancelled),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                CustomDataTable(
                  title: 'orders_title'.tr,
                  subtitle: 'orders_subtitle'.tr,
                  searchHint: 'search_orders_hint'.tr,
                  onSearchChanged: (q) => context.read<OrderCubit>().filterOrders(query: q),
                  emptyMessage: 'no_orders_found'.tr,
                  emptyIcon: Icons.shopping_bag_outlined,
                  columns: [
                    DataTableColumn(label: 'order_id'.tr),
                    DataTableColumn(label: 'customer'.tr),
                    DataTableColumn(label: 'payment'.tr),
                    DataTableColumn(label: 'ordered_items'.tr),
                    DataTableColumn(label: 'total'.tr),
                    DataTableColumn(label: 'date'.tr),
                    DataTableColumn(label: 'status'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: orders.map((o) {
                    return DataRow(
                      onSelectChanged: (_) {
                        OrderDetailsDrawer.show(
                          context,
                          o,
                          onStatusChanged: (newStatus) {
                            context.read<OrderCubit>().updateStatus(o.id, newStatus);
                          },
                        );
                      },
                      cells: [
                        DataCell(
                          Text(
                            o.id,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColor.primary),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.shippingAddress.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${o.shippingAddress.city} • ${AppFormatters.formatPhone(o.shippingAddress.phoneNumber)}',
                                style: const TextStyle(fontSize: 11, color: AppColor.textMutedDark),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(o.paymentMethod)),
                        DataCell(Text('items_ordered_count'.trParams({'count': '${o.items.length}'}))),
                        DataCell(
                          Text(
                            AppFormatters.formatEGP(o.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(AppFormatters.formatDateTime(o.orderDate))),
                        DataCell(StatusChip.fromOrderStatus(o.status)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  OrderDetailsDrawer.show(
                                    context,
                                    o,
                                    onStatusChanged: (newStatus) {
                                      context.read<OrderCubit>().updateStatus(o.id, newStatus);
                                    },
                                  );
                                },
                                icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                label: Text('order_details'.tr, style: const TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary.withValues(alpha: 0.15),
                                  foregroundColor: AppColor.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () => OrderShareDialog.show(context, o),
                                icon: const Icon(Icons.share_rounded, size: 16),
                                tooltip: 'share_with_courier'.tr,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  foregroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.all(6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),

                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        if (state is OrderError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.error),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton.icon(
                    onPressed: () => context.read<OrderCubit>().loadOrders(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('reload'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ElevatedButton.icon(
            onPressed: () => context.read<OrderCubit>().loadOrders(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('reload'.tr),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterChip(
    BuildContext context,
    String statusKey,
    String label,
    String selectedStatus, {
    Color color = AppColor.primary,
  }) {
    final isSelected = selectedStatus.toLowerCase() == statusKey.toLowerCase();

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : null,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (_) {
          context.read<OrderCubit>().filterOrders(status: statusKey);
        },
      ),
    );
  }
}
