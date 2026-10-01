import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/erp_report_models.dart';

class InventoryValuationReportTab extends StatelessWidget {
  final InventoryValuationModel valuation;

  const InventoryValuationReportTab({super.key, required this.valuation});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currency = AppLocalizations.of(context).translate('currency_egp');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 900 ? 3 : 1;
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: constraints.maxWidth > 900 ? 2.2 : 2.5,
              children: [
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('inventory_cost_value'),
                  value: '${valuation.totalCostValue.toStringAsFixed(2)} $currency',
                  subtitle: '${valuation.totalUnitsInStock} ${AppLocalizations.of(context).translate('units_in_stock')}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('inventory_retail_value'),
                  value: '${valuation.totalRetailValue.toStringAsFixed(2)} $currency',
                  subtitle: '${valuation.totalSkusCount} ${AppLocalizations.of(context).translate('unique_variations')}',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('potential_gross_profit'),
                  value: '${valuation.potentialGrossProfit.toStringAsFixed(2)} $currency',
                  subtitle: '${AppLocalizations.of(context).translate('potential_margin')}: ${valuation.potentialMargin.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  isHighlight: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Stock Health Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : AppColor.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('stock_health_distribution'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHealthIndicator(
                      context,
                      label: AppLocalizations.of(context).translate('in_stock_healthy'),
                      count: (valuation.totalProductsCount -
                              valuation.lowStockCount -
                              valuation.outOfStockCount)
                          .clamp(0, 99999),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHealthIndicator(
                      context,
                      label: AppLocalizations.of(context).translate('low_stock_warning'),
                      count: valuation.lowStockCount,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHealthIndicator(
                      context,
                      label: AppLocalizations.of(context).translate('out_of_stock_critical'),
                      count: valuation.outOfStockCount,
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.5)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColor.textPrimaryDark
                        : AppColor.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColor.textMutedDark
                      : AppColor.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
