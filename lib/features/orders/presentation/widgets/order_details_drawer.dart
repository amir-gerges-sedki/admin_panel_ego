import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../pos/data/models/pos_sale_model.dart';
import '../../../pos/utils/pos_receipt_printer.dart';
import '../../data/models/order_model.dart';
import '../../utils/order_invoice_printer.dart';
import '../../utils/order_share_helper.dart';
import 'order_return_dialog.dart';
import 'order_share_dialog.dart';
import 'order_status_dispatcher.dart';

class OrderDetailsDrawer extends StatelessWidget {
  final OrderModel order;
  final ValueChanged<String>? onStatusChanged;

  const OrderDetailsDrawer({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  static void show(BuildContext context, OrderModel order, {ValueChanged<String>? onStatusChanged}) {
    UnifiedModalSheet.show(
      context: context,
      title: 'order_number'.trParams({'id': order.id}),
      subtitle: '${AppFormatters.formatDateTime(order.orderDate)} • ${order.paymentMethod}',
      icon: Icons.receipt_long_rounded,
      maxWidth: 960,
      content: OrderDetailsDrawer(order: order, onStatusChanged: onStatusChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Dispatcher, Customer Details & Actions
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusHeader(context, isDark),
                    if (order.isReturned || order.returnHistory.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.sm + 2),
                      _buildReturnAuditBanner(context, isDark),
                    ],
                    const SizedBox(height: AppSizes.sm + 2),
                    _buildCustomerAndAddressCard(context, isDark),
                    if (order.orderNotes.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.sm + 2),
                      _buildCustomerNotesCard(context, isDark),
                    ],
                    const SizedBox(height: AppSizes.sm + 2),
                    _buildActionToolbar(context, isDark),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // Right Column: Ordered Items & Financial Invoice
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOrderedItemsCard(context, isDark),
                    const SizedBox(height: AppSizes.sm + 2),
                    _buildFinancialBreakdownCard(context, isDark),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(context, isDark),
            if (order.isReturned || order.returnHistory.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm + 2),
              _buildReturnAuditBanner(context, isDark),
            ],
            const SizedBox(height: AppSizes.sm + 2),
            _buildCustomerAndAddressCard(context, isDark),
            if (order.orderNotes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm + 2),
              _buildCustomerNotesCard(context, isDark),
            ],
            const SizedBox(height: AppSizes.sm + 2),
            _buildOrderedItemsCard(context, isDark),
            const SizedBox(height: AppSizes.sm + 2),
            _buildFinancialBreakdownCard(context, isDark),
            const SizedBox(height: AppSizes.sm + 2),
            _buildActionToolbar(context, isDark),
          ],
        );
      },
    );
  }

  // --- 1. STATUS HEADER & DISPATCHER ---
  Widget _buildStatusHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${'current_status'.tr}: ',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  StatusChip.fromOrderStatus(order.status),
                ],
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.id));
                  HelperFun.showNotificationAlert(
                    title: 'copy_order_id'.tr,
                    message: '${'copied_to_clipboard'.tr}: #${order.id}',
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Tooltip(
                  message: 'copy_order_id'.tr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 13, color: AppColor.primary),
                        const SizedBox(width: 4),
                        Text(
                          '#${order.id}',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'order_time'.tr}: ${AppFormatters.formatDateTime(order.orderDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
              ),
              Text(
                '${'total'.tr}: ${AppFormatters.formatEGP(order.totalAmount)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColor.primary),
              ),
            ],
          ),
          if (order.isPosSale) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 22, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معاملة بيع كاشير مباشرة (In-Store POS)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF8B5CF6)),
                        ),
                        Text(
                          order.cashierName.isNotEmpty
                              ? 'تم التحصيل والتسليم بالفرع بواسطة: ${order.cashierName}'
                              : 'تم التحصيل والتسليم بالفرع فورياً بدون الحاجة للشحن.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSizes.md),
            OrderStatusDispatcher(
              currentStatus: order.status,
              onStatusSelected: (newStatus) {
                onStatusChanged?.call(newStatus);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. CUSTOMER & DELIVERY ADDRESS ---
  Widget _buildCustomerAndAddressCard(BuildContext context, bool isDark) {
    final addr = order.shippingAddress;
    final firstLetter = addr.name.isNotEmpty ? addr.name.substring(0, 1).toUpperCase() : 'C';

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColor.primary.withValues(alpha: 0.15),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addr.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    if (order.customerEmail.isNotEmpty)
                      Text(
                        order.customerEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              if (addr.phoneNumber.isNotEmpty)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: addr.phoneNumber));
                    HelperFun.showNotificationAlert(
                      title: 'copy_phone'.tr,
                      message: '${'copied_to_clipboard'.tr}: ${addr.phoneNumber}',
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColor.primary),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatPhone(addr.phoneNumber),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColor.statusPending),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'shipping_address'.tr}: ${addr.governorate.isNotEmpty ? addr.governorate : addr.city} • ${addr.street}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    if (addr.building.isNotEmpty || addr.floor.isNotEmpty || addr.apartment.isNotEmpty || addr.landmark.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        addr.formattedFullAddress,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () => OrderShareHelper.launchGoogleMaps(addr),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map_outlined, size: 13, color: AppColor.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'open_in_google_maps'.tr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => OrderShareDialog.show(context, order),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.share_rounded, size: 13, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'share_order'.tr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

  }

  // --- 3. CUSTOMER SPECIAL NOTES ---
  Widget _buildCustomerNotesCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'customer_notes'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.orderNotes,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. ORDERED ITEMS SECTION ---
  Widget _buildOrderedItemsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'ordered_items_label'.tr} (${order.items.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                ),
              ),
              if (order.items.isNotEmpty)
                Text(
                  '${order.items.fold<int>(0, (total, itm) => total + itm.quantity)} Total Qty',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
            ],
          ),
          const Divider(height: 16),

          if (order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 32, color: AppColor.warning),
                    const SizedBox(height: 6),
                    Text(
                      'no_items_in_order'.tr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final item = order.items[i];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: isDark ? AppColor.darkCard : AppColor.lightCard,
                        child: item.image.isNotEmpty
                            ? Image.network(
                                item.image,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.inventory_2_outlined, size: 22, color: AppColor.primary),
                              )
                            : const Icon(Icons.inventory_2_outlined, size: 22, color: AppColor.primary),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm + 4),

                    // Item Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                          ),
                          if (item.brand.isNotEmpty || item.sku.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (item.brand.isNotEmpty)
                                  Text(
                                    item.brand,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.primary),
                                  ),
                                if (item.brand.isNotEmpty && item.sku.isNotEmpty)
                                  const Text(' • ', style: TextStyle(fontSize: 10, color: AppColor.textMutedDark)),
                                if (item.sku.isNotEmpty)
                                  Text(
                                    'SKU: ${item.sku}',
                                    style: TextStyle(fontSize: 10, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                                  ),
                              ],
                            ),
                          ],
                          if (item.selectedVariation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: item.selectedVariation.entries.map((e) {
                                Color badgeColor = AppColor.primary;
                                final key = e.key.toLowerCase();
                                if (key.contains('flavor') || key.contains('flavour')) {
                                  badgeColor = const Color(0xFF10B981);
                                } else if (key.contains('style') || key.contains('type') || key.contains('dl') || key.contains('mtl')) {
                                  badgeColor = const Color(0xFF8B5CF6);
                                } else if (key.contains('size') || key.contains('bottle') || key.contains('ml')) {
                                  badgeColor = const Color(0xFF6366F1);
                                } else if (key.contains('nicotine') || key.contains('mg')) {
                                  badgeColor = const Color(0xFFEC4899);
                                } else if (key.contains('color') || key.contains('colour')) {
                                  badgeColor = const Color(0xFF06B6D4);
                                } else if (key.contains('resistance') || key.contains('ohm')) {
                                  badgeColor = const Color(0xFFF59E0B);
                                } else if (key.contains('wattage')) {
                                  badgeColor = const Color(0xFFE11D48);
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
                                  ),
                                  child: Text(
                                    '${e.key}: ${e.value}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: badgeColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Price Breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.formatEGP(item.totalItemPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${item.quantity}x ${AppFormatters.formatEGP(item.price)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        if (item.originalPrice != null && item.originalPrice! > item.price)
                          Text(
                            AppFormatters.formatEGP(item.originalPrice!),
                            style: const TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: AppColor.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 5. FINANCIAL INVOICE BREAKDOWN ---
  Widget _buildFinancialBreakdownCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        children: [
          _buildPriceRow('subtotal'.tr, AppFormatters.formatEGP(order.subTotal)),
          const SizedBox(height: 4),
          _buildPriceRow(
            'delivery_fee'.tr,
            order.shippingCost == 0 ? 'free_delivery_notice'.tr : AppFormatters.formatEGP(order.shippingCost),
            isFree: order.shippingCost == 0,
          ),
          if (order.taxFee > 0) ...[
            const SizedBox(height: 4),
            _buildPriceRow('tax_fee'.tr, AppFormatters.formatEGP(order.taxFee)),
          ],
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _buildPriceRow(
              order.couponCode.isNotEmpty
                  ? '${'discount_applied'.tr} (${order.couponCode})'
                  : 'discount_applied'.tr,
              '- ${AppFormatters.formatEGP(order.discount)}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 16),
          _buildPriceRow(
            'grand_total'.tr,
            AppFormatters.formatEGP(order.totalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'payment'.tr}: ${order.paymentMethod}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (order.paymentStatus.toLowerCase() == 'paid'
                          ? AppColor.success
                          : AppColor.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.paymentStatus.toLowerCase() == 'paid'
                      ? 'paid'.tr
                      : (order.paymentMethod.toLowerCase().contains('cash')
                          ? 'cash_on_delivery'.tr
                          : order.paymentStatus.toUpperCase()),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: order.paymentStatus.toLowerCase() == 'paid'
                        ? AppColor.success
                        : AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. ACTION TOOLBAR (SHARE FOR DELIVERY, RETURN / REFUND & PRINT INVOICE) ---
  Widget _buildActionToolbar(BuildContext context, bool isDark) {
    if (order.isPosSale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () => PosReceiptPrinter.printThermalReceipt(PosSaleModel.fromOrder(order)),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('طباعة إيصال حراري (POS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () => OrderInvoicePrinter.showOrderInvoicePreview(context, order),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: Text('print_invoice'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final returned = await OrderReturnDialog.show(context, order);
              if (returned == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.assignment_return_rounded, size: 16, color: Color(0xFFF97316)),
            label: const Text(
              'تسجيل مرتجع / استرداد للأصناف',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFF97316)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.5)),
              backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                onPressed: () => OrderShareDialog.show(context, order),
                icon: const Icon(Icons.share_rounded, size: 15),
                label: Text('share_order'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                onPressed: () => OrderInvoicePrinter.printThermalOrderReceipt(order),
                icon: const Icon(Icons.receipt_rounded, size: 15),
                label: const Text('إيصال حراري', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: OutlinedButton.icon(
                onPressed: () => OrderInvoicePrinter.showOrderInvoicePreview(context, order),
                icon: const Icon(Icons.print_outlined, size: 15),
                label: Text('print_invoice'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final returned = await OrderReturnDialog.show(context, order);
            if (returned == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.assignment_return_rounded, size: 16, color: Color(0xFFF97316)),
          label: const Text(
            'تسجيل مرتجع / استرداد للأصناف (Return Items)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFF97316)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.5)),
            backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnAuditBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_return_rounded, size: 18, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              const Text(
                'سجل المرتجعات والاسترداد:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
              ),
              const Spacer(),
              if (order.refundedAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'إجمالي المسترد: ${AppFormatters.formatEGP(order.refundedAmount)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                  ),
                ),
            ],
          ),
          if (order.returnReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'السبب: ${order.returnReason}',
              style: TextStyle(fontSize: 11.5, color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
          ],
          if (order.returnHistory.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...order.returnHistory.map((ret) {
              final items = ret['items'] is List ? ret['items'] as List : [];
              final refund = ret['refundAmount'] ?? 0.0;
              final dateStr = ret['timestamp']?.toString() ?? '';
              final performedBy = ret['performedBy']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عملية إرجاع (${items.length} صنف)${performedBy.isNotEmpty ? " • بواسطة: $performedBy" : ""}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'مسترد: ${AppFormatters.formatEGP((refund as num).toDouble())}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        AppFormatters.formatDateTime(DateTime.tryParse(dateStr) ?? DateTime.now()),
                        style: TextStyle(fontSize: 9.5, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isFree = false, bool isDiscount = false}) {
    Color? color;
    if (isTotal) color = AppColor.primary;
    if (isFree) color = AppColor.success;
    if (isDiscount) color = AppColor.error;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
