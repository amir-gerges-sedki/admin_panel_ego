import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/cashier_shift_model.dart';
import '../cubit/shift_cubit.dart';

class CloseShiftDialog extends StatefulWidget {
  final CashierShiftModel shift;

  const CloseShiftDialog({super.key, required this.shift});

  static Future<bool?> show(BuildContext context, CashierShiftModel shift) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ShiftCubit>(),
        child: CloseShiftDialog(shift: shift),
      ),
    );
  }

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countedCashController = TextEditingController();
  final _closingNotesController = TextEditingController();

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _countedCashController.text = widget.shift.calculatedExpectedCash.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _closingNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitCloseShift() async {
    if (!_formKey.currentState!.validate()) return;

    final countedCash = double.tryParse(_countedCashController.text.trim()) ?? 0.0;
    setState(() => _isClosing = true);

    try {
      final closed = await context.read<ShiftCubit>().closeShift(
            actualCountedCash: countedCash,
            closingNotes: _closingNotesController.text.trim(),
            closedBy: widget.shift.cashierName,
          );

      if (mounted) {
        if (closed != null) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('shift_closed_success'),
              ),
              backgroundColor: AppColor.success,
            ),
          );
        } else {
          setState(() => _isClosing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosing = false);
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
    final shift = widget.shift;
    final expCash = shift.calculatedExpectedCash;
    final countedCash = double.tryParse(_countedCashController.text.trim()) ?? expCash;
    final diff = countedCash - expCash;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('close_shift_reconciliation_title'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${shift.branchName} • ${shift.cashierName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _isClosing
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

                // Cash Breakdown Cards Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkCard : AppColor.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('opening_drawer_cash'),
                            value: AppFormatters.formatEGP(shift.openingCash),
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColor.primary,
                          ),
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('pos_cash_sales'),
                            value: AppFormatters.formatEGP(shift.cashSales),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('card_visa_sales'),
                            value: AppFormatters.formatEGP(shift.cardSales),
                            icon: Icons.credit_card_rounded,
                            color: const Color(0xFF3B82F6),
                          ),
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('instapay_vodafone_sales'),
                            value: AppFormatters.formatEGP(shift.instapaySales + shift.vodafoneCashSales),
                            icon: Icons.send_to_mobile_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('drawer_cash_ins'),
                            value: '+${AppFormatters.formatEGP(shift.cashIns)}',
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFF10B981),
                          ),
                          _buildStatItem(
                            label: AppLocalizations.of(context).translate('drawer_cash_outs'),
                            value: '-${AppFormatters.formatEGP(shift.cashOuts + shift.cashRefunds)}',
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('expected_drawer_cash'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            AppFormatters.formatEGP(expCash),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Counted Cash Input
                Text(
                  AppLocalizations.of(context).translate('physical_counted_drawer_cash'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _countedCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.point_of_sale_rounded, size: 18, color: AppColor.primary),
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
                    if (parsed == null || parsed < 0) {
                      return AppLocalizations.of(context).translate('enter_valid_amount');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Difference indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: diff.abs() < 0.01
                        ? Colors.blue.withValues(alpha: 0.1)
                        : (diff > 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            diff.abs() < 0.01
                                ? Icons.check_circle_rounded
                                : (diff > 0 ? Icons.add_circle_rounded : Icons.warning_rounded),
                            size: 16,
                            color: diff.abs() < 0.01
                                ? AppColor.primary
                                : (diff > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            diff.abs() < 0.01
                                ? AppLocalizations.of(context).translate('drawer_balanced')
                                : (diff > 0
                                    ? AppLocalizations.of(context).translate('drawer_cash_surplus')
                                    : AppLocalizations.of(context).translate('drawer_cash_shortage')),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${diff > 0 ? '+' : ''}${AppFormatters.formatEGP(diff)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: diff.abs() < 0.01
                              ? AppColor.primary
                              : (diff > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Closing Notes
                Text(
                  AppLocalizations.of(context).translate('closing_notes_optional'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _closingNotesController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).translate('shift_reconciliation_notes_hint'),
                    filled: true,
                    fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isClosing
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
                    ElevatedButton.icon(
                      onPressed: _isClosing ? null : _submitCloseShift,
                      icon: _isClosing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_rounded, size: 18),
                      label: Text(
                        AppLocalizations.of(context).translate('confirm_close_shift_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
