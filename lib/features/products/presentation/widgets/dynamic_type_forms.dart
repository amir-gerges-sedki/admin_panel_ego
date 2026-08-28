import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_form_cubit.dart';
import 'color_palette_picker_dialog.dart';

class DynamicTypeFormSection extends StatelessWidget {
  const DynamicTypeFormSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        switch (state.categoryType) {
          case ProductCategoryType.liquid:
            return const LiquidFormSection();
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
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF0EA5E9), size: 22),
            SizedBox(width: 8),
            Text('أضف نكهة جديدة (Add Flavor)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _addFlavorAndClose(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة النكهة'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Banner
            _buildSectionHeader(
              context,
              title: 'مواصفات السائل والنكهات (E-Liquid Specifications)',
              subtitle:
                  'أضف النكهات المتاحة، نمط السحب MTL/DL، ونسب النيكوتين وحجم العبوات',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: AppSizes.md),

            // Liquid Origin / Classification Selector
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
              child: Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تصنيف ومصدر الليكويد (Origin):',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  ChoiceChip(
                    avatar: const Text('🇪🇬', style: TextStyle(fontSize: 13)),
                    label: const Text(
                      'Local Liquid (محلي)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    selected: state.liquidOrigin == 'Local',
                    selectedColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.25),
                    onSelected: (selected) {
                      if (selected) cubit.setLiquidOrigin('Local');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Text('🌍', style: TextStyle(fontSize: 13)),
                    label: const Text(
                      'Premium Liquid (بريميوم / مستورد)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    selected: state.liquidOrigin == 'Premium',
                    selectedColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.25),
                    onSelected: (selected) {
                      if (selected) cubit.setLiquidOrigin('Premium');
                    },
                  ),
                ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.icecream_outlined, size: 18, color: Color(0xFF0EA5E9)),
                          SizedBox(width: 6),
                          Text(
                            'النكهات المتاحة (Available Flavors)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddFlavorDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('أضف نكهة جديدة', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
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
                          const Expanded(
                            child: Text(
                              'لا توجد نكهات مضافة بعد (No flavors available). اضغط "أضف نكهة جديدة" لإنشاء النكهة الأولى.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAddFlavorDialog(context),
                            child: const Text('أضف الآن'),
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

            // 2. Vaping Style (MTL vs DL vs Both)
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
                  const Row(
                    children: [
                      Icon(Icons.air_rounded, size: 18, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 6),
                      Text(
                        'نوع السحبة والاستخدام (Vaping Inhalation Style)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'MTL',
                        icon: Icon(Icons.smoking_rooms_rounded, size: 16),
                        label: Text('MTL (سحبة سيجارة ضيقة)'),
                      ),
                      ButtonSegment(
                        value: 'DL',
                        icon: Icon(Icons.cloud_queue_rounded, size: 16),
                        label: Text('DL (سحبة شيشة واسعة)'),
                      ),
                      ButtonSegment(
                        value: 'BOTH',
                        icon: Icon(Icons.all_inclusive_rounded, size: 16),
                        label: Text('كلاهما (Both MTL & DL)'),
                      ),
                    ],
                    selected: {state.vapeStyle},
                    onSelectionChanged: (val) {
                      cubit.setVapeStyle(val.first);
                    },
                  ),
                  const SizedBox(height: 6),
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
                        Text(
                          state.vapeStyle == 'DL'
                              ? '⚡ نمط DL: نيكوتين 3mg و 6mg فقط (Freebase)'
                              : state.vapeStyle == 'MTL'
                                  ? '⚡ نمط MTL: نيكوتين من 6mg إلى 50mg (Salt Nic)'
                                  : '⚡ كلاهما: يتم توليد DL لـ (3mg, 6mg) و MTL لـ (6mg إلى 50mg) تلقائياً',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // 3. Nicotines & Bottle Sizes
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nicotines
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                      border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نسب النيكوتين (Nicotine Strengths)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                                decoration: const InputDecoration(
                                  hintText: '+ مخصص (مثال: 35mg)',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () {
                                cubit.addCustomNicotine(_customNicController.text);
                                _customNicController.clear();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),

                // Sizes
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                      border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حجم العبوة (Bottle Sizes)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                                decoration: const InputDecoration(
                                  hintText: '+ حجم مخصص (مثال: 50ml)',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () {
                                cubit.addCustomSize(_customSizeController.text);
                                _customSizeController.clear();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  @override
  void dispose() {
    _customColorController.dispose();
    super.dispose();
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
              subtitle: 'حدد قدرة الوات، نوع البطارية، الشحن، وخيارات الألوان المتاحة',
              icon: Icons.vape_free_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: AppSizes.md),

            // Wattage & Battery System
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.maxWattage,
                    decoration: const InputDecoration(
                      labelText: 'أقصى قدرة وات (Max Wattage)',
                      hintText: 'e.g. 30W / 80W / 100W / 200W',
                      prefixIcon: Icon(Icons.flash_on_rounded, size: 18),
                    ),
                    onChanged: (v) => cubit.updateDeviceSpecs(maxWattage: v),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.batteryType.isNotEmpty ? state.batteryType : 'Built-in Battery',
                    decoration: const InputDecoration(
                      labelText: 'نظام البطارية (Battery System)',
                      prefixIcon: Icon(Icons.battery_charging_full_rounded, size: 18),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Built-in Battery', child: Text('بطارية مدمجة (Built-in)')),
                      DropdownMenuItem(value: 'Single 18650 Battery', child: Text('بطارية خارجية فردية 18650')),
                      DropdownMenuItem(value: 'Dual 18650 Battery', child: Text('بطاريتين خارجيتين 18650')),
                      DropdownMenuItem(value: 'Single 21700 Battery', child: Text('بطارية خارجية 21700')),
                    ],
                    onChanged: (v) => cubit.updateDeviceSpecs(batteryType: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Battery Capacity & Charging Port
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.batteryCapacity,
                    decoration: const InputDecoration(
                      labelText: 'سعة البطارية (Battery Capacity mAh)',
                      hintText: 'e.g. 1000mAh / 3000mAh',
                    ),
                    onChanged: (v) => cubit.updateDeviceSpecs(batteryCapacity: v),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    initialValue: state.chargingPort,
                    decoration: const InputDecoration(
                      labelText: 'منفذ الشحن (Charging Port)',
                      hintText: 'e.g. USB-C 2A',
                    ),
                    onChanged: (v) => cubit.updateDeviceSpecs(chargingPort: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Screen & Airflow
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.screenType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الشاشة (Screen Display)',
                      hintText: 'e.g. 0.96" TFT / OLED / LED Indicator',
                    ),
                    onChanged: (v) => cubit.updateDeviceSpecs(screenType: v),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    initialValue: state.airflowType,
                    decoration: const InputDecoration(
                      labelText: 'نظام تدفق الهواء (Airflow Control)',
                      hintText: 'e.g. Adjustable Slider Switch',
                    ),
                    onChanged: (v) => cubit.updateDeviceSpecs(airflowType: v),
                  ),
                ),
              ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ألوان وفينش الجهاز وتدرج الباكجينج (Device & Packaging Colors)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      ElevatedButton.icon(
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
                      ),
                    ],
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
                          label: Text(color),
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
                              String hexColor = text;
                              if (!text.startsWith('#')) {
                                final parsed = ColorUtils.parseColorsFromText(text);
                                if (parsed.isNotEmpty) {
                                  hexColor = ColorUtils.toHex(parsed.first);
                                }
                              }
                              cubit.addCustomColor(hexColor);
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
                            String hexColor = text;
                            if (!text.startsWith('#')) {
                              final parsed = ColorUtils.parseColorsFromText(text);
                              if (parsed.isNotEmpty) {
                                hexColor = ColorUtils.toHex(parsed.first);
                              }
                            }
                            cubit.addCustomColor(hexColor);
                            _customColorController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          foregroundColor: isDark ? Colors.white : Colors.black,
                        ),
                        child: const Text('إضافة'),
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
              title:
                  'مواصفات الكويلات والكارتردج والبودات (Coils & Cartridges Specs)',
              subtitle:
                  'حدد الأجهزة المتوافقة، السعة، نظام التعبئة، والمقاومات بالأوم لتوليد المتغيرات بدقة',
              icon: Icons.bolt_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: AppSizes.md),

            TextFormField(
              initialValue: state.podCompatibleDevices,
              decoration: const InputDecoration(
                labelText:
                    'الأجهزة والتانكات المتوافقة (Compatible Devices & Tanks)',
                hintText:
                    'e.g. OXVA XLIM Series (Pro 2, SQ Pro, SE) / VOOPOO PnP / Vaporesso XROS',
              ),
              onChanged: (v) => cubit.updatePodSpecs(compatibleDevices: v),
            ),
            const SizedBox(height: AppSizes.md),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.podCapacity,
                    decoration: const InputDecoration(
                      labelText: 'السعة الافتراضية (Default Capacity)',
                      hintText: 'e.g. 2.0ml / 3.0ml',
                    ),
                    onChanged: (v) => cubit.updatePodSpecs(capacity: v),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: SwitchListTile(
                    title: const Text(
                      'بودات معبأة مسبقاً (Pre-filled)',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: state.isPrefilledPod,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (v) => cubit.updatePodSpecs(isPrefilled: v),
                  ),
                ),
              ],
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
                      const Row(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'سعات البود والخرطوشة (Capacity ml - Variations)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
                      const Row(
                        children: [
                          Icon(
                            Icons.input_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'نظام وطريقة التعبئة (Fill System / Type - Variations)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
                  const Text(
                    'مقاومات الكويلات والبودات المتاحة (Resistances Ω)',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              title: 'مواصفات الملحقات والإكسسوارات (Accessory Specs)',
              subtitle: 'حدد نوع الملحق، مواصفات الخامة، والتوافق',
              icon: Icons.handyman_rounded,
              color: const Color(0xFFEC4899),
            ),
            const SizedBox(height: AppSizes.md),

            TextFormField(
              initialValue: state.accessoryCategory,
              decoration: const InputDecoration(
                labelText: 'نوع الملحق (Accessory Subcategory)',
                hintText: 'e.g. Batteries 18650 / Cotton / Pyrex Glass / Chargers',
              ),
              onChanged: (v) => cubit.updateAccessorySpecs(category: v),
            ),
            const SizedBox(height: AppSizes.md),

            TextFormField(
              initialValue: state.accessoryCompatibility,
              decoration: const InputDecoration(
                labelText: 'التوافق (Compatibility)',
                hintText: 'e.g. Universal 510 Thread / Fit Zeus Tank',
              ),
              onChanged: (v) => cubit.updateAccessorySpecs(compatibility: v),
            ),
            const SizedBox(height: AppSizes.md),

            TextFormField(
              initialValue: state.accessoryMaterial,
              decoration: const InputDecoration(
                labelText: 'الخامة / المواصفة (Material & Technical Specs)',
                hintText: 'e.g. High-Drain Li-ion 3000mAh / Organic Cotton',
              ),
              onChanged: (v) => cubit.updateAccessorySpecs(material: v),
            ),
          ],
        );
      },
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
    padding: const EdgeInsets.all(AppSizes.sm + 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.xs + 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                ),
              ),
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
