import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../employees/data/models/employee_model.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';

/// Quick staff salesperson switcher dialog for POS
class QuickStaffSwitchDialog extends StatefulWidget {
  const QuickStaffSwitchDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<PosCubit>(),
        child: const QuickStaffSwitchDialog(),
      ),
    );
  }

  @override
  State<QuickStaffSwitchDialog> createState() => _QuickStaffSwitchDialogState();
}

class _QuickStaffSwitchDialogState extends State<QuickStaffSwitchDialog> {
  EmployeeModel? _selectedStaff;
  String _pin = '';
  String? _errorMessage;
  bool _isVerifying = false;

  void _onStaffSelected(EmployeeModel staff) {
    setState(() {
      _selectedStaff = staff;
      _pin = '';
      _errorMessage = null;
    });
  }

  void _onBackToList() {
    setState(() {
      _selectedStaff = null;
      _pin = '';
      _errorMessage = null;
    });
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  void _onClearPressed() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _submitPin() async {
    if (_selectedStaff == null) return;
    if (_pin.length < 4) {
      setState(() => _errorMessage = 'يرجى إدخال كود PIN المكون من 4 إلى 6 أرقام');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final cubit = context.read<PosCubit>();
    final result = await cubit.switchSalesPersonWithPin(
      staff: _selectedStaff!,
      pin: _pin,
    );

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (result.success) {
      HelperFun.showNotificationAlert(
        title: 'تم تحديد البائع بنجاح',
        message: 'تم تعيين ${_selectedStaff!.name} كمسؤول مبيعات للفاتورة الحالية.',
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = result.error ?? 'كود PIN غير صحيح!';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            width: 460,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: _selectedStaff == null
                  ? _buildStaffList(context, state, isDark)
                  : _buildPinKeypad(context, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffList(BuildContext context, PosState state, bool isDark) {
    final activeStaff = state.availableStaff.isNotEmpty
        ? state.availableStaff
        : <EmployeeModel>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: const Icon(Icons.badge_outlined, color: AppColor.primary, size: 22),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحديد بائع المعاملة (سيلز)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'اختر موظف المبيعات لربط الفاتورة بنقاطه ونسبة عمولته',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        const Divider(height: 24),

        // Active Salesperson Banner
        if (state.activeSalesPerson != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'البائع الحالي: ${state.activeSalesPerson!.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<PosCubit>().clearActiveSalesPerson();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('إلغاء التحديد', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

        // Staff List
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: activeStaff.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 40,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                        const SizedBox(height: 10),
                        const Text(
                          'لا يوجد موظفون نشطون مسجلون حالياً.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يمكن إضافة وتفعيل الموظفين من شاشة الموظفين.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeStaff.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final staff = activeStaff[index];
                    final isCurrent = state.activeSalesPerson?.id == staff.id;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onStaffSelected(staff),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColor.primary.withValues(alpha: 0.08)
                                : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColor.primary
                                  : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isCurrent
                                    ? AppColor.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                child: Text(
                                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isCurrent ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrent ? AppColor.primary : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${staff.jobTitle.isNotEmpty ? staff.jobTitle : 'موظف مبيعات'} • عمولة ${staff.commissionRate}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                const Icon(Icons.check_circle_rounded, color: AppColor.primary, size: 20)
                              else
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPinKeypad(BuildContext context, bool isDark) {
    final staff = _selectedStaff!;
    final cubit = context.read<PosCubit>();
    final isLockedOut = cubit.isStaffLockedOut(staff.id);
    final remainingSecs = cubit.remainingLockoutSeconds(staff.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Back & Staff Info
        Row(
          children: [
            IconButton(
              onPressed: _onBackToList,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              tooltip: 'العودة للقائمة',
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColor.primary.withValues(alpha: 0.15),
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'أدخل كود PIN للتأكيد والتبديل السريع',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        const Divider(height: 20),

        // Lockout Warning if applicable
        if (isLockedOut)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الموظف محظور مؤقتاً لتكرار الخطأ! يرجى الانتظار $remainingSecs ثانية.',
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // PIN Display Dots
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? AppColor.primary
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  border: Border.all(
                    color: isFilled ? AppColor.primary : Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
        ),

        // Error message if any
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

        // Numeric Keypad (3x4 Grid)
        _buildNumericKeypad(isDark, isLockedOut || _isVerifying),
        const SizedBox(height: 12),

        // Submit Button
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: (isLockedOut || _isVerifying || _pin.length < 4) ? null : _submitPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('تأكيد واختيار كبائع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericKeypad(bool isDark, bool disabled) {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], isDark, disabled),
        const SizedBox(height: 8),
        _buildKeypadRow(['4', '5', '6'], isDark, disabled),
        const SizedBox(height: 8),
        _buildKeypadRow(['7', '8', '9'], isDark, disabled),
        const SizedBox(height: 8),
        _buildKeypadRow(['clear', '0', 'backspace'], isDark, disabled),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark, bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadButton(key, isDark, disabled),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String key, bool isDark, bool disabled) {
    final isClear = key == 'clear';
    final isBackspace = key == 'backspace';

    return SizedBox(
      height: 48,
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: InkWell(
          onTap: disabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  if (isClear) {
                    _onClearPressed();
                  } else if (isBackspace) {
                    _onDeletePressed();
                  } else {
                    _onDigitPressed(key);
                  }
                },
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          child: Center(
            child: isClear
                ? const Text('C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.redAccent))
                : isBackspace
                    ? const Icon(Icons.backspace_outlined, size: 20, color: Colors.grey)
                    : Text(
                        key,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
