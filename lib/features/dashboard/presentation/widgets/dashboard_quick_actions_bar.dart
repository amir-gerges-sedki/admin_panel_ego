import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../common/widgets/apps_launcher/apps_launcher_dialog.dart';
import '../../../expenses/presentation/widgets/expense_form_dialog.dart';
import '../../../inventory_audit/presentation/widgets/physical_stock_audit_dialog.dart';
import '../../../products/presentation/widgets/product_creation_wizard.dart';
import '../../../suppliers/presentation/widgets/create_purchase_invoice_dialog.dart';

/// Compact one-click quick actions bar — inline chips for common tasks
class DashboardQuickActionsBar extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardQuickActionsBar({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final actions = [
      _QuickActionData(
        titleKey: 'apps_launcher_title',
        icon: Icons.apps_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () {
          if (onNavigateTab != null) {
            AppsLauncherDialog.show(
              context,
              currentTabIndex: 0,
              onSelectTab: onNavigateTab!,
            );
          }
        },
      ),
      _QuickActionData(
        titleKey: 'quick_action_pos',
        icon: Icons.point_of_sale_rounded,
        color: const Color(0xFF10B981),
        onTap: () => onNavigateTab?.call(1), // POS
      ),
      _QuickActionData(
        titleKey: 'quick_action_add_product',
        icon: Icons.add_box_rounded,
        color: AppColor.primary,
        onTap: () => ProductCreationWizard.show(context),
      ),
      _QuickActionData(
        titleKey: 'quick_action_new_po',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF06B6D4),
        onTap: () => CreatePurchaseInvoiceDialog.show(context),
      ),
      _QuickActionData(
        titleKey: 'quick_action_add_expense',
        icon: Icons.money_off_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => ExpenseFormDialog.show(context),
      ),
      _QuickActionData(
        titleKey: 'quick_action_stock_audit',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => PhysicalStockAuditDialog.show(context),
      ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: actions.map((act) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: act.onTap,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: act.color.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(act.icon, size: 14, color: act.color),
                  const SizedBox(width: 5),
                  Text(
                    act.titleKey.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: act.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionData {
  final String titleKey;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.titleKey,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
