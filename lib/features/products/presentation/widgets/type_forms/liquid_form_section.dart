import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../cubit/product_form_cubit.dart';
import 'form_section_header.dart';

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
            buildSectionHeader(
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
