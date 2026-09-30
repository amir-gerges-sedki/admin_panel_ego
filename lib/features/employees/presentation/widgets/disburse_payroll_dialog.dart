import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../roles/presentation/cubit/auth_role_cubit.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/payroll_slip_model.dart';
import '../../data/models/salary_advance_model.dart';
import '../cubit/employee_cubit.dart';
import '../cubit/employee_state.dart';

class DisbursePayrollDialog extends StatefulWidget {
  final EmployeeModel? initialEmployee;

  const DisbursePayrollDialog({super.key, this.initialEmployee});

  static Future<void> show(BuildContext context, {EmployeeModel? initialEmployee}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DisbursePayrollDialog(initialEmployee: initialEmployee),
    );
  }

  @override
  State<DisbursePayrollDialog> createState() => _DisbursePayrollDialogState();
}

class _DisbursePayrollDialogState extends State<DisbursePayrollDialog> {
  final _formKey = GlobalKey<FormState>();

  EmployeeModel? _selectedEmployee;
  final _bonusesController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _recordToExpenses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;
  }

  @override
  void dispose() {
    _bonusesController.dispose();
    _deductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _bonuses => double.tryParse(_bonusesController.text.trim()) ?? 0.0;
  double get _deductions => double.tryParse(_deductionsController.text.trim()) ?? 0.0;

  double _calculateNetSalary(double base, double advances) {
    final net = base + _bonuses - advances - _deductions;
    return net > 0 ? net : 0.0;
  }

  Future<void> _submit(List<SalaryAdvanceModel> advancesToDeduct, double advancesSum) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'select_employee_required'.tr,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = context.read<AuthRoleCubit>().state;
      final disbursedBy = authState.activeAdminEmail.isNotEmpty
          ? authState.activeAdminEmail
          : authState.activeAdminName;

      final monthStr = '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}';
      final net = _calculateNetSalary(_selectedEmployee!.baseSalary, advancesSum);

      final slip = PayrollSlipModel(
        id: '',
        employeeId: _selectedEmployee!.id,
        employeeName: _selectedEmployee!.name,
        jobTitle: _selectedEmployee!.jobTitle,
        monthPeriod: monthStr,
        baseSalary: _selectedEmployee!.baseSalary,
        totalBonuses: _bonuses,
        totalAdvances: advancesSum,
        totalDeductions: _deductions,
        netSalary: net,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
        disbursedBy: disbursedBy,
        createdAt: DateTime.now(),
      );

      await context.read<EmployeeCubit>().disbursePayroll(
            slip: slip,
            advancesToDeduct: advancesToDeduct,
            recordToExpenses: _recordToExpenses,
          );

      if (mounted) {
        Navigator.of(context).pop();
        HelperFun.showNotificationAlert(
          title: 'success'.tr,
          message: 'payroll_disbursed_success'.tr,
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

        final List<SalaryAdvanceModel> advancesToDeduct = (_selectedEmployee != null && state is EmployeeLoaded)
            ? state.getUnsettledAdvancesForEmployee(_selectedEmployee!.id)
            : <SalaryAdvanceModel>[];

        final double advancesSum = advancesToDeduct.fold(0.0, (sum, a) => sum + a.amount);
        final double base = _selectedEmployee?.baseSalary ?? 0.0;
        final double net = _calculateNetSalary(base, advancesSum);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
          backgroundColor: isDark ? AppColor.darkCard : Colors.white,
          child: Container(
            width: 620,
            constraints: const BoxConstraints(maxHeight: 750),
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm + 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'disburse_payroll_title'.tr,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'disburse_payroll_subtitle'.tr,
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
                          // 1. Employee Selection
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
                                      '${emp.name} (${emp.jobTitle})',
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

                          // 2. Financial Breakdown Cards
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('base_monthly_salary'.tr, style: const TextStyle(fontSize: 12)),
                                    Text(
                                      AppFormatters.formatEGP(base),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text('advances_to_deduct'.tr, style: const TextStyle(fontSize: 12)),
                                        if (advancesToDeduct.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${advancesToDeduct.length} سلفة',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '- ${AppFormatters.formatEGP(advancesSum)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 3. Bonuses & Deductions Inputs
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'bonuses_and_rewards'.tr,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _bonusesController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        prefixIcon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                        suffixText: 'ج.م',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'penalties_and_deductions'.tr,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _deductionsController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        prefixIcon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                        suffixText: 'ج.م',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 4. Net Salary Due Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'net_salary_due'.tr,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '(${_selectedEmployee?.name ?? ""})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  AppFormatters.formatEGP(net),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // 5. Payment Method & Expense Integration
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),

                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'record_payroll_as_expense'.tr,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'record_payroll_as_expense_subtitle'.tr,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            value: _recordToExpenses,
                            activeColor: AppColor.primary,
                            onChanged: (val) => setState(() => _recordToExpenses = val ?? true),
                          ),
                          const SizedBox(height: AppSizes.sm),

                          // 6. Notes
                          Text('notes'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'ملاحظات إضافية حول صرف الراتب...',
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
                        onPressed: _isSaving ? null : () => _submit(advancesToDeduct, advancesSum),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          'confirm_disburse_payroll'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
