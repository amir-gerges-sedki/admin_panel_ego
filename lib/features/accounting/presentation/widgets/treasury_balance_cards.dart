import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/treasury_summary_model.dart';

class TreasuryBalanceCards extends StatelessWidget {
  final TreasurySummaryModel summary;
  final VoidCallback onAddTransaction;

  const TreasuryBalanceCards({
    super.key,
    required this.summary,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 700 ? 2 : 1);

        return Column(
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
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColor.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).translate('treasury_safe_balances'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    AppLocalizations.of(context).translate('record_cash_flow'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: constraints.maxWidth > 1200 ? 1.65 : 1.85,
              children: [
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('cash_drawer_safe'),
                  amount: summary.cashBalance,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981), // Emerald
                  subtitle: AppLocalizations.of(context).translate('cash_in_drawer_note'),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('pos_card_bank'),
                  amount: summary.cardBalance,
                  icon: Icons.credit_card_rounded,
                  color: const Color(0xFF3B82F6), // Blue
                  subtitle: AppLocalizations.of(context).translate('visa_mastercard_note'),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('instapay_account'),
                  amount: summary.instapayBalance,
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFF8B5CF6), // Purple
                  subtitle: AppLocalizations.of(context).translate('instapay_transfers_note'),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('vodafone_cash_wallets'),
                  amount: summary.vodafoneCashBalance,
                  icon: Icons.phone_android_rounded,
                  color: const Color(0xFFEF4444), // Red
                  subtitle: AppLocalizations.of(context).translate('mobile_wallets_note'),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('total_liquid_capital'),
                  amount: summary.totalLiquidAssets,
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF0EA5E9), // Sky
                  subtitle: AppLocalizations.of(context).translate('all_channels_sum'),
                  isDark: isDark,
                  isHighlight: true,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('inventory_cost_value'),
                  amount: summary.inventoryCostValue,
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFFF59E0B), // Amber
                  subtitle: AppLocalizations.of(context).translate('stock_at_cost_price'),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('supplier_payables_debt'),
                  amount: summary.supplierPayables,
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFF43F5E), // Rose
                  subtitle: AppLocalizations.of(context).translate('unpaid_invoices_balance'),
                  isDark: isDark,
                  isWarning: summary.supplierPayables > 0,
                ),
                _buildCard(
                  context,
                  title: AppLocalizations.of(context).translate('net_working_capital'),
                  amount: summary.netWorkingCapital,
                  icon: Icons.trending_up_rounded,
                  color: summary.netWorkingCapital >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  subtitle: AppLocalizations.of(context).translate('liquid_plus_inventory_minus_debt'),
                  isDark: isDark,
                  isHighlight: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
    bool isHighlight = false,
    bool isWarning = false,
  }) {
    final currency = AppLocalizations.of(context).translate('currency_egp');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? color.withValues(alpha: 0.5)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: isHighlight ? 1.5 : 1.0,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  '${amount.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isWarning
                        ? const Color(0xFFEF4444)
                        : (isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
