import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';

/// Settings card for general delivery and shipping rules
class DeliverySettingsCard extends StatelessWidget {
  final TextEditingController deliveryFeeController;
  final TextEditingController thresholdController;
  final TextEditingController deliveryTimeController;
  final bool isDark;

  const DeliverySettingsCard({
    super.key,
    required this.deliveryFeeController,
    required this.thresholdController,
    required this.deliveryTimeController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shipping_delivery_title'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'shipping_delivery_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: deliveryFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'flat_delivery_fee'.tr,
                    hintText: 'flat_delivery_fee_hint'.tr,
                    helperText: 'flat_delivery_fee_help'.tr,
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (double.tryParse(v) == null) {
                      return 'invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'free_shipping_threshold'.tr,
                    hintText: 'free_shipping_threshold_hint'.tr,
                    helperText: 'free_shipping_threshold_help'.tr,
                    helperMaxLines: 2,
                    prefixIcon:
                        const Icon(Icons.card_giftcard_outlined, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (double.tryParse(v) == null) {
                      return 'invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: deliveryTimeController,
            decoration: InputDecoration(
              labelText: 'estimated_delivery_time'.tr,
              hintText: 'estimated_delivery_time_hint'.tr,
              helperText: 'estimated_delivery_time_help'.tr,
              prefixIcon: const Icon(Icons.access_time_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
