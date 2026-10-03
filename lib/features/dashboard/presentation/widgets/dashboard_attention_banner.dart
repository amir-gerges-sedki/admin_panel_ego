import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../inventory_audit/presentation/widgets/physical_stock_audit_dialog.dart';
import '../../data/models/dashboard_analytics_model.dart';

/// Compact notification strip for actionable operational alerts
class DashboardAttentionBanner extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final int pendingOrdersCount;
  final ValueChanged<int>? onNavigateTab;

  const DashboardAttentionBanner({
    super.key,
    required this.analytics,
    required this.pendingOrdersCount,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final hasLowStock = analytics.lowStockAlertsCount > 0;
    final hasPendingOrders = pendingOrdersCount > 0;
    final hasSupplierDue = analytics.totalSupplierBalanceDue > 0;

    final hasAnyAttention = hasLowStock || hasPendingOrders || hasSupplierDue;

    if (!hasAnyAttention) {
      // Clean state — minimal success indicator
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColor.success.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'attention_all_clear_msg'.tr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.success.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    }

    // Compact inline alert chips
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (hasLowStock)
          _buildAlertChip(
            context,
            icon: Icons.warning_amber_rounded,
            color: AppColor.warning,
            text: 'attention_low_stock_msg'.trParams({
              'count': analytics.lowStockAlertsCount.toString(),
            }),
            onTap: () => PhysicalStockAuditDialog.show(context),
            isDark: isDark,
          ),
        if (hasPendingOrders)
          _buildAlertChip(
            context,
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF3B82F6),
            text: 'attention_pending_orders_msg'.trParams({
              'count': pendingOrdersCount.toString(),
            }),
            onTap: () => onNavigateTab?.call(4),
            isDark: isDark,
          ),
        if (hasSupplierDue)
          _buildAlertChip(
            context,
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFFEF4444),
            text: 'attention_supplier_due_msg'.trParams({
              'amount': AppFormatters.formatCompactEGP(analytics.totalSupplierBalanceDue),
            }),
            onTap: () => onNavigateTab?.call(5),
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildAlertChip(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
