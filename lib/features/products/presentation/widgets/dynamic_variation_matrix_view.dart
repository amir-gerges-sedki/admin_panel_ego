import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../cubit/product_form_cubit.dart';
import 'variation_image_dialog.dart';

class DynamicVariationMatrixView extends StatefulWidget {
  const DynamicVariationMatrixView({super.key});

  @override
  State<DynamicVariationMatrixView> createState() =>
      _DynamicVariationMatrixViewState();
}

class _DynamicVariationMatrixViewState
    extends State<DynamicVariationMatrixView> {
  late TextEditingController _bulkPriceController;
  late TextEditingController _bulkSalePriceController;
  late TextEditingController _bulkStockController;

  @override
  void initState() {
    super.initState();
    _bulkPriceController = TextEditingController(text: '450');
    _bulkSalePriceController = TextEditingController(text: '450');
    _bulkStockController = TextEditingController(text: '20');
  }

  @override
  void dispose() {
    _bulkPriceController.dispose();
    _bulkSalePriceController.dispose();
    _bulkStockController.dispose();
    super.dispose();
  }

  void _applyBulk() {
    final price = double.tryParse(_bulkPriceController.text) ?? 0.0;
    final sale = double.tryParse(_bulkSalePriceController.text) ?? price;
    final stock = int.tryParse(_bulkStockController.text) ?? 0;

    context.read<ProductFormCubit>().applyBulkPriceAndStock(price, sale, stock);
    HelperFun.successSnackbar(
      'تم تحديث الكل',
      'تم تطبيق السعر ($price ج.م) والمخزون ($stock) على جميع المتغيرات.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();
        final vars = state.variations;
        final color = state.categoryType.accentColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar Banner
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hub_rounded, size: 20, color: color),
                          const SizedBox(width: 8),
                          Text(
                            'مصفوفة متغيرات الصنف (${vars.length} عنصر مفعل)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColor.textPrimaryDark
                                  : AppColor.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'يتم توليد الـ SKUs والأسعار والمخزون تلقائياً وفقاً للمواصفات والنكهات المختارة',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      cubit.generateDynamicVariations();
                      HelperFun.successSnackbar(
                        'تم التوليد',
                        'تم توليد مصفوفة المتغيرات بنجاح.',
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('توليد المصفوفة الآن (Generate Matrix)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Bulk Editor Bar
            if (vars.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColor.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'تعديل جماعي سريع:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: TextField(
                        controller: _bulkPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر الأساسي (ج.م)',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _bulkSalePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سعر العرض (ج.م)',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _bulkStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية / المخزون',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyBulk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('تطبيق على الكل'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      tooltip: 'تطبيق صورة جماعية على المتغيرات',
                      onPressed: () {
                        if (vars.isNotEmpty) {
                          VariationImageDialog.show(
                            context,
                            variationIndex: 0,
                            variation: vars.first,
                            cubit: cubit,
                            existingProductImages: [
                              if (state.thumbnail.isNotEmpty) state.thumbnail,
                              ...state.images,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: AppColor.error,
                        size: 20,
                      ),
                      tooltip: 'حذف جميع المتغيرات',
                      onPressed: () => cubit.clearVariations(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Variations Table or Empty State
            if (vars.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.view_in_ar_rounded,
                        size: 36,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'لم يتم توليد مصفوفة المتغيرات بعد',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط على زر "توليد مصفوفة المتغيرات" لإنشاء توليفة تلقائية من الـ SKUs والأسعار والمخزون بناءً على الخيارات السابقة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton.icon(
                      onPressed: () => cubit.generateDynamicVariations(),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('توليد المصفوفة تلقائياً'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vars.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final v = vars[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Variation Image Thumbnail / Picker
                          InkWell(
                            onTap: () {
                              VariationImageDialog.show(
                                context,
                                variationIndex: index,
                                variation: v,
                                cubit: cubit,
                                existingProductImages: [
                                  if (state.thumbnail.isNotEmpty)
                                    state.thumbnail,
                                  ...state.images,
                                ],
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Tooltip(
                              message: v.image.isNotEmpty
                                  ? 'تعديل صورة المتغير (${v.sku})'
                                  : 'إضافة صورة مخصصة لهذا المتغير',
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColor.darkSubCard
                                      : AppColor.lightSubCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: v.image.isNotEmpty
                                        ? const Color(0xFF6366F1)
                                        : (isDark
                                              ? AppColor.darkBorder
                                              : AppColor.lightBorder),
                                    width: v.image.isNotEmpty ? 1.5 : 1,
                                  ),
                                ),
                                child: v.image.isNotEmpty
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            child: Image.network(
                                               v.image,
                                               width: 44,
                                               height: 44,
                                               fit: BoxFit.cover,
                                               errorBuilder:
                                                   (context, error, stackTrace) =>
                                                       const Center(
                                                         child: Icon(
                                                           Icons
                                                               .broken_image_rounded,
                                                           size: 18,
                                                           color: Colors.grey,
                                                         ),
                                                       ),
                                             ),
                                          ),
                                          Positioned(
                                            bottom: 1,
                                            right: 1,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 8,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 16,
                                            color: color,
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'صورة',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // SKU & Attributes
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      v.sku,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: v.attributeValues.entries.map((e) {
                                    return _buildAttributeTag(e.key, e.value);
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Price input
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: v.salePrice.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'السعر (ج.م)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                              onChanged: (val) {
                                final p = double.tryParse(val) ?? v.salePrice;
                                cubit.updateVariationRow(
                                  index,
                                  v.copyWith(salePrice: p, price: p),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Stock input
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: v.stock.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'المخزون',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                              onChanged: (val) {
                                final s = int.tryParse(val) ?? v.stock;
                                cubit.updateVariationRow(
                                  index,
                                  v.copyWith(stock: s),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Delete Row
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColor.error,
                            ),
                            tooltip: 'حذف هذا المتغير',
                            onPressed: () => cubit.removeVariationRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAttributeTag(String key, String value) {
    Color tagColor = AppColor.primary;
    final k = key.toLowerCase();
    final isColor = k.contains('color');

    if (k.contains('flavor') || k.contains('flavour')) {
      tagColor = const Color(0xFF10B981); // Emerald
    } else if (k.contains('style') || k.contains('mtl') || k.contains('dl')) {
      tagColor = const Color(0xFF8B5CF6); // Purple
    } else if (k.contains('nic')) {
      tagColor = const Color(0xFFF59E0B); // Amber
    } else if (k.contains('size') || k.contains('capacity')) {
      tagColor = const Color(0xFF0EA5E9); // Cyan
    } else if (isColor) {
      tagColor = const Color(0xFFEC4899); // Pink
    } else if (k.contains('res') || k.contains('ohm')) {
      tagColor = const Color(0xFFF97316); // Orange
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tagColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isColor) ...[
            ColorUtils.buildColorIndicator(value, size: 10),
            const SizedBox(width: 4),
          ],
          Text(
            '$key: $value',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }
}
