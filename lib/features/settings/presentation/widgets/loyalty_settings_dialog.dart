import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/store_settings_model.dart';
import '../cubit/settings_cubit.dart';

/// Interactive modal sheet allowing Super Admins to customize store-wide Loyalty Points rules
class LoyaltySettingsDialog extends StatefulWidget {
  const LoyaltySettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return UnifiedModalSheet.show(
      context: context,
      title: 'loyalty_program_rules'.tr.isNotEmpty ? 'loyalty_program_rules'.tr : 'قواعد برنامج نقاط الولاء',
      subtitle: 'loyalty_program_rules_sub'.tr.isNotEmpty
          ? 'loyalty_program_rules_sub'.tr
          : 'تحديد معدل اكتساب النقاط وقيمتها المالية عند الاستبدال',
      icon: Icons.stars_rounded,
      maxWidth: 620,
      content: const LoyaltySettingsDialog(),
    );
  }

  @override
  State<LoyaltySettingsDialog> createState() => _LoyaltySettingsDialogState();
}

class _LoyaltySettingsDialogState extends State<LoyaltySettingsDialog> {
  late TextEditingController _egpPerEarnedPointController;
  late TextEditingController _egpValuePerRedeemedPointController;
  late TextEditingController _minPointsToRedeemController;
  late TextEditingController _testBillController;

  bool _isLoyaltyEnabled = true;
  bool _isSaving = false;
  bool _initialized = false;
  StoreSettingsModel? _currentSettings;

  @override
  void initState() {
    super.initState();
    _testBillController = TextEditingController(text: '200');
    _testBillController.addListener(() => setState(() {}));
  }

