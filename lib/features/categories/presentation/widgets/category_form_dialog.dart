import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/category_model.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? initialCategory;
  final ValueChanged<CategoryModel> onSave;

  const CategoryFormDialog({super.key, this.initialCategory, required this.onSave});

  static void show(BuildContext context, {CategoryModel? initialCategory, required ValueChanged<CategoryModel> onSave}) {
    UnifiedModalSheet.show(
      context: context,
      title: initialCategory == null ? 'add_category'.tr : 'edit_category'.tr,
      icon: Icons.category_outlined,
      maxWidth: 500,
      content: CategoryFormDialog(initialCategory: initialCategory, onSave: onSave),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  bool _isFeatured = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    _imageController = TextEditingController(text: widget.initialCategory?.image ?? '');
    _isFeatured = widget.initialCategory?.isFeatured ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cat = CategoryModel(
      id: widget.initialCategory?.id ?? 'CAT_${_nameController.text.toUpperCase().replaceAll(' ', '_')}',
      name: _nameController.text.trim(),
      image: _imageController.text.trim(),
      isFeatured: _isFeatured,
      productsCount: widget.initialCategory?.productsCount ?? 0,
    );
    widget.onSave(cat);
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
            decoration: InputDecoration(labelText: '${'category_name'.tr} *', hintText: 'e.g. Salt Nicotine E-Liquids'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _imageController,
            decoration: const InputDecoration(labelText: 'Category Icon / Image URL'),
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
