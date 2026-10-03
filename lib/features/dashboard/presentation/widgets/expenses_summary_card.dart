import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/widgets/expense_form_dialog.dart';
import '../../data/models/dashboard_analytics_model.dart';

/// Operational Expenses (OpEx) Dashboard Card
class ExpensesSummaryCard extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final ValueChanged<int>? onNavigateTab;

  const ExpensesSummaryCard({
    super.key,
    required this.analytics,
    this.onNavigateTab,
  });

  String _getCategoryDisplayName(String key) {
    if (key.isEmpty) return '—';
    final cat = ExpenseCategory.fromString(key);
    if (cat != ExpenseCategory.other || key == 'other' || key == 'expense_cat_other') {
      return cat.labelKey.tr;
    }
    return key.tr.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final totalExpenses = analytics.totalExpenses;
    final count = analytics.periodExpensesCount;
    final topCategoryKey = analytics.topExpenseCategory;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          width: 1.0,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
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
                    Icons.receipt_long_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'expenses_dashboard_title'.tr,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'metric_expenses_count_subtitle'.trParams({'count': count.toString()}),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'expenses_dashboard_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: Text(
                    'add_expense_quick_btn'.tr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => ExpenseFormDialog.show(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Metrics
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm + 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'metric_total_expenses_title'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatEGP(totalExpenses),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm + 4),
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
                        Text(
                          'metric_top_expense_cat'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCategoryDisplayName(topCategoryKey),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer Link to Expenses Screen (Tab 6 in Shell)
          if (onNavigateTab != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
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
                  Text(
                    'expenses_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  InkWell(
                    onTap: () => onNavigateTab!(6), // Tab 6 is Expenses in Shell
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'manage_expenses_hub_btn'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
