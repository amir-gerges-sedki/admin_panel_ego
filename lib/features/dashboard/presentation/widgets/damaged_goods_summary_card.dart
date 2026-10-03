import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../damaged_stock/data/models/damaged_stock_model.dart';
import '../../../damaged_stock/presentation/widgets/damaged_stock_form_dialog.dart';
import '../../data/models/dashboard_analytics_model.dart';

/// Damaged Goods & Inventory Waste Dashboard Card
class DamagedGoodsSummaryCard extends StatelessWidget {
  final DashboardAnalyticsModel analytics;
  final ValueChanged<int>? onNavigateTab;

  const DamagedGoodsSummaryCard({
    super.key,
    required this.analytics,
    this.onNavigateTab,
  });

  String _getReasonDisplayName(String key) {
    if (key.isEmpty) return '—';
    final rsn = DamagedReason.fromString(key);
    if (rsn != DamagedReason.other || key == 'other' || key == 'damage_reason_other') {
      return rsn.labelKey.tr;
    }
    return key.tr.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final totalLoss = analytics.totalDamagedLoss;
    final unitsCount = analytics.periodDamagedUnitsCount;
    final topReasonKey = analytics.topDamageReason;

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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Color(0xFFEF4444),
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
                              'damaged_goods_dashboard_title'.tr,
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
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'metric_damaged_units_subtitle'.trParams({'count': unitsCount.toString()}),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'damaged_goods_dashboard_subtitle'.tr,
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
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: Text(
                    'log_damage_quick_btn'.tr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => DamagedStockFormDialog.show(context),
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
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'metric_damaged_loss_title'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatEGP(totalLoss),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
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
                          'metric_top_damage_reason'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getReasonDisplayName(topReasonKey),
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

          // Footer Link to Damaged Goods Screen (Tab 7 in Shell)
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
                    'damaged_stock_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  InkWell(
                    onTap: () => onNavigateTab!(7), // Tab 7 is Damaged Stock in Shell
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'manage_damaged_hub_btn'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
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
