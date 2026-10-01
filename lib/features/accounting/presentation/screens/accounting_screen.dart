import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/accounting_cubit.dart';
import '../cubit/accounting_state.dart';
import '../widgets/profit_loss_statement_view.dart';
import '../widgets/record_cash_transaction_dialog.dart';
import '../widgets/treasury_balance_cards.dart';
import '../widgets/treasury_transactions_table.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AccountingCubit>().loadAccountingData();
  }

  void _openAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountingCubit>(),
        child: const RecordCashTransactionDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AccountingCubit, AccountingState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadAccountingData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector Bar
                  _buildPeriodFilterBar(context, state, isDark),
                  const SizedBox(height: 20),

                  if (state.status == AccountingStatus.loading &&
                      state.treasurySummary.totalLiquidAssets == 0)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // 1. Treasury & Safe Balances Cards
                    TreasuryBalanceCards(
                      summary: state.treasurySummary,
                      onAddTransaction: _openAddTransactionDialog,
                    ),
                    const SizedBox(height: 24),

                    // 2. Main Columns (P&L and Movements)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 1000) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: ProfitLossStatementView(
                                  profitLoss: state.profitLoss,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 4,
                                child: TreasuryTransactionsTable(
                                  transactions: state.transactions,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              ProfitLossStatementView(profitLoss: state.profitLoss),
                              const SizedBox(height: 20),
                              TreasuryTransactionsTable(
                                transactions: state.transactions,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilterBar(
    BuildContext context,
    AccountingState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('financial_period'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              AccountingPeriod.today,
              AccountingPeriod.thisWeek,
              AccountingPeriod.thisMonth,
              AccountingPeriod.lastMonth,
              AccountingPeriod.thisYear,
            ].map((period) {
              final isSelected = state.selectedPeriod == period;
              return ChoiceChip(
                label: Text(
                  AppLocalizations.of(context).isArabic
                      ? period.arabicLabel
                      : period.englishLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColor.primary,
                backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                onSelected: (selected) {
                  if (selected) {
                    context.read<AccountingCubit>().loadAccountingData(period: period);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