  void _initFromSettings(StoreSettingsModel settings) {
    if (_initialized) return;
    _currentSettings = settings;
    _isLoyaltyEnabled = settings.isLoyaltyEnabled;
    _egpPerEarnedPointController = TextEditingController(
      text: settings.egpPerEarnedPoint == settings.egpPerEarnedPoint.toInt()
          ? settings.egpPerEarnedPoint.toInt().toString()
          : settings.egpPerEarnedPoint.toString(),
    );
    _egpValuePerRedeemedPointController = TextEditingController(
      text: settings.egpValuePerRedeemedPoint.toString(),
    );
    _minPointsToRedeemController = TextEditingController(
      text: settings.minPointsToRedeem.toString(),
    );

    _egpPerEarnedPointController.addListener(() => setState(() {}));
    _egpValuePerRedeemedPointController.addListener(() => setState(() {}));
    _minPointsToRedeemController.addListener(() => setState(() {}));
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _egpPerEarnedPointController.dispose();
      _egpValuePerRedeemedPointController.dispose();
      _minPointsToRedeemController.dispose();
    }
    _testBillController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_currentSettings == null) return;
    final egpEarned = double.tryParse(_egpPerEarnedPointController.text.trim()) ?? 10.0;
    final egpValue = double.tryParse(_egpValuePerRedeemedPointController.text.trim()) ?? 0.5;
    final minPts = int.tryParse(_minPointsToRedeemController.text.trim()) ?? 10;

    if (egpEarned <= 0) {
      HelperFun.warningSnackbar(
        title: 'تنبيه',
        message: 'يجب أن يكون معدل الاكتساب أكبر من صفر',
      );
      return;
    }
    if (egpValue <= 0) {
      HelperFun.warningSnackbar(
        title: 'تنبيه',
        message: 'يجب أن تكون قيمة النقطة أكبر من صفر',
      );
      return;
    }

    setState(() => _isSaving = true);
    final updated = _currentSettings!.copyWith(
      isLoyaltyEnabled: _isLoyaltyEnabled,
      egpPerEarnedPoint: egpEarned,
      egpValuePerRedeemedPoint: egpValue,
      minPointsToRedeem: minPts,
    );

    try {
      await context.read<SettingsCubit>().saveSettings(updated);
      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        HelperFun.successSnackbar(
          isArabic ? 'نجاح' : 'Success',
          isArabic
              ? 'تم تحديث وحفظ قواعد نقاط الولاء بنجاح'
              : 'Loyalty program rules saved successfully',
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading && !_initialized) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SettingsLoaded) {
          _initFromSettings(state.settings);
        } else if (!_initialized) {
          _initFromSettings(const StoreSettingsModel(
            phoneNumber: '',
            whatsNumber: '',
            email: '',
            address: '',
          ));
        }

        final double egpEarned = double.tryParse(_egpPerEarnedPointController.text.trim()) ?? 10.0;
        final double egpValue = double.tryParse(_egpValuePerRedeemedPointController.text.trim()) ?? 0.5;
        final int minPoints = int.tryParse(_minPointsToRedeemController.text.trim()) ?? 10;
        final double testBill = double.tryParse(_testBillController.text.trim()) ?? 200.0;

        final int simulatedPoints = (egpEarned > 0 && _isLoyaltyEnabled)
            ? (testBill / egpEarned).floor()
            : 0;
        final double simulatedDiscount = (egpValue > 0 && _isLoyaltyEnabled)
            ? (simulatedPoints * egpValue)
            : 0.0;
        final double cashbackPercentage = testBill > 0 ? (simulatedDiscount / testBill) * 100 : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Master Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isLoyaltyEnabled
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                    : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: _isLoyaltyEnabled
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFF59E0B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'تفعيل نظام نقاط الولاء والمكافآت' : 'Enable Loyalty Points Program',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic
                                    ? 'يمنح العملاء نقاطاً تلقائياً عند الشراء من الكاشير أو التطبيق'
                                    : 'Automatically awards customers points upon cashier or online sales',
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
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _isLoyaltyEnabled,
                    activeThumbColor: const Color(0xFFF59E0B),
                    activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    onChanged: (val) => setState(() => _isLoyaltyEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Form Inputs
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earning Rate
                Expanded(
                  child: _buildInputField(
                    isDark: isDark,
                    controller: _egpPerEarnedPointController,
                    label: isArabic ? 'معدل الاكتساب (جنيه / نقطة)' : 'Earning Rate (EGP/Point)',
                    hint: '10',
                    suffix: isArabic ? 'ج.م لكل نقطة' : 'EGP / pt',
                    description: isArabic
                        ? 'كم ينفق العميل في الفاتورة ليكسب نقطة واحدة؟ (مثال: 10 ج.م)'
                        : 'How many EGP spent awards 1 point (e.g. 10 EGP)',
                    icon: Icons.monetization_on_outlined,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                // Redemption Value
                Expanded(
                  child: _buildInputField(
                    isDark: isDark,
                    controller: _egpValuePerRedeemedPointController,
                    label: isArabic ? 'قيمة النقطة عند الاستبدال' : 'Redemption Value (EGP)',
                    hint: '0.5',
                    suffix: isArabic ? 'ج.م خصم' : 'EGP disc',
                    description: isArabic
                        ? 'قيمة الخصم بالجنيه للنقطة الواحدة عند الدفع (مثال: 0.5 ج.م)'
                        : 'Discount amount per 1 point redeemed (e.g. 0.5 EGP)',
                    icon: Icons.discount_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Minimum Points to redeem
            _buildInputField(
              isDark: isDark,
              controller: _minPointsToRedeemController,
              label: isArabic ? 'الحد الأدنى للنقاط لبدء الاستبدال' : 'Minimum Points To Redeem',
              hint: '10',
              suffix: isArabic ? 'نقطة كحد أدنى' : 'pts min',
              description: isArabic
                  ? 'أقل رصيد نقاط يلزم أن يمتلكه العميل ليتمكن من الخصم من الفاتورة'
                  : 'Minimum balance required before a customer can redeem points',
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: AppSizes.lg),

            // Live Simulator Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E2A), const Color(0xFF26201A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_rounded, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'محاكي الحساب التفاعلي (مباشر)' : 'Live Interactive Simulator',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const Spacer(),
                      // Input for test bill
                      SizedBox(
                        width: 120,
                        height: 32,
                        child: TextField(
                          controller: _testBillController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            prefixText: isArabic ? 'فاتورة: ' : 'Bill: ',
                            prefixStyle: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                            ),
                            suffixText: isArabic ? 'ج.م' : 'EGP',
                            suffixStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: isDark ? AppColor.darkCard : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Earned Points Preview
                      Expanded(
                        child: _buildSimMetric(
                          isDark: isDark,
                          title: isArabic ? 'النقاط المكتسبة للعميل' : 'Customer Earns',
                          value: '$simulatedPoints ${isArabic ? 'نقطة' : 'pts'}',
                          formula: '${testBill.toStringAsFixed(0)} ÷ ${egpEarned.toStringAsFixed(0)}',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      Container(width: 1, height: 48, color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                      // Future Discount Value
                      Expanded(
                        child: _buildSimMetric(
                          isDark: isDark,
                          title: isArabic ? 'قيمة الخصم المستقبلي' : 'Discount Value',
                          value: '${simulatedDiscount.toStringAsFixed(1)} ${isArabic ? 'ج.م' : 'EGP'}',
                          formula: '$simulatedPoints × $egpValue',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Container(width: 1, height: 48, color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                      // Cashback %
                      Expanded(
                        child: _buildSimMetric(
                          isDark: isDark,
                          title: isArabic ? 'نسبة الوفر/الكاش باك' : 'Reward Return',
                          value: '${cashbackPercentage.toStringAsFixed(1)}%',
                          formula: isArabic ? 'عائد مجزي للعميل' : 'Effective return',
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'أي عميل يشتري بـ ${testBill.toStringAsFixed(0)} جنيه سيحصل تلقائياً على $simulatedPoints نقطة في رصيده، وتمنحه خصماً قدره ${simulatedDiscount.toStringAsFixed(1)} جنيه في الزيارة القادمة (الحد الأدنى لبدء الاستبدال: $minPoints نقطة).'
                                : 'A customer spending ${testBill.toStringAsFixed(0)} EGP earns $simulatedPoints pts ($simulatedDiscount EGP discount, min $minPoints pts to redeem).',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isArabic ? 'حفظ إعدادات النقاط' : 'Save Loyalty Rules',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required String description,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColor.primary),
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
            filled: true,
            fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              borderSide: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSimMetric({
    required bool isDark,
    required String title,
    required String value,
    required String formula,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            formula,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
