import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../suppliers/data/models/supplier_model.dart';
import '../../../suppliers/presentation/cubit/supplier_cubit.dart';
import '../../../suppliers/presentation/cubit/supplier_state.dart';
import '../../../suppliers/presentation/widgets/create_purchase_invoice_dialog.dart';
import '../../../suppliers/presentation/widgets/record_payment_dialog.dart';
import '../../data/models/dashboard_analytics_model.dart';

/// Comprehensive Supplier Financials & Accounts Payable Dashboard Card
class SupplierFinancialsCard extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final ValueChanged<int>? onNavigateTab;

  const SupplierFinancialsCard({
    super.key,
    required this.analytics,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final totalPurchases = analytics.totalSupplierPurchases;
    final totalPaid = analytics.totalSupplierPaid;
    final totalDue = analytics.totalSupplierBalanceDue;
    final hasDue = totalDue > 0;
    final topDueList = analytics.topSuppliersDue;

    final double paidPercentage = totalPurchases > 0
        ? ((totalPaid / totalPurchases) * 100).clamp(0.0, 100.0)
        : (totalDue == 0 ? 100.0 : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: hasDue
              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.25)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasDue
                ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSizes.md + 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'supplier_financials_title'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasDue
                                  ? AppColor.error.withValues(alpha: 0.12)
                                  : AppColor.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hasDue
                                  ? 'payables_due_badge'.tr
                                  : 'all_settled_badge'.tr,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: hasDue ? AppColor.error : AppColor.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'supplier_financials_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Header Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 15),
                      label: Text(
                        'new_invoice_btn'.tr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => CreatePurchaseInvoiceDialog.show(context),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.payment_rounded, size: 15),
                      label: Text(
                        'pay_supplier_btn'.tr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => RecordPaymentDialog.show(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Core Financial Metrics Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                final payablesBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'metric_accounts_payable_title'.tr,
                  value: AppFormatters.formatEGP(totalDue),
                  subtitle: 'metric_accounts_payable_subtitle'.tr,
                  icon: Icons.money_off_csred_rounded,
                  accentColor: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  isAlert: hasDue,
                );

                final purchasesBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'metric_total_purchases_title'.tr,
                  value: AppFormatters.formatEGP(totalPurchases),
                  subtitle: 'metric_active_suppliers_count'.trParams({
                    'count': analytics.activeSuppliersCount.toString(),
                  }),
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                );

                final paidBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'metric_total_disbursed_title'.tr,
                  value: AppFormatters.formatEGP(totalPaid),
                  subtitle: 'metric_settlement_rate'.trParams({
                    'rate': paidPercentage.toStringAsFixed(1),
                  }),
                  icon: Icons.check_circle_outline_rounded,
                  accentColor: const Color(0xFF10B981),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 4, child: payablesBox),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: purchasesBox),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: paidBox),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      payablesBox,
                      const SizedBox(height: 10),
                      purchasesBox,
                      const SizedBox(height: 10),
                      paidBox,
                    ],
                  );
                }
              },
            ),
          ),

          // Settlement Progress Bar
          if (totalPurchases > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'inflow_settlement_ratio'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      Text(
                        'settlement_progress_summary'.trParams({
                          'rate': paidPercentage.toStringAsFixed(1),
                          'remaining': AppFormatters.formatCompactEGP(totalDue),
                        }),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (paidPercentage * 10).round().clamp(0, 1000),
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          if (hasDue)
                            Expanded(
                              flex: ((100.0 - paidPercentage) * 10).round().clamp(1, 1000),
                              child: Container(color: const Color(0xFFEF4444)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Top Vendors with Outstanding Balance
          if (topDueList.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.sm + 4),
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'top_due_suppliers'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (onNavigateTab != null)
                        InkWell(
                          onTap: () => onNavigateTab!(4), // Tab 4 is Suppliers Screen in Shell
                          child: Text(
                            'view_full_directory'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topDueList.map((sup) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_rounded, size: 14, color: AppColor.primary),
                            const SizedBox(width: 6),
                            Text(
                              sup.name,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppFormatters.formatEGP(sup.balanceDue),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _openPaymentForSupplier(context, sup.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'pay_btn_short'.tr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'all_suppliers_settled'.tr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openPaymentForSupplier(BuildContext context, String supplierId) {
    final supState = context.read<SupplierCubit>().state;
    SupplierModel? target;
    if (supState is SupplierLoaded) {
      target = supState.suppliers.where((s) => s.id == supplierId).firstOrNull;
    }
    RecordPaymentDialog.show(context, initialSupplier: target);
  }

  Widget _buildMetricBox({
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: isAlert
            ? accentColor.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(
          color: isAlert
              ? accentColor.withValues(alpha: 0.35)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: isAlert ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isAlert ? accentColor : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
