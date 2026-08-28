import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/coupon_model.dart';

class CouponFormDialog extends StatefulWidget {
  final CouponModel? initialCoupon;
  final ValueChanged<CouponModel> onSave;

  const CouponFormDialog({super.key, this.initialCoupon, required this.onSave});

  static void show(BuildContext context, {CouponModel? initialCoupon, required ValueChanged<CouponModel> onSave}) {
    UnifiedModalSheet.show(
      context: context,
      title: initialCoupon == null ? 'add_coupon'.tr : 'edit'.tr,
      icon: Icons.local_offer_outlined,
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
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCoupon?.code ?? '');
    _discountController = TextEditingController(text: widget.initialCoupon != null ? widget.initialCoupon!.discountPercentage.toString() : '20');
    _minAmountController = TextEditingController(text: widget.initialCoupon != null ? widget.initialCoupon!.minOrderAmount.toString() : '500');
    _isActive = widget.initialCoupon?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final coupon = CouponModel(
      id: widget.initialCoupon?.id ?? 'COUPON_${_codeController.text.toUpperCase()}',
      code: _codeController.text.trim().toUpperCase(),
      discountPercentage: double.tryParse(_discountController.text) ?? 10.0,
      minOrderAmount: double.tryParse(_minAmountController.text) ?? 0.0,
      isActive: _isActive,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      usageCount: widget.initialCoupon?.usageCount ?? 0,
    );
    widget.onSave(coupon);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: '${'coupon_code'.tr} *', hintText: 'e.g. VAPE20, FREESHIP2000'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '${'discount_percentage'.tr} *', hintText: '20'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'min_cart_requirement'.tr, hintText: '500'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Switch(
                value: _isActive,
                activeThumbColor: AppColor.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(width: 8),
              Text('active'.tr),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text('cancel'.tr)),
              const SizedBox(width: AppSizes.md),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
                child: Text('save'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
