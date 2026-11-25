import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../cubit/product_form_cubit.dart';
import '../product_selector_dialog.dart';
import 'form_section_header.dart';

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
            buildSectionHeader(
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
