import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/image_picker/dual_image_picker_field.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_form_cubit.dart';
import 'color_palette_picker_dialog.dart';
import 'product_selector_dialog.dart';

class DynamicTypeFormSection extends StatelessWidget {
  const DynamicTypeFormSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        switch (state.categoryType) {
          case ProductCategoryType.liquid:
            return const LiquidFormSection();
          case ProductCategoryType.disposable:
            return const DisposableFormSection();
          case ProductCategoryType.device:
            return const DeviceFormSection();
          case ProductCategoryType.pod:
          case ProductCategoryType.coil:
            return const CoilsAndCartridgesFormSection();
          case ProductCategoryType.accessory:
            return const AccessoryFormSection();
        }
      },
    );
  }
}

// ----------------------------------------------------------------------
// 1. LIQUID FORM SECTION
// ----------------------------------------------------------------------
class LiquidFormSection extends StatefulWidget {
  const LiquidFormSection({super.key});

  @override
  State<LiquidFormSection> createState() => _LiquidFormSectionState();
}

class _LiquidFormSectionState extends State<LiquidFormSection> {
  final TextEditingController _customFlavorController = TextEditingController();
  final TextEditingController _customNicController = TextEditingController();
  final TextEditingController _customSizeController = TextEditingController();

  @override
  void dispose() {
    _customFlavorController.dispose();
    super.dispose();
  }

