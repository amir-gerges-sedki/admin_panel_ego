import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../common/widgets/image_picker/dual_image_picker_field.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_form_cubit.dart';

class VariationImageDialog extends StatefulWidget {
  final int variationIndex;
  final ProductVariationModel variation;
  final ProductFormCubit cubit;
  final List<String> existingProductImages;

  const VariationImageDialog({
    super.key,
    required this.variationIndex,
    required this.variation,
    required this.cubit,
    this.existingProductImages = const [],
  });

  static void show(
    BuildContext context, {
    required int variationIndex,
    required ProductVariationModel variation,
    required ProductFormCubit cubit,
    List<String> existingProductImages = const [],
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: 'variation_image_title'.trParams({'sku': variation.sku}),
      subtitle: 'variation_image_subtitle'.tr,
      icon: Icons.add_photo_alternate_outlined,
      maxWidth: 540,
      content: VariationImageDialog(
        variationIndex: variationIndex,
        variation: variation,
        cubit: cubit,
        existingProductImages: existingProductImages,
      ),
    );
  }

  @override
  State<VariationImageDialog> createState() => _VariationImageDialogState();
}

class _VariationImageDialogState extends State<VariationImageDialog> {
  String _currentPreviewUrl = '';

  @override
  void initState() {
    super.initState();
    _currentPreviewUrl = widget.variation.image;
  }

  void _applySingle() {
    widget.cubit.setVariationImage(widget.variationIndex, _currentPreviewUrl);
    Navigator.of(context).pop();
    HelperFun.successSnackbar(
      'image_updated_title'.tr,
      'image_updated_msg'.trParams({'sku': widget.variation.sku}),
    );
  }

  void _applyToMatchingAttribute() {
    final color =
        widget.variation.attributeValues['Color'] ??
        widget.variation.attributeValues['color'];
    final flavor =
        widget.variation.attributeValues['Flavour'] ??
        widget.variation.attributeValues['Flavor'] ??
        widget.variation.attributeValues['flavor'];

    if (color != null && color.isNotEmpty) {
      widget.cubit.applyImageToColorVariations(color, _currentPreviewUrl);
      Navigator.of(context).pop();
      HelperFun.successSnackbar(
        'bulk_applied_title'.tr,
        'applied_to_color_msg'.trParams({'color': color}),
      );
    } else if (flavor != null && flavor.isNotEmpty) {
      widget.cubit.applyImageToFlavorVariations(flavor, _currentPreviewUrl);
      Navigator.of(context).pop();
      HelperFun.successSnackbar(
        'bulk_applied_title'.tr,
        'applied_to_flavor_msg'.trParams({'flavor': flavor}),
      );
    } else {
      _applySingle();
    }
  }

  void _applyToAll() {
    widget.cubit.applyImageToAllVariations(_currentPreviewUrl);
    Navigator.of(context).pop();
    HelperFun.successSnackbar(
      'applied_to_all_title'.tr,
      'applied_to_all_msg'.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    final colorVal =
        widget.variation.attributeValues['Color'] ??
        widget.variation.attributeValues['color'];
    final flavorVal =
        widget.variation.attributeValues['Flavour'] ??
        widget.variation.attributeValues['Flavor'] ??
        widget.variation.attributeValues['flavor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DualImagePickerField(
          initialUrl: _currentPreviewUrl,
          label: 'variation_image_url_label',
          storageFolder: 'variations',
          customFileName: widget.variation.sku.isNotEmpty
              ? 'var_${widget.variation.sku.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}'
              : null,
          onImageChanged: (url) {
            setState(() {
              _currentPreviewUrl = url;
            });
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Quick Gallery from existing product images
        if (widget.existingProductImages.isNotEmpty) ...[
          Text(
            'choose_from_existing_photos'.tr,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.existingProductImages.map((img) {
                final isSelected = _currentPreviewUrl == img;

                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentPreviewUrl = img;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColor.primary
                              : (isDark
                                    ? AppColor.darkBorder
                                    : AppColor.lightBorder),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_rounded, size: 16),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        const Divider(height: 24),

        // Action Buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            if (colorVal != null && colorVal.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _currentPreviewUrl.isNotEmpty
                    ? _applyToMatchingAttribute
                    : null,
                icon: const Icon(Icons.color_lens_outlined, size: 16),
                label: Text('apply_to_all_color'.trParams({'color': colorVal})),
              )
            else if (flavorVal != null && flavorVal.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _currentPreviewUrl.isNotEmpty
                    ? _applyToMatchingAttribute
                    : null,
                icon: const Icon(Icons.local_florist_outlined, size: 16),
                label: Text('apply_to_all_flavor'.trParams({'flavor': flavorVal})),
              ),
            OutlinedButton.icon(
              onPressed: _currentPreviewUrl.isNotEmpty ? _applyToAll : null,
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: Text('apply_to_all_variations'.tr),
            ),
            ElevatedButton.icon(
              onPressed: _applySingle,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text('save_for_this_variation'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
