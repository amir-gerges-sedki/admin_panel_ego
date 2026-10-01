import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/treasury_transaction_model.dart';
import '../cubit/accounting_cubit.dart';
import 'record_cash_transaction_dialog.dart';

class TreasuryTransactionsTable extends StatelessWidget {
  final List<TreasuryTransactionModel> transactions;

  const TreasuryTransactionsTable({super.key, required this.transactions});

  void _editTransaction(BuildContext context, TreasuryTransactionModel t) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountingCubit>(),
        child: RecordCashTransactionDialog(transaction: t),
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TreasuryTransactionModel t) {
    final loc = AppLocalizations.of(context);
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 22),
            const SizedBox(width: 8),
            Text(
              loc.translate('delete_transaction'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          loc.translate('confirm_delete_treasury_tx'),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<AccountingCubit>().deleteTransaction(t.id);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.translate('transaction_deleted_success')),
                    backgroundColor: AppColor.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currency = AppLocalizations.of(context).translate('currency_egp');

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColor.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).translate('recent_treasury_movements'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('no_transactions_found'),
                  style: TextStyle(
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = transactions[index];
                final isPositive = t.type == TreasuryTransactionType.cashIn ||
                    t.type == TreasuryTransactionType.capitalInjection;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    t.reason.isNotEmpty ? t.reason : t.type.arabicLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    '${AppLocalizations.of(context).isArabic ? t.channel.arabicLabel : t.channel.englishLabel} • ${DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColor.textMutedDark
                          : AppColor.textMutedLight,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isPositive ? '+' : '-'}${t.amount.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        splashRadius: 18,
                        onSelected: (val) {
                          if (val == 'edit') {
                            _editTransaction(context, t);
                          } else if (val == 'delete') {
                            _confirmDeleteTransaction(context, t);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 16),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).translate('edit')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 16, color: AppColor.error),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).translate('delete'),
                                  style: const TextStyle(color: AppColor.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
