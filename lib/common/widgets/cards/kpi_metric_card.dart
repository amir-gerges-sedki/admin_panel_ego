import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';

/// Luxury Glassmorphic KPI Metric Card
class KpiMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String delta;
  final bool isPositive;
  final IconData icon;
  final Color accentColor;
  final List<double>? sparklineData;

  const KpiMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    this.isPositive = true,
    required this.icon,
    this.accentColor = AppColor.primary,
    this.sparklineData,
  });

  @override
  State<KpiMetricCard> createState() => _KpiMetricCardState();
}

class _KpiMetricCardState extends State<KpiMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final sparkline = widget.sparklineData;
    final hasSparkline = sparkline != null && sparkline.length >= 2;

    double minVal = 0;
    double maxVal = 10;
    if (hasSparkline) {
      minVal = sparkline.reduce((a, b) => a < b ? a : b);
      maxVal = sparkline.reduce((a, b) => a > b ? a : b);
      if (minVal == maxVal) {
        minVal = minVal > 0 ? minVal * 0.5 : 0;
        maxVal = maxVal > 0 ? maxVal * 1.5 : 10;
      } else {
        minVal = minVal * 0.8;
        maxVal = maxVal * 1.2;
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(AppSizes.md + 2),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkCard : AppColor.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.5)
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: _isHovered ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row: Icon + Delta Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 2),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.accentColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: (widget.isPositive ? AppColor.success : AppColor.error).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm + 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: widget.isPositive ? AppColor.success : AppColor.error,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.delta,
                        style: TextStyle(
                          color: widget.isPositive ? AppColor.success : AppColor.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Value & Title
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Mini Sparkline (rendered only if data exists)
            SizedBox(
              height: 36,
              child: hasSparkline
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (sparkline.length - 1).toDouble(),
                        minY: minVal,
                        maxY: maxVal,
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sparkline
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: widget.accentColor,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: widget.accentColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
