import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/employee_model.dart';
import '../cubit/employee_cubit.dart';

class EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? employee;

  const EmployeeFormDialog({super.key, this.employee});

  static Future<void> show(BuildContext context, {EmployeeModel? employee}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmployeeFormDialog(employee: employee),
    );
  }

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _baseSalaryController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _notesController;

  late DateTime _hireDate;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp?.name ?? '');
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _nationalIdController = TextEditingController(text: emp?.nationalId ?? '');
    _jobTitleController = TextEditingController(text: emp?.jobTitle ?? '');
    _baseSalaryController = TextEditingController(
      text: emp != null && emp.baseSalary > 0 ? emp.baseSalary.toStringAsFixed(2) : '',
    );
    _addressController = TextEditingController(text: emp?.address ?? '');
    _emergencyContactController = TextEditingController(text: emp?.emergencyContact ?? '');
    _notesController = TextEditingController(text: emp?.notes ?? '');

    _hireDate = emp?.hireDate ?? DateTime.now();
    _isActive = emp?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _jobTitleController.dispose();
    _baseSalaryController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final salary = double.tryParse(_baseSalaryController.text.trim()) ?? 0.0;
    if (salary < 0) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'invalid_amount'.tr,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final employeeRecord = EmployeeModel(
        id: widget.employee?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isNotEmpty
            ? _jobTitleController.text.trim()
            : 'staff_role'.tr,
        baseSalary: salary,
        hireDate: _hireDate,
        isActive: _isActive,
        address: _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        await context.read<EmployeeCubit>().updateEmployee(employeeRecord);
      } else {
        await context.read<EmployeeCubit>().addEmployee(employeeRecord);
      }

      if (mounted) {
        Navigator.of(context).pop();
        HelperFun.showNotificationAlert(
          title: 'success'.tr,
          message: _isEdit ? 'employee_updated_success'.tr : 'employee_added_success'.tr,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
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
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm + 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'edit_employee_title'.tr : 'add_employee_title'.tr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'employee_form_subtitle'.tr,
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
                      // 1. Employee Name
                      Text(
                        'employee_name'.tr,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
                        decoration: InputDecoration(
                          hintText: 'employee_name_hint'.tr,
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 2. Phone & National ID
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'employee_phone'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
                                  decoration: InputDecoration(
                                    hintText: '01xxxxxxxxx',
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
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
                                  'national_id'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nationalIdController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '14 رقم قومي',
                                    prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 3. Job Title & Base Salary
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'job_title_position'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _jobTitleController,
                                  decoration: InputDecoration(
                                    hintText: 'job_title_hint'.tr,
                                    prefixIcon: const Icon(Icons.work_outline_rounded, size: 18),
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
                                  'base_monthly_salary'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _baseSalaryController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'required_field'.tr;
                                    final val = double.tryParse(v.trim());
                                    if (val == null || val < 0) return 'invalid_amount'.tr;
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
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 4. Hire Date & Status Switch
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickHireDate,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppColor.primary),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('hire_date'.tr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(
                                          AppFormatters.formatDate(_hireDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('employee_active_status'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                value: _isActive,
                                activeThumbColor: const Color(0xFF10B981),
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 5. Address & Emergency Contact
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('address'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    hintText: 'العنوان السكني...',
                                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
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
                                Text('emergency_contact'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emergencyContactController,
                                  decoration: InputDecoration(
                                    hintText: 'هاتف الطوارئ / قريب...',
                                    prefixIcon: const Icon(Icons.contact_phone_outlined, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 6. Notes
                      Text('notes'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أي ملاحظات إضافية عن الموظف...',
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
                      _isEdit ? 'save_changes'.tr : 'add_employee_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
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
  }
}
