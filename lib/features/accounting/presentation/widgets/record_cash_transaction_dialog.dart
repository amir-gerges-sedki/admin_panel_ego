import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/treasury_transaction_model.dart';
import '../cubit/accounting_cubit.dart';

class RecordCashTransactionDialog extends StatefulWidget {
  final TreasuryTransactionModel? transaction;

  const RecordCashTransactionDialog({super.key, this.transaction});

  @override
  State<RecordCashTransactionDialog> createState() =>
      _RecordCashTransactionDialogState();
}

class _RecordCashTransactionDialogState
    extends State<RecordCashTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  late final TextEditingController _refController;

  late TreasuryTransactionType _selectedType;
  late PaymentChannelType _selectedChannel;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toStringAsFixed(2) : '',
    );
    _reasonController = TextEditingController(text: t?.reason ?? '');
    _refController = TextEditingController(text: t?.referenceNumber ?? '');
    _selectedType = t?.type ?? TreasuryTransactionType.cashIn;
    _selectedChannel = t?.channel ?? PaymentChannelType.cash;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final cubit = context.read<AccountingCubit>();
    bool success;

    if (widget.transaction != null) {
      final updated = widget.transaction!.copyWith(
        type: _selectedType,
        channel: _selectedChannel,
        amount: amount,
        reason: _reasonController.text.trim(),
        referenceNumber: _refController.text.trim(),
      );
      success = await cubit.updateTransaction(updated);
    } else {
      success = await cubit.recordTransaction(
        type: _selectedType,
        channel: _selectedChannel,
        amount: amount,
        reason: _reasonController.text.trim(),
        referenceNumber: _refController.text.trim(),
      );
    }

    if (mounted && success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction != null
                ? AppLocalizations.of(context).translate('transaction_updated_successfully')
                : AppLocalizations.of(context).translate('transaction_recorded_successfully'),
          ),
          backgroundColor: AppColor.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        widget.transaction != null
                            ? AppLocalizations.of(context).translate('edit')
                            : AppLocalizations.of(context).translate('record_treasury_entry'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction Type
              Text(
                AppLocalizations.of(context).translate('transaction_type'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<TreasuryTransactionType>(
                initialValue: _selectedType,
                isExpanded: true,
                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                decoration: _inputDecoration(isDark),
                items: TreasuryTransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      AppLocalizations.of(context).isArabic
                          ? type.arabicLabel
                          : type.englishLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 14),

              // Payment Channel
              Text(
                AppLocalizations.of(context).translate('payment_channel'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<PaymentChannelType>(
                initialValue: _selectedChannel,
                isExpanded: true,
                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                decoration: _inputDecoration(isDark),
                items: PaymentChannelType.values.map((chan) {
                  return DropdownMenuItem(
                    value: chan,
                    child: Text(
                      AppLocalizations.of(context).isArabic
                          ? chan.arabicLabel
                          : chan.englishLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedChannel = val);
                },
              ),
              const SizedBox(height: 14),

              // Amount
              Text(
                AppLocalizations.of(context).translate('amount_egp'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(isDark, hint: '0.00'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('field_required');
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return AppLocalizations.of(context).translate('enter_valid_amount');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Reason / Description
              Text(
                AppLocalizations.of(context).translate('reason_or_description'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                decoration: _inputDecoration(
                  isDark,
                  hint: AppLocalizations.of(context).translate('transaction_notes_hint'),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('field_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Reference Number
              Text(
                AppLocalizations.of(context).translate('reference_receipt_number'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _refController,
                decoration: _inputDecoration(
                  isDark,
                  hint: 'Optional (e.g. REC-10492)',
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('cancel'),
                      style: TextStyle(
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      widget.transaction != null
                          ? AppLocalizations.of(context).translate('edit')
                          : AppLocalizations.of(context).translate('save_entry'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
    );
  }
}
