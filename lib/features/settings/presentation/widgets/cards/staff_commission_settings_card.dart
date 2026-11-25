import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/formatters/formatters.dart';

/// Settings card for global store-wide sales commission and staff bonus rates
class StaffCommissionSettingsCard extends StatefulWidget {
  final TextEditingController commissionRateController;
  final bool isDark;

  const StaffCommissionSettingsCard({
    super.key,
    required this.commissionRateController,
    required this.isDark,
  });

  @override
  State<StaffCommissionSettingsCard> createState() =>
      _StaffCommissionSettingsCardState();
}

class _StaffCommissionSettingsCardState
    extends State<StaffCommissionSettingsCard> {
  static const List<double> _presets = [1.0, 2.0, 2.5, 3.0, 5.0, 7.5, 10.0];

  @override
  void initState() {
    super.initState();
    widget.commissionRateController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.commissionRateController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rate =
        double.tryParse(widget.commissionRateController.text.trim()) ?? 2.5;
    const sampleSales = 100000.0;
    final sampleBonus = sampleSales * (rate / 100.0);

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عمولات ومكافآت السيلز (Staff Sales Commission)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'النسبة الموحدة لكل السيلز — تُحسب تلقائياً عند كل بيع',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppColor.textMutedDark
                            : AppColor.textMutedLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Commission Rate Input
          TextFormField(
            controller: widget.commissionRateController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'يرجى إدخال نسبة العمولة';
              }
              final val = double.tryParse(v.trim());
              if (val == null || val < 0 || val > 100) {
                return 'النسبة يجب أن تكون بين 0% و 100%';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: '2.5',
              suffixText: '% من المبيعات',
              prefixIcon: const Icon(
                Icons.percent_rounded,
                size: 18,
                color: Color(0xFF10B981),
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm + 2),

          // Preset Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _presets.map((preset) {
              final isSelected = (rate - preset).abs() < 0.01;
              return ActionChip(
                label: Text('$preset%'),
                backgroundColor: isSelected
                    ? const Color(0xFF10B981)
                    : (widget.isDark
                        ? AppColor.darkSubCard
                        : AppColor.lightSubCard),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (widget.isDark ? Colors.white : Colors.black87),
                ),
                onPressed: () {
                  widget.commissionRateController.text =
                      preset.toString();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.sm + 2),

          // Compact live calculation preview
          Row(
            children: [
              const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'مثال: مبيعات 100,000 ج.م ← مكافأة ${AppFormatters.formatEGP(sampleBonus)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: widget.isDark
                        ? AppColor.textMutedDark
                        : AppColor.textMutedLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
