import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/cashier_shift_model.dart';
import '../cubit/shift_cubit.dart';

class ShiftCashEntryDialog extends StatefulWidget {
  final CashierShiftModel shift;
  final bool initialIsCashIn;

  const ShiftCashEntryDialog({
    super.key,
    required this.shift,
    this.initialIsCashIn = true,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CashierShiftModel shift,
    bool isCashIn = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ShiftCubit>(),
        child: ShiftCashEntryDialog(shift: shift, initialIsCashIn: isCashIn),
      ),
    );
  }

  @override
  State<ShiftCashEntryDialog> createState() => _ShiftCashEntryDialogState();
}

class _ShiftCashEntryDialogState extends State<ShiftCashEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  late bool _isCashIn;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isCashIn = widget.initialIsCashIn;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : (_isCashIn ? 'إيداع نقدية بالدرج' : 'صرف مصاريف نقدية من الدرج');

    setState(() => _isSubmitting = true);

    try {
      final cubit = context.read<ShiftCubit>();
      final success = _isCashIn
          ? await cubit.addCashIn(
              amount: amount,
              reason: reason,
              performedBy: widget.shift.cashierName,
            )
          : await cubit.addCashOut(
              amount: amount,
              reason: reason,
              performedBy: widget.shift.cashierName,
            );

      if (mounted) {
        if (success) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isCashIn
                    ? AppLocalizations.of(context).translate('cash_in_recorded_success')
                    : AppLocalizations.of(context).translate('cash_out_recorded_success'),
              ),
              backgroundColor: AppColor.success,
            ),
          );
        } else {
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error')}: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: _isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isCashIn
                            ? AppLocalizations.of(context).translate('shift_cash_in_title')
                            : AppLocalizations.of(context).translate('shift_cash_out_title'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (context.mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode Toggle (Cash In vs Cash Out)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isCashIn = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isCashIn ? const Color(0xFF10B981) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.of(context).translate('drawer_cash_in_btn'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isCashIn
                                  ? Colors.white
                                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isCashIn = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isCashIn ? const Color(0xFFEF4444) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppLocalizations.of(context).translate('drawer_cash_out_btn'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_isCashIn
                                  ? Colors.white
                                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              Text(
                AppLocalizations.of(context).translate('amount'),
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_rounded, size: 18),
                  suffixText: 'EGP',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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

              // Reason
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
                decoration: InputDecoration(
                  hintText: _isCashIn
                      ? AppLocalizations.of(context).translate('cash_in_reason_hint')
                      : AppLocalizations.of(context).translate('cash_out_reason_hint'),
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('field_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (context.mounted && Navigator.of(context).canPop()) {
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
                    onPressed: _isSubmitting ? null : _submitEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isCashIn
                                ? AppLocalizations.of(context).translate('record_cash_in_btn')
                                : AppLocalizations.of(context).translate('record_cash_out_btn'),
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
}
