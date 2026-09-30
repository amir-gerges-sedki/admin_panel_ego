import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/dashboard_analytics_model.dart';

class BrandShareDonutChart extends StatelessWidget {
  final List<BrandShareData> brandShares;

  const BrandShareDonutChart({super.key, required this.brandShares});

  static const List<Color> _palette = [
    AppColor.primary,
    AppColor.secondary,
    AppColor.statusProcessing,
    AppColor.statusShipped,
    AppColor.statusPending,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'brand_share_title'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'brand_share_subtitle'.tr,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          if (brandShares.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 40,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'no_brand_distribution_data'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: brandShares.asMap().entries.map((e) {
                          final color = _palette[e.key % _palette.length];
                          return PieChartSectionData(
                            color: color,
                            value: e.value.sharePercentage,
                            title: '${e.value.sharePercentage.toInt()}%',
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: brandShares.asMap().entries.map((e) {
                      final color = _palette[e.key % _palette.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.brandName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                ),
                              ),
                            ),
                            Text(
                              '${e.value.sharePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
