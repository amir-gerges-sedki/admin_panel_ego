import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../roles/presentation/cubit/auth_role_cubit.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/salary_advance_model.dart';
import '../cubit/employee_cubit.dart';
import '../cubit/employee_state.dart';

class SalaryAdvanceFormDialog extends StatefulWidget {
  final EmployeeModel? initialEmployee;

  const SalaryAdvanceFormDialog({super.key, this.initialEmployee});

  static Future<void> show(BuildContext context, {EmployeeModel? initialEmployee}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SalaryAdvanceFormDialog(initialEmployee: initialEmployee),
    );
  }

  @override
  State<SalaryAdvanceFormDialog> createState() => _SalaryAdvanceFormDialogState();
}

class _SalaryAdvanceFormDialogState extends State<SalaryAdvanceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  EmployeeModel? _selectedEmployee;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _advanceDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _advanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _advanceDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'select_employee_required'.tr,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'invalid_amount'.tr,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = context.read<AuthRoleCubit>().state;
      final disbursedBy = authState.activeAdminEmail.isNotEmpty
          ? authState.activeAdminEmail
          : authState.activeAdminName;

      final monthStr = '${_advanceDate.year}-${_advanceDate.month.toString().padLeft(2, '0')}';

      final advanceRecord = SalaryAdvanceModel(
        id: '',
        employeeId: _selectedEmployee!.id,
        employeeName: _selectedEmployee!.name,
        amount: amount,
        date: _advanceDate,
        monthPeriod: monthStr,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
        disbursedBy: disbursedBy,
        createdAt: DateTime.now(),
      );

      await context.read<EmployeeCubit>().disburseSalaryAdvance(advanceRecord);

      if (mounted) {
        Navigator.of(context).pop();
        HelperFun.showNotificationAlert(
          title: 'success'.tr,
          message: 'advance_recorded_success'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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

    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        final List<EmployeeModel> employees = state is EmployeeLoaded
            ? state.allEmployees.where((e) => e.isActive).toList()
            : <EmployeeModel>[];

        if (_selectedEmployee == null && employees.isNotEmpty) {
          _selectedEmployee = employees.first;
        }

        final double currentAdvances = (_selectedEmployee != null && state is EmployeeLoaded)
            ? state.getUnsettledAdvancesAmountForEmployee(_selectedEmployee!.id)
            : 0.0;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
          backgroundColor: isDark ? AppColor.darkCard : Colors.white,
          child: Container(
            width: 550,
            constraints: const BoxConstraints(maxHeight: 650),
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
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm + 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'disburse_advance_title'.tr,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'disburse_advance_subtitle'.tr,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.md),

                  // Form Body
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Select Employee
                          Text(
                            'select_employee'.tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<EmployeeModel>(
                                value: _selectedEmployee,
                                isExpanded: true,
                                items: employees.map((emp) {
                                  return DropdownMenuItem<EmployeeModel>(
                                    value: emp,
                                    child: Text(
                                      '${emp.name} (${emp.jobTitle}) - ${"salary".tr}: ${AppFormatters.formatEGP(emp.baseSalary)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedEmployee = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 2. Employee Info & Current Advances Card
                          if (_selectedEmployee != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'base_monthly_salary'.tr,
                                        style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                                      ),
                                      Text(
                                        AppFormatters.formatEGP(_selectedEmployee!.baseSalary),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'current_month_advances'.tr,
                                        style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                                      ),
                                      Text(
                                        AppFormatters.formatEGP(currentAdvances),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                          ],

                          // 3. Advance Amount & Date
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'advance_amount_egp'.tr,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _amountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'required_field'.tr;
                                        final n = double.tryParse(v.trim());
                                        if (n == null || n <= 0) return 'invalid_amount'.tr;
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        suffixText: 'ج.م',
                                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'advance_date'.tr,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: _pickDate,
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColor.primary),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppFormatters.formatDate(_advanceDate),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 4. Payment Method
                          Text(
                            'payment_method'.tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _paymentMethod,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'cash', child: Text('payment_method_cash'.tr)),
                                  DropdownMenuItem(value: 'instapay', child: Text('payment_method_instapay'.tr)),
                                  DropdownMenuItem(value: 'vodafone_cash', child: Text('payment_method_vodafone_cash'.tr)),
                                  DropdownMenuItem(value: 'bank_transfer', child: Text('payment_method_bank_transfer'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _paymentMethod = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 5. Notes
                          Text(
                            'notes_and_explanation'.tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'سبب السلفة أو أي تفاصيل...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.md),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'confirm_disburse_advance'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
