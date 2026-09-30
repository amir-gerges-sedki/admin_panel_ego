import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/expense_model.dart';
import '../cubit/expense_cubit.dart';

class ExpenseFormDialog extends StatefulWidget {
  final ExpenseModel? expense;

  const ExpenseFormDialog({super.key, this.expense});

  static Future<void> show(BuildContext context, {ExpenseModel? expense}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ExpenseCubit>(),
        child: ExpenseFormDialog(expense: expense),
      ),
    );
  }

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _recordedByController;
  late TextEditingController _notesController;

  late ExpenseCategory _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'cash',
    'instapay',
    'vodafone_cash',
    'bank_transfer',
    'card',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '',
    );
    _recordedByController = TextEditingController(text: e?.recordedBy ?? 'Admin');
    _notesController = TextEditingController(text: e?.notes ?? '');

    _selectedCategory = e?.category ?? ExpenseCategory.utilities;
    _selectedPaymentMethod = e?.paymentMethod ?? 'cash';
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _recordedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
    if (amount <= 0) {
      HelperFun.showNotificationAlert(
        title: 'alert'.tr,
        message: 'invalid_amount'.tr,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cubit = context.read<ExpenseCubit>();

      if (widget.expense != null) {
        final updated = widget.expense!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          recordedBy: _recordedByController.text.trim(),
          notes: _notesController.text.trim(),
        );
        await cubit.updateExpense(updated);
        if (mounted) {
          Navigator.of(context).pop();
          HelperFun.showNotificationAlert(
            title: 'success'.tr,
            message: 'expense_updated_success'.tr,
          );
        }
      } else {
        final newExpense = ExpenseModel(
          id: '',
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          recordedBy: _recordedByController.text.trim().isEmpty
              ? 'Admin'
              : _recordedByController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await cubit.addExpense(newExpense);
        if (mounted) {
          Navigator.of(context).pop();
          HelperFun.showNotificationAlert(
            title: 'success'.tr,
            message: 'expense_added_success'.tr,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.showNotificationAlert(
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isEdit = widget.expense != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
      ),
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note_rounded : Icons.add_card_rounded,
                          color: AppColor.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm + 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'edit_expense'.tr : 'add_new_expense'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'expense_form_desc'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Title & Amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'expense_title'.tr,
                                hintText: 'expense_title_hint'.tr,
                                prefixIcon: const Icon(Icons.title_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'field_required'.tr;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'expense_amount_egp'.tr,
                                prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
                                suffixText: 'currency_egp'.tr,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'field_required'.tr;
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n <= 0) {
                                  return 'invalid_amount'.tr;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 2. Category Selection
                      Text(
                        'expense_category'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ExpenseCategory.values.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            avatar: Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                            label: Text(cat.labelKey.tr),
                            selected: isSelected,
                            selectedColor: cat.color,
                            backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 3. Date & Payment Method
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'expense_date'.tr,
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                child: Text(
                                  AppFormatters.formatDate(_selectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPaymentMethod,
                              decoration: InputDecoration(
                                labelText: 'payment_method'.tr,
                                prefixIcon: const Icon(Icons.payment_rounded, size: 18),
                              ),
                              items: _paymentMethods.map((pm) {
                                return DropdownMenuItem(
                                  value: pm,
                                  child: Text('payment_method_$pm'.tr),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPaymentMethod = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 4. Responsible Person (Recorded By)
                      TextFormField(
                        controller: _recordedByController,
                        decoration: InputDecoration(
                          labelText: 'expense_recorded_by'.tr,
                          hintText: 'expense_recorded_by_hint'.tr,
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 5. Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'notes'.tr,
                          hintText: 'expense_notes_hint'.tr,
                          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.sm),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _onSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(isEdit ? Icons.save_rounded : Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'saving'.tr
                          : (isEdit ? 'update_expense'.tr : 'save_expense'.tr),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
