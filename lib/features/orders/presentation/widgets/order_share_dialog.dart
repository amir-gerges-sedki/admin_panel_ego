import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../../utils/order_share_helper.dart';

class OrderShareDialog extends StatelessWidget {
  final OrderModel order;

  const OrderShareDialog({
    super.key,
    required this.order,
  });

  static void show(BuildContext context, OrderModel order) {
    UnifiedModalSheet.show(
      context: context,
      title: 'share_order'.tr,
      subtitle: '${'order_number'.trParams({'id': order.id})} • ${order.shippingAddress.name}',
      icon: Icons.share_rounded,
      maxWidth: 560,
      content: OrderShareDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final addr = order.shippingAddress;
    final formattedText = OrderShareHelper.generateCourierSlipText(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Customer & Address Information
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name & Phone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: AppColor.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            addr.name.isNotEmpty ? addr.name : 'customer'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (addr.phoneNumber.isNotEmpty)
                    Text(
                      AppFormatters.formatPhone(addr.phoneNumber),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                ],
              ),
              const Divider(height: 16),

              // Full Address
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
                          '${addr.governorate.isNotEmpty ? addr.governorate : addr.city} • ${addr.street}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                        ),
                        if (addr.building.isNotEmpty || addr.floor.isNotEmpty || addr.apartment.isNotEmpty || addr.landmark.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            addr.formattedFullAddress,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Customer Note if present
              if (order.orderNotes.isNotEmpty) ...[
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.orderNotes,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm + 4),

        // 2. Ordered Items List & Total Amount
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'ordered_items_label'.tr} (${order.items.length})',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),

              // Items
              ...order.items.map((itm) {
                final variations = itm.selectedVariation.isNotEmpty
                    ? ' (${itm.selectedVariation.values.join(', ')})'
                    : '';
                final itemTitle = itm.formattedTitleWithBrand;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${itm.quantity}x $itemTitle$variations',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.formatEGP(itm.totalItemPrice),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),


              const Divider(height: 16),

              // Total Collection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'amount_to_collect'.tr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    AppFormatters.formatEGP(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // 3. Share via WhatsApp Action (Full-width Primary Button)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final launched = await OrderShareHelper.launchWhatsApp(message: formattedText);
              if (context.mounted) {
                HelperFun.showNotificationAlert(
                  title: 'WhatsApp',
                  message: launched
                      ? 'تم فتح الواتساب ونسخ تفاصيل الطلب للحافظة'
                      : 'تم نسخ نص الطلب للحافظة (يمكنك لصقه مباشرة في محادثة الواتساب)',
                  context: context,
                );
              }
            },
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: const Text(
              'WhatsApp',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
              elevation: 0,
            ),
          ),
        ),



        const SizedBox(height: 8),

        // Copy & Maps Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => OrderShareHelper.copyToClipboard(
                  context,
                  formattedText,
                  successMessage: 'order_number'.trParams({'id': order.id}),
                ),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: Text('copy_courier_slip'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => OrderShareHelper.launchGoogleMaps(order.shippingAddress),
              icon: const Icon(Icons.map_outlined, size: 15, color: AppColor.primary),
              label: Text('open_in_google_maps'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
