import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/erp_report_models.dart';

class SalesPerformanceReportTab extends StatelessWidget {
  final List<ProductSalesPerformanceModel> products;

  const SalesPerformanceReportTab({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currency = AppLocalizations.of(context).translate('currency_egp');

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            AppLocalizations.of(context).translate('no_sales_in_period'),
            style: TextStyle(
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
        ),
      );
    }

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('top_products_sales_margins'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${products.length} ${AppLocalizations.of(context).translate('products_sold')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              ),
              columns: [
                DataColumn(label: Text(AppLocalizations.of(context).translate('product_title'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('units_sold'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('total_revenue'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('cogs_cost'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('gross_profit'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('profit_margin'))),
              ],
              rows: products.map((p) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          p.productTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${p.quantitySold}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text('${p.totalRevenue.toStringAsFixed(2)} $currency')),
                    DataCell(Text('${p.totalCogs.toStringAsFixed(2)} $currency')),
                    DataCell(
                      Text(
                        '${p.grossProfit.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.grossProfit >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.profitMargin >= 25
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.profitMargin >= 25
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
