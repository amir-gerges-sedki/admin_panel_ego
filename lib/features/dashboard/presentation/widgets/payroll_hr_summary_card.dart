import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../employees/presentation/widgets/disburse_payroll_dialog.dart';
import '../../../employees/presentation/widgets/salary_advance_form_dialog.dart';
import '../../data/models/dashboard_analytics_model.dart';

/// Comprehensive HR, Employees & Payroll Dashboard Card
class PayrollHrSummaryCard extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final ValueChanged<int>? onNavigateTab;

  const PayrollHrSummaryCard({
    super.key,
    required this.analytics,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final activeCount = analytics.activeEmployeesCount;
    final salariesPool = analytics.monthlySalariesPool;
    final advancesTotal = analytics.periodAdvancesTotal;
    final paidSalariesTotal = analytics.periodPaidSalariesTotal;

    final double payrollExecutionRate = salariesPool > 0
        ? ((paidSalariesTotal / salariesPool) * 100).clamp(0.0, 100.0)
        : (paidSalariesTotal > 0 ? 100.0 : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.md + 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: Color(0xFF6366F1),
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
                            'payroll_hr_dashboard_title'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'staff_members_count'.trParams({'count': activeCount.toString()}),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'payroll_hr_dashboard_subtitle'.tr,
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
                      icon: const Icon(Icons.price_change_outlined, size: 15),
                      label: Text(
                        'disburse_advance_quick_btn'.tr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => SalaryAdvanceFormDialog.show(context),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 15),
                      label: Text(
                        'issue_payroll_quick_btn'.tr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => DisbursePayrollDialog.show(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 4 Metric Boxes
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final staffBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'kpi_active_staff_title'.tr,
                  value: '$activeCount',
                  subtitle: 'active_employee'.tr,
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFF3B82F6),
                );

                final poolBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'kpi_base_salaries_pool_title'.tr,
                  value: AppFormatters.formatEGP(salariesPool),
                  subtitle: 'base_monthly_salary'.tr,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                );

                final advancesBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'kpi_advances_period_title'.tr,
                  value: AppFormatters.formatEGP(advancesTotal),
                  subtitle: 'tab_salary_advances'.tr,
                  icon: Icons.price_change_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  isAlert: advancesTotal > 0,
                );

                final paidBox = _buildMetricBox(
                  isDark: isDark,
                  title: 'kpi_paid_payroll_period_title'.tr,
                  value: AppFormatters.formatEGP(paidSalariesTotal),
                  subtitle: 'tab_payroll_history'.tr,
                  icon: Icons.check_circle_rounded,
                  accentColor: const Color(0xFF10B981),
                );

                if (width >= 900) {
                  return Row(
                    children: [
                      Expanded(child: staffBox),
                      const SizedBox(width: 10),
                      Expanded(child: poolBox),
                      const SizedBox(width: 10),
                      Expanded(child: advancesBox),
                      const SizedBox(width: 10),
                      Expanded(child: paidBox),
                    ],
                  );
                } else if (width >= 550) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: staffBox),
                          const SizedBox(width: 10),
                          Expanded(child: poolBox),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: advancesBox),
                          const SizedBox(width: 10),
                          Expanded(child: paidBox),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      staffBox,
                      const SizedBox(height: 10),
                      poolBox,
                      const SizedBox(height: 10),
                      advancesBox,
                      const SizedBox(height: 10),
                      paidBox,
                    ],
                  );
                }
              },
            ),
          ),

          // Payroll Disbursement Progress Bar
          if (salariesPool > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'payroll_execution_ratio'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      Text(
                        'payroll_execution_summary'.trParams({
                          'paid': AppFormatters.formatCompactEGP(paidSalariesTotal),
                          'pool': AppFormatters.formatCompactEGP(salariesPool),
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
                            flex: (payrollExecutionRate * 10).round().clamp(0, 1000),
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          if (payrollExecutionRate < 100.0)
                            Expanded(
                              flex: ((100.0 - payrollExecutionRate) * 10).round().clamp(1, 1000),
                              child: Container(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Footer Link to Full Employees Tab (Index 8 in Shell)
          if (onNavigateTab != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.cardRadiusLg - 1),
                  bottomRight: Radius.circular(AppSizes.cardRadiusLg - 1),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 15,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'employees_management_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => onNavigateTab!(8), // Tab 8 is Employees Screen in Shell
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'manage_employees_hub_btn'.tr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
                    fontSize: 17,
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
