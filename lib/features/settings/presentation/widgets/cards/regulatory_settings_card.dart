import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';

/// Settings card for age verification and health warning compliance
class RegulatorySettingsCard extends StatelessWidget {
  final bool enforceAge;
  final bool showWarning;
  final ValueChanged<bool> onEnforceAgeChanged;
  final ValueChanged<bool> onShowWarningChanged;
  final bool isDark;

  const RegulatorySettingsCard({
    super.key,
    required this.enforceAge,
    required this.showWarning,
    required this.onEnforceAgeChanged,
    required this.onShowWarningChanged,
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
                  color: AppColor.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColor.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'regulatory_settings'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'regulatory_subtitle'.tr,
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
          const SizedBox(height: AppSizes.md),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'age_verification'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'age_verification_desc'.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              value: enforceAge,
              activeThumbColor: AppColor.primary,
              onChanged: onEnforceAgeChanged,
            ),
          ),
          const Divider(height: 16),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'nicotine_warning_banner'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'nicotine_warning_banner_desc'.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              value: showWarning,
              activeThumbColor: AppColor.primary,
              onChanged: onShowWarningChanged,
            ),
          ),
        ],
      ),
    );
  }
}
