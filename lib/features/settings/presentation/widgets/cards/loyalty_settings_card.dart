import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';

/// Settings card for customer loyalty & rewards program
class LoyaltySettingsCard extends StatelessWidget {
  final bool isLoyaltyEnabled;
  final ValueChanged<bool> onLoyaltyEnabledChanged;
  final TextEditingController egpPerEarnedPointController;
  final TextEditingController egpValuePerRedeemedPointController;
  final TextEditingController minPointsToRedeemController;
  final bool isDark;

  const LoyaltySettingsCard({
    super.key,
    required this.isLoyaltyEnabled,
    required this.onLoyaltyEnabledChanged,
    required this.egpPerEarnedPointController,
    required this.egpValuePerRedeemedPointController,
    required this.minPointsToRedeemController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final double egpEarned =
        double.tryParse(egpPerEarnedPointController.text.trim()) ?? 10.0;
    final double egpValue =
        double.tryParse(egpValuePerRedeemedPointController.text.trim()) ?? 0.5;
    final int minPoints =
        int.tryParse(minPointsToRedeemController.text.trim()) ?? 10;

    final int simPts200 =
        egpEarned > 0 && isLoyaltyEnabled ? (200 / egpEarned).floor() : 0;
    final double simDisc200 =
        egpValue > 0 && isLoyaltyEnabled ? (simPts200 * egpValue) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isLoyaltyEnabled
              ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
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
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFF59E0B),
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
                          ? 'برنامج نقاط الولاء والمكافآت'
                          : 'Loyalty & Rewards Program',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'التحكم في معادلة اكتساب النقاط وقيمتها المالية عند الاستبدال'
                          : 'Configure points earning rate & monetary redemption value',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isLoyaltyEnabled,
                activeThumbColor: const Color(0xFFF59E0B),
                activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                onChanged: onLoyaltyEnabledChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: egpPerEarnedPointController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isArabic
                  ? 'معدل الاكتساب (جنيه لكل نقطة)'
                  : 'Earning Rate (EGP per Point)',
              hintText: '10',
              prefixIcon: const Icon(Icons.monetization_on_outlined, size: 18),
              suffixText: isArabic ? 'ج.م / نقطة' : 'EGP / pt',
              helperText: isArabic
                  ? 'كم ينفق العميل ليكسب نقطة واحدة؟ (مثال: 10 ج.م -> كل 200 ج.م مشتريات تمنحه 20 نقطة)'
                  : 'How many EGP spent awards 1 point (e.g. 10 EGP -> 200 EGP earns 20 pts)',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: egpValuePerRedeemedPointController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isArabic
                  ? 'قيمة استبدال النقطة (بالجنيه)'
                  : 'Redemption Value (EGP)',
              hintText: '0.5',
              prefixIcon: const Icon(Icons.discount_outlined, size: 18),
              suffixText: isArabic ? 'ج.م خصم' : 'EGP disc',
              helperText: isArabic
                  ? 'قيمة الخصم بالجنيه لكل نقطة يستبدلها العميل (مثال: 0.5 ج.م للنقطة -> الـ 20 نقطة تخصم 10 جنيهات)'
                  : 'Monetary discount in EGP per point redeemed (e.g. 0.5 EGP -> 20 pts = 10 EGP disc)',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: minPointsToRedeemController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isArabic
                  ? 'الحد الأدنى للنقاط للاستبدال'
                  : 'Minimum Points to Redeem',
              hintText: '10',
              prefixIcon: const Icon(Icons.shield_outlined, size: 18),
              suffixText: isArabic ? 'نقطة' : 'pts',
              helperText: isArabic
                  ? 'أقل رصيد نقاط يلزم توفره لدى العميل ليتمكن من الخصم من الفاتورة (حماية لمنع الخصم بنقاط قليلة)'
                  : 'Minimum balance a customer needs before they can redeem points',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? '💡 مثال حي تفاعلي: لو العميل اشترى بـ 200 جنيه -> سيكتسب $simPts200 نقطة ولاء (وقيمتها عند الاستبدال = ${simDisc200.toStringAsFixed(1)} جنيه خصم، والحد الأدنى للاستبدال = $minPoints نقطة).'
                        : '💡 Live Calculation: If a customer spends 200 EGP -> they earn $simPts200 points (worth ${simDisc200.toStringAsFixed(1)} EGP discount, min $minPoints pts to redeem).',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
