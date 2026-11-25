import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../data/models/governorate_delivery_model.dart';

/// Settings card for per-governorate shipping delivery fees & toggles
class GovernoratesDeliveryCard extends StatefulWidget {
  final List<GovernorateDeliveryModel> governorates;
  final ValueChanged<List<GovernorateDeliveryModel>> onGovernoratesChanged;
  final bool isDark;

  const GovernoratesDeliveryCard({
    super.key,
    required this.governorates,
    required this.onGovernoratesChanged,
    required this.isDark,
  });

  @override
  State<GovernoratesDeliveryCard> createState() => _GovernoratesDeliveryCardState();
}

class _GovernoratesDeliveryCardState extends State<GovernoratesDeliveryCard> {
  late List<GovernorateDeliveryModel> _govList;
  final _govSearchController = TextEditingController();
  String _govSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _govList = List.from(widget.governorates);
  }

  @override
  void didUpdateWidget(covariant GovernoratesDeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.governorates != oldWidget.governorates) {
      _govList = List.from(widget.governorates);
    }
  }

  @override
  void dispose() {
    _govSearchController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onGovernoratesChanged(List.from(_govList));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filteredGovs = _govList.where((gov) {
      if (_govSearchQuery.isEmpty) return true;
      final query = _govSearchQuery.toLowerCase().trim();
      return gov.nameAr.toLowerCase().contains(query) ||
          gov.nameEn.toLowerCase().contains(query) ||
          gov.id.toLowerCase().contains(query);
    }).toList();

    final activeCount = _govList.where((g) => g.isAvailable == true).length;
    final totalCount = _govList.length;

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
                      _govList = _govList
                          .map((g) => g.copyWith(isAvailable: true))
                          .toList();
                    });
                  } else if (action == 'disable_all') {
                    setState(() {
                      _govList = _govList
                          .map((g) => g.copyWith(isAvailable: false))
                          .toList();
                    });
                  } else if (action == 'set_bulk_fee') {
                    _showBulkPriceDialog(context);
                  } else if (action == 'reset_defaults') {
                    setState(() {
                      _govList =
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
                      _govList = _govList
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
                      _govList = _govList
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
                      _govList.indexWhere((g) => g.id == gov.id);
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
              enabled: gov.isAvailable == true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: (gov.isAvailable == true)
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
                fillColor: (gov.isAvailable == true)
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
                  _govList[originalIndex] =
                      _govList[originalIndex].copyWith(deliveryFee: fee);
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Switch
          Switch.adaptive(
            value: gov.isAvailable == true,
            activeThumbColor: const Color(0xFF6366F1),
            activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
            onChanged: (v) {
              if (originalIndex >= 0) {
                setState(() {
                  _govList[originalIndex] =
                      _govList[originalIndex].copyWith(isAvailable: v);
                });
                _notifyChanged();
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
                  _govList = _govList
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
}