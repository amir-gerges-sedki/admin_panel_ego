import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/banner_model.dart';

class BannerFormDialog extends StatefulWidget {
  final BannerModel? initialBanner;
  final ValueChanged<BannerModel> onSave;

  const BannerFormDialog({super.key, this.initialBanner, required this.onSave});

  static void show(BuildContext context, {BannerModel? initialBanner, required ValueChanged<BannerModel> onSave}) {
    UnifiedModalSheet.show(
      context: context,
      title: initialBanner == null ? 'add_banner'.tr : 'edit'.tr,
      icon: Icons.view_carousel_outlined,
      maxWidth: 500,
      content: BannerFormDialog(initialBanner: initialBanner, onSave: onSave),
    );
  }

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageController;
  late TextEditingController _targetController;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialBanner?.title ?? '');
    _imageController = TextEditingController(text: widget.initialBanner?.imageUrl ?? '');
    _targetController = TextEditingController(text: widget.initialBanner?.targetScreen ?? '/shop');
    _active = widget.initialBanner?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final banner = BannerModel(
      id: widget.initialBanner?.id ?? 'BANNER_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      imageUrl: _imageController.text.trim(),
      targetScreen: _targetController.text.trim(),
      active: _active,
    );
    widget.onSave(banner);
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
            controller: _titleController,
            decoration: InputDecoration(labelText: '${'banner_title_col'.tr} *', hintText: 'e.g. Weekend SaltNic Sale'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _imageController,
            decoration: InputDecoration(labelText: '${'banner_image'.tr} *'),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _targetController,
            decoration: InputDecoration(labelText: 'target_destination'.tr),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Switch(
                value: _active,
                activeThumbColor: AppColor.primary,
                onChanged: (v) => setState(() => _active = v),
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
