import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';

/// Settings card for smoking cessation program & quit smoking health calculator
class SmokingCessationCard extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final TextEditingController cessationDiscountController;
  final TextEditingController defaultPackPriceController;
  final bool isDark;

  const SmokingCessationCard({
    super.key,
    required this.isEnabled,
    required this.onEnabledChanged,
    required this.cessationDiscountController,
    required this.defaultPackPriceController,
    required this.isDark,
  });

  @override
  State<SmokingCessationCard> createState() => _SmokingCessationCardState();
}

class _SmokingCessationCardState extends State<SmokingCessationCard> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isCessationActive = widget.isEnabled;
    final double packPrice =
        double.tryParse(widget.defaultPackPriceController.text.trim()) ?? 90.0;
    final double discount =
        double.tryParse(widget.cessationDiscountController.text.trim()) ?? 10.0;

    // Financial & Health Simulator: 1 pack per day
    final double monthlySavings = packPrice * 30;
    final double yearlySavings = packPrice * 365;
    final int cigarettesAvoidedMonth = 20 * 30;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isCessationActive
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (widget.isDark ? AppColor.darkBorder : AppColor.lightBorder),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.smoke_free_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'برنامج ومساعد الإقلاع عن التدخين'
                          : 'Quit Smoking & Cessation Hub',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'عرض حاسبة التوفير المالي والصحي وخطة النزول بالنيكوتين في تطبيق العملاء'
                          : 'Show health/money savings calculator & nicotine step-down plan in customer app',
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
              Switch(
                value: isCessationActive,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                onChanged: widget.onEnabledChanged,
              ),
            ],
          ),
          if (isCessationActive) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.defaultPackPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'سعر علبة السجائر الافتراضي'
                          : 'Default Cigarette Pack Price',
                      hintText: '90',
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                      suffixText: isArabic ? 'ج.م' : 'EGP',
                      helperText: isArabic
                          ? 'يُستخدم لحساب التوفير المالي الشهري للعميل'
                          : 'Used to calculate customer monthly money saved',
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    controller: widget.cessationDiscountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'خصم تشجيعي لخفض النيكوتين (%)'
                          : 'Nicotine Step-Down Discount (%)',
                      hintText: '10',
                      prefixIcon:
                          const Icon(Icons.trending_down_rounded, size: 18),
                      suffixText: '%',
                      helperText: isArabic
                          ? 'خصم تشجيعي عند طلب تركيز نيكوتين أقل'
                          : 'Incentive discount when buying lower nicotine',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety_rounded,
                      color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? '🚭 محاكاة تجربة العميل: لو كان يدخن علبة واحدة يومياً بسعر ${packPrice.toInt()} ج.م -> سيعرض له التطبيق توفير ${monthlySavings.toInt()} ج.م شهرياً (${yearlySavings.toInt()} ج.م سنوياً) مع تجنب $cigarettesAvoidedMonth سيجارة احتراق وقطران، وخصم ${discount.toInt()}% على بدائل النيكوتين المخفف!'
                          : '🚭 Customer Preview: Smoking 1 pack/day at ${packPrice.toInt()} EGP -> app shows savings of ${monthlySavings.toInt()} EGP/mo (${yearlySavings.toInt()} EGP/yr), avoiding $cigarettesAvoidedMonth cigarettes and ${discount.toInt()}% off lower nicotine products!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
