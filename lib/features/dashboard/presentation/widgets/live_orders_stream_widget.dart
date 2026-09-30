import 'package:flutter/material.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';

class LiveOrdersStreamWidget extends StatelessWidget {
  final List<OrderModel> recentOrders;
  final ValueChanged<OrderModel>? onOrderTapped;

  const LiveOrdersStreamWidget({
    super.key,
    required this.recentOrders,
    this.onOrderTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColor.statusDelivered,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'live_orders_feed_title'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Text(
                  'real_time_stream_badge'.tr,
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentOrders.take(5).length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, i) {
              final order = recentOrders[i];
              return InkWell(
                onTap: () => onOrderTapped?.call(order),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColor.primary, size: 20),
                      ),
                      const SizedBox(width: AppSizes.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  order.id,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '• ${order.shippingAddress.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'order_items_summary'.trParams({
                                'count': '${order.items.length}',
                                'method': order.displayPaymentMethod,
                                'city': order.shippingAddress.city,
                              }),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatEGP(order.totalAmount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusChip.fromOrderStatus(order.status),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
