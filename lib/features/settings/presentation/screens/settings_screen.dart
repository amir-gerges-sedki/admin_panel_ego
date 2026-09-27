import '../../../badges/data/models/badge_model.dart';
import '../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../badges/presentation/cubit/badge_state.dart';
import '../../../badges/presentation/widgets/badges_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/governorate_delivery_model.dart';
import '../../data/models/store_branch_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeCubit>().loadBadges();
    });
  }
  late TextEditingController _whatsController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _thresholdController;
  late TextEditingController _deliveryTimeController;
  late TextEditingController _lowStockThresholdController;
  late TextEditingController _govSearchController;

  bool _enforceAge = true;
  bool _showWarning = true;
  bool _isInitialized = false;
  bool _isSaving = false;
  List<StoreBranchModel> _branches = [];
  List<GovernorateDeliveryModel> _governorates = [];
  String _govSearchQuery = '';

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
    _deliveryTimeController = TextEditingController(
      text: settings.estimatedDeliveryTime,
    );
    _lowStockThresholdController = TextEditingController(
      text: settings.lowStockThreshold.toString(),
    );
    _govSearchController = TextEditingController();
    _enforceAge = settings.enforceAgeVerification;
    _showWarning = settings.showNicotineWarningBanner;
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
    if (_isInitialized) {
      _phoneController.dispose();
      _whatsController.dispose();
      _emailController.dispose();
      _addressController.dispose();
      _deliveryFeeController.dispose();
      _thresholdController.dispose();
      _deliveryTimeController.dispose();
      _lowStockThresholdController.dispose();
      _govSearchController.dispose();
    }
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final updated = StoreSettingsModel(
      phoneNumber: _phoneController.text.trim(),
      whatsNumber: _whatsController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      enforceAgeVerification: _enforceAge,
      showNicotineWarningBanner: _showWarning,
      flatDeliveryFee: double.tryParse(_deliveryFeeController.text) ?? 0.0,
      freeShippingThreshold:
          double.tryParse(_thresholdController.text) ?? 2000.0,
      estimatedDeliveryTime: _deliveryTimeController.text.trim(),
      lowStockThreshold:
          int.tryParse(_lowStockThresholdController.text.trim()) ?? 10,
      branches: _branches,
      governorates: _governorates,
    );

    try {
      await context.read<SettingsCubit>().saveSettings(updated);
      if (mounted) {
        HelperFun.successSnackbar('success'.tr, 'store_settings_saved'.tr);
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
                              _buildContactCard(isDark),
                              const SizedBox(height: AppSizes.lg),
                              _buildBranchesCard(isDark),
                              const SizedBox(height: AppSizes.lg),
                              _buildDeliveryCard(isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: Column(
                            children: [
                              _buildGovernoratesDeliveryCard(isDark),
                              const SizedBox(height: AppSizes.lg),
                              _buildInventoryCard(isDark),
                              const SizedBox(height: AppSizes.lg),
                              _buildBadgesCard(isDark),
                              const SizedBox(height: AppSizes.lg),
                              _buildRegulatoryCard(isDark),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildContactCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildBranchesCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildDeliveryCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildGovernoratesDeliveryCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildInventoryCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildBadgesCard(isDark),
                    const SizedBox(height: AppSizes.lg),
                    _buildRegulatoryCard(isDark),
                  ],

                  const SizedBox(height: AppSizes.lg),
                  _buildFirestoreCard(isDark),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'contact_support_title'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'contact_support_subtitle'.tr,
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
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          TextFormField(
            controller: _whatsController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'whatsapp_number'.tr,
              hintText: 'whatsapp_number_hint'.tr,
              prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'required_field'.tr : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'store_phone'.tr,
              hintText: 'store_phone_hint'.tr,
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'required_field'.tr : null,
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'support_email'.tr,
              hintText: 'support_email_hint'.tr,
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'store_address'.tr,
              hintText: 'store_address_hint'.tr,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesCard(bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
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
                      'store_branches'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'store_branches_subtitle'.tr,
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
              ElevatedButton.icon(
                onPressed: () => _showBranchDialog(context),
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: Text('add_branch'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (_branches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 38,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_branches_added'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'no_branches_desc'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _branches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final branch = _branches[index];
                return _buildBranchItem(branch, index, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBranchItem(StoreBranchModel branch, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: branch.isPrimary
              ? const Color(0xFF10B981)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: branch.isPrimary ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      branch.name.isNotEmpty ? branch.name : 'branch_name'.tr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              if (branch.isPrimary) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        'primary_branch_badge'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'edit_branch'.tr,
                onPressed: () =>
                    _showBranchDialog(context, branch: branch, index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                tooltip: 'delete_branch'.tr,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (delCtx) => AlertDialog(
                      title: Text('delete_branch'.tr),
                      content: Text('delete_branch_confirm'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(delCtx),
                          child: Text('cancel'.tr),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _branches.removeAt(index);
                            });
                            Navigator.pop(delCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('delete_branch'.tr),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (branch.address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    branch.address,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          if (branch.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 15,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  branch.phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
          if (branch.mapsUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(branch.mapsUrl);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded,
                        size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      'preview_map'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded,
                        size: 12, color: Color(0xFF0EA5E9)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBranchDialog(BuildContext context,
      {StoreBranchModel? branch, int? index}) {
    final nameController = TextEditingController(text: branch?.name ?? '');
    final phoneController = TextEditingController(text: branch?.phone ?? '');
    final addressController =
        TextEditingController(text: branch?.address ?? '');
    final mapsUrlController =
        TextEditingController(text: branch?.mapsUrl ?? '');
    double? lat = branch?.latitude;
    double? lng = branch?.longitude;
    bool isPrimary = branch?.isPrimary ?? false;
    bool isLocating = false;
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = HelperFun.isDarkMode(dialogCtx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  isDark ? AppColor.darkCard : AppColor.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusSm),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    branch == null ? 'add_branch'.tr : 'edit_branch'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'branch_name'.tr,
                            hintText: 'branch_name_hint'.tr,
                            prefixIcon:
                                const Icon(Icons.badge_outlined, size: 18),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'required_field'.tr
                              : null,
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'branch_phone'.tr,
                            hintText: 'branch_phone_hint'.tr,
                            prefixIcon:
                                const Icon(Icons.phone_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'branch_address'.tr,
                            hintText: 'branch_address_hint'.tr,
                            prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                size: 18),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'required_field'.tr
                              : null,
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextFormField(
                          controller: mapsUrlController,
                          decoration: InputDecoration(
                            labelText: 'maps_link'.tr,
                            hintText: 'maps_link_hint'.tr,
                            prefixIcon:
                                const Icon(Icons.map_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isLocating
                                  ? null
                                  : () async {
                                      setDialogState(
                                          () => isLocating = true);
                                      try {
                                        bool serviceEnabled = await Geolocator
                                            .isLocationServiceEnabled();
                                        if (!serviceEnabled) {
                                          HelperFun.warningSnackbar(
                                            title: 'warning'.tr,
                                            message:
                                                'يرجى تفعيل خدمة الموقع الجغرافي (GPS) في الجهاز/المتصفح',
                                          );
                                          return;
                                        }
                                        LocationPermission permission =
                                            await Geolocator
                                                .checkPermission();
                                        if (permission ==
                                            LocationPermission.denied) {
                                          permission = await Geolocator
                                              .requestPermission();
                                          if (permission ==
                                              LocationPermission.denied) {
                                            HelperFun.warningSnackbar(
                                              title: 'warning'.tr,
                                              message:
                                                  'تم رفض إذن الوصول للموقع',
                                            );
                                            return;
                                          }
                                        }
                                        if (permission ==
                                            LocationPermission
                                                .deniedForever) {
                                          HelperFun.errorSnackbar(
                                            title: 'error'.tr,
                                            message:
                                                'إذن الموقع مرفوض نهائياً، يرجى تفعيله من إعدادات المتصفح',
                                          );
                                          return;
                                        }
                                        final Position pos =
                                            await Geolocator
                                                .getCurrentPosition(
                                          locationSettings:
                                              const LocationSettings(
                                            accuracy: LocationAccuracy.high,
                                            timeLimit:
                                                Duration(seconds: 15),
                                          ),
                                        );
                                        lat = pos.latitude;
                                        lng = pos.longitude;
                                        mapsUrlController.text =
                                            'https://maps.google.com/?q=$lat,$lng';
                                        HelperFun.successSnackbar(
                                          'success'.tr,
                                          '${'location_acquired'.tr} ($lat, $lng)',
                                        );
                                      } catch (e) {
                                        HelperFun.errorSnackbar(
                                          title: 'error'.tr,
                                          message: 'تعذر التقاط الموقع: $e',
                                        );
                                      } finally {
                                        setDialogState(
                                            () => isLocating = false);
                                      }
                                    },
                              icon: isLocating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF10B981),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                      color: Color(0xFF10B981),
                                    ),
                              label: Text(
                                isLocating
                                    ? 'locating'.tr
                                    : 'get_live_location'.tr,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFF10B981)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (mapsUrlController.text.trim().isNotEmpty)
                              TextButton.icon(
                                onPressed: () async {
                                  var raw = mapsUrlController.text.trim();
                                  if (!raw.startsWith('http://') &&
                                      !raw.startsWith('https://') &&
                                      !raw.startsWith('geo:')) {
                                    raw = 'https://$raw';
                                  }
                                  final uri = Uri.tryParse(raw);
                                  if (uri != null) {
                                    try {
                                      await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication);
                                    } catch (_) {}
                                  }
                                },
                                icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 14),
                                label: Text(
                                  'preview_map'.tr,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        if (lat != null && lng != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'is_primary_branch'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: isPrimary,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (v) =>
                              setDialogState(() => isPrimary = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!dialogFormKey.currentState!.validate()) return;
                    final updatedBranch = StoreBranchModel(
                      id: branch?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      mapsUrl: mapsUrlController.text.trim(),
                      latitude: lat,
                      longitude: lng,
                      isPrimary: isPrimary,
                    );

                    setState(() {
                      if (isPrimary) {
                        _branches = _branches
                            .map((b) => b.copyWith(isPrimary: false))
                            .toList();
                      }
                      if (index != null &&
                          index >= 0 &&
                          index < _branches.length) {
                        _branches[index] = updatedBranch;
                      } else {
                        _branches.add(updatedBranch);
                      }
                    });

                    Navigator.pop(dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusSm),
                    ),
                  ),
                  child: Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shipping_delivery_title'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'shipping_delivery_subtitle'.tr,
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
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'flat_delivery_fee'.tr,
                    hintText: 'flat_delivery_fee_hint'.tr,
                    helperText: 'flat_delivery_fee_help'.tr,
                    helperMaxLines: 2,
                    prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (double.tryParse(v) == null) {
                      return 'invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextFormField(
                  controller: _thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'free_shipping_threshold'.tr,
                    hintText: 'free_shipping_threshold_hint'.tr,
                    helperText: 'free_shipping_threshold_help'.tr,
                    helperMaxLines: 2,
                    prefixIcon:
                        const Icon(Icons.card_giftcard_outlined, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'required_field'.tr;
                    }
                    if (double.tryParse(v) == null) {
                      return 'invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          TextFormField(
            controller: _deliveryTimeController,
            decoration: InputDecoration(
              labelText: 'estimated_delivery_time'.tr,
              hintText: 'estimated_delivery_time_hint'.tr,
              helperText: 'estimated_delivery_time_help'.tr,
              prefixIcon: const Icon(Icons.access_time_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernoratesDeliveryCard(bool isDark) {
    final filteredGovs = _governorates.where((gov) {
      if (_govSearchQuery.isEmpty) return true;
      final query = _govSearchQuery.toLowerCase().trim();
      return gov.nameAr.toLowerCase().contains(query) ||
          gov.nameEn.toLowerCase().contains(query) ||
          gov.id.toLowerCase().contains(query);
    }).toList();

    final activeCount = _governorates.where((g) => g.isAvailable).length;
    final totalCount = _governorates.length;

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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'governorates_delivery_title'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$activeCount / $totalCount ${'active'.tr}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'governorates_delivery_subtitle'.tr,
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
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Search & Quick Action Toolbar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _govSearchController,
                    onChanged: (v) {
                      setState(() {
                        _govSearchQuery = v;
                      });
                    },
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'search_governorates_hint'.tr,
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: _govSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _govSearchController.clear();
                                setState(() => _govSearchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'خيارات مجمعة',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    ),
                  ),
                  child: const Icon(Icons.more_vert_rounded, size: 18),
                ),
                onSelected: (action) {
                  if (action == 'enable_all') {
                    setState(() {
                      _governorates = _governorates
                          .map((g) => g.copyWith(isAvailable: true))
                          .toList();
                    });
                  } else if (action == 'disable_all') {
                    setState(() {
                      _governorates = _governorates
                          .map((g) => g.copyWith(isAvailable: false))
                          .toList();
                    });
                  } else if (action == 'set_bulk_fee') {
                    _showBulkPriceDialog(context);
                  } else if (action == 'reset_defaults') {
                    setState(() {
                      _governorates =
                          GovernorateDeliveryModel.defaultGovernorates();
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'set_bulk_fee',
                    child: Row(
                      children: [
                        const Icon(Icons.price_change_outlined,
                            size: 16, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text('set_bulk_fee'.tr,
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'enable_all',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text('enable_all_governorates'.tr,
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disable_all',
                    child: Row(
                      children: [
                        const Icon(Icons.highlight_off_rounded,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text('disable_all_governorates'.tr,
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'reset_defaults',
                    child: Row(
                      children: [
                        const Icon(Icons.restore_rounded,
                            size: 16, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text('reset_governorates_default'.tr,
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Quick Action Pill Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionChip(
                  label: 'set_bulk_fee'.tr,
                  icon: Icons.price_change_outlined,
                  color: const Color(0xFF6366F1),
                  onTap: () => _showBulkPriceDialog(context),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickActionChip(
                  label: 'enable_all_governorates'.tr,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    setState(() {
                      _governorates = _governorates
                          .map((g) => g.copyWith(isAvailable: true))
                          .toList();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildQuickActionChip(
                  label: 'disable_all_governorates'.tr,
                  icon: Icons.highlight_off_rounded,
                  color: Colors.redAccent,
                  onTap: () {
                    setState(() {
                      _governorates = _governorates
                          .map((g) => g.copyWith(isAvailable: false))
                          .toList();
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // List of Governorates inside a height-constrained scroll box
          if (filteredGovs.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 32,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'no_governorates_match'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 460),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredGovs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final gov = filteredGovs[i];
                  final originalIndex =
                      _governorates.indexWhere((g) => g.id == gov.id);
                  return _buildGovernorateItem(gov, originalIndex, isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernorateItem(
      GovernorateDeliveryModel gov, int originalIndex, bool isDark) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final primaryName = isAr ? gov.nameAr : gov.nameEn;
    final secondaryName = isAr ? gov.nameEn : gov.nameAr;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gov.isAvailable
            ? (isDark ? AppColor.darkSubCard : AppColor.lightSubCard)
            : (isDark
                ? AppColor.darkSubCard.withValues(alpha: 0.4)
                : AppColor.lightSubCard.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: gov.isAvailable
              ? (const Color(0xFF6366F1).withValues(alpha: isDark ? 0.3 : 0.2))
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: gov.isAvailable ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: gov.isAvailable
                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_city_rounded,
              size: 16,
              color: gov.isAvailable ? const Color(0xFF6366F1) : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),

          // Governorate Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primaryName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: gov.isAvailable
                        ? (isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight)
                        : (isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight),
                  ),
                ),
                Text(
                  secondaryName,
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

          // Price input
          SizedBox(
            width: 110,
            height: 34,
            child: TextFormField(
              initialValue: gov.deliveryFee.toInt().toString(),
              enabled: gov.isAvailable,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: gov.isAvailable
                    ? (isDark ? Colors.white : AppColor.textPrimaryLight)
                    : Colors.grey,
              ),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                suffixText: 'egp_currency'.tr,
                suffixStyle: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
                filled: true,
                fillColor: gov.isAvailable
                    ? (isDark ? AppColor.darkCard : Colors.white)
                    : (isDark ? Colors.black26 : Colors.grey.shade100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) {
                final fee = double.tryParse(v.trim());
                if (fee != null && fee >= 0 && originalIndex >= 0) {
                  _governorates[originalIndex] =
                      _governorates[originalIndex].copyWith(deliveryFee: fee);
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Switch
          Switch.adaptive(
            value: gov.isAvailable,
            activeThumbColor: const Color(0xFF6366F1),
            activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
            onChanged: (v) {
              if (originalIndex >= 0) {
                setState(() {
                  _governorates[originalIndex] =
                      _governorates[originalIndex].copyWith(isAvailable: v);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBulkPriceDialog(BuildContext context) {
    final controller = TextEditingController(text: '0');
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: const Icon(
                Icons.price_change_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'bulk_fee_title'.tr,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'bulk_fee_desc'.tr,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColor.textSecondaryDark
                    : AppColor.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'shipping_fee_egp'.tr,
                suffixText: 'egp_currency'.tr,
                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final fee = double.tryParse(controller.text.trim());
              if (fee != null && fee >= 0) {
                setState(() {
                  _governorates = _governorates
                      .map((g) => g.copyWith(deliveryFee: fee))
                      .toList();
                });
                Navigator.pop(dialogCtx);
                HelperFun.successSnackbar(
                  'success'.tr,
                  'تم تطبيق سعر $fee ج.م على جميع المحافظات بنجاح',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
            ),
            child: Text('apply'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard(bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'badges'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'badges_subtitle'.tr,
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
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'badges_card_desc'.tr,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Badges dynamic preview row taking colors selected from admin
          BlocBuilder<BadgeCubit, BadgeState>(
            builder: (context, state) {
              final badges = state is BadgeLoaded ? state.badges : <BadgeModel>[];

              Color parseColor(String hex, Color fallback) {
                try {
                  final clean = hex.replaceAll('#', '').trim();
                  return Color(int.parse('FF$clean', radix: 16));
                } catch (_) {
                  return fallback;
                }
              }

              // If admin configured badges in Firestore, display them dynamically with their admin colors!
              if (badges.isNotEmpty) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges.map((badge) {
                    final color = parseColor(badge.colorHex, const Color(0xFFF59E0B));
                    final textColor = parseColor(badge.textColorHex, Colors.white);
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    final label = (isAr && badge.nameAr.trim().isNotEmpty) ? badge.nameAr : badge.name;
                    return _buildSampleBadgeChip(label, color, textColor: textColor);
                  }).toList(),
                );
              }

              // Fallback sample preview with smart lookup for default badges
              Color getColorFor(String defaultName, Color fallback) {
                final match = badges.where((b) => b.name.trim().toUpperCase() == defaultName.toUpperCase()).firstOrNull;
                return match != null ? parseColor(match.colorHex, fallback) : fallback;
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSampleBadgeChip('SALE', getColorFor('SALE', const Color(0xFFEF4444))),
                  _buildSampleBadgeChip('NEW', getColorFor('NEW', const Color(0xFF10B981))),
                  _buildSampleBadgeChip('HOT DEAL', getColorFor('HOT DEAL', const Color(0xFFF59E0B))),
                  _buildSampleBadgeChip('LIMITED', getColorFor('LIMITED', const Color(0xFF0EA5E9))),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton.icon(
            onPressed: () async {
              await BadgesManagementDialog.show(context);
              if (mounted) {
                context.read<BadgeCubit>().loadBadges();
              }
            },
            icon: const Icon(Icons.stars_rounded, size: 18),
            label: Text('manage_badges'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md - 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleBadgeChip(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
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
                padding: const EdgeInsets.all(8),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'regulatory_settings'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'regulatory_subtitle'.tr,
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
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'age_verification'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'age_verification_desc'.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              value: _enforceAge,
              activeThumbColor: AppColor.primary,
              onChanged: (v) => setState(() => _enforceAge = v),
            ),
          ),
          const Divider(height: 16),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'nicotine_warning_banner'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'nicotine_warning_banner_desc'.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              value: _showWarning,
              activeThumbColor: AppColor.primary,
              onChanged: (v) => setState(() => _showWarning = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: AppColor.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'firestore_sync_title'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'firestore_sync_desc'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          OutlinedButton.icon(
            onPressed: () {
              HelperFun.successSnackbar(
                'success'.tr,
                'firestore_sync_active'.tr,
              );
            },
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: Text('check_sync_status'.tr),
            style: OutlinedButton.styleFrom(
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

  Widget _buildInventoryCard(bool isDark) {
    final currentVal = int.tryParse(_lowStockThresholdController.text.trim()) ?? 10;

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
                        color: isDark
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
            controller: _lowStockThresholdController,
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
                backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                side: BorderSide(
                  color: isSelected
                      ? AppColor.warning
                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? AppColor.warning
                      : (isDark ? Colors.white : AppColor.textPrimaryLight),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _lowStockThresholdController.text = preset.toString();
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
