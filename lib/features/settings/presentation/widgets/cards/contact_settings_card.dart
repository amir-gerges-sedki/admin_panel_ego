import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';

/// Settings card for store contact and support info
class ContactSettingsCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController whatsController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final bool isDark;

  const ContactSettingsCard({
    super.key,
    required this.phoneController,
    required this.whatsController,
    required this.emailController,
    required this.addressController,
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
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'contact_support_title'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'contact_support_subtitle'.tr,
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
          TextFormField(
            controller: whatsController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'whatsapp_number'.tr,
              hintText: 'whatsapp_number_hint'.tr,
              prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'required_field'.tr : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'store_phone'.tr,
              hintText: 'store_phone_hint'.tr,
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'required_field'.tr : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'support_email'.tr,
              hintText: 'support_email_hint'.tr,
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'store_address'.tr,
              hintText: 'store_address_hint'.tr,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
