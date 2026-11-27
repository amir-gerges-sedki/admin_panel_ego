import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/governorate_delivery_model.dart';
import '../../data/models/store_branch_model.dart';
import '../../data/models/store_settings_model.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/cards/badges_settings_card.dart';
import '../widgets/cards/branches_settings_card.dart';
import '../widgets/cards/contact_settings_card.dart';
import '../widgets/cards/delivery_settings_card.dart';
import '../widgets/cards/firestore_settings_card.dart';
import '../widgets/cards/governorates_delivery_card.dart';
import '../widgets/cards/inventory_settings_card.dart';
import '../widgets/cards/loyalty_settings_card.dart';
import '../widgets/cards/regulatory_settings_card.dart';
import '../widgets/cards/smoking_cessation_card.dart';
import '../widgets/cards/staff_commission_settings_card.dart';

/// Comprehensive store settings screen organized into modular settings cards
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _whatsController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _egpPerEarnedPointController = TextEditingController();
  final _egpValuePerRedeemedPointController = TextEditingController();
  final _minPointsToRedeemController = TextEditingController();
  final _cessationDiscountController = TextEditingController();
  final _defaultPackPriceController = TextEditingController();
  final _commissionRateController = TextEditingController();

  bool _enforceAge = true;
  bool _showWarning = true;
  bool _isLoyaltyEnabled = true;
  bool _enableSmokingCessationProgram = true;
  bool _isInitialized = false;
  bool _isSaving = false;
  List<StoreBranchModel> _branches = [];
  List<GovernorateDeliveryModel> _governorates = [];

  bool get _enforceAgeSafe => _enforceAge == true;
  bool get _showWarningSafe => _showWarning == true;
  bool get _isLoyaltyEnabledSafe => _isLoyaltyEnabled == true;
  bool get _enableSmokingCessationSafe => _enableSmokingCessationProgram == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeCubit>().loadBadges();
    });
  }

  void _initFields(StoreSettingsModel settings) {
    if (_isInitialized) return;

    _enforceAge = settings.enforceAgeVerification == true;
    _showWarning = settings.showNicotineWarningBanner == true;
    _isLoyaltyEnabled = settings.isLoyaltyEnabled == true;
    _enableSmokingCessationProgram =
        settings.enableSmokingCessationProgram == true;

    _phoneController.text = settings.phoneNumber;
    _whatsController.text = settings.whatsNumber;
    _emailController.text = settings.email;
    _addressController.text = settings.address;
    _deliveryFeeController.text = settings.flatDeliveryFee.toInt().toString();
    _thresholdController.text =
        settings.freeShippingThreshold.toInt().toString();
    _deliveryTimeController.text = settings.estimatedDeliveryTime;
    _lowStockThresholdController.text = settings.lowStockThreshold.toString();
    _egpPerEarnedPointController.text =
        settings.egpPerEarnedPoint == settings.egpPerEarnedPoint.toInt()
            ? settings.egpPerEarnedPoint.toInt().toString()
            : settings.egpPerEarnedPoint.toString();
    _egpValuePerRedeemedPointController.text =
        settings.egpValuePerRedeemedPoint.toString();
    _minPointsToRedeemController.text =
        settings.minPointsToRedeem.toString();
    _cessationDiscountController.text =
        settings.cessationDiscountPercent == settings.cessationDiscountPercent.toInt()
            ? settings.cessationDiscountPercent.toInt().toString()
            : settings.cessationDiscountPercent.toString();
    _defaultPackPriceController.text =
        settings.defaultCigarettePackPrice == settings.defaultCigarettePackPrice.toInt()
            ? settings.defaultCigarettePackPrice.toInt().toString()
            : settings.defaultCigarettePackPrice.toString();
    _commissionRateController.text =
        settings.defaultSalesCommissionRate == settings.defaultSalesCommissionRate.toInt()
            ? settings.defaultSalesCommissionRate.toInt().toString()
            : settings.defaultSalesCommissionRate.toString();

    final dynamic rawBranches = (settings as dynamic).branches;
    if (rawBranches is List) {
      _branches = rawBranches.whereType<StoreBranchModel>().toList();
    } else {
      _branches = [];
    }

    _governorates = List<GovernorateDeliveryModel>.from(
      settings.governorates.isNotEmpty
          ? settings.governorates
          : GovernorateDeliveryModel.defaultGovernorates(),
    );

    _isInitialized = true;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _deliveryFeeController.dispose();
    _thresholdController.dispose();
    _deliveryTimeController.dispose();
    _lowStockThresholdController.dispose();
    _egpPerEarnedPointController.dispose();
    _egpValuePerRedeemedPointController.dispose();
    _minPointsToRedeemController.dispose();
    _cessationDiscountController.dispose();
    _defaultPackPriceController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      HelperFun.errorSnackbar(
        title: 'error'.tr,
        message: 'يرجى مراجعة الحقول المطلوبة قبل الحفظ',
      );
      return;
    }

    setState(() => _isSaving = true);
    final updated = StoreSettingsModel(
      phoneNumber: _phoneController.text.trim(),
      whatsNumber: _whatsController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      enforceAgeVerification: _enforceAgeSafe,
      showNicotineWarningBanner: _showWarningSafe,
      flatDeliveryFee: double.tryParse(_deliveryFeeController.text) ?? 0.0,
      freeShippingThreshold:
          double.tryParse(_thresholdController.text) ?? 2000.0,
      estimatedDeliveryTime: _deliveryTimeController.text.trim(),
      lowStockThreshold:
          int.tryParse(_lowStockThresholdController.text.trim()) ?? 10,
      isLoyaltyEnabled: _isLoyaltyEnabledSafe,
      egpPerEarnedPoint:
          double.tryParse(_egpPerEarnedPointController.text.trim()) ?? 10.0,
      egpValuePerRedeemedPoint:
          double.tryParse(_egpValuePerRedeemedPointController.text.trim()) ?? 0.5,
      minPointsToRedeem:
          int.tryParse(_minPointsToRedeemController.text.trim()) ?? 10,
      enableSmokingCessationProgram: _enableSmokingCessationSafe,
      cessationDiscountPercent:
          double.tryParse(_cessationDiscountController.text.trim()) ?? 10.0,
      defaultCigarettePackPrice:
          double.tryParse(_defaultPackPriceController.text.trim()) ?? 90.0,
      defaultSalesCommissionRate:
          double.tryParse(_commissionRateController.text.trim()) ?? 2.5,
      branches: _branches,
      governorates: _governorates,
    );

    try {
      await context.read<SettingsCubit>().saveSettings(updated);
      if (mounted) {
        HelperFun.successSnackbar('success'.tr, 'store_settings_saved'.tr);
      }
    } catch (e) {
      if (mounted) {
        HelperFun.errorSnackbar(
          title: 'error'.tr,
          message: 'فشل حفظ الإعدادات: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SettingsLoaded) {
          _initFields(state.settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  _buildHeader(context, isDark, isDesktop),
                  const SizedBox(height: AppSizes.lg),

                  // Cards Grid / Stack
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ContactSettingsCard(
                                phoneController: _phoneController,
                                whatsController: _whatsController,
                                emailController: _emailController,
                                addressController: _addressController,
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              BranchesSettingsCard(
                                branches: _branches,
                                onBranchesChanged: (b) => setState(() => _branches = b),
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              DeliverySettingsCard(
                                deliveryFeeController: _deliveryFeeController,
                                thresholdController: _thresholdController,
                                deliveryTimeController: _deliveryTimeController,
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              StaffCommissionSettingsCard(
                                commissionRateController: _commissionRateController,
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              LoyaltySettingsCard(
                                isLoyaltyEnabled: _isLoyaltyEnabledSafe,
                                onLoyaltyEnabledChanged: (v) => setState(() => _isLoyaltyEnabled = v),
                                egpPerEarnedPointController: _egpPerEarnedPointController,
                                egpValuePerRedeemedPointController: _egpValuePerRedeemedPointController,
                                minPointsToRedeemController: _minPointsToRedeemController,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: Column(
                            children: [
                              GovernoratesDeliveryCard(
                                governorates: _governorates,
                                onGovernoratesChanged: (g) => setState(() => _governorates = g),
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              InventorySettingsCard(
                                lowStockThresholdController: _lowStockThresholdController,
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              BadgesSettingsCard(isDark: isDark),
                              const SizedBox(height: AppSizes.lg),
                              RegulatorySettingsCard(
                                enforceAge: _enforceAgeSafe,
                                showWarning: _showWarningSafe,
                                onEnforceAgeChanged: (v) => setState(() => _enforceAge = v),
                                onShowWarningChanged: (v) => setState(() => _showWarning = v),
                                isDark: isDark,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              SmokingCessationCard(
                                isEnabled: _enableSmokingCessationSafe,
                                onEnabledChanged: (v) => setState(() => _enableSmokingCessationProgram = v),
                                cessationDiscountController: _cessationDiscountController,
                                defaultPackPriceController: _defaultPackPriceController,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ContactSettingsCard(
                      phoneController: _phoneController,
                      whatsController: _whatsController,
                      emailController: _emailController,
                      addressController: _addressController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    BranchesSettingsCard(
                      branches: _branches,
                      onBranchesChanged: (b) => setState(() => _branches = b),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    DeliverySettingsCard(
                      deliveryFeeController: _deliveryFeeController,
                      thresholdController: _thresholdController,
                      deliveryTimeController: _deliveryTimeController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    StaffCommissionSettingsCard(
                      commissionRateController: _commissionRateController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    LoyaltySettingsCard(
                      isLoyaltyEnabled: _isLoyaltyEnabledSafe,
                      onLoyaltyEnabledChanged: (v) => setState(() => _isLoyaltyEnabled = v),
                      egpPerEarnedPointController: _egpPerEarnedPointController,
                      egpValuePerRedeemedPointController: _egpValuePerRedeemedPointController,
                      minPointsToRedeemController: _minPointsToRedeemController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    GovernoratesDeliveryCard(
                      governorates: _governorates,
                      onGovernoratesChanged: (g) => setState(() => _governorates = g),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    InventorySettingsCard(
                      lowStockThresholdController: _lowStockThresholdController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    BadgesSettingsCard(isDark: isDark),
                    const SizedBox(height: AppSizes.lg),
                    RegulatorySettingsCard(
                      enforceAge: _enforceAgeSafe,
                      showWarning: _showWarningSafe,
                      onEnforceAgeChanged: (v) => setState(() => _enforceAge = v),
                      onShowWarningChanged: (v) => setState(() => _showWarning = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SmokingCessationCard(
                      isEnabled: _enableSmokingCessationSafe,
                      onEnabledChanged: (v) => setState(() => _enableSmokingCessationProgram = v),
                      cessationDiscountController: _cessationDiscountController,
                      defaultPackPriceController: _defaultPackPriceController,
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: AppSizes.lg),
                  FirestoreSettingsCard(isDark: isDark),
                  const SizedBox(height: AppSizes.xl),

                  // Bottom Save Action
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildSaveButton(),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<SettingsCubit>().loadSettings(),
            child: Text('reload_settings'.tr),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
          child: const Icon(
            Icons.settings_suggest_rounded,
            color: AppColor.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings_title'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColor.textPrimaryDark
                      : AppColor.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'settings_subtitle'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : () => _save(context),
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_rounded, size: 18),
      label: Text('save_settings'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.borderRadiusMd,
          ),
        ),
        elevation: 2,
      ),
    );
  }
}
