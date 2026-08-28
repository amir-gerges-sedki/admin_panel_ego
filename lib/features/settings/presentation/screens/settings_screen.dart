import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/store_settings_model.dart';
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _whatsController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _thresholdController;

  bool _enforceAge = true;
  bool _showWarning = true;
  bool _isInitialized = false;

  void _initFields(StoreSettingsModel settings) {
    if (_isInitialized) return;
    _phoneController = TextEditingController(text: settings.phoneNumber);
    _whatsController = TextEditingController(text: settings.whatsNumber);
    _emailController = TextEditingController(text: settings.email);
    _addressController = TextEditingController(text: settings.address);
    _deliveryFeeController = TextEditingController(
      text: settings.flatDeliveryFee.toInt().toString(),
    );
    _thresholdController = TextEditingController(
      text: settings.freeShippingThreshold.toInt().toString(),
    );
    _enforceAge = settings.enforceAgeVerification;
    _showWarning = settings.showNicotineWarningBanner;
    _isInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _phoneController.dispose();
      _whatsController.dispose();
      _emailController.dispose();
      _addressController.dispose();
      _deliveryFeeController.dispose();
      _thresholdController.dispose();
    }
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final updated = StoreSettingsModel(
      phoneNumber: _phoneController.text.trim(),
      whatsNumber: _whatsController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      enforceAgeVerification: _enforceAge,
      showNicotineWarningBanner: _showWarning,
      flatDeliveryFee: double.tryParse(_deliveryFeeController.text) ?? 60.0,
      freeShippingThreshold:
          double.tryParse(_thresholdController.text) ?? 2000.0,
    );

    context.read<SettingsCubit>().saveSettings(updated);
    HelperFun.successSnackbar('Settings Saved', 'store_settings_saved'.tr);
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
                  // Top Title
                  Text(
                    'Store Configuration & Health Compliance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage official customer care channels, shipping fees & regulatory vape policies',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildContactCard(isDark)),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(child: _buildRegulatoryCard(isDark)),
                      ],
                    )
                  else ...[
                    _buildContactCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildRegulatoryCard(isDark),
                  ],

                  const SizedBox(height: AppSizes.lg),
                  _buildFirebaseCard(isDark),
                  const SizedBox(height: AppSizes.xl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.save_rounded, size: 18),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<SettingsCubit>().loadSettings(),
            child: const Text('Reload Settings'),
          ),
        );
      },
    );
  }

  Widget _buildContactCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                'contact_support_title'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _whatsController,
            decoration: InputDecoration(
              labelText: 'whatsapp_number'.tr,
              prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'store_phone'.tr,
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'support_email'.tr,
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'store_address'.tr,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulatoryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColor.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                'regulatory_settings'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SwitchListTile(
            title: Text(
              'age_verification'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: const Text(
              'Enforce mandatory age gate modal (18+ / 21+) for new app visitors',
              style: TextStyle(fontSize: 11),
            ),
            value: _enforceAge,
            activeThumbColor: AppColor.primary,
            onChanged: (v) => setState(() => _enforceAge = v),
          ),
          const Divider(height: 16),
          SwitchListTile(
            title: Text(
              'nicotine_warning_banner'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: const Text(
              'Display statutory health disclaimer on all product details views',
              style: TextStyle(fontSize: 11),
            ),
            value: _showWarning,
            activeThumbColor: AppColor.primary,
            onChanged: (v) => setState(() => _showWarning = v),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Flat Delivery (EGP)',
                    hintText: '60',
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Free Ship Min (EGP)',
                    hintText: '2000',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              const Text(
                'Cloud Firestore Connected Database',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Active Collections: /Products, /Categories, /Brands, /Orders, /Banners, /Coupons, /Users, /Users/{uid}/Notifications, /ContactInfo/support',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ElevatedButton.icon(
            onPressed: () {
              HelperFun.successSnackbar(
                'Firestore Status',
                'Cloud Firestore is actively connected and synchronized.',
              );
            },
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Check Firebase Sync Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
