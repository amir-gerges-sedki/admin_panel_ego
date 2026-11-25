import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../cubit/product_form_cubit.dart';
import 'form_section_header.dart';

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
            buildSectionHeader(
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