  void _showAddFlavorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF0EA5E9), size: 22),
            const SizedBox(width: 8),
            Text('add_flavor_dialog_title'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: _customFlavorController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم النكهة / Flavor Name',
            hintText: 'e.g. Watermelon Ice / Tobacco Gold',
          ),
          onSubmitted: (_) {
            _addFlavorAndClose(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => _addFlavorAndClose(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            child: Text('add_flavor_btn'.tr),
          ),
        ],
      ),
    );
  }

  void _addFlavorAndClose(BuildContext ctx) {
    final text = _customFlavorController.text.trim();
    if (text.isNotEmpty) {
      context.read<ProductFormCubit>().addCustomFlavor(text);
      _customFlavorController.clear();
      Navigator.of(ctx).pop();
      HelperFun.successSnackbar('تمت إضافة النكهة', 'تمت إضافة "$text" وتفعيلها لهذا الصنف.');
    }
  }

  Widget _buildOriginOptionTile({
    required BuildContext context,
    required String title,
    required String flagEmoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = HelperFun.isDarkMode(context);
    const activeColor = Color(0xFF0EA5E9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.25)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVapeStyleCheckboxTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    final isDark = HelperFun.isDarkMode(context);
    const activeColor = Color(0xFF8B5CF6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked
              ? activeColor.withValues(alpha: isDark ? 0.20 : 0.10)
              : (isDark ? AppColor.darkCard : AppColor.lightCard),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          border: Border.all(
            color: isChecked
                ? activeColor
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isChecked ? 1.8 : 1.0,
          ),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked
                      ? activeColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.25)),
                  width: isChecked ? 1.5 : 1.2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 18,
              color: isChecked
                  ? activeColor
                  : (isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();
        final bool hasMtl = state.vapeStyle == 'MTL' || state.vapeStyle == 'BOTH';
        final bool hasDl = state.vapeStyle == 'DL' || state.vapeStyle == 'BOTH';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Banner
            _buildSectionHeader(
              context,
              title: isArabic ? 'مواصفات السائل والنكهات' : 'E-Liquid Specifications',
              subtitle: isArabic
                  ? 'أضف النكهات المتاحة، نمط السحب MTL/DL، ونسب النيكوتين وحجم العبوات'
                  : 'Manage flavors, MTL/DL vape styles, nicotine strengths, and bottle sizes',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: AppSizes.md),

            // Liquid Origin / Classification Selector (Prominent high-contrast)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(
                  AppSizes.borderRadiusMd,
                ),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;

                  final headerPart = Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic ? 'مصدر وتصنيف السائل:' : 'Liquid Origin & Classification:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );

                  final buttonsPart = Row(
                    mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      isCompact
                          ? Expanded(
                              child: _buildOriginOptionTile(
                                context: context,
                                title: isArabic ? 'سائل محلي' : 'Local Liquid',
                                flagEmoji: '🇪🇬',
                                isSelected: state.liquidOrigin == 'Local',
                                onTap: () => cubit.setLiquidOrigin('Local'),
                              ),
                            )
                          : _buildOriginOptionTile(
                              context: context,
                              title: isArabic ? 'سائل محلي' : 'Local Liquid',
                              flagEmoji: '🇪🇬',
                              isSelected: state.liquidOrigin == 'Local',
                              onTap: () => cubit.setLiquidOrigin('Local'),
                            ),
                      const SizedBox(width: 8),
                      isCompact
                          ? Expanded(
                              child: _buildOriginOptionTile(
                                context: context,
                                title: isArabic ? 'مستورد بريميوم' : 'Premium Liquid',
                                flagEmoji: '🌍',
                                isSelected: state.liquidOrigin == 'Premium',
                                onTap: () => cubit.setLiquidOrigin('Premium'),
                              ),
                            )
                          : _buildOriginOptionTile(
                              context: context,
                              title: isArabic ? 'مستورد بريميوم' : 'Premium Liquid',
                              flagEmoji: '🌍',
                              isSelected: state.liquidOrigin == 'Premium',
                              onTap: () => cubit.setLiquidOrigin('Premium'),
                            ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerPart,
                        const SizedBox(height: 8),
                        buttonsPart,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: headerPart),
                      const SizedBox(width: 12),
                      buttonsPart,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 1. Flavors Selector & Quick Add Flavor Button
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 430;

                      final titleWidget = Row(
                        children: [
                          const Icon(Icons.icecream_outlined, size: 18, color: Color(0xFF0EA5E9)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isArabic ? 'النكهات المتاحة' : 'Available Flavors',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );

                      final addBtn = ElevatedButton.icon(
                        onPressed: () => _showAddFlavorDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          isArabic ? 'أضف نكهة جديدة' : 'Add New Flavor',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
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
                              child: addBtn,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: titleWidget),
                          const SizedBox(width: 8),
                          addBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (state.availableFlavors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : AppColor.lightCard,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0EA5E9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'لا توجد نكهات مضافة بعد. اضغط "أضف نكهة جديدة" لإنشاء النكهة الأولى.'
                                  : 'No flavors available yet. Tap "Add New Flavor" to create the first flavor.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAddFlavorDialog(context),
                            child: Text(isArabic ? 'أضف الآن' : 'Add Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.availableFlavors.map((flavor) {
                        final isSelected = state.selectedFlavors.contains(flavor);
                        final isActive = state.activeFlavor == flavor;

                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(flavor),
                              if (isActive) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                          checkmarkColor: const Color(0xFF0EA5E9),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF0EA5E9) : null,
                          ),
                          onSelected: (val) {
                            cubit.toggleFlavorSelection(flavor);
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 2. Vaping Style (MTL / DL Checkboxes - Both button removed)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.air_rounded, size: 18, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isArabic ? 'نوع السحبة والاستخدام' : 'Vaping Inhalation Style',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 450;
                      final mtlTile = _buildVapeStyleCheckboxTile(
                        context: context,
                        title: isArabic ? 'MTL (سحبة سيجارة ضيقة)' : 'MTL (Mouth To Lung)',
                        subtitle: isArabic ? 'نيكوتين 6mg إلى 50mg' : '6mg to 50mg (Salt & High Nic)',
                        icon: Icons.smoking_rooms_rounded,
                        isChecked: hasMtl,
                        onTap: () => cubit.toggleVapeStyleOption('MTL'),
                      );
                      final dlTile = _buildVapeStyleCheckboxTile(
                        context: context,
                        title: isArabic ? 'DL (سحبة شيشة واسعة)' : 'DL (Direct To Lung)',
                        subtitle: isArabic ? 'نيكوتين 3mg و 6mg' : '3mg & 6mg (Freebase Sub-ohm)',
                        icon: Icons.cloud_queue_rounded,
                        isChecked: hasDl,
                        onTap: () => cubit.toggleVapeStyleOption('DL'),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            mtlTile,
                            const SizedBox(height: 8),
                            dlTile,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: mtlTile),
                          const SizedBox(width: AppSizes.md),
                          Expanded(child: dlTile),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            state.vapeStyle == 'DL'
                                ? (isArabic
                                      ? '⚡ نمط DL فقط: نيكوتين 3mg و 6mg (سحب كثيف وشيشة)'
                                      : '⚡ DL Only: 3mg & 6mg nicotines (Sub-ohm / Freebase)')
                                : state.vapeStyle == 'MTL'
                                    ? (isArabic
                                          ? '⚡ نمط MTL فقط: نيكوتين من 6mg إلى 50mg (سولت نيك)'
                                          : '⚡ MTL Only: 6mg to 50mg nicotines (Salt Nic)')
                                    : (isArabic
                                          ? '⚡ كلاهما مفعل (MTL & DL): يتم توليد DL لـ (3mg, 6mg) و MTL لـ (6mg إلى 50mg) تلقائياً'
                                          : '⚡ Both Active: Auto-generates DL (3mg, 6mg) and MTL (6mg to 50mg) variations'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 3. Nicotines & Bottle Sizes
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;

                final nicotinesCard = Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'نسب النيكوتين' : 'Nicotine Strengths',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: state.availableNicotines.map((nic) {
                          final isSel = state.selectedNicotines.contains(nic);
                          return FilterChip(
                            label: Text(nic, style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                            onSelected: (_) => cubit.toggleNicotine(nic),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customNicController,
                              decoration: InputDecoration(
                                hintText: isArabic ? '+ مخصص (مثال: 35mg)' : '+ Custom (e.g. 35mg)',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              cubit.addCustomNicotine(_customNicController.text);
                              _customNicController.clear();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final sizesCard = Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'حجم العبوة' : 'Bottle Sizes',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: state.availableSizes.map((size) {
                          final isSel = state.selectedSizes.contains(size);
                          return FilterChip(
                            label: Text(size, style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                            onSelected: (_) => cubit.toggleSize(size),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customSizeController,
                              decoration: InputDecoration(
                                hintText: isArabic ? '+ حجم مخصص (مثال: 50ml)' : '+ Custom (e.g. 50ml)',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              cubit.addCustomSize(_customSizeController.text);
                              _customSizeController.clear();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      nicotinesCard,
                      const SizedBox(height: AppSizes.md),
                      sizesCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: nicotinesCard),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: sizesCard),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 1.5. DISPOSABLE FORM SECTION (سحبات جاهزة)
// ----------------------------------------------------------------------
class DisposableFormSection extends StatefulWidget {
  const DisposableFormSection({super.key});

  @override
  State<DisposableFormSection> createState() => _DisposableFormSectionState();
}

class _DisposableFormSectionState extends State<DisposableFormSection> {
  final TextEditingController _customFlavorController = TextEditingController();
  final TextEditingController _customNicController = TextEditingController();
  final TextEditingController _puffsController = TextEditingController();
  final TextEditingController _batteryController = TextEditingController();
  final FocusNode _puffsFocusNode = FocusNode();
  final FocusNode _batteryFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductFormCubit>().state;
    _puffsController.text = state.puffsCount;
    _batteryController.text = state.disposableBatteryCapacity;

    _puffsFocusNode.addListener(() {
      if (!_puffsFocusNode.hasFocus && _puffsController.text.trim().isNotEmpty) {
        GlobalDisposableSpecsPool.addPuff(_puffsController.text.trim());
        if (mounted) setState(() {});
      }
    });

    _batteryFocusNode.addListener(() {
      if (!_batteryFocusNode.hasFocus && _batteryController.text.trim().isNotEmpty) {
        GlobalDisposableSpecsPool.addBattery(_batteryController.text.trim());
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _puffsFocusNode.dispose();
    _batteryFocusNode.dispose();
    _customFlavorController.dispose();
    _customNicController.dispose();
    _puffsController.dispose();
    _batteryController.dispose();
    super.dispose();
  }

  void _showAddFlavorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف نكهة جديدة (Add Flavor)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: _customFlavorController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم النكهة / Flavor Name',
            hintText: 'e.g. Watermelon Ice / Blue Razz Lemonade',
          ),
          onSubmitted: (_) {
            _addFlavorAndClose(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => _addFlavorAndClose(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            child: Text('add_flavor_btn'.tr),
          ),
        ],
      ),
    );
  }

  void _addFlavorAndClose(BuildContext ctx) {
    final text = _customFlavorController.text.trim();
    if (text.isNotEmpty) {
      context.read<ProductFormCubit>().addCustomFlavor(text);
      _customFlavorController.clear();
      Navigator.of(ctx).pop();
      HelperFun.successSnackbar(
        'تمت إضافة النكهة',
        'تمت إضافة "$text" وتفعيلها لهذا الصنف.',
      );
    }
  }

  Widget _buildVapeStyleCheckboxTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    final isDark = HelperFun.isDarkMode(context);
    const activeColor = Color(0xFFF59E0B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked
              ? activeColor.withValues(alpha: isDark ? 0.20 : 0.10)
              : (isDark ? AppColor.darkCard : AppColor.lightCard),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          border: Border.all(
            color: isChecked
                ? activeColor
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isChecked ? 1.8 : 1.0,
          ),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked
                      ? activeColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.25)),
                  width: isChecked ? 1.5 : 1.2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 18,
              color: isChecked
                  ? activeColor
                  : (isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listenWhen: (prev, curr) =>
          prev.puffsCount != curr.puffsCount ||
          prev.disposableBatteryCapacity != curr.disposableBatteryCapacity,
      listener: (context, state) {
        if (_puffsController.text != state.puffsCount) {
          _puffsController.text = state.puffsCount;
        }
        if (_batteryController.text != state.disposableBatteryCapacity) {
          _batteryController.text = state.disposableBatteryCapacity;
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();
        final bool hasMtl =
            state.vapeStyle == 'MTL' || state.vapeStyle == 'BOTH';
        final bool hasDl = state.vapeStyle == 'DL' || state.vapeStyle == 'BOTH';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Banner
            _buildSectionHeader(
              context,
              title: isArabic
                  ? 'مواصفات السحبات الجاهزة (Disposable)'
                  : 'Disposable Vape Specifications',
              subtitle: isArabic
                  ? 'حدد النكهات، عدد السحبات (Puffs)، سعة البطارية، ونمط السحب MTL/DL'
                  : 'Configure flavors, puffs count, battery capacity, and MTL/DL vaping style',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: AppSizes.md),

            // 1. Puffs & Battery Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;

                final puffsCard = Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.speed_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'عدد السحبات (Puffs)'
                                  : 'Puffs Count',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextField(
                        controller: _puffsController,
                        focusNode: _puffsFocusNode,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'عدد السحبات / Puffs'
                              : 'Number of Puffs',
                          hintText: 'e.g. 5000 / 8000 / 12000',
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.cloud_queue_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        onChanged: (val) {
                          cubit.updateDisposableSpecs(puffsCount: val.trim());
                        },
                        onSubmitted: (val) {
                          final clean = val.trim();
                          if (clean.isNotEmpty) {
                            GlobalDisposableSpecsPool.addPuff(clean);
                            setState(() {});
                          }
                        },
                      ),
                      if (GlobalDisposableSpecsPool.puffOptions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          isArabic ? 'خيارات سابقة مسجلة:' : 'Previously Used Options:',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: GlobalDisposableSpecsPool.puffOptions.map((preset) {
                            final isSel =
                                state.puffsCount == preset;
                            return ChoiceChip(
                              label: Text(
                                preset.toLowerCase().contains('puff')
                                    ? preset
                                    : '$preset Puffs',
                                style: const TextStyle(fontSize: 10.5),
                              ),
                              selected: isSel,
                              selectedColor:
                                  const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              onSelected: (selected) {
                                final newVal = selected ? preset : '';
                                _puffsController.text = newVal;
                                cubit.updateDisposableSpecs(
                                  puffsCount: newVal,
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );

                final batteryCard = Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.battery_charging_full_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'سعة البطارية (Battery Capacity)'
                                  : 'Battery Capacity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      TextField(
                        controller: _batteryController,
                        focusNode: _batteryFocusNode,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'سعة البطارية / Battery'
                              : 'Battery Capacity',
                          hintText: 'e.g. 650mAh (Rechargeable)',
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.battery_std_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        onChanged: (val) {
                          cubit.updateDisposableSpecs(
                            batteryCapacity: val.trim(),
                          );
                        },
                        onSubmitted: (val) {
                          final clean = val.trim();
                          if (clean.isNotEmpty) {
                            GlobalDisposableSpecsPool.addBattery(clean);
                            setState(() {});
                          }
                        },
                      ),
                      if (GlobalDisposableSpecsPool.batteryOptions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          isArabic ? 'خيارات سابقة مسجلة:' : 'Previously Used Options:',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: GlobalDisposableSpecsPool.batteryOptions.map((preset) {
                            final isSel = state.disposableBatteryCapacity
                                .toLowerCase() ==
                                preset.toLowerCase();
                            return ChoiceChip(
                              label: Text(
                                preset,
                                style: const TextStyle(fontSize: 10.5),
                              ),
                              selected: isSel,
                              selectedColor:
                                  const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              onSelected: (selected) {
                                final newVal = selected ? preset : '';
                                _batteryController.text = newVal;
                                cubit.updateDisposableSpecs(
                                  batteryCapacity: newVal,
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      puffsCard,
                      const SizedBox(height: AppSizes.md),
                      batteryCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: puffsCard),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: batteryCard),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // 2. Vape Style MTL / DL
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.air_rounded,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'نمط السحب (MTL / DL Vaping Style)'
                              : 'Vaping Style (MTL / DL)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 450;
                      final mtlTile = _buildVapeStyleCheckboxTile(
                        context: context,
                        title: 'MTL (سحبة سيجارة)',
                        subtitle: 'Mouth to Lung - سحب ضيق ناعم',
                        icon: Icons.air_outlined,
                        isChecked: hasMtl,
                        onTap: () {
                          if (hasMtl && hasDl) {
                            cubit.setVapeStyle('DL');
                          } else if (hasMtl && !hasDl) {
                            // Don't allow unchecking both
                          } else {
                            cubit.setVapeStyle('BOTH');
                          }
                        },
                      );
                      final dlTile = _buildVapeStyleCheckboxTile(
                        context: context,
                        title: 'DL / DTL (سحبة شيشة)',
                        subtitle: 'Direct Lung - سحب واسع وبخار كثيف',
                        icon: Icons.cloud_outlined,
                        isChecked: hasDl,
                        onTap: () {
                          if (hasDl && hasMtl) {
                            cubit.setVapeStyle('MTL');
                          } else if (hasDl && !hasMtl) {
                            // Don't allow unchecking both
                          } else {
                            cubit.setVapeStyle('BOTH');
                          }
                        },
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            mtlTile,
                            const SizedBox(height: 8),
                            dlTile,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: mtlTile),
                          const SizedBox(width: 10),
                          Expanded(child: dlTile),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 3. Nicotine Strengths
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic
                            ? 'نسب النيكوتين (Nicotine Strengths)'
                            : 'Nicotine Strengths',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.availableNicotines.map((nic) {
                      final isSel = state.selectedNicotines.contains(nic);
                      return FilterChip(
                        label: Text(nic, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.25),
                        checkmarkColor: const Color(0xFFF59E0B),
                        onSelected: (_) => cubit.toggleNicotine(nic),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customNicController,
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? '+ إضافة نسبة نيكوتين مخصصة (مثال: 20mg أو 50mg أو 5%)'
                                : '+ Add custom nicotine (e.g. 20mg, 50mg, 5%)',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              cubit.addCustomNicotine(val.trim());
                              _customNicController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_customNicController.text.trim().isNotEmpty) {
                            cubit.addCustomNicotine(_customNicController.text.trim());
                            _customNicController.clear();
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(isArabic ? 'إضافة' : 'Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 4. Flavors Selector & Quick Add Flavor Button
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 430;

                      final titlePart = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.icecream_outlined,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? 'النكهات المتاحة للسحبة' : 'Available Flavors',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );

                      final addBtn = ElevatedButton.icon(
                        onPressed: () => _showAddFlavorDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          isArabic ? 'أضف نكهة جديدة' : 'Add New Flavor',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            titlePart,
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: addBtn,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          titlePart,
                          addBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (state.availableFlavors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : AppColor.lightCard,
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'لا توجد نكهات مضافة بعد. اضغط "أضف نكهة جديدة" لإنشاء النكهة الأولى.'
                                  : 'No flavors available yet. Tap "Add New Flavor" to create the first flavor.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAddFlavorDialog(context),
                            child: Text(isArabic ? 'أضف الآن' : 'Add Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.availableFlavors.map((flavor) {
                        final isSelected =
                            state.selectedFlavors.contains(flavor);

                        return FilterChip(
                          label: Text(flavor),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.25),
                          checkmarkColor: const Color(0xFFF59E0B),
                          onSelected: (_) {
                            cubit.toggleFlavorSelection(flavor);
                          },
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
}

// ----------------------------------------------------------------------
// 2. DEVICE FORM SECTION
// ----------------------------------------------------------------------
class DeviceFormSection extends StatefulWidget {
  const DeviceFormSection({super.key});

  @override
  State<DeviceFormSection> createState() => _DeviceFormSectionState();
}

class _DeviceFormSectionState extends State<DeviceFormSection> {
  final TextEditingController _customColorController = TextEditingController();

  // All spec options (wattage, battery, charging port, screen, airflow) are
  // now stored in GlobalDeviceSpecsPool — a session-persistent pool that
  // seeds from Firestore products and accumulates values across product creation.

  @override
  void dispose() {
    _customColorController.dispose();
    super.dispose();
  }

  void _showAddWattageDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف قدرة وات جديدة (Add Wattage)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'الوات / Wattage',
            hintText: 'e.g. 28W أو 35W أو 250W',
          ),
          onSubmitted: (val) => _onWattageAdded(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _onWattageAdded(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  void _onWattageAdded(BuildContext ctx, String raw) {
    String clean = raw.trim();
    if (clean.isEmpty) return;
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      clean = '${clean}W';
    } else if (!clean.toUpperCase().endsWith('W') &&
        RegExp(r'^\d+\s*w?$', caseSensitive: false).hasMatch(clean)) {
      clean = '${clean.replaceAll(RegExp(r'\s'), '')}W';
    }
    GlobalDeviceSpecsPool.addWattage(clean);
    context.read<ProductFormCubit>().updateDeviceSpecs(maxWattage: clean);
    setState(() {}); // rebuild to show new chip
    Navigator.of(ctx).pop();
  }

  void _showAddBatteryCapacityDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_std_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف سعة بطارية جديدة (Battery Capacity)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'سعة البطارية / Capacity (mAh)',
            hintText: 'e.g. 1350mAh أو 1400mAh أو 3500mAh',
          ),
          onSubmitted: (val) => _onBatteryCapacityAdded(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _onBatteryCapacityAdded(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  void _onBatteryCapacityAdded(BuildContext ctx, String raw) {
    String clean = raw.trim();
    if (clean.isEmpty) return;
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      clean = '${clean}mAh';
    }
    GlobalDeviceSpecsPool.addBatteryCapacity(clean);
    context.read<ProductFormCubit>().updateDeviceSpecs(batteryCapacity: clean);
    setState(() {}); // rebuild to show new chip
    Navigator.of(ctx).pop();
  }

  void _showAddBatterySystemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final arController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_charging_full_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف نظام بطارية جديد (Battery System)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'نظام البطارية / System Name',
                hintText: 'e.g. Single 20700 Battery',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: arController,
              decoration: const InputDecoration(
                labelText: 'الوصف بالعربية (اختياري)',
                hintText: 'مثال: بطارية خارجية فردية (Single 20700)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final ar = arController.text.trim();
              final label = ar.isNotEmpty ? ar : name;
              GlobalDeviceSpecsPool.addBatterySystem(name, label);
              context.read<ProductFormCubit>().updateDeviceSpecs(batteryType: name);
              setState(() {}); // rebuild dropdown
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  void _showAddChargingPortDialog(BuildContext context) {
    final nameController = TextEditingController();
    final arController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.electrical_services_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف منفذ أو سرعة شحن جديدة (Charging Port)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم المنفذ / Port & Speed',
                hintText: 'e.g. USB Type-C 2.5A (Fast Charge)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: arController,
              decoration: const InputDecoration(
                labelText: 'الوصف بالعربية (اختياري)',
                hintText: 'مثال: Type-C شحن فائق (5V/2.5A)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final ar = arController.text.trim();
              final label = ar.isNotEmpty ? ar : name;
              GlobalDeviceSpecsPool.addChargingPort(name, label);
              context.read<ProductFormCubit>().updateDeviceSpecs(chargingPort: name);
              setState(() {}); // rebuild dropdown
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  void _showAddScreenTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final arController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tv_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف نوع شاشة جديد (Screen Display)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'نوع الشاشة / Screen Type',
                hintText: 'e.g. 1.47" TFT Color Screen',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: arController,
              decoration: const InputDecoration(
                labelText: 'الوصف بالعربية (اختياري)',
                hintText: 'مثال: شاشة ألوان 1.47 بوصة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final ar = arController.text.trim();
              final label = ar.isNotEmpty ? ar : name;
              GlobalDeviceSpecsPool.addScreenType(name, label);
              context.read<ProductFormCubit>().updateDeviceSpecs(screenType: name);
              setState(() {}); // rebuild dropdown
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  void _showAddAirflowTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final arController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.air_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف نظام تدفق هواء جديد (Airflow Control)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'نظام تدفق الهواء / Airflow Type',
                hintText: 'e.g. Stepless 360 Airflow Control',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: arController,
              decoration: const InputDecoration(
                labelText: 'الوصف بالعربية (اختياري)',
                hintText: 'مثال: تحكم تدفق هواء سلس 360 درجة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final ar = arController.text.trim();
              final label = ar.isNotEmpty ? ar : name;
              GlobalDeviceSpecsPool.addAirflowType(name, label);
              context.read<ProductFormCubit>().updateDeviceSpecs(airflowType: name);
              setState(() {}); // rebuild dropdown
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة واختيار'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton({
    required VoidCallback onTap,
    required String tooltip,
    Color color = const Color(0xFF6366F1),
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm + 2),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm + 2),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.add_rounded, color: color, size: 22),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildStringDropdownItems(
    List<String> options,
    String currentValue,
  ) {
    final list = List<String>.from(options);
    if (currentValue.isNotEmpty && !list.contains(currentValue)) {
      list.insert(0, currentValue);
    }
    return list
        .map(
          (val) => DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<String>> _buildMapDropdownItems(
    Map<String, String> options,
    String currentValue,
  ) {
    final map = Map<String, String>.from(options);
    if (currentValue.isNotEmpty && !map.containsKey(currentValue)) {
      map[currentValue] = currentValue;
    }
    return map.entries
        .map(
          (entry) => DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value, style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              title: 'مواصفات الجهاز والبطارية (Device Hardware Specs)',
              subtitle: 'اختر قدرة الوات، سعة البطارية والأمبير، نوع البطارية، الشحن، وخيارات الألوان',
              icon: Icons.vape_free_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: AppSizes.md),

            // Row 1: Max Wattage & Battery Capacity (الوات والأمبير)
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                final wattageCard = Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('dev_watt_${state.maxWattage}'),
                              initialValue: state.maxWattage.isNotEmpty ? state.maxWattage : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'أقصى قدرة وات (Max Wattage)',
                                prefixIcon: Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF6366F1)),
                                isDense: true,
                              ),
                              hint: Text('select_wattage_hint'.tr),
                              items: _buildStringDropdownItems(GlobalDeviceSpecsPool.wattageOptions, state.maxWattage),
                              onChanged: (v) => cubit.updateDeviceSpecs(maxWattage: v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickAddButton(
                            onTap: () => _showAddWattageDialog(context),
                            tooltip: 'أضف قدرة وات جديدة (Add Wattage)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'خيارات شائعة للوات:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: GlobalDeviceSpecsPool.wattageOptions.map((preset) {
                          final isSel = state.maxWattage == preset;
                          return ChoiceChip(
                            label: Text(preset, style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            onSelected: (selected) {
                              cubit.updateDeviceSpecs(maxWattage: selected ? preset : '');
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );

                final capacityCard = Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('dev_cap_${state.batteryCapacity}'),
                              initialValue: state.batteryCapacity.isNotEmpty ? state.batteryCapacity : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'سعة البطارية والأمبير (Battery Capacity / mAh)',
                                prefixIcon: Icon(Icons.battery_std_rounded, size: 18, color: Color(0xFF6366F1)),
                                isDense: true,
                              ),
                              hint: Text('select_battery_hint'.tr),
                              items: _buildStringDropdownItems(GlobalDeviceSpecsPool.batteryCapacities, state.batteryCapacity),
                              onChanged: (v) => cubit.updateDeviceSpecs(batteryCapacity: v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickAddButton(
                            onTap: () => _showAddBatteryCapacityDialog(context),
                            tooltip: 'أضف سعة بطارية جديدة (Add Battery Capacity)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'خيارات شائعة للبطارية والأمبير:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: GlobalDeviceSpecsPool.batteryCapacities.map((preset) {
                          final isSel = state.batteryCapacity == preset;
                          final shortLabel = preset.replaceAll(' (بطارية خارجية)', '');
                          return ChoiceChip(
                            label: Text(shortLabel, style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            onSelected: (selected) {
                              cubit.updateDeviceSpecs(batteryCapacity: selected ? preset : '');
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      wattageCard,
                      const SizedBox(height: AppSizes.md),
                      capacityCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: wattageCard),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: capacityCard),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Row 2: Battery System & Charging Port
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                final batField = Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dev_bat_${state.batteryType}'),
                        initialValue: state.batteryType.isNotEmpty ? state.batteryType : 'Built-in Battery',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'نظام نوع البطارية (Battery System)',
                          prefixIcon: Icon(Icons.battery_charging_full_rounded, size: 18, color: Color(0xFF6366F1)),
                        ),
                        items: _buildMapDropdownItems(GlobalDeviceSpecsPool.batterySystems, state.batteryType),
                        onChanged: (v) => cubit.updateDeviceSpecs(batteryType: v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAddButton(
                      onTap: () => _showAddBatterySystemDialog(context),
                      tooltip: 'أضف نظام بطارية جديد (Add Battery System)',
                    ),
                  ],
                );

                final portField = Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dev_port_${state.chargingPort}'),
                        initialValue: state.chargingPort.isNotEmpty ? state.chargingPort : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'منفذ وسرعة الشحن (Charging Port)',
                          prefixIcon: Icon(Icons.electrical_services_rounded, size: 18, color: Color(0xFF6366F1)),
                        ),
                        hint: Text('select_charging_port_hint'.tr),
                        items: _buildMapDropdownItems(GlobalDeviceSpecsPool.chargingPorts, state.chargingPort),
                        onChanged: (v) => cubit.updateDeviceSpecs(chargingPort: v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAddButton(
                      onTap: () => _showAddChargingPortDialog(context),
                      tooltip: 'أضف منفذ شحن جديد (Add Charging Port)',
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    children: [
                      batField,
                      const SizedBox(height: AppSizes.md),
                      portField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: batField),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: portField),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Row 3: Screen & Airflow
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;

                final screenField = Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dev_screen_${state.screenType}'),
                        initialValue: state.screenType.isNotEmpty ? state.screenType : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'نوع الشاشة والعرض (Screen Display)',
                          prefixIcon: Icon(Icons.tv_rounded, size: 18, color: Color(0xFF6366F1)),
                        ),
                        hint: Text('select_screen_type_hint'.tr),
                        items: _buildMapDropdownItems(GlobalDeviceSpecsPool.screenTypes, state.screenType),
                        onChanged: (v) => cubit.updateDeviceSpecs(screenType: v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAddButton(
                      onTap: () => _showAddScreenTypeDialog(context),
                      tooltip: 'أضف نوع شاشة جديد (Add Screen Display)',
                    ),
                  ],
                );

                final airField = Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dev_air_${state.airflowType}'),
                        initialValue: state.airflowType.isNotEmpty ? state.airflowType : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'نظام تدفق الهواء (Airflow Control)',
                          prefixIcon: Icon(Icons.air_rounded, size: 18, color: Color(0xFF6366F1)),
                        ),
                        hint: Text('select_airflow_hint'.tr),
                        items: _buildMapDropdownItems(GlobalDeviceSpecsPool.airflowTypes, state.airflowType),
                        onChanged: (v) => cubit.updateDeviceSpecs(airflowType: v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAddButton(
                      onTap: () => _showAddAirflowTypeDialog(context),
                      tooltip: 'أضف نظام تدفق هواء جديد (Add Airflow)',
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    children: [
                      screenField,
                      const SizedBox(height: AppSizes.md),
                      airField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: screenField),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: airField),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Colors Selector
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 620;
                      final titleWidget = const Text(
                        'ألوان وفينش الجهاز وتدرج الباكجينج (Device & Packaging Colors)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      );
                      final pickerBtn = ElevatedButton.icon(
                        onPressed: () {
                          ColorPalettePickerDialog.show(
                            context,
                            onColorSelected: (c) => cubit.addCustomColor(c),
                          );
                        },
                        icon: const Icon(Icons.palette_rounded, size: 16),
                        label: const Text(
                          'منتقي الألوان والباكجينج (Palette & Mix Picker)',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const SizedBox(height: 8),
                  if (state.availableColors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'لا توجد ألوان مضافة بعد. اضغط على منتقي الألوان أو أضف أسماء الألوان بالأسفل لتوليد متغيرات الألوان.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.availableColors.map((color) {
                        final isSel = state.selectedColors.contains(color);
                        return FilterChip(
                          avatar: ColorUtils.buildColorIndicator(color, size: 14),
                          label: Text(ColorUtils.getReadableColorName(color)),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          onSelected: (_) => cubit.toggleColor(color),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customColorController,
                          decoration: const InputDecoration(
                            hintText: '+ أضف اسم لون يدوي (e.g. Titanium Grey / Black)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onSubmitted: (val) {
                            final text = val.trim();
                            if (text.isNotEmpty) {
                              String colorName = text;
                              if (!text.startsWith('#') && !text.contains('(')) {
                                final parsed = ColorUtils.parseColorsFromText(text);
                                if (parsed.isNotEmpty) {
                                  final hex = ColorUtils.toHex(parsed.first);
                                  colorName = '$text ($hex)';
                                }
                              }
                              cubit.addCustomColor(colorName);
                              _customColorController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customColorController.text.trim();
                          if (text.isNotEmpty) {
                            String colorName = text;
                            if (!text.startsWith('#') && !text.contains('(')) {
                              final parsed = ColorUtils.parseColorsFromText(text);
                              if (parsed.isNotEmpty) {
                                final hex = ColorUtils.toHex(parsed.first);
                                colorName = '$text ($hex)';
                              }
                            }
                            cubit.addCustomColor(colorName);
                            _customColorController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          foregroundColor: isDark ? Colors.white : Colors.black,
                        ),
                        child: Text('add'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 3. COILS & CARTRIDGES FORM SECTION (UNIFIED)
// ----------------------------------------------------------------------
class CoilsAndCartridgesFormSection extends StatefulWidget {
  const CoilsAndCartridgesFormSection({super.key});

  @override
  State<CoilsAndCartridgesFormSection> createState() =>
      _CoilsAndCartridgesFormSectionState();
}

class _CoilsAndCartridgesFormSectionState
    extends State<CoilsAndCartridgesFormSection> {
  final TextEditingController _customResController = TextEditingController();
  final TextEditingController _customCapacityController = TextEditingController();
  final TextEditingController _customFillTypeController = TextEditingController();

  @override
  void dispose() {
    _customResController.dispose();
    _customCapacityController.dispose();
    _customFillTypeController.dispose();
    super.dispose();
  }

  void _showAddResistanceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text(
              'أضف مقاومة كويل / بود جديدة (Add Resistance Ω)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'المقاومة / Resistance (Ω)',
            hintText: 'e.g. 0.7Ω أو 0.3Ω أو 0.15Ω',
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<ProductFormCubit>().addCustomPodResistance(val);
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ProductFormCubit>().addCustomPodResistance(controller.text);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('add_resistance_btn'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              title:
                  'مواصفات الكويلات والكارتردج والبودات (Coils & Cartridges Specs)',
              subtitle:
                  'حدد الأجهزة المتوافقة، السعة، نظام التعبئة، والمقاومات بالأوم لتوليد المتغيرات بدقة',
              icon: Icons.bolt_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: AppSizes.md),

            // Compatible Devices & Tanks Selection
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 580;
                      final titleWidget = Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'الأجهزة والتانكات المتوافقة (Compatible Devices & Tanks)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          'اختيار من المتجر',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: state.podCompatibleDevices,
                    decoration: const InputDecoration(
                      labelText:
                          'نص توافق عام يدوي (Manual Compatibility Text)',
                      hintText:
                          'e.g. OXVA XLIM Series (Pro 2, SQ Pro, SE) / VOOPOO PnP / Vaporesso XROS',
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        cubit.updatePodSpecs(compatibleDevices: v),
                  ),
                  if (state.compatibleProducts.isNotEmpty ||
                      state.compatibleProductIds.isNotEmpty) ...[
                    const SizedBox(height: 10),
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
                                backgroundColor: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                side: BorderSide(
                                  color: const Color(0xFF10B981)
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
                                backgroundColor: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                              );
                            }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 550;

                final capField = TextFormField(
                  initialValue: state.podCapacity,
                  decoration: const InputDecoration(
                    labelText: 'السعة الافتراضية (Default Capacity)',
                    hintText: 'e.g. 2.0ml / 3.0ml',
                  ),
                  onChanged: (v) => cubit.updatePodSpecs(capacity: v),
                );

                final switchTile = Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    title: const Text(
                      'بودات معبأة مسبقاً (Pre-filled)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: state.isPrefilledPod,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (v) => cubit.updatePodSpecs(isPrefilled: v),
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      capField,
                      const SizedBox(height: AppSizes.sm),
                      switchTile,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: capField),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: switchTile),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // 1. Capacity Selection Container (Variations)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'سعات البود والخرطوشة (Capacity ml - Variations)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (state.selectedPodCapacities.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.selectedPodCapacities.length} سعة مختارة',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حدد السعات المتاحة (مثل 2.0ml و 3.0ml) ليتم توليدها كخيارات للشراء (Variations) للعملاء.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.availablePodCapacities.map((cap) {
                      final isSel = state.selectedPodCapacities.contains(cap);
                      return FilterChip(
                        avatar: const Icon(
                          Icons.opacity_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        label: Text(cap),
                        selected: isSel,
                        selectedColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.25),
                        onSelected: (_) => cubit.togglePodCapacity(cap),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customCapacityController,
                          decoration: const InputDecoration(
                            hintText:
                                '+ أضف سعة مخصصة (مثال: 2ml / 2.5ml / 3ml / 5ml)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              cubit.addCustomPodCapacity(val);
                              _customCapacityController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          if (_customCapacityController.text.trim().isNotEmpty) {
                            cubit.addCustomPodCapacity(
                              _customCapacityController.text,
                            );
                            _customCapacityController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 2. Fill Type Selection Container (Variations)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.input_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'نظام وطريقة التعبئة (Fill System / Type - Variations)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (state.selectedPodFillTypes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.selectedPodFillTypes.length} نظام ملء',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر نظام الملء (Top Fill / Side Fill) ليتم تضمينه في خيارات ومتغيرات المنتج للعملاء.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.availablePodFillTypes.map((fill) {
                      final isSel = state.selectedPodFillTypes.contains(fill);
                      return FilterChip(
                        avatar: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        label: Text(fill),
                        selected: isSel,
                        selectedColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.25),
                        onSelected: (_) => cubit.togglePodFillType(fill),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customFillTypeController,
                          decoration: const InputDecoration(
                            hintText:
                                '+ أضف نظام ملء مخصص (مثال: Top Fill / Side Fill)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              cubit.addCustomPodFillType(val);
                              _customFillTypeController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          if (_customFillTypeController.text.trim().isNotEmpty) {
                            cubit.addCustomPodFillType(
                              _customFillTypeController.text,
                            );
                            _customFillTypeController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),


            // Resistances Selection Container
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'مقاومات الكويلات والبودات المتاحة (Resistances Ω)'
                              : 'Available Resistances (Ω)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.15),
                          foregroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        tooltip: isArabic
                            ? 'أضف مقاومة جديدة (Add Resistance Ω)'
                            : 'Add Resistance (Ω)',
                        onPressed: () => _showAddResistanceDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (state.availablePodResistances.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'لا توجد مقاومات مضافة. أضف قيم المقاومة أدناه.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColor.textMutedDark
                              : AppColor.textMutedLight,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.availablePodResistances.map((res) {
                        final isSel = state.selectedPodResistances.contains(res);
                        return FilterChip(
                          avatar: const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          label: Text(res),
                          selected: isSel,
                          selectedColor: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.25),
                          onSelected: (_) => cubit.togglePodResistance(res),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customResController,
                          decoration: const InputDecoration(
                            hintText:
                                '+ أضف مقاومة جديدة (مثال: 0.6Ω / 0.8Ω / 1.2Ω)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              cubit.addCustomPodResistance(val);
                              _customResController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          if (_customResController.text.trim().isNotEmpty) {
                            cubit.addCustomPodResistance(
                              _customResController.text,
                            );
                            _customResController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wattage Range per Resistance Table & Auto-Format Specs Button
            if (state.selectedPodResistances.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.electric_bolt_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'نطاق الواط الموصى به لكل مقاومة (Recommended Wattage)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            cubit.autoFormatWattageIntoDescription();
                            HelperFun.successSnackbar(
                              'تم التوليد بنجاح',
                              'تم إدراج مواصفات المقاومات والواط في وصف المنتج بدقة.',
                            );
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                          label: const Text(
                            '⚡ توليد وتنسيق الواط في الوصف',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك تعديل نطاق الواط لكل مقاومة، وسيتم حفظها بالمواصفات وتوليدها داخل وصف المنتج للعملاء في المتجر.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                    const Divider(height: 20),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.selectedPodResistances.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final res = state.selectedPodResistances[idx];
                        final currentWatt =
                            state.podResistanceWattages[res] ??
                            ProductFormCubit.getSuggestedWattage(res);
                        final styleNote =
                            ProductFormCubit.getSuggestedVapingStyle(res);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColor.darkSubCard
                                : AppColor.lightSubCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  res,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  initialValue: currentWatt,
                                  decoration: const InputDecoration(
                                    labelText: 'نطاق الواط',
                                    hintText: 'e.g. 18W - 25W',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      cubit.updatePodResistanceWattage(
                                        res,
                                        val,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColor.darkCard
                                        : AppColor.lightCard,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    styleNote,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColor.textPrimaryDark
                                          : AppColor.textPrimaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 5. ACCESSORY FORM SECTION
// ----------------------------------------------------------------------
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
            _buildSectionHeader(
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

// ----------------------------------------------------------------------
// Helper Section Header Banner
// ----------------------------------------------------------------------
Widget _buildSectionHeader(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
}) {
  final isDark = HelperFun.isDarkMode(context);

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.md,
      vertical: AppSizes.sm + 2,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: isDark ? 0.16 : 0.08),
          color.withValues(alpha: isDark ? 0.05 : 0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSizes.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

