import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/color_utils.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../cubit/product_form_cubit.dart';
import '../color_palette_picker_dialog.dart';
import 'form_section_header.dart';

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
            buildSectionHeader(
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
