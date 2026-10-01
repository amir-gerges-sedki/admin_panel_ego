import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/profit_loss_model.dart';

class ProfitLossStatementView extends StatelessWidget {
  final ProfitLossModel profitLoss;

  const ProfitLossStatementView({super.key, required this.profitLoss});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currency = AppLocalizations.of(context).translate('currency_egp');

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).translate('income_statement_pnl'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: profitLoss.netProfit >= 0
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${AppLocalizations.of(context).translate('net_margin')}: ${profitLoss.netProfitMargin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: profitLoss.netProfit >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Revenue Breakdown
          _buildSectionHeader(context, AppLocalizations.of(context).translate('sales_revenue'), isDark),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('gross_sales'),
            amount: profitLoss.grossSales,
            currency: currency,
            isDark: isDark,
          ),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('discounts_deductions'),
            amount: -profitLoss.discountsGiven,
            currency: currency,
            isDark: isDark,
            isNegative: true,
          ),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('net_sales_revenue'),
            amount: profitLoss.netRevenue,
            currency: currency,
            isDark: isDark,
            isBold: true,
            color: AppColor.primary,
          ),
          const Divider(height: 24),

          // 2. Cost of Goods Sold (COGS)
          _buildSectionHeader(context, AppLocalizations.of(context).translate('cogs_title'), isDark),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('cogs_purchased_cost'),
            amount: -profitLoss.totalCogs,
            currency: currency,
            isDark: isDark,
            isNegative: true,
          ),
          _buildRow(
            context,
            label: '${AppLocalizations.of(context).translate('gross_profit')} (${profitLoss.grossProfitMargin.toStringAsFixed(1)}%)',
            amount: profitLoss.grossProfit,
            currency: currency,
            isDark: isDark,
            isBold: true,
            color: const Color(0xFF10B981),
          ),
          const Divider(height: 24),

          // 3. Operating Expenses & Overheads
          _buildSectionHeader(context, AppLocalizations.of(context).translate('operating_overheads'), isDark),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('operating_expenses'),
            amount: -profitLoss.operatingExpenses,
            currency: currency,
            isDark: isDark,
            isNegative: true,
          ),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('employee_salaries_payroll'),
            amount: -profitLoss.payrollExpenses,
            currency: currency,
            isDark: isDark,
            isNegative: true,
          ),
          _buildRow(
            context,
            label: AppLocalizations.of(context).translate('damaged_inventory_losses'),
            amount: -profitLoss.damagedStockLoss,
            currency: currency,
            isDark: isDark,
            isNegative: true,
          ),
          const Divider(height: 24),

          // 4. Net Profit (Bottom Line)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profitLoss.netProfit >= 0
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: profitLoss.netProfit >= 0
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('net_operating_profit'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profitLoss.totalOrders} ${AppLocalizations.of(context).translate('orders_completed')} • ${profitLoss.totalItemsSold} ${AppLocalizations.of(context).translate('items_sold')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${profitLoss.netProfit >= 0 ? '+' : ''}${profitLoss.netProfit.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: profitLoss.netProfit >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required double amount,
    required String currency,
    required bool isDark,
    bool isBold = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ??
                  (isNegative
                      ? const Color(0xFFEF4444)
                      : (isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight)),
            ),
          ),
        ],
      ),
    );
  }
}
