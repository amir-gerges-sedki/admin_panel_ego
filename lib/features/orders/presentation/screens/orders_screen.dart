import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../pos/data/models/pos_sale_model.dart';
import '../../../pos/utils/pos_receipt_printer.dart';
import '../../data/models/order_model.dart';
import '../../utils/order_invoice_printer.dart';
import '../cubit/order_cubit.dart';
import '../widgets/order_details_drawer.dart';
import '../widgets/order_share_dialog.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  void _openOrderDetails(BuildContext context, OrderModel order) {
    OrderDetailsDrawer.show(
      context,
      order,
      onStatusChanged: (newStatus) {
        context.read<OrderCubit>().updateStatus(order.id, newStatus);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderLoaded) {
          final orders = state.filteredOrders;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Channel / Source Filter Segmented Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSourceTabButton(
                          context,
                          isDark: isDark,
                          keyName: 'ONLINE',
                          icon: Icons.phone_android_rounded,
                          title: 'طلبات الأبلكيشن والتوصيل',
                          subtitle: 'طلبات الشحن والديسباتش',
                          count: state.onlineCount,
                          isSelected: state.sourceFilter == 'ONLINE',
                          activeColor: const Color(0xFF3B82F6),
                          badgeAlert: state.pendingOnlineCount > 0 ? '${state.pendingOnlineCount} جديد' : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSourceTabButton(
                          context,
                          isDark: isDark,
                          keyName: 'POS',
                          icon: Icons.point_of_sale_rounded,
                          title: 'مبيعات الفرع والكاشير',
                          subtitle: 'بيع مباشر فوري بالمتجر',
                          count: state.posCount,
                          isSelected: state.sourceFilter == 'POS',
                          activeColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSourceTabButton(
                          context,
                          isDark: isDark,
                          keyName: 'ALL',
                          icon: Icons.all_inclusive_rounded,
                          title: 'كافة المعاملات والطلبات',
                          subtitle: 'سجل المبيعات الشامل',
                          count: state.totalCount,
                          isSelected: state.sourceFilter == 'ALL',
                          activeColor: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // 2. Status Filter Segmented Bar (Only shown for ALL or ONLINE tabs)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(context, 'ALL', 'status_all'.tr, state.statusFilter),
                      _buildStatusFilterChip(context, 'Pending', 'status_pending'.tr, state.statusFilter, color: AppColor.statusPending),
                      _buildStatusFilterChip(context, 'Processing', 'status_processing'.tr, state.statusFilter, color: AppColor.statusProcessing),
                      _buildStatusFilterChip(context, 'Shipped', 'status_shipped'.tr, state.statusFilter, color: AppColor.statusShipped),
                      _buildStatusFilterChip(context, 'Delivered', 'status_delivered'.tr, state.statusFilter, color: AppColor.statusDelivered),
                      _buildStatusFilterChip(
                        context,
                        'Returned',
                        state.returnedCount > 0 ? 'المرتجعات (${state.returnedCount})' : 'المرتجعات',
                        state.statusFilter,
                        color: const Color(0xFFF97316),
                      ),
                      _buildStatusFilterChip(context, 'Cancelled', 'status_cancelled'.tr, state.statusFilter, color: AppColor.statusCancelled),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm + 4),

                // 3. Custom Data Table with Order Source Badges & Tailored Actions
                CustomDataTable(
                  title: state.sourceFilter == 'ONLINE'
                      ? 'طلبات تطبيق المتجر (Online Orders)'
                      : (state.sourceFilter == 'POS'
                          ? 'مبيعات الكاشير والفرع (In-Store POS)'
                          : 'orders_title'.tr),
                  subtitle: state.sourceFilter == 'ONLINE'
                      ? 'متابعة وتجهيز طلبات الشحن والتوصيل للمناديب'
                      : (state.sourceFilter == 'POS'
                          ? 'سجل عمليات البيع المباشر داخل المتجر والإيصالات'
                          : 'orders_subtitle'.tr),
                  searchHint: 'search_orders_hint'.tr,
                  showCheckboxColumn: false,
                  onSearchChanged: (q) => context.read<OrderCubit>().filterOrders(query: q),
                  emptyMessage: state.sourceFilter == 'ONLINE'
                      ? 'لا توجد طلبات أونلاين مسجلة'
                      : (state.sourceFilter == 'POS'
                          ? 'لا توجد عمليات بيع كاشير مسجلة'
                          : 'no_orders_found'.tr),
                  emptyIcon: state.sourceFilter == 'POS' ? Icons.point_of_sale_outlined : Icons.shopping_bag_outlined,
                  columns: [
                    DataTableColumn(label: 'order_id'.tr),
                    const DataTableColumn(label: 'المصدر / القناة'),
                    DataTableColumn(label: 'customer'.tr),
                    DataTableColumn(label: 'payment'.tr),
                    DataTableColumn(label: 'ordered_items'.tr),
                    DataTableColumn(label: 'total'.tr),
                    DataTableColumn(label: 'date'.tr),
                    DataTableColumn(label: 'status'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: orders.map((o) {
                    final isPos = o.isPosSale;

                    return DataRow(
                      onSelectChanged: (_) => _openOrderDetails(context, o),
                      cells: [
                        // 1. Order ID
                        DataCell(
                          Text(
                            '#${o.id}',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isPos ? const Color(0xFF8B5CF6) : AppColor.primary,
                            ),
                          ),
                        ),

                        // 2. Source / Channel Badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isPos ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isPos ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPos ? Icons.storefront_rounded : Icons.phone_android_rounded,
                                  size: 13,
                                  color: isPos ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPos ? 'كاشير الفرع' : 'تطبيق أونلاين',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isPos ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 3. Customer / Cashier Info
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.shippingAddress.name.isNotEmpty
                                    ? o.shippingAddress.name
                                    : (isPos ? 'عميل مباشر' : 'عميل غير مسجل'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                isPos
                                    ? (o.cashierName.isNotEmpty
                                        ? 'كاشير: ${o.cashierName}'
                                        : 'مبيعات مباشرة بالفرع')
                                    : '${o.shippingAddress.city} • ${AppFormatters.formatPhone(o.shippingAddress.phoneNumber)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Payment Method
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                o.paymentMethod.toLowerCase().contains('cash') || o.paymentMethod.contains('نقدي')
                                    ? Icons.payments_outlined
                                    : (o.paymentMethod.toLowerCase().contains('card') || o.paymentMethod.contains('فيزا')
                                        ? Icons.credit_card_rounded
                                        : Icons.account_balance_wallet_outlined),
                                size: 14,
                                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                              ),
                              const SizedBox(width: 5),
                              Text(o.paymentMethod, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),

                        // 5. Ordered Items Count
                        DataCell(Text('items_ordered_count'.trParams({'count': '${o.items.length}'}))),

                        // 6. Total Amount
                        DataCell(
                          Text(
                            AppFormatters.formatEGP(o.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),

                        // 7. Date
                        DataCell(Text(AppFormatters.formatDateTime(o.orderDate), style: const TextStyle(fontSize: 11.5))),

                        // 8. Status
                        DataCell(StatusChip.fromOrderStatus(o.status)),

                        // 9. Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Details button
                              IconButton(
                                onPressed: () => _openOrderDetails(context, o),
                                icon: const Icon(Icons.visibility_outlined, size: 17),
                                tooltip: 'order_details'.tr,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                                  foregroundColor: AppColor.primary,
                                  padding: const EdgeInsets.all(6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Thermal Receipt Print for POS OR Courier Share for Online Orders
                              if (isPos) ...[
                                IconButton(
                                  onPressed: () => PosReceiptPrinter.printThermalReceipt(PosSaleModel.fromOrder(o)),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 17),
                                  tooltip: 'طباعة إيصال الكاشير الحراري',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                    foregroundColor: const Color(0xFF8B5CF6),
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ] else ...[
                                IconButton(
                                  onPressed: () => OrderShareDialog.show(context, o),
                                  icon: const Icon(Icons.share_rounded, size: 17),
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
                              const SizedBox(width: 6),

                              // A4 Invoice Print
                              IconButton(
                                onPressed: () => OrderInvoicePrinter.showOrderInvoicePreview(context, o),
                                icon: const Icon(Icons.print_outlined, size: 17),
                                tooltip: 'print_invoice'.tr,
                                style: IconButton.styleFrom(
                                  backgroundColor: (isDark ? Colors.white10 : Colors.black12),
                                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildSourceTabButton(
    BuildContext context, {
    required bool isDark,
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required bool isSelected,
    required Color activeColor,
    String? badgeAlert,
  }) {
    return InkWell(
      onTap: () {
        context.read<OrderCubit>().filterOrders(sourceFilter: keyName);
      },
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : (isDark ? AppColor.darkCard : AppColor.lightCard),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? activeColor : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeAlert != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColor.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeAlert,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : (isDark ? AppColor.darkCard : AppColor.lightCard),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
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
