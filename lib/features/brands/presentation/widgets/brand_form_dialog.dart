import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../common/widgets/image_picker/dual_image_picker_field.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/brand_model.dart';
import '../../data/repositories/brand_repository.dart';

class BrandFormDialog extends StatefulWidget {
  final BrandModel? initialBrand;
  final FutureOr<void> Function(BrandModel) onSave;

  const BrandFormDialog({super.key, this.initialBrand, required this.onSave});

  static void show(
    BuildContext context, {
    BrandModel? initialBrand,
    required FutureOr<void> Function(BrandModel) onSave,
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: initialBrand == null ? 'add_brand'.tr : 'edit_brand'.tr,
      subtitle: initialBrand == null
          ? 'add_brand_subtitle'.tr
          : 'edit_brand_subtitle'.tr,
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
  bool _isLoading = false;
  String? _errorKey;
  Map<String, String>? _errorParams;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialBrand?.name ?? '',
    );
    _imageController = TextEditingController(
      text: widget.initialBrand?.image ?? '',
    );
    _isFeatured = widget.initialBrand?.isFeatured ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorKey = null;
      _errorParams = null;
      _errorMessage = null;
    });

    final brand = BrandModel(
      id:
          widget.initialBrand?.id ??
          'BRAND_${_nameController.text.toUpperCase().replaceAll(' ', '_')}',
      name: _nameController.text.trim(),
      image: _imageController.text.trim(),
      isFeatured: _isFeatured,
      productsCount: widget.initialBrand?.productsCount ?? 0,
      sortOrder: widget.initialBrand?.sortOrder ?? 0,
    );

    try {
      await widget.onSave(brand);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialBrand == null
                  ? 'item_created'.tr
                  : 'item_updated'.tr,
            ),
            backgroundColor: AppColor.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on BrandException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorKey = e.key;
          _errorParams = e.params;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorKey = null;
          _errorParams = null;
          final errStr = e.toString().replaceFirst('Exception: ', '').trim();
          _errorMessage = errStr.isNotEmpty ? errStr : 'error_occurred'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, localeState) {
        final displayError = _errorKey != null
            ? _errorKey!.trParams(_errorParams)
            : _errorMessage;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (displayError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColor.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColor.error,
                        size: 18,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: AppColor.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${'brand_name'.tr} *',
                  hintText: 'brand_name_hint'.tr,
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'required'.tr : null,
              ),
              const SizedBox(height: AppSizes.md),
              DualImagePickerField(
                initialUrl: _imageController.text,
                label: 'brand_logo_url',
                storageFolder: 'brands',
                customFileName: _nameController.text.trim().isNotEmpty
                    ? 'brand_${_nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}'
                    : null,
                onImageChanged: (url) {
                  _imageController.text = url;
                },
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isFeatured,
                    activeColor: AppColor.primary,
                    onChanged: (v) => setState(() => _isFeatured = v ?? true),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'featured'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'featured_brand_desc'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.md,
                      ),
                    ),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: AppSizes.md),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xl,
                        vertical: AppSizes.md,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.initialBrand == null
                                ? 'add_brand'.tr
                                : 'save'.tr,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
