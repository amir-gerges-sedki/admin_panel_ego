import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../data/models/store_branch_model.dart';

/// Settings card for managing physical store branches and GPS locations
class BranchesSettingsCard extends StatefulWidget {
  final List<StoreBranchModel> branches;
  final ValueChanged<List<StoreBranchModel>> onBranchesChanged;
  final bool isDark;

  const BranchesSettingsCard({
    super.key,
    required this.branches,
    required this.onBranchesChanged,
    required this.isDark,
  });

  @override
  State<BranchesSettingsCard> createState() => _BranchesSettingsCardState();
}

class _BranchesSettingsCardState extends State<BranchesSettingsCard> {
  late List<StoreBranchModel> _branchesList;

  @override
  void initState() {
    super.initState();
    _branchesList = List.from(widget.branches);
  }

  @override
  void didUpdateWidget(covariant BranchesSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.branches != oldWidget.branches) {
      _branchesList = List.from(widget.branches);
    }
  }

  void _notifyChanged() {
    widget.onBranchesChanged(List.from(_branchesList));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
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
          if (_branchesList.isEmpty)
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
              itemCount: _branchesList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final branch = _branchesList[index];
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
          color: branch.isPrimary == true
              ? const Color(0xFF10B981)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: branch.isPrimary == true ? 1.5 : 1.0,
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
              if (branch.isPrimary == true) ...[
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
                              _branchesList.removeAt(index);
                            });
                            _notifyChanged();
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
                        _branchesList = _branchesList
                            .map((b) => b.copyWith(isPrimary: false))
                            .toList();
                      }
                      if (index != null &&
                          index >= 0 &&
                          index < _branchesList.length) {
                        _branchesList[index] = updatedBranch;
                      } else {
                        _branchesList.add(updatedBranch);
                      }
                    });
                    _notifyChanged();

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
}