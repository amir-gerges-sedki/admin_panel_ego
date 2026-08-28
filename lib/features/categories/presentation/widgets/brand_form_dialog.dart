import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/category_model.dart';

class BrandFormDialog extends StatefulWidget {
  final BrandModel? initialBrand;
  final ValueChanged<BrandModel> onSave;

  const BrandFormDialog({super.key, this.initialBrand, required this.onSave});

  static void show(BuildContext context, {BrandModel? initialBrand, required ValueChanged<BrandModel> onSave}) {
    UnifiedModalSheet.show(
      context: context,
      title: initialBrand == null ? 'add_brand'.tr : 'edit_brand'.tr,
      icon: Icons.branding_watermark_outlined,
      maxWidth: 500,
      content: BrandFormDialog(initialBrand: initialBrand, onSave: onSave),
    );
  }

  @override
  State<BrandFormDialog> createState() => _BrandFormDialogState();
}

class _BrandFormDialogState extends State<BrandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  bool _isFeatured = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialBrand?.name ?? '');
    _imageController = TextEditingController(text: widget.initialBrand?.image ?? '');
    _isFeatured = widget.initialBrand?.isFeatured ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final brand = BrandModel(
      id: widget.initialBrand?.id ?? 'BRAND_${_nameController.text.toUpperCase().replaceAll(' ', '_')}',
      name: _nameController.text.trim(),
      image: _imageController.text.trim(),
      isFeatured: _isFeatured,
      productsCount: widget.initialBrand?.productsCount ?? 0,
    );
    widget.onSave(brand);
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
            controller: _nameController,
            decoration: InputDecoration(labelText: '${'brand_name'.tr} *', hintText: 'e.g. Vaporesso, GeekVape, VGOD'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _imageController,
            decoration: const InputDecoration(labelText: 'Brand Logo URL'),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Switch(
                value: _isFeatured,
                activeThumbColor: AppColor.primary,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              const SizedBox(width: 8),
              Text('featured'.tr),
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
