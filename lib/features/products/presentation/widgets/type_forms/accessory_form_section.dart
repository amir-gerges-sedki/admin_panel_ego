import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../common/widgets/image_picker/dual_image_picker_field.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/color_utils.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../cubit/product_form_cubit.dart';
import '../color_palette_picker_dialog.dart';
import '../product_selector_dialog.dart';
import 'form_section_header.dart';

class AccessoryFormSection extends StatelessWidget {
  const AccessoryFormSection({super.key});

  static const _accentColor = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();
        final productImages = [
          if (state.thumbnail.isNotEmpty) state.thumbnail,
          ...state.images,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ─────────────────────────────────────────
            buildSectionHeader(
              context,
              title: 'مواصفات الملحقات والإكسسوارات (Accessory Specs)',
              subtitle:
                  'أضف صور الملحق وألوانه بسهولة وبشكل اختياري لتوليد المتغيرات والأسعار',
              icon: Icons.handyman_rounded,
              color: _accentColor,
            ),
            const SizedBox(height: AppSizes.md),

            // ── Card 1: Images & Colors ─────────────────────────────────
            _buildCard(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header with Primary Actions
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 620;
                      final titleWidget = Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.collections_rounded,
                                size: 16, color: _accentColor),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'صور وألوان الملحق (Images & Colors)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'أضف صور الملحق واربطها بالألوان (اختياري) عبر المنتقي البصري',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actionButtons = Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          // 1. Add Image Button
                          ElevatedButton.icon(
                            onPressed: () => _showAddImageDialog(
                              context,
                              cubit,
                              isDark,
                              state,
                            ),
                            icon: const Icon(Icons.add_photo_alternate_rounded,
                                size: 15),
                            label: const Text(
                              '+ إضافة صورة',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),

                          // 2. Add Color via Palette Picker Button
                          OutlinedButton.icon(
                            onPressed: () {
                              ColorPalettePickerDialog.show(
                                context,
                                onColorSelected: (color) {
                                  cubit.addCustomColor(color);
                                  HelperFun.successSnackbar(
                                    'تمت إضافة اللون',
                                    'تمت إضافة اللون "$color" بنجاح.',
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.colorize_rounded, size: 14),
                            label: const Text(
                              '+ إضافة لون (المنتقي)',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: const BorderSide(color: _accentColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            titleWidget,
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: actionButtons,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleWidget),
                          const SizedBox(width: 8),
                          actionButtons,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Sub-section A: Visual Image Gallery ──────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColor.darkBorder
                            : AppColor.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_library_outlined,
                                      size: 15, color: _accentColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'صور الملحق (${productImages.length})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _showAddImageDialog(
                                context,
                                cubit,
                                isDark,
                                state,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 14),
                              label: const Text('إضافة صورة',
                                  style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                foregroundColor: _accentColor,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (productImages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'لم يتم رفع أي صور للملحق بعد. اضغط على "+ إضافة صورة" لرفع صور الملحق وربطها بالألوان.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColor.textMutedDark
                                          : AppColor.textMutedLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: productImages.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, idx) {
                                final img = productImages[idx];
                                final isThumb = state.thumbnail == img;
                                final matchedColor = state.colorImages.entries
                                    .where((e) => e.value == img)
                                    .map((e) => e.key)
                                    .firstOrNull;

                                return InkWell(
                                  onTap: () => _showImageDetailsDialog(
                                    context,
                                    cubit,
                                    isDark,
                                    state,
                                    img,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 86,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isThumb
                                            ? Colors.amber.shade600
                                            : (matchedColor != null
                                                ? _accentColor
                                                : (isDark
                                                    ? AppColor.darkBorder
                                                    : AppColor.lightBorder)),
                                        width: isThumb || matchedColor != null
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          child: Image.network(
                                            img,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                size: 20,
                                                color: AppColor.error,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Main thumbnail badge
                                        if (isThumb)
                                          Positioned(
                                            top: 3,
                                            right: 3,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.star,
                                                      size: 8,
                                                      color: Colors.white),
                                                  SizedBox(width: 1),
                                                  Text(
                                                    'رئيسية',
                                                    style: TextStyle(
                                                      fontSize: 7.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                        // Quick Delete Button
                                        Positioned(
                                          top: 3,
                                          left: 3,
                                          child: InkWell(
                                            onTap: () => cubit
                                                .removeProductImageUrl(img),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(2.5),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Bottom Color Status Banner
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2, horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: matchedColor != null
                                                  ? Colors.black87
                                                  : Colors.black54,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft: Radius.circular(6),
                                                bottomRight: Radius.circular(6),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (matchedColor != null) ...[
                                                  ColorUtils
                                                      .buildColorIndicator(
                                                          matchedColor,
                                                          size: 8),
                                                  const SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      matchedColor,
                                                      style: const TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const Text(
                                                    '📷 عامة',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sub-section B: Colors List ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.palette_outlined,
                                size: 15, color: _accentColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'ألوان الملحق (${state.selectedColors.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          ColorPalettePickerDialog.show(
                            context,
                            onColorSelected: (color) {
                              cubit.addCustomColor(color);
                              HelperFun.successSnackbar(
                                'تمت إضافة اللون',
                                'تمت إضافة اللون "$color" بنجاح.',
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.colorize_rounded, size: 14),
                        label: const Text('+ إضافة لون من المنتقي',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: _accentColor,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Active Selected Colors Wrap
                  if (state.selectedColors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'لا توجد ألوان مضافة بعد. يمكنك المتابعة بدون ألوان لإنشاء صنف قياسي موحد بالصور العامة، أو إضافة ألوان لإنشاء متغيرات بالأسعار والصور لكل لون.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColor.textMutedDark
                              : AppColor.textMutedLight,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.selectedColors.map((color) {
                        final img = state.colorImages[color] ?? '';
                        final hasImg = img.isNotEmpty;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColor.darkCard
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasImg
                                  ? _accentColor
                                  : (isDark
                                      ? AppColor.darkBorder
                                      : AppColor.lightBorder),
                              width: hasImg ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorUtils.buildColorIndicator(color, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                color,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Image status badge / action button
                              InkWell(
                                onTap: () => _showColorImagePicker(
                                  context,
                                  cubit,
                                  isDark,
                                  state,
                                  color,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasImg
                                        ? _accentColor.withValues(alpha: 0.15)
                                        : (isDark
                                            ? Colors.white10
                                            : Colors.black
                                                .withValues(alpha: 0.05)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: hasImg
                                          ? _accentColor
                                          : Colors.grey.shade400,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasImg) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          child: Image.network(
                                            img,
                                            width: 14,
                                            height: 14,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                              Icons.broken_image_rounded,
                                              size: 12,
                                              color: AppColor.error,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'صورة',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _accentColor,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 3),
                                        const Text(
                                          '+ صورة',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Delete color button
                              InkWell(
                                onTap: () => cubit.toggleColor(color),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Card 2: Compatible Products (Devices & Tanks) ─────────────
            _buildCard(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 620;
                      final titleWidget = Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.link_rounded,
                                size: 16, color: _accentColor),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الأجهزة والتانكات المتوافقة (Compatible Products)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'اختر الأجهزة أو التانكات المتوافقة مع هذا الملحق لربطها وعرضها في صفحة تفاصيل المنتج بتطبيق المستخدم',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final pickerBtn = ElevatedButton.icon(
                        onPressed: () {
                          ProductSelectorDialog.show(
                            context,
                            initialSelectedIds: state.compatibleProductIds,
                            onSelected: (selected) =>
                                cubit.setCompatibleProducts(selected),
                          );
                        },
                        icon: const Icon(Icons.add_link_rounded, size: 15),
                        label: const Text(
                          'اختيار الأجهزة المتوافقة',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            titleWidget,
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: pickerBtn,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleWidget),
                          const SizedBox(width: 8),
                          pickerBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  if (state.compatibleProducts.isEmpty &&
                      state.compatibleProductIds.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColor.darkBorder
                              : AppColor.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لم يتم ربط أجهزة أو تانكات بعد. اضغط على زر "اختيار الأجهزة المتوافقة" للبحث والاختيار من المنتجات المتاحة.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColor.textMutedDark
                                    : AppColor.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.compatibleProducts.isNotEmpty
                          ? state.compatibleProducts.map((p) {
                              return Chip(
                                avatar: p.thumbnail.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(3),
                                        child: Image.network(
                                          p.thumbnail,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(
                                            Icons.devices_other_rounded,
                                            size: 14,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.devices_other_rounded,
                                        size: 14,
                                      ),
                                label: Text(
                                  '${p.brand.name.isNotEmpty ? "${p.brand.name} " : ""}${p.displayTitle}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon:
                                    const Icon(Icons.close, size: 14),
                                onDeleted: () =>
                                    cubit.removeCompatibleProduct(p.id),
                                backgroundColor: _accentColor
                                    .withValues(alpha: 0.12),
                                side: BorderSide(
                                  color: _accentColor
                                      .withValues(alpha: 0.3),
                                ),
                              );
                            }).toList()
                          : state.compatibleProductIds.map((id) {
                              return Chip(
                                label: Text('ID: $id',
                                    style: const TextStyle(fontSize: 11)),
                                deleteIcon:
                                    const Icon(Icons.close, size: 14),
                                onDeleted: () =>
                                    cubit.removeCompatibleProduct(id),
                                backgroundColor: _accentColor
                                    .withValues(alpha: 0.12),
                              );
                            }).toList(),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddImageDialog(
    BuildContext context,
    ProductFormCubit cubit,
    bool isDark,
    ProductFormState state,
  ) {
    String previewUrl = '';
    bool setAsThumbnail = state.thumbnail.isEmpty;
    String? selectedColor;

    final availableImages = [
      if (state.thumbnail.isNotEmpty) state.thumbnail,
      ...state.images,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_photo_alternate_rounded,
                    color: _accentColor, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إضافة صورة للملحق',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DualImagePickerField(
                      initialUrl: previewUrl,
                      label: 'رابط أو رفع الصورة',
                      storageFolder: 'products',
                      customFileName: state.title.trim().isNotEmpty
                          ? 'acc_${state.title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}'
                          : null,
                      onImageChanged: (url) {
                        setModalState(() => previewUrl = url);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: setAsThumbnail,
                          activeColor: _accentColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setModalState(() =>
                                setAsThumbnail = val ?? false);
                          },
                        ),
                        const Text(
                          'تعيين كصورة رئيسية (Thumbnail)',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),

                    if (availableImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'أو اختر من صور المنتج المرفوعة:',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableImages.toSet().map((img) {
                            final isSel = previewUrl == img;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() => previewUrl = img);
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSel
                                          ? _accentColor
                                          : Colors.grey.shade400,
                                      width: isSel ? 2.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image_rounded,
                                        size: 14),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Color linking section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ربط الصورة بلون (اختياري):',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ColorPalettePickerDialog.show(
                              context,
                              onColorSelected: (color) {
                                cubit.addCustomColor(color);
                                setModalState(() => selectedColor = color);
                              },
                            );
                          },
                          icon: const Icon(Icons.colorize_rounded,
                              size: 14, color: _accentColor),
                          label: const Text('اختيار من المنتقي',
                              style: TextStyle(
                                  fontSize: 11, color: _accentColor)),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // General option
                        ChoiceChip(
                          label: const Text('📷 صورة عامة (بدون لون)',
                              style: TextStyle(fontSize: 11)),
                          selected: selectedColor == null,
                          selectedColor: _accentColor.withValues(alpha: 0.15),
                          onSelected: (_) {
                            setModalState(() => selectedColor = null);
                          },
                        ),
                        // Existing colors
                        ...state.selectedColors.map((c) {
                          final isSel = selectedColor == c;
                          return ChoiceChip(
                            avatar: ColorUtils.buildColorIndicator(c, size: 14),
                            label: Text(ColorUtils.getReadableColorName(c),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                            selected: isSel,
                            selectedColor: _accentColor.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setModalState(() => selectedColor = c);
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  final imgUrl = previewUrl.trim();
                  if (imgUrl.isEmpty) {
                    HelperFun.warningSnackbar(
                      title: 'warning'.tr,
                      message: 'image_url_hint'.tr,
                    );
                    return;
                  }

                  cubit.addProductImage(imgUrl);
                  if (setAsThumbnail) {
                    cubit.setThumbnail(imgUrl);
                  }
                  if (selectedColor != null && selectedColor!.isNotEmpty) {
                    cubit.setColorImage(selectedColor!, imgUrl);
                  }

                  Navigator.of(ctx).pop();
                  HelperFun.successSnackbar(
                    'upload_success_title'.tr,
                    'upload_success_msg'.tr,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('save_image_btn'.tr),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImageDetailsDialog(
    BuildContext context,
    ProductFormCubit cubit,
    bool isDark,
    ProductFormState state,
    String imageUrl,
  ) {
    final matchedColor = state.colorImages.entries
        .where((e) => e.value == imageUrl)
        .map((e) => e.key)
        .firstOrNull;

    String? selectedColor = matchedColor;
    final isThumb = state.thumbnail == imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: _accentColor, size: 22),
                SizedBox(width: 8),
                Text(
                  'خيارات صورة الملحق',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _accentColor, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.broken_image_rounded,
                                  size: 28),
                            ),
                          ),
                          if (isThumb)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 10, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      'رئيسية',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick thumbnail set button
                    if (!isThumb) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          cubit.setThumbnail(imageUrl);
                          Navigator.of(ctx).pop();
                          HelperFun.successSnackbar('تم التحديث',
                              'تم تعيين هذه الصورة كصورة رئيسية للمنتج.');
                        },
                        icon: const Icon(Icons.star_border_rounded,
                            size: 16, color: Colors.amber),
                        label: const Text(
                          'تعيين كصورة رئيسية للمنتج (Main Thumbnail)',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade800,
                          side: BorderSide(color: Colors.amber.shade600),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ربط الصورة بلون:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ColorPalettePickerDialog.show(
                              context,
                              onColorSelected: (color) {
                                cubit.addCustomColor(color);
                                setModalState(() => selectedColor = color);
                              },
                            );
                          },
                          icon: const Icon(Icons.colorize_rounded,
                              size: 14, color: _accentColor),
                          label: const Text('اختيار من المنتقي',
                              style: TextStyle(
                                  fontSize: 11, color: _accentColor)),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('📷 صورة عامة (بدون لون)',
                              style: TextStyle(fontSize: 11)),
                          selected: selectedColor == null,
                          selectedColor: _accentColor.withValues(alpha: 0.15),
                          onSelected: (_) {
                            setModalState(() => selectedColor = null);
                          },
                        ),
                        ...state.selectedColors.map((c) {
                          final isSel = selectedColor == c;
                          return ChoiceChip(
                            avatar: ColorUtils.buildColorIndicator(c, size: 14),
                            label: Text(ColorUtils.getReadableColorName(c),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                            selected: isSel,
                            selectedColor: _accentColor.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setModalState(() => selectedColor = c);
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  cubit.removeProductImageUrl(imageUrl);
                  Navigator.of(ctx).pop();
                  HelperFun.successSnackbar(
                      'تم الحذف', 'تم حذف الصورة من المنتج.');
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColor.error),
                label: const Text('حذف الصورة',
                    style: TextStyle(color: AppColor.error)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedColor != null && selectedColor!.isNotEmpty) {
                    cubit.setColorImage(selectedColor!, imageUrl);
                  } else {
                    if (matchedColor != null) {
                      cubit.setColorImage(matchedColor, '');
                    }
                  }

                  Navigator.of(ctx).pop();
                  HelperFun.successSnackbar(
                      'تم الحفظ', 'تم تحديث إعدادات الصورة بنجاح.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorImagePicker(
    BuildContext context,
    ProductFormCubit cubit,
    bool isDark,
    ProductFormState state,
    String color,
  ) {
    final currentUrl = state.colorImages[color] ?? '';
    final urlController = TextEditingController(text: currentUrl);
    String previewUrl = currentUrl;

    final availableImages = [
      if (state.thumbnail.isNotEmpty) state.thumbnail,
      ...state.images,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                ColorUtils.buildColorIndicator(color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'صورة اللون (${ColorUtils.getReadableColorName(color)})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColor.darkSubCard
                              : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: previewUrl.isNotEmpty
                                ? _accentColor
                                : Colors.grey.shade400,
                            width: previewUrl.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: previewUrl.isNotEmpty
                            ? Image.network(
                                previewUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: AppColor.error,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'رابط الصورة (Image URL)',
                        hintText: 'https://example.com/accessory.png',
                        isDense: true,
                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        suffixIcon: urlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  urlController.clear();
                                  setModalState(() => previewUrl = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setModalState(() => previewUrl = val.trim());
                      },
                    ),

                    if (availableImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'أو اختر من صور المنتج المرفوعة:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableImages.toSet().map((img) {
                            final isSelected = previewUrl == img;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () {
                                  urlController.text = img;
                                  setModalState(() => previewUrl = img);
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? _accentColor
                                          : Colors.grey.shade400,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.broken_image_rounded,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (currentUrl.isNotEmpty)
                TextButton(
                  onPressed: () {
                    cubit.setColorImage(color, '');
                    Navigator.of(ctx).pop();
                    HelperFun.successSnackbar(
                      'تمت الإزالة',
                      'تم حذف صورة اللون "$color".',
                    );
                  },
                  child: const Text(
                    'إزالة الصورة',
                    style: TextStyle(color: AppColor.error),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final finalUrl = previewUrl.trim();
                  if (finalUrl.isNotEmpty) {
                    cubit.addProductImage(finalUrl);
                  }
                  cubit.setColorImage(color, finalUrl);
                  Navigator.of(ctx).pop();
                  HelperFun.successSnackbar(
                    'تم حفظ الصورة',
                    'تم تعيين صورة اللون "$color" بنجاح.',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ الصورة'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: child,
    );
  }
}
