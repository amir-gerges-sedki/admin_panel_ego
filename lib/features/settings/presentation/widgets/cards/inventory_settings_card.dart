import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';

/// Settings card for inventory stock levels and low-stock alerts
class InventorySettingsCard extends StatefulWidget {
  final TextEditingController lowStockThresholdController;
  final bool isDark;

  const InventorySettingsCard({
    super.key,
    required this.lowStockThresholdController,
    required this.isDark,
  });

  @override
  State<InventorySettingsCard> createState() => _InventorySettingsCardState();
}

class _InventorySettingsCardState extends State<InventorySettingsCard> {
  @override
  Widget build(BuildContext context) {
    final currentVal = int.tryParse(widget.lowStockThresholdController.text.trim()) ?? 10;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: widget.isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColor.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'inventory_stock_settings'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'inventory_stock_settings_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          TextFormField(
            controller: widget.lowStockThresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'low_stock_threshold_label'.tr,
              hintText: 'low_stock_threshold_hint'.tr,
              helperText: 'low_stock_threshold_help'.tr,
              helperMaxLines: 3,
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'required_field'.tr;
              }
              final n = int.tryParse(v.trim());
              if (n == null || n < 0) {
                return 'invalid';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 20, 50].map((preset) {
              final isSelected = currentVal == preset;
              return ChoiceChip(
                label: Text('$preset ${preset <= 10 ? "Units / قطع" : "Units"}'),
                selected: isSelected,
                selectedColor: AppColor.warning.withValues(alpha: 0.2),
                backgroundColor: widget.isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                side: BorderSide(
                  color: isSelected
                      ? AppColor.warning
                      : (widget.isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? AppColor.warning
                      : (widget.isDark ? Colors.white : AppColor.textPrimaryLight),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      widget.lowStockThresholdController.text = preset.toString();
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
