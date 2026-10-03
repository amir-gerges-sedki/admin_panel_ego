import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';

import '../../../../common/widgets/apps_launcher/apps_launcher_dialog.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback? onExportPressed;
  final ValueChanged<int>? onNavigateTab;

  const DashboardHeader({
    super.key,
    this.onExportPressed,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'executive_overview'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        if (onNavigateTab != null) ...[
          FilledButton.icon(
            onPressed: () => AppsLauncherDialog.show(
              context,
              currentTabIndex: 0,
              onSelectTab: onNavigateTab!,
            ),
            icon: const Icon(Icons.apps_rounded, size: 16),
            label: Text('apps_launcher_title'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSizes.xs + 2),
        ],
        OutlinedButton.icon(
          onPressed: onExportPressed ??
              () {
                HelperFun.successSnackbar(
                  'export_csv'.tr,
                  'export_download_success'.tr.replaceAll('{name}', 'executive_summary_file'.tr),
                );
              },
          icon: const Icon(Icons.download_rounded, size: 15),
          label: Text('export_csv'.tr),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            side: BorderSide(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
