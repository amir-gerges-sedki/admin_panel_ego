import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../../utils/order_share_helper.dart';
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
      maxWidth: 720,
      content: OrderDetailsDrawer(order: order, onStatusChanged: onStatusChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Quick Info & Status Header
        _buildStatusHeader(context, isDark),
        const SizedBox(height: AppSizes.md),

        // 2. Customer & Delivery Address Card
        _buildCustomerAndAddressCard(context, isDark),
        const SizedBox(height: AppSizes.md),

        // 3. Customer Special Notes (if any)
        if (order.orderNotes.isNotEmpty) ...[
          _buildCustomerNotesCard(context, isDark),
          const SizedBox(height: AppSizes.md),
        ],

        // 4. Ordered Items Section
        _buildOrderedItemsCard(context, isDark),
        const SizedBox(height: AppSizes.md),

        // 5. Financial Invoice Breakdown
        _buildFinancialBreakdownCard(context, isDark),
        const SizedBox(height: AppSizes.md),

        // 6. Action Toolbar (Print Invoice / Export)
        _buildActionToolbar(context, isDark),
        const SizedBox(height: AppSizes.md),

        // 7. Collapsible Technical Data Inspector (Firestore Payload)
        _buildRawDataInspector(context, isDark),
      ],
    );
  }

  // --- 1. STATUS HEADER & DISPATCHER ---
  Widget _buildStatusHeader(BuildContext context, bool isDark) {
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    '${'current_status'.tr}: ',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  StatusChip.fromOrderStatus(order.status),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: order.id));
                      HelperFun.showNotificationAlert(
                        title: 'copy_order_id'.tr,
                        message: '${'copied_to_clipboard'.tr}: #${order.id}',
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text(
                            '#${order.id}',
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => OrderShareDialog.show(context, order),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.share_rounded, size: 13, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text(
                            'share_order'.tr,
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
                ],
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
          const SizedBox(height: AppSizes.md),
          OrderStatusDispatcher(
            currentStatus: order.status,
            onStatusSelected: (newStatus) {
              onStatusChanged?.call(newStatus);
              Navigator.of(context).pop();
            },
          ),
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
                    Row(
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
                        const SizedBox(width: 10),
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
                                  'share_with_courier'.tr,
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

  // --- 6. ACTION TOOLBAR (SHARE FOR DELIVERY & PRINT INVOICE) ---
  Widget _buildActionToolbar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ElevatedButton.icon(
            onPressed: () => OrderShareDialog.show(context, order),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: Text('share_with_courier'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm + 4),
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            onPressed: () => _showPrintableInvoiceDialog(context),
            icon: const Icon(Icons.print_outlined, size: 16),
            label: Text('print_invoice'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
            ),
          ),
        ),
      ],
    );
  }


  // --- 7. RAW DATA INSPECTOR (COLLAPSIBLE) ---
  Widget _buildRawDataInspector(BuildContext context, bool isDark) {
    if (order.rawDocData.isEmpty) return const SizedBox.shrink();

    final formattedJson = _safeFormatJson(order.rawDocData);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: const Icon(Icons.code_rounded, size: 18, color: AppColor.primary),
        title: Text(
          'raw_data_inspector'.tr,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.sm + 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
            child: SelectableText(
              formattedJson,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFormatJson(Map<String, dynamic> data) {
    try {
      final encoder = JsonEncoder.withIndent('  ', (dynamic item) {
        if (item is Timestamp) {
          return item.toDate().toIso8601String();
        }
        if (item is DateTime) {
          return item.toIso8601String();
        }
        if (item is DocumentReference) {
          return item.path;
        }
        if (item is GeoPoint) {
          return {'latitude': item.latitude, 'longitude': item.longitude};
        }
        return item.toString();
      });
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
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

  void _showPrintableInvoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = HelperFun.isDarkMode(ctx);
        return Dialog(
          backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EGO VAPE STORE',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColor.primary),
                          ),
                          Text('invoice_title'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(AppFormatters.formatDate(order.orderDate), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Customer Summary
                  Text(
                    '${'customer'.tr}: ${order.shippingAddress.name} (${order.shippingAddress.phoneNumber})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${'shipping_address'.tr}: ${order.shippingAddress.formattedFullAddress}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Items Table
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            ),
                            children: const [
                              Padding(padding: EdgeInsets.all(6), child: Text('Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(6), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(6), child: Text('Price', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(6), child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                            ],
                          ),
                          ...order.items.map((itm) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      itm.selectedVariation.isNotEmpty
                                          ? '${itm.title} (${itm.selectedVariation.values.join(', ')})'
                                          : itm.title,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  Padding(padding: const EdgeInsets.all(6), child: Text('${itm.quantity}', style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(AppFormatters.formatEGP(itm.price), style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(AppFormatters.formatEGP(itm.totalItemPrice), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 16),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'payment'.tr}: ${order.paymentMethod}', style: const TextStyle(fontSize: 12)),
                      Text(
                        '${'grand_total'.tr}: ${AppFormatters.formatEGP(order.totalAmount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColor.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('confirm'.tr),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
