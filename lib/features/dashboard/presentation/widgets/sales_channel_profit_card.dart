import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/dashboard_analytics_model.dart';

import '../screens/product_sales_report_screen.dart';

class SalesChannelProfitCard extends StatelessWidget {
  final DashboardAnalyticsModel analytics;

  const SalesChannelProfitCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final online = analytics.onlineMetrics;
    final pos = analytics.posMetrics;
    final combined = analytics.combinedMetrics;

    final double totalRev = combined.revenue > 0 ? combined.revenue : 1.0;
    final double onlineShare = combined.revenue > 0 ? (online.revenue / totalRev) * 100 : 0.0;
    final double posShare = combined.revenue > 0 ? (pos.revenue / totalRev) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title & Period Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppColor.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مقارنة المبيعات وصافي الأرباح (القنوات)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'فصل مبيعات وأرباح تطبيق الأونلاين عن كاشير الفرع مع الإجمالي',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  analytics.periodLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Channel Ratio Progress Bar
          if (combined.revenue > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 4),
                        Text(
                          'تطبيق الأونلاين: ${onlineShare.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 4),
                        Text(
                          'كاشير الفرع: ${posShare.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (onlineShare * 10).toInt().clamp(1, 1000),
                          child: Container(color: const Color(0xFF3B82F6)),
                        ),
                        Expanded(
                          flex: (posShare * 10).toInt().clamp(1, 1000),
                          child: Container(color: const Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
          ],

          // 3-Column Comparative Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              final onlineCard = _buildChannelMetricBox(
                context: context,
                isDark: isDark,
                channelTitle: 'تطبيق الأونلاين (App)',
                channelSubtitle: 'طلبات التوصيل والشحن',
                icon: Icons.phone_android_rounded,
                accentColor: const Color(0xFF3B82F6),
                metrics: online,
                isConsolidated: false,
              );

              final posCard = _buildChannelMetricBox(
                context: context,
                isDark: isDark,
                channelTitle: 'كاشير الفرع (POS)',
                channelSubtitle: 'مبيعات مباشرة بالمتجر',
                icon: Icons.storefront_rounded,
                accentColor: const Color(0xFF8B5CF6),
                metrics: pos,
                isConsolidated: false,
              );

              final consolidatedCard = _buildChannelMetricBox(
                context: context,
                isDark: isDark,
                channelTitle: 'الإجمالي المجمّع (Total)',
                channelSubtitle: 'أونلاين + كاشير الفرع',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFF10B981),
                metrics: combined,
                isConsolidated: true,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: onlineCard),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: posCard),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: consolidatedCard),
                  ],
                );
              }

              return Column(
                children: [
                  onlineCard,
                  const SizedBox(height: AppSizes.md),
                  posCard,
                  const SizedBox(height: AppSizes.md),
                  consolidatedCard,
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.md),

          // Action Banner: View Itemized Product Sales Breakdown
          InkWell(
            onTap: () => ProductSalesReportScreen.show(context, analytics),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColor.primary.withValues(alpha: 0.22),
                          const Color(0xFF1E1B4B).withValues(alpha: 0.4),
                        ]
                      : [
                          AppColor.primary.withValues(alpha: 0.1),
                          Colors.purple.withValues(alpha: 0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: AppColor.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppColor.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'عرض تفاصيل مبيعات المنتجات والأصناف',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${analytics.productSales.length} منتج مباع',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'عرض كميات كل صنف مباع في التطبيق والفرع، التكلفة، وصافي الربح لكل منتج',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColor.primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelMetricBox({
    required BuildContext context,
    required bool isDark,
    required String channelTitle,
    required String channelSubtitle,
    required IconData icon,
    required Color accentColor,
    required ChannelFinancialMetrics metrics,
    required bool isConsolidated,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isConsolidated ? accentColor.withValues(alpha: 0.5) : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: isConsolidated ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Channel Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channelTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    Text(
                      channelSubtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${metrics.count} عملية',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: accentColor),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Total Revenue
          _buildRowItem(
            isDark: isDark,
            label: 'إجمالي المبيعات:',
            value: AppFormatters.formatEGP(metrics.revenue),
            isBold: true,
            valueColor: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            fontSize: 14,
          ),
          const SizedBox(height: 6),

          // Cost of Goods Sold (COGS)
          _buildRowItem(
            isDark: isDark,
            label: 'تكلفة البضاعة (COGS):',
            value: AppFormatters.formatEGP(metrics.cost),
            valueColor: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            fontSize: 11.5,
          ),
          const SizedBox(height: 8),

          // Net Profit & Profit Margin Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (metrics.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (metrics.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'صافي المكسب (Net Profit):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      AppFormatters.formatEGP(metrics.netProfit),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: metrics.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (metrics.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${metrics.profitMargin.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Average Ticket Value
          _buildRowItem(
            isDark: isDark,
            label: 'متوسط العملية:',
            value: AppFormatters.formatEGP(metrics.averageTicket),
            valueColor: accentColor,
            fontSize: 11,
          ),

          if (metrics.refundedAmount > 0) ...[
            const SizedBox(height: 6),
            _buildRowItem(
              isDark: isDark,
              label: 'مرتجعات ومبالغ مستردة (${metrics.returnedCount}):',
              value: '-${AppFormatters.formatEGP(metrics.refundedAmount)}',
              valueColor: const Color(0xFFF97316),
              fontSize: 11,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required bool isDark,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 12,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
