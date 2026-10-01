import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/shift_cubit.dart';
import '../../data/models/cashier_shift_model.dart';

class OpenShiftDialog extends StatefulWidget {
  const OpenShiftDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ShiftCubit>()),
          BlocProvider.value(value: context.read<SettingsCubit>()),
        ],
        child: const OpenShiftDialog(),
      ),
    );
  }

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashierNameController = TextEditingController(text: 'Store Cashier');
  final _openingCashController = TextEditingController();
  final _notesController = TextEditingController();

  StoreBranchModel? _selectedBranch;
  String _selectedBranchId = 'main_branch';
  CashierShiftModel? _lastClosedShift;
  bool _isLoadingLastShift = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded && settingsState.settings.branches.isNotEmpty) {
      final primary = settingsState.settings.branches.firstWhere(
        (b) => b.isPrimary,
        orElse: () => settingsState.settings.branches.first,
      );
      _selectedBranch = primary;
      _selectedBranchId = primary.id;
    }
    _loadLastClosedShift();
  }

  Future<void> _loadLastClosedShift() async {
    setState(() => _isLoadingLastShift = true);
    try {
      final shift = await context.read<ShiftCubit>().getLastClosedShift(
            branchId: _selectedBranchId,
          );
      if (mounted) {
        setState(() {
          _lastClosedShift = shift;
          _isLoadingLastShift = false;
          if (shift != null) {
            final balance = shift.actualCountedCash ?? shift.expectedCash;
            _openingCashController.text = balance.toStringAsFixed(2);
          } else {
            _openingCashController.text = '0.00';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLastShift = false;
          _openingCashController.text = '0.00';
        });
      }
    }
  }

  @override
  void dispose() {
    _cashierNameController.dispose();
    _openingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOpenShift() async {
    if (!_formKey.currentState!.validate()) return;

    final openingCash = double.tryParse(_openingCashController.text.trim()) ?? 0.0;
    final cashierName = _cashierNameController.text.trim().isNotEmpty
        ? _cashierNameController.text.trim()
        : 'Store Cashier';

    final branchId = _selectedBranch?.id ?? _selectedBranchId;
    final branchName = _selectedBranch?.name ?? 'Main Branch (الفرع الرئيسي)';

    setState(() => _isSubmitting = true);

    try {
      final shift = await context.read<ShiftCubit>().openShift(
            branchId: branchId,
            branchName: branchName,
            cashierId: 'cashier_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            cashierName: cashierName,
            openingCash: openingCash,
            openingNotes: _notesController.text.trim(),
          );

      if (mounted) {
        if (shift != null) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('shift_opened_success'),
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
        width: 480,
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
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_filled_rounded,
                          color: AppColor.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).translate('open_cashier_shift_title'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
              const SizedBox(height: 18),

              // Branch Selector
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, settingsState) {
                  List<StoreBranchModel> branches = [];
                  if (settingsState is SettingsLoaded) {
                    branches = settingsState.settings.branches;
                  }

                  if (branches.isEmpty) {
                    branches = [
                      const StoreBranchModel(
                        id: 'main_branch',
                        name: 'الفرع الرئيسي (Main Branch)',
                        isPrimary: true,
                      ),
                    ];
                  }

                  // Deduplicate branches by ID
                  final seenIds = <String>{};
                  final uniqueBranches = <StoreBranchModel>[];
                  for (final b in branches) {
                    if (seenIds.add(b.id)) {
                      uniqueBranches.add(b);
                    }
                  }

                  final effectiveBranchId = uniqueBranches.any((b) => b.id == _selectedBranchId)
                      ? _selectedBranchId
                      : uniqueBranches.first.id;

                  _selectedBranch = uniqueBranches.firstWhere((b) => b.id == effectiveBranchId);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('select_branch'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: effectiveBranchId,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                        decoration: _inputDecoration(isDark, prefixIcon: Icons.storefront_rounded),
                        items: uniqueBranches.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(
                              b.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBranchId = val;
                              _selectedBranch = uniqueBranches.firstWhere((b) => b.id == val);
                            });
                            _loadLastClosedShift();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Cashier Name
              Text(
                AppLocalizations.of(context).translate('cashier_name'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cashierNameController,
                decoration: _inputDecoration(isDark, prefixIcon: Icons.badge_rounded),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppLocalizations.of(context).translate('field_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Previous Shift Closing Cash Feedback Banner
              if (_isLoadingLastShift) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate('fetching_drawer_balance'),
                          style: const TextStyle(fontSize: 12, color: AppColor.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_lastClosedShift != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColor.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, color: AppColor.success, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).translate('previous_shift_closing_cash'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColor.success,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(_lastClosedShift!.actualCountedCash ?? _lastClosedShift!.expectedCash).toStringAsFixed(2)} EGP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColor.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppLocalizations.of(context).translate('previous_shift_closed_by').replaceAll('{name}', _lastClosedShift!.closedBy.isNotEmpty ? _lastClosedShift!.closedBy : 'الكاشير السابق')}${_lastClosedShift!.closedAt != null ? ' • ${_lastClosedShift!.closedAt!.hour.toString().padLeft(2, '0')}:${_lastClosedShift!.closedAt!.minute.toString().padLeft(2, '0')}' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).translate('previous_shift_auto_filled_hint'),
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColor.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.info.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColor.info, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate('no_previous_shift_found'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Opening Drawer Float Cash (EGP)
              Text(
                AppLocalizations.of(context).translate('opening_drawer_cash'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _openingCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  isDark,
                  prefixIcon: Icons.account_balance_wallet_rounded,
                  suffixText: 'EGP',
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
              const SizedBox(height: 14),

              // Notes
              Text(
                AppLocalizations.of(context).translate('opening_notes_optional'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(
                  isDark,
                  hint: AppLocalizations.of(context).translate('shift_notes_hint'),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
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
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOpenShift,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      AppLocalizations.of(context).translate('start_shift_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
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
    );
  }

  InputDecoration _inputDecoration(
    bool isDark, {
    String? hint,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColor.primary) : null,
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
