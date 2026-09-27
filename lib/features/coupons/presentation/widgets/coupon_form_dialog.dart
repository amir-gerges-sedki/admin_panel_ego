import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/coupon_model.dart';
import '../cubit/coupon_cubit.dart';

class CouponFormDialog extends StatefulWidget {
  final CouponModel? initialCoupon;
  final ValueChanged<CouponModel> onSave;

  const CouponFormDialog({super.key, this.initialCoupon, required this.onSave});

  static void show(
    BuildContext context, {
    CouponModel? initialCoupon,
    required ValueChanged<CouponModel> onSave,
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: initialCoupon == null ? 'add_coupon'.tr : 'edit_coupon'.tr,
      subtitle: initialCoupon != null && initialCoupon.usageCount > 0
          ? 'used_times_count'.trParams({
              'count': '${initialCoupon.usageCount}',
            })
          : 'coupons_subtitle'.tr,
      icon: Icons.confirmation_number_outlined,
      maxWidth: 500,
      content: CouponFormDialog(initialCoupon: initialCoupon, onSave: onSave),
    );
  }

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _discountController;
  late TextEditingController _minAmountController;
  late DateTime _startDate;
  late DateTime _expiryDate;
  bool _isActive = true;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.initialCoupon?.code ?? '',
    );
    _discountController = TextEditingController(
      text: widget.initialCoupon != null
          ? widget.initialCoupon!.discountPercentage.toInt().toString()
          : '',
    );
    _minAmountController = TextEditingController(
      text:
          widget.initialCoupon != null &&
              widget.initialCoupon!.minOrderAmount > 0
          ? widget.initialCoupon!.minOrderAmount.toInt().toString()
          : '',
    );
    _startDate = widget.initialCoupon?.startDate ?? DateTime.now();
    _expiryDate =
        widget.initialCoupon?.expiryDate ??
        DateTime.now().add(const Duration(days: 30));
    _isActive = widget.initialCoupon?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        if (_expiryDate.isBefore(_startDate)) {
          _expiryDate = _startDate.add(const Duration(days: 30));
        }
        _dateError = null;
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate.isAfter(_startDate)
          ? _expiryDate
          : _startDate.add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
        if (_expiryDate.isBefore(_startDate)) {
          _dateError = 'invalid_date_range'.tr;
        } else {
          _dateError = null;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate.isBefore(_startDate)) {
      setState(() {
        _dateError = 'invalid_date_range'.tr;
      });
      return;
    }

    final coupon = CouponModel(
      id: widget.initialCoupon?.id ?? _codeController.text.trim().toUpperCase(),
      code: _codeController.text.trim().toUpperCase(),
      discountPercentage: double.tryParse(_discountController.text) ?? 0.0,
      minOrderAmount: double.tryParse(_minAmountController.text) ?? 0.0,
      isActive: _isActive,
      startDate: _startDate,
      expiryDate: _expiryDate,
      usageCount: widget.initialCoupon?.usageCount ?? 0,
    );
    widget.onSave(coupon);
    Navigator.of(context).pop();
  }

  void _confirmDeleteFromDialog(BuildContext context, CouponModel coupon) {
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColor.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_coupon_title'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          coupon.code.trim().isNotEmpty
              ? 'delete_coupon_confirm_with_code'.trParams({
                  'code': coupon.code,
                })
              : 'delete_coupon_confirm'.tr,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColor.textSecondaryDark
                : AppColor.textSecondaryLight,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CouponCubit>().deleteCoupon(coupon.id);
              Navigator.of(context).pop();
              HelperFun.successSnackbar('success'.tr, 'item_deleted'.tr);
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. PROMO CODE INPUT
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
            ],
            decoration: InputDecoration(
              labelText: '${'coupon_code'.tr} *',
              prefixIcon: const Icon(
                Icons.confirmation_number_outlined,
                size: 20,
              ),
              suffixIcon: _codeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _codeController.clear()),
                    )
                  : null,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),

          // 2. DISCOUNT & MINIMUM ORDER SECTION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount Percentage
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '${'discount_percentage'.tr} *',
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0 || val > 100) return '1-100%';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // Minimum Purchase Amount
              Expanded(
                child: TextFormField(
                  controller: _minAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'min_purchase_amount'.tr,
                    suffixText: 'EGP',
                    prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // 3. VALIDITY DATES
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStartDate,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColor.darkSubCard
                          : AppColor.lightSubCard,
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusMd,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColor.darkBorder
                            : AppColor.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColor.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'start_date'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.formatDate(_startDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: InkWell(
                  onTap: _pickExpiryDate,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColor.darkSubCard
                          : AppColor.lightSubCard,
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusMd,
                      ),
                      border: Border.all(
                        color: _dateError != null
                            ? AppColor.error
                            : (isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            size: 16,
                            color: AppColor.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'end_date'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.formatDate(_expiryDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_dateError != null) ...[
            const SizedBox(height: 6),
            Text(
              _dateError!,
              style: const TextStyle(
                color: AppColor.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.md),

          // 4. ACTIVE STATUS CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(
                color: _isActive
                    ? AppColor.success.withValues(alpha: 0.3)
                    : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isActive ? AppColor.success : Colors.grey)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isActive
                        ? Icons.check_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: _isActive ? AppColor.success : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'active'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isActive
                            ? 'active_status_desc'.tr
                            : 'inactive_status_desc'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColor.success,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // 5. ACTION BUTTONS
          Row(
            children: [
              if (widget.initialCoupon != null) ...[
                TextButton.icon(
                  onPressed: () =>
                      _confirmDeleteFromDialog(context, widget.initialCoupon!),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColor.error,
                  ),
                  label: Text(
                    'delete_coupon'.tr,
                    style: const TextStyle(
                      color: AppColor.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr),
              ),
              const SizedBox(width: AppSizes.md),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                label: Text(
                  widget.initialCoupon == null ? 'add_coupon'.tr : 'save'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
