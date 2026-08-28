import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/dashboard_analytics_model.dart';

class RevenueLineChart extends StatelessWidget {
  final List<RevenuePoint> weeklyTrend;

  const RevenueLineChart({super.key, required this.weeklyTrend});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final maxRevenue = weeklyTrend.isEmpty
        ? 1000.0
        : weeklyTrend.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final maxY = maxRevenue > 0 ? (maxRevenue * 1.25) : 1000.0;
    final hasData = weeklyTrend.any((p) => p.revenue > 0);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue & Sales Trajectory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Weekly revenue performance in Egyptian Pounds (EGP)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Text(
                  'Last 7 Days',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 40,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'No revenue history for the last 7 days yet',
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
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (val, meta) => Text(
                          val >= 1000 ? '${(val / 1000).toInt()}k' : '${val.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < weeklyTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                weeklyTrend[idx].label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (weeklyTrend.length - 1).clamp(0, 9999).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final point = weeklyTrend[s.spotIndex];
                        return LineTooltipItem(
                          '${point.label}\n${AppFormatters.formatEGP(point.revenue)}\n${point.ordersCount} Orders',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyTrend
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColor.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColor.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColor.primary.withValues(alpha: 0.28),
                            AppColor.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
