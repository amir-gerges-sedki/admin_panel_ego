import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback? onExportPressed;

  const DashboardHeader({super.key, this.onExportPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'executive_overview'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'executive_overview_sub'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.md),
        ElevatedButton.icon(
          onPressed: onExportPressed ??
              () {
                HelperFun.successSnackbar(
                  'export_csv'.tr,
                  'export_download_success'.tr.replaceAll('{name}', 'executive_summary_file'.tr),
                );
              },
          icon: const Icon(Icons.download_rounded, size: 16),
          label: Text('export_csv'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
          ),
        ),
      ],
    );
  }
}
