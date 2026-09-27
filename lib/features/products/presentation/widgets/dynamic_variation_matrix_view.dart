import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_form_cubit.dart';
import 'variation_image_dialog.dart';

class DynamicVariationMatrixView extends StatefulWidget {
  const DynamicVariationMatrixView({super.key});

  @override
  State<DynamicVariationMatrixView> createState() =>
      _DynamicVariationMatrixViewState();
}

class _DynamicVariationMatrixViewState
    extends State<DynamicVariationMatrixView> {
  // Common & Non-Liquid Controllers
  late TextEditingController _bulkPriceController;
  late TextEditingController _bulkSalePriceController;
  late TextEditingController _bulkCostPriceController;
  late TextEditingController _bulkStockController;
  late TextEditingController _searchController;
  String _searchQuery = '';

  // Liquid Smart Tier Pricing Controllers
  late TextEditingController _mtlStandardController;
  late TextEditingController _mtlStandardSaleController;
  late TextEditingController _mtl18mgController;
  late TextEditingController _mtl18mgSaleController;
  late TextEditingController _dl3mgController;
  late TextEditingController _dl3mgSaleController;
  late TextEditingController _dl6mgController;
  late TextEditingController _dl6mgSaleController;
  late TextEditingController _salt30mgController;
  late TextEditingController _salt30mgSaleController;
  late TextEditingController _salt50mgController;
  late TextEditingController _salt50mgSaleController;

  String _selectedSizeFilter = 'ALL';
  bool _filterTableBySelectedSize = true;
  int _currentPage = 0;
  static const int _pageSize = 25;
  int _lastSyncedVariationCount = -1;
  String? _lastSyncedSize;

  @override
  void initState() {
    super.initState();
    _bulkPriceController = TextEditingController();
    _bulkSalePriceController = TextEditingController();
    _bulkCostPriceController = TextEditingController();
    _bulkStockController = TextEditingController();
    _searchController = TextEditingController();

    _mtlStandardController = TextEditingController();
    _mtlStandardSaleController = TextEditingController();
    _mtl18mgController = TextEditingController();
    _mtl18mgSaleController = TextEditingController();
    _dl3mgController = TextEditingController();
    _dl3mgSaleController = TextEditingController();
    _dl6mgController = TextEditingController();
    _dl6mgSaleController = TextEditingController();
    _salt30mgController = TextEditingController();
    _salt30mgSaleController = TextEditingController();
    _salt50mgController = TextEditingController();
    _salt50mgSaleController = TextEditingController();
  }

  @override
  void dispose() {
    _bulkPriceController.dispose();
    _bulkSalePriceController.dispose();
    _bulkCostPriceController.dispose();
    _bulkStockController.dispose();
    _searchController.dispose();
    _mtlStandardController.dispose();
    _mtlStandardSaleController.dispose();
    _mtl18mgController.dispose();
    _mtl18mgSaleController.dispose();
    _dl3mgController.dispose();
    _dl3mgSaleController.dispose();
    _dl6mgController.dispose();
    _dl6mgSaleController.dispose();
    _salt30mgController.dispose();
    _salt30mgSaleController.dispose();
    _salt50mgController.dispose();
    _salt50mgSaleController.dispose();
    super.dispose();
  }

  void _syncLiquidTierControllers(
    List<ProductVariationModel> vars, {
    bool force = false,
  }) {
    if (!force &&
        vars.length == _lastSyncedVariationCount &&
        _selectedSizeFilter == _lastSyncedSize) {
      return;
    }
    _lastSyncedVariationCount = vars.length;
    _lastSyncedSize = _selectedSizeFilter;

    if (vars.isEmpty) return;

    final cleanFilter = _selectedSizeFilter.replaceAll(' ', '').toUpperCase();
    final targetVars = cleanFilter == 'ALL'
        ? vars
        : vars
            .where(
              (v) =>
                  (v.attributeValues['Size'] ?? '').replaceAll(' ', '').toUpperCase() ==
                  cleanFilter,
            )
            .toList();

    final searchPool = targetVars.isNotEmpty ? targetVars : vars;

    double? findPrice(bool Function(ProductVariationModel) test) {
      final match = searchPool.where(test).toList();
      if (match.isEmpty) return null;
      return match.first.price > 0 ? match.first.price : match.first.salePrice;
    }

    double? findSalePrice(bool Function(ProductVariationModel) test) {
      final match = searchPool.where(test).toList();
      if (match.isEmpty) return null;
      return match.first.salePrice > 0 ? match.first.salePrice : null;
    }

    // 1. MTL Standard (6 / 9 / 12 / 3 mg)
    bool isMtlStandard(ProductVariationModel v) {
      final style = (v.attributeValues['Style'] ?? '').toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return style == 'MTL' &&
          (nic.contains('6') ||
              nic.contains('9') ||
              nic.contains('12') ||
              nic.contains('3')) &&
          !nic.contains('18') &&
          !nic.contains('30') &&
          !nic.contains('50');
    }
    final mtlPrice = findPrice(isMtlStandard);
    final mtlSale = findSalePrice(isMtlStandard);
    if (mtlPrice != null) {
      _mtlStandardController.text = mtlPrice.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _mtlStandardController.clear();
    }
    if (mtlSale != null) {
      _mtlStandardSaleController.text = mtlSale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _mtlStandardSaleController.clear();
    }

    // 2. DL 3mg
    bool isDl3(ProductVariationModel v) {
      final style = (v.attributeValues['Style'] ?? '').toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return style == 'DL' && nic.contains('3');
    }
    final dl3 = findPrice(isDl3);
    final dl3Sale = findSalePrice(isDl3);
    if (dl3 != null) {
      _dl3mgController.text = dl3.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _dl3mgController.clear();
    }
    if (dl3Sale != null) {
      _dl3mgSaleController.text = dl3Sale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _dl3mgSaleController.clear();
    }

    // 3. DL 6mg
    bool isDl6(ProductVariationModel v) {
      final style = (v.attributeValues['Style'] ?? '').toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return style == 'DL' && nic.contains('6');
    }
    final dl6 = findPrice(isDl6);
    final dl6Sale = findSalePrice(isDl6);
    if (dl6 != null) {
      _dl6mgController.text = dl6.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _dl6mgController.clear();
    }
    if (dl6Sale != null) {
      _dl6mgSaleController.text = dl6Sale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _dl6mgSaleController.clear();
    }

    // 4. Salt Nic 30mg
    bool isSalt30(ProductVariationModel v) {
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return nic.contains('30') || nic.contains('20') || nic.contains('25');
    }
    final salt30 = findPrice(isSalt30);
    final salt30Sale = findSalePrice(isSalt30);
    if (salt30 != null) {
      _salt30mgController.text = salt30.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _salt30mgController.clear();
    }
    if (salt30Sale != null) {
      _salt30mgSaleController.text = salt30Sale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _salt30mgSaleController.clear();
    }

    // 5. Salt Nic 50mg
    bool isSalt50(ProductVariationModel v) {
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return nic.contains('50');
    }
    final salt50 = findPrice(isSalt50);
    final salt50Sale = findSalePrice(isSalt50);
    if (salt50 != null) {
      _salt50mgController.text = salt50.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _salt50mgController.clear();
    }
    if (salt50Sale != null) {
      _salt50mgSaleController.text = salt50Sale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _salt50mgSaleController.clear();
    }

    // 6. MTL 18mg
    bool isMtl18(ProductVariationModel v) {
      final style = (v.attributeValues['Style'] ?? '').toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      return style == 'MTL' && nic.contains('18');
    }
    final mtl18 = findPrice(isMtl18);
    final mtl18Sale = findSalePrice(isMtl18);
    if (mtl18 != null) {
      _mtl18mgController.text = mtl18.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _mtl18mgController.clear();
    }
    if (mtl18Sale != null) {
      _mtl18mgSaleController.text = mtl18Sale.toStringAsFixed(0);
    } else if (cleanFilter != 'ALL') {
      _mtl18mgSaleController.clear();
    }
  }

  /// Checks if any variations exist for a given bottle size and nicotine tier.
  bool _hasTierVariations({
    required List<ProductVariationModel> vars,
    required String size,
    required String tierKey,
  }) {
    final cleanSize = size.replaceAll(' ', '').toUpperCase();
    final sizePool = cleanSize == 'ALL'
        ? vars
        : vars.where((v) {
            final vSize = (v.attributeValues['Size'] ?? '')
                .replaceAll(' ', '')
                .toUpperCase();
            return vSize == cleanSize;
          }).toList();

    return sizePool.any((v) {
      final style = (v.attributeValues['Style'] ?? '').trim().toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').trim().toLowerCase();

      switch (tierKey.toLowerCase()) {
        case 'mtl_standard':
          return (style == 'MTL' || style.isEmpty) &&
              (nic.contains('6') ||
                  nic.contains('9') ||
                  nic.contains('12') ||
                  nic.contains('3')) &&
              !nic.contains('18') &&
              !nic.contains('30') &&
              !nic.contains('50');
        case 'dl3':
          return (style == 'DL' || style.isEmpty) && nic.contains('3');
        case 'dl6':
          return (style == 'DL' || style.isEmpty) && nic.contains('6');
        case 'salt30':
          return nic.contains('30') ||
              nic.contains('20') ||
              nic.contains('25');
        case 'salt50':
          return nic.contains('50');
        case 'mtl18':
          return (style == 'MTL' || style.isEmpty) && nic.contains('18');
        default:
          return false;
      }
    });
  }

  void _applyLiquidTierPrices(BuildContext context, bool isArabic) {
    final mtlPrice = double.tryParse(_mtlStandardController.text);
    final mtlSale = double.tryParse(_mtlStandardSaleController.text);
    final dl3Price = double.tryParse(_dl3mgController.text);
    final dl3Sale = double.tryParse(_dl3mgSaleController.text);
    final dl6Price = double.tryParse(_dl6mgController.text);
    final dl6Sale = double.tryParse(_dl6mgSaleController.text);
    final salt30Price = double.tryParse(_salt30mgController.text);
    final salt30Sale = double.tryParse(_salt30mgSaleController.text);
    final salt50Price = double.tryParse(_salt50mgController.text);
    final salt50Sale = double.tryParse(_salt50mgSaleController.text);
    final mtl18Price = double.tryParse(_mtl18mgController.text);
    final mtl18Sale = double.tryParse(_mtl18mgSaleController.text);

    context.read<ProductFormCubit>().applyLiquidTierPrices(
      targetSize: _selectedSizeFilter == 'ALL' ? null : _selectedSizeFilter,
      mtlStandardPrice: mtlPrice,
      mtlStandardSalePrice: mtlSale,
      dl3mgPrice: dl3Price,
      dl3mgSalePrice: dl3Sale,
      dl6mgPrice: dl6Price,
      dl6mgSalePrice: dl6Sale,
      salt30mgPrice: salt30Price,
      salt30mgSalePrice: salt30Sale,
      salt50mgPrice: salt50Price,
      salt50mgSalePrice: salt50Sale,
      mtl18mgPrice: mtl18Price,
      mtl18mgSalePrice: mtl18Sale,
    );

    if (_selectedSizeFilter != 'ALL') {
      setState(() {
        _filterTableBySelectedSize = true;
        _currentPage = 0;
      });
    }

    final sizeLabel = _selectedSizeFilter == 'ALL'
        ? (isArabic ? 'جميع الأحجام' : 'all sizes')
        : _selectedSizeFilter;

    HelperFun.successSnackbar(
      isArabic ? 'تم تحديث أسعار الفئات' : 'Tier Prices Applied',
      isArabic
          ? 'تم تطبيق أسعار فئات النيكوتين بنجاح على عبوات ($sizeLabel).'
          : 'Nicotine tier prices applied successfully for ($sizeLabel).',
    );
  }

  void _applyBulkStock(BuildContext context, bool isArabic) {
    final stock = int.tryParse(_bulkStockController.text);
    if (stock == null || stock < 0) {
      HelperFun.warningSnackbar(
        title: isArabic ? 'تنبيه' : 'Warning',
        message: isArabic
            ? 'يرجى إدخال كمية مخزون صحيحة'
            : 'Please enter a valid stock quantity',
      );
      return;
    }
    context.read<ProductFormCubit>().bulkUpdateStock(stock);
    HelperFun.successSnackbar(
      isArabic ? 'تم تحديث المخزون' : 'Stock Updated',
      isArabic
          ? 'تم تطبيق كمية المخزون ($stock) على جميع المتغيرات بنجاح.'
          : 'Stock quantity ($stock) applied to all variations successfully.',
    );
  }

  void _applyBulk(BuildContext context, bool isArabic) {
    final price = double.tryParse(_bulkPriceController.text) ?? 0.0;
    final sale = double.tryParse(_bulkSalePriceController.text) ?? price;
    final cost = double.tryParse(_bulkCostPriceController.text) ?? 0.0;
    final stock = int.tryParse(_bulkStockController.text) ?? -1;

    context.read<ProductFormCubit>().applyBulkPriceAndStock(
      price,
      sale,
      stock >= 0 ? stock : 0,
      cost > 0 ? cost : null,
    );
    HelperFun.successSnackbar(
      isArabic ? 'تم تحديث الكل' : 'Bulk Updated',
      isArabic
          ? 'تم تطبيق الأسعار والتكلفة والمخزون على جميع المتغيرات بنجاح.'
          : 'Prices, cost, and stock applied to all variations successfully.',
    );
  }

  Widget _buildTierPriceCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required TextEditingController saleController,
    required Color badgeColor,
    required bool isDark,
    required bool isArabic,
    bool isExcluded = false,
    String? tierKey,
    VoidCallback? onExclude,
  }) {
    return Container(
      width: 165,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isExcluded
            ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100)
            : (isDark ? AppColor.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExcluded
              ? Colors.grey.withValues(alpha: 0.3)
              : badgeColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isExcluded ? Colors.grey : badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExcluded ? Colors.grey : badgeColor,
                    decoration: isExcluded ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (_selectedSizeFilter != 'ALL' && onExclude != null && !isExcluded)
                Tooltip(
                  message: isArabic
                      ? 'استبعاد هذه الفئة من عبوات ($_selectedSizeFilter) لعدم توفرها'
                      : 'Exclude this tier from ($_selectedSizeFilter)',
                  child: InkWell(
                    onTap: onExclude,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 14,
                        color: AppColor.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isExcluded
                ? (isArabic ? 'غير متوفر بهذا الحجم' : 'Not stocked for this size')
                : subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isExcluded ? FontWeight.w600 : FontWeight.normal,
              color: isExcluded
                  ? AppColor.error
                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 6),
          if (isExcluded)
            Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                isArabic ? 'مستبعد من المصفوفة' : 'Excluded',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Column(
              children: [
                // Base Price
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: isArabic ? 'أساسي ' : 'Base ',
                      prefixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                      suffixText: 'ج.م',
                      suffixStyle: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      isDense: true,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Sale Price
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: saleController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                    ),
                    decoration: InputDecoration(
                      prefixText: isArabic ? 'عرض ' : 'Sale ',
                      prefixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669),
                      ),
                      suffixText: 'ج.م',
                      suffixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      isDense: true,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669))
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669))
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSizeChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color color,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, state) {
        final cubit = context.read<ProductFormCubit>();
        final vars = state.variations;
        final color = state.categoryType.accentColor;

        final totalStock = vars.fold<int>(0, (sum, v) => sum + v.stock);
        final totalValue = vars.fold<double>(
          0.0,
          (sum, v) => sum + (v.salePrice * v.stock),
        );

        // Pre-fill general stock/price if empty and state has values
        if (_bulkStockController.text.isEmpty && state.baseStock > 0) {
          _bulkStockController.text = state.baseStock.toString();
        }
        if (_bulkPriceController.text.isEmpty && state.basePrice > 0) {
          _bulkPriceController.text = state.basePrice.toStringAsFixed(0);
        }
        if (_bulkSalePriceController.text.isEmpty && state.salePrice > 0) {
          _bulkSalePriceController.text = state.salePrice.toStringAsFixed(0);
        }
        if (_bulkCostPriceController.text.isEmpty && state.baseCostPrice > 0) {
          _bulkCostPriceController.text = state.baseCostPrice.toStringAsFixed(0);
        }

        // Available sizes in variations
        final availableSizes = vars
            .map((v) => v.attributeValues['Size'])
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (_selectedSizeFilter != 'ALL' && !availableSizes.contains(_selectedSizeFilter)) {
          _selectedSizeFilter = 'ALL';
        }

        // Active tiers presence in variations
        final bool hasMtlStandard = vars.any((v) {
          final style = (v.attributeValues['Style'] ?? '').toUpperCase();
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return style == 'MTL' &&
              (nic.contains('6') ||
                  nic.contains('9') ||
                  nic.contains('12') ||
                  nic.contains('3')) &&
              !nic.contains('18') &&
              !nic.contains('30') &&
              !nic.contains('50');
        });

        final bool hasDl3 = vars.any((v) {
          final style = (v.attributeValues['Style'] ?? '').toUpperCase();
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return style == 'DL' && nic.contains('3');
        });

        final bool hasDl6 = vars.any((v) {
          final style = (v.attributeValues['Style'] ?? '').toUpperCase();
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return style == 'DL' && nic.contains('6');
        });

        final bool hasSalt30 = vars.any((v) {
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return nic.contains('30') || nic.contains('20') || nic.contains('25');
        });

        final bool hasSalt50 = vars.any((v) {
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return nic.contains('50');
        });

        final bool hasMtl18 = vars.any((v) {
          final style = (v.attributeValues['Style'] ?? '').toUpperCase();
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
          return style == 'MTL' && nic.contains('18');
        });

        // Schedule liquid controllers sync without mutating during build
        if (state.categoryType == ProductCategoryType.liquid &&
            vars.isNotEmpty &&
            (vars.length != _lastSyncedVariationCount || _selectedSizeFilter != _lastSyncedSize)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _syncLiquidTierControllers(vars);
            }
          });
        }

        // Filter variations by size and search query
        final indexedVars = vars.asMap().entries.toList();
        final sizeFilteredEntries = (_selectedSizeFilter != 'ALL' && _filterTableBySelectedSize)
            ? indexedVars.where((entry) {
                final vSize = (entry.value.attributeValues['Size'] ?? '')
                    .replaceAll(' ', '')
                    .toUpperCase();
                final target = _selectedSizeFilter.replaceAll(' ', '').toUpperCase();
                return vSize == target;
              }).toList()
            : indexedVars;

        final filteredEntries = _searchQuery.isEmpty
            ? sizeFilteredEntries
            : sizeFilteredEntries.where((entry) {
                final v = entry.value;
                final query = _searchQuery.toLowerCase();
                final skuMatches = v.sku.toLowerCase().contains(query);
                final attrMatches = v.attributeValues.values.any(
                  (val) => val.toLowerCase().contains(query),
                );
                return skuMatches || attrMatches;
              }).toList();

        final totalFiltered = filteredEntries.length;
        final maxPages = totalFiltered > 0 ? (totalFiltered / _pageSize).ceil() : 1;
        if (_currentPage >= maxPages) {
          _currentPage = maxPages > 0 ? maxPages - 1 : 0;
        }
        if (_currentPage < 0) _currentPage = 0;

        final startIndex = _currentPage * _pageSize;
        final endIndex = min(startIndex + _pageSize, totalFiltered);
        final pageEntries = totalFiltered > 0
            ? filteredEntries.sublist(startIndex, endIndex)
            : <MapEntry<int, ProductVariationModel>>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar Banner
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: isDark ? 0.18 : 0.1),
                    color.withValues(alpha: isDark ? 0.06 : 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;

                  final textColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.hub_rounded, size: 18, color: color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'مصفوفة متغيرات الصنف (${vars.length} SKU مفعل)'
                                  : 'Product Variations Matrix (${vars.length} SKUs Active)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColor.textPrimaryDark
                                    : AppColor.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isArabic
                            ? 'توليد تلقائي فوري لجميع الـ SKUs والأسعار والمخزون بناءً على النكهات والمواصفات المختارة'
                            : 'Instant automatic generation of all SKUs, prices, and stock based on chosen specs and flavors',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  );

                  final generateBtn = ElevatedButton.icon(
                    onPressed: () {
                      cubit.generateDynamicVariations();
                      HelperFun.successSnackbar(
                        isArabic ? 'تم التوليد' : 'Generated',
                        isArabic
                            ? 'تم توليد مصفوفة المتغيرات بنجاح.'
                            : 'Variations matrix generated successfully.',
                      );
                    },
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: Text(isArabic ? 'توليد مصفوفة المتغيرات' : 'Generate Matrix'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        textColumn,
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: generateBtn,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: textColumn),
                      const SizedBox(width: 12),
                      generateBtn,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Smart Nicotine Pricing Rule Info Banner (for liquids)
            if (state.categoryType == ProductCategoryType.liquid) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'قاعدة تسعير النيكوتين الذكية: تركيزات (6mg / 9mg / 12mg) متطابقة في السعر تماماً، 3mg الأقل، 18mg أعلى بنسبة طفيفة، وتركيزات السولت (30mg / 50mg) بنسبة أعلى بحسب سعة العبوة.'
                            : 'Smart Nicotine Pricing Rule: (6mg / 9mg / 12mg) share identical pricing; 3mg is lowest; 18mg slightly higher; Salt Nic (30mg / 50mg) higher based on volume.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bulk Editor Bar & Search Field
            if (vars.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Quick Bulk Actions (Bulk Image & Clear)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColor.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.categoryType == ProductCategoryType.liquid
                                ? (isArabic
                                    ? 'التحكم الذكي في أسعار الفئات والمخزون:'
                                    : 'Smart Tier Pricing & Stock Control:')
                                : (isArabic ? 'تعديل جماعي سريع:' : 'Quick Bulk Edit:'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                          tooltip: isArabic
                              ? 'تطبيق صورة جماعية على المتغيرات'
                              : 'Apply bulk image to variations',
                          onPressed: () {
                            if (vars.isNotEmpty) {
                              VariationImageDialog.show(
                                context,
                                variationIndex: 0,
                                variation: vars.first,
                                cubit: cubit,
                                existingProductImages: [
                                  if (state.thumbnail.isNotEmpty) state.thumbnail,
                                  ...state.images,
                                ],
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            color: AppColor.error,
                            size: 20,
                          ),
                          tooltip: isArabic
                              ? 'حذف جميع المتغيرات'
                              : 'Clear all variations',
                          onPressed: () => cubit.clearVariations(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // 1. LIQUID SMART TIER PRICING PANEL
                    if (state.categoryType == ProductCategoryType.liquid) ...[
                      // Size Selector Filter (if multiple bottle sizes exist)
                      if (availableSizes.length > 1) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isArabic ? 'الحجم المستهدف:' : 'Target Size:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColor.textSecondaryDark
                                    : AppColor.textSecondaryLight,
                              ),
                            ),
                            _buildSizeChoiceChip(
                              label: isArabic ? 'كل الأحجام' : 'All Sizes',
                              isSelected: _selectedSizeFilter == 'ALL',
                              color: color,
                              isDark: isDark,
                              onSelected: () {
                                setState(() {
                                  _selectedSizeFilter = 'ALL';
                                  _filterTableBySelectedSize = false;
                                  _currentPage = 0;
                                });
                                _syncLiquidTierControllers(vars, force: true);
                              },
                            ),
                            ...availableSizes.map(
                              (sz) => _buildSizeChoiceChip(
                                label: sz,
                                isSelected: _selectedSizeFilter == sz,
                                color: color,
                                isDark: isDark,
                                onSelected: () {
                                  setState(() {
                                    _selectedSizeFilter = sz;
                                    _filterTableBySelectedSize = true;
                                    _currentPage = 0;
                                  });
                                  _syncLiquidTierControllers(vars, force: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                      ],

                      // Tier Price Inputs Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (hasMtlStandard)
                            _buildTierPriceCard(
                              title: 'MTL (6 / 9 / 12 mg)',
                              subtitle: isArabic ? 'فري بيز موحد' : 'Unified Freebase',
                              controller: _mtlStandardController,
                              saleController: _mtlStandardSaleController,
                              badgeColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'mtl_standard',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'mtl_standard',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                    targetSize: _selectedSizeFilter,
                                    tierKey: 'mtl_standard',
                                  );
                                  HelperFun.successSnackbar(
                                    isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                    isArabic
                                        ? 'تم استبعاد فئة MTL (6 / 9 / 12 mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                        : 'MTL (6 / 9 / 12 mg) excluded from ($_selectedSizeFilter) successfully.',
                                  );
                              },
                            ),
                          if (hasDl3)
                            _buildTierPriceCard(
                              title: 'DL (3mg)',
                              subtitle: isArabic ? 'سعر DL 3mg المستقل' : 'DL 3mg Tier',
                              controller: _dl3mgController,
                              saleController: _dl3mgSaleController,
                              badgeColor: const Color(0xFF0EA5E9),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'dl3',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'dl3',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                  targetSize: _selectedSizeFilter,
                                  tierKey: 'dl3',
                                );
                                HelperFun.successSnackbar(
                                  isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة DL (3mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'DL (3mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasDl6)
                            _buildTierPriceCard(
                              title: 'DL (6mg)',
                              subtitle: isArabic ? 'سعر DL 6mg المستقل' : 'DL 6mg Tier',
                              controller: _dl6mgController,
                              saleController: _dl6mgSaleController,
                              badgeColor: const Color(0xFF0284C7),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'dl6',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'dl6',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                  targetSize: _selectedSizeFilter,
                                  tierKey: 'dl6',
                                );
                                HelperFun.successSnackbar(
                                  isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة DL (6mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'DL (6mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasSalt30)
                            _buildTierPriceCard(
                              title: 'Salt Nic (30mg)',
                              subtitle: isArabic ? 'سولت نيكوتين' : 'Salt Nicotine',
                              controller: _salt30mgController,
                              saleController: _salt30mgSaleController,
                              badgeColor: const Color(0xFFF59E0B),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'salt30',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'salt30',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                  targetSize: _selectedSizeFilter,
                                  tierKey: 'salt30',
                                );
                                HelperFun.successSnackbar(
                                  isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة Salt Nic (30mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'Salt Nic (30mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasSalt50)
                            _buildTierPriceCard(
                              title: 'Salt Nic (50mg)',
                              subtitle: isArabic ? 'سولت نيكوتين عالي' : 'High Salt Nic',
                              controller: _salt50mgController,
                              saleController: _salt50mgSaleController,
                              badgeColor: const Color(0xFFEF4444),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'salt50',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'salt50',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                  targetSize: _selectedSizeFilter,
                                  tierKey: 'salt50',
                                );
                                HelperFun.successSnackbar(
                                  isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة Salt Nic (50mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'Salt Nic (50mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasMtl18)
                            _buildTierPriceCard(
                              title: 'MTL (18mg)',
                              subtitle: isArabic ? 'فري بيز عالي' : 'High Freebase',
                              controller: _mtl18mgController,
                              saleController: _mtl18mgSaleController,
                              badgeColor: const Color(0xFF6366F1),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'mtl18',
                              isExcluded: _selectedSizeFilter != 'ALL' &&
                                  !_hasTierVariations(
                                    vars: vars,
                                    size: _selectedSizeFilter,
                                    tierKey: 'mtl18',
                                  ),
                              onExclude: () {
                                cubit.removeLiquidTierVariations(
                                  targetSize: _selectedSizeFilter,
                                  tierKey: 'mtl18',
                                );
                                HelperFun.successSnackbar(
                                  isArabic ? 'تم استبعاد الفئة' : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة MTL (18mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'MTL (18mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),

                          // Apply Tier Prices Button
                          ElevatedButton.icon(
                            onPressed: () => _applyLiquidTierPrices(context, isArabic),
                            icon: const Icon(Icons.price_check_rounded, size: 16),
                            label: Text(
                              _selectedSizeFilter == 'ALL'
                                  ? (isArabic
                                      ? 'تطبيق أسعار الفئات (لكل الأحجام)'
                                      : 'Apply Tier Prices (All Sizes)')
                                  : (isArabic
                                      ? 'تطبيق أسعار ($_selectedSizeFilter)'
                                      : 'Apply to ($_selectedSizeFilter)'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Global Stock + Search row for Liquids
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 620;

                          final stockField = SizedBox(
                            width: isCompact ? 130 : 140,
                            child: TextField(
                              controller: _bulkStockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'المخزون للكل' : 'Stock for All',
                                hintText: state.baseStock > 0 ? '${state.baseStock}' : '0',
                                isDense: true,
                                suffixText: isArabic ? 'قطع' : 'pcs',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          );

                          final applyStockBtn = OutlinedButton.icon(
                            onPressed: () => _applyBulkStock(context, isArabic),
                            icon: const Icon(Icons.inventory_2_outlined, size: 15),
                            label: Text(
                              isArabic ? 'تطبيق المخزون على الكل' : 'Apply Stock to All',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          );

                          final searchField = TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'بحث في المتغيرات (بالـ SKU أو النكهة أو المقاومة)...'
                                  : 'Search variations (by SKU, flavor, style)...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    stockField,
                                    const SizedBox(width: 8),
                                    Expanded(child: applyStockBtn),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                searchField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              stockField,
                              const SizedBox(width: 8),
                              applyStockBtn,
                              const SizedBox(width: 12),
                              Expanded(child: searchField),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      // 2. NON-LIQUID STANDARD BULK ROW (Devices, Pods, Accessories)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 750;

                          final costPriceField = TextField(
                            controller: _bulkCostPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'سعر التكلفة' : 'Cost Price',
                              hintText: state.baseCostPrice > 0
                                  ? state.baseCostPrice.toStringAsFixed(0)
                                  : '0',
                              isDense: true,
                              prefixText: 'EGP ',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          );

                          final priceField = TextField(
                            controller: _bulkPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'السعر الأساسي' : 'Base Price',
                              hintText: state.basePrice > 0
                                  ? state.basePrice.toStringAsFixed(0)
                                  : '0',
                              isDense: true,
                              prefixText: 'EGP ',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          );

                          final salePriceField = TextField(
                            controller: _bulkSalePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'سعر العرض' : 'Sale Price',
                              hintText: state.salePrice > 0
                                  ? state.salePrice.toStringAsFixed(0)
                                  : '0',
                              isDense: true,
                              prefixText: 'EGP ',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          );

                          final stockField = TextField(
                            controller: _bulkStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'الكمية / المخزون' : 'Stock Quantity',
                              hintText: state.baseStock > 0 ? '${state.baseStock}' : '0',
                              isDense: true,
                              suffixText: isArabic ? 'قطع' : 'units',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          );

                          final applyBtn = ElevatedButton.icon(
                            onPressed: () => _applyBulk(context, isArabic),
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: Text(isArabic ? 'تطبيق على الكل' : 'Apply to All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: costPriceField),
                                    const SizedBox(width: 8),
                                    Expanded(child: priceField),
                                    const SizedBox(width: 8),
                                    Expanded(child: salePriceField),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: stockField),
                                    const SizedBox(width: 8),
                                    applyBtn,
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: costPriceField),
                              const SizedBox(width: 8),
                              Expanded(child: priceField),
                              const SizedBox(width: 8),
                              Expanded(child: salePriceField),
                              const SizedBox(width: 8),
                              Expanded(child: stockField),
                              const SizedBox(width: 8),
                              applyBtn,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: isArabic
                                    ? 'بحث في المتغيرات (بالـ SKU أو اللون أو المقاومة)...'
                                    : 'Search variations (by SKU, color, resistance)...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Variations Table or Empty State
            if (vars.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.view_in_ar_rounded,
                        size: 36,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      isArabic ? 'لم يتم توليد مصفوفة المتغيرات بعد' : 'Variations matrix not generated yet',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'اضغط على زر "توليد مصفوفة المتغيرات" لإنشاء توليفة تلقائية من الـ SKUs والأسعار والمخزون بناءً على الخيارات السابقة'
                          : 'Click "Generate Matrix" to automatically create SKUs, prices, and stock based on chosen specifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton.icon(
                      onPressed: () => cubit.generateDynamicVariations(),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: Text(isArabic ? 'توليد المصفوفة تلقائياً' : 'Auto Generate Matrix'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    // 0. Active Table View Filter Bar
                    if (state.categoryType == ProductCategoryType.liquid && _selectedSizeFilter != 'ALL')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSizes.borderRadiusMd),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 500;
                            final filterText = Row(
                              mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_rounded, size: 14, color: color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _filterTableBySelectedSize
                                        ? (isArabic
                                            ? 'عرض عبوات ($_selectedSizeFilter) فقط ($totalFiltered صنف)'
                                            : 'Viewing ($_selectedSizeFilter) only ($totalFiltered SKUs)')
                                        : (isArabic
                                            ? 'عرض كل الأحجام ($totalFiltered صنف)'
                                            : 'Viewing all sizes ($totalFiltered SKUs)'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );

                            final filterToggleBtn = TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterTableBySelectedSize = !_filterTableBySelectedSize;
                                  _currentPage = 0;
                                });
                              },
                              icon: Icon(
                                _filterTableBySelectedSize
                                    ? Icons.unfold_more_rounded
                                    : Icons.filter_list_rounded,
                                size: 14,
                              ),
                              label: Text(
                                _filterTableBySelectedSize
                                    ? (isArabic ? 'عرض كل الأحجام' : 'Show All Sizes')
                                    : (isArabic ? 'تصفية بـ ($_selectedSizeFilter)' : 'Filter by ($_selectedSizeFilter)'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: color,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  filterText,
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: filterToggleBtn,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: filterText),
                                const SizedBox(width: 8),
                                filterToggleBtn,
                              ],
                            );
                          },
                        ),
                      ),

                    // 1. Table Content (Horizontally scrollable on small screens)
                    LayoutBuilder(
                      builder: (context, tableConstraints) {
                        final tableWidth = max(tableConstraints.maxWidth, 760.0);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColor.darkSubCard.withValues(alpha: 0.8)
                                        : AppColor.lightSubCard,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                        (state.categoryType == ProductCategoryType.liquid &&
                                                _selectedSizeFilter != 'ALL')
                                            ? 0
                                            : AppSizes.borderRadiusMd,
                                      ),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                                      ),
                                    ),
                                  ),
                      child: Row(
                        children: [
                          // Column 1: Image Header
                          SizedBox(
                            width: 44,
                            child: Center(
                              child: Text(
                                isArabic ? 'الصورة' : 'Image',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Column 2: SKU & Specs Header
                          Expanded(
                            flex: 4,
                            child: Text(
                              isArabic
                                  ? 'رمز الصنف (SKU) والمواصفات'
                                  : 'SKU & Specifications',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Column 3: Cost Price Header
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                isArabic ? 'التكلفة (ج.م)' : 'Cost (EGP)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Column 4: Base Price Header
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                isArabic ? 'الأساسي (ج.م)' : 'Base (EGP)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Column 5: Sale Price Header
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                isArabic ? 'العرض (ج.م)' : 'Sale (EGP)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Column 6: Profit & Margin Header
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                isArabic ? 'الربح / الهامش' : 'Profit / Margin',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Column 7: Stock Header
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                isArabic ? 'المخزون' : 'Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Column 8: Action Header
                          SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                isArabic ? 'حذف' : 'Del',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Data Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageEntries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final originalIndex = pageEntries[i].key;
                        final v = pageEntries[i].value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Variation Image Thumbnail / Picker
                              InkWell(
                                onTap: () {
                                  VariationImageDialog.show(
                                    context,
                                    variationIndex: originalIndex,
                                    variation: v,
                                    cubit: cubit,
                                    existingProductImages: [
                                      if (state.thumbnail.isNotEmpty)
                                        state.thumbnail,
                                      ...state.images,
                                    ],
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Tooltip(
                                  message: v.image.isNotEmpty
                                      ? (isArabic
                                          ? 'تعديل صورة المتغير (${v.sku})'
                                          : 'Edit variation image (${v.sku})')
                                      : (isArabic
                                          ? 'إضافة صورة مخصصة لهذا المتغير'
                                          : 'Add custom image for this variation'),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColor.darkSubCard
                                          : AppColor.lightSubCard,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: v.image.isNotEmpty
                                            ? const Color(0xFF6366F1)
                                            : (isDark
                                                  ? AppColor.darkBorder
                                                  : AppColor.lightBorder),
                                        width: v.image.isNotEmpty ? 1.5 : 1,
                                      ),
                                    ),
                                    child: v.image.isNotEmpty
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(7),
                                                child: Image.network(
                                                  v.image,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error, stackTrace) =>
                                                          const Center(
                                                            child: Icon(
                                                              Icons.broken_image_rounded,
                                                              size: 18,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 1,
                                                right: 1,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(
                                                      alpha: 0.6,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    size: 8,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 16,
                                                color: color,
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                isArabic ? 'صورة' : 'Image',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                  color: color,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // SKU & Attributes
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '#${originalIndex + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            v.sku,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 14),
                                          tooltip: isArabic ? 'نسخ رمز الـ SKU' : 'Copy SKU',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: v.sku));
                                            HelperFun.successSnackbar(
                                              isArabic ? 'تم النسخ' : 'Copied',
                                              isArabic ? 'تم نسخ الـ SKU: ${v.sku}' : 'SKU copied: ${v.sku}',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: v.attributeValues.entries.map((e) {
                                        return _buildAttributeTag(e.key, e.value);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Cost Price input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('cost_price_$originalIndex'),
                                  initialValue: v.costPrice > 0 ? v.costPrice.toStringAsFixed(0) : '',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: (isDark
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFD97706))
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF59E0B),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final c = double.tryParse(val) ?? 0.0;
                                    cubit.updateVariationRow(
                                      originalIndex,
                                      v.copyWith(costPrice: c),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Base Price input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('base_price_$originalIndex'),
                                  initialValue: (v.price > 0 ? v.price : v.salePrice).toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColor.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final p = double.tryParse(val) ?? (val.isEmpty ? 0.0 : v.price);
                                    final sp = (v.salePrice == 0 || v.salePrice == v.price) ? p : v.salePrice;
                                    cubit.updateVariationRow(
                                      originalIndex,
                                      v.copyWith(price: p, salePrice: sp),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Sale Price input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('sale_price_$originalIndex'),
                                  initialValue: v.salePrice.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF059669),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: (isDark
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF059669))
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: (isDark
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFF059669))
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF10B981),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final sp = double.tryParse(val) ?? (val.isEmpty ? 0.0 : v.salePrice);
                                    cubit.updateVariationRow(
                                      originalIndex,
                                      v.copyWith(salePrice: sp),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Live Profit Margin Badge
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (v.effectivePrice >= v.costPrice && v.costPrice > 0)
                                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                          : (v.costPrice > v.effectivePrice
                                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                              : Colors.transparent),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: (v.effectivePrice >= v.costPrice && v.costPrice > 0)
                                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                            : (v.costPrice > v.effectivePrice
                                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                                : Colors.transparent),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          v.costPrice > 0
                                              ? '${(v.effectivePrice - v.costPrice) >= 0 ? '+' : ''}${(v.effectivePrice - v.costPrice).toStringAsFixed(0)} EGP'
                                              : '-',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: (v.effectivePrice >= v.costPrice && v.costPrice > 0)
                                                ? const Color(0xFF10B981)
                                                : (v.costPrice > v.effectivePrice
                                                    ? const Color(0xFFEF4444)
                                                    : Colors.grey),
                                          ),
                                        ),
                                        if (v.costPrice > 0 && v.effectivePrice > 0)
                                          Text(
                                            '${v.profitMarginPercent.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: v.profitMarginPercent >= 0
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Stock input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('stock_$originalIndex'),
                                  initialValue: v.stock.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: AppColor.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final s = int.tryParse(val) ?? (val.isEmpty ? 0 : v.stock);
                                    cubit.updateVariationRow(
                                      originalIndex,
                                      v.copyWith(stock: s),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Delete Row
                              SizedBox(
                                width: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColor.error,
                                  ),
                                  tooltip: isArabic
                                      ? 'حذف هذا المتغير'
                                      : 'Delete variation',
                                  onPressed: () =>
                                      cubit.removeVariationRow(originalIndex),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 3. Pagination Controls Bar
                    if (maxPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColor.darkSubCard.withValues(alpha: 0.6)
                              : AppColor.lightSubCard,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(AppSizes.borderRadiusMd),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 550;

                            final countText = Text(
                              isArabic
                                  ? 'عرض ${startIndex + 1} - $endIndex من إجمالي $totalFiltered صنف'
                                  : 'Showing ${startIndex + 1} - $endIndex of $totalFiltered SKUs',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColor.textSecondaryDark
                                    : AppColor.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );

                            final buttonsRow = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 12),
                                  label: Text(isArabic ? 'السابق' : 'Prev'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isArabic
                                        ? 'صفحة ${_currentPage + 1} من $maxPages'
                                        : 'Page ${_currentPage + 1} of $maxPages',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _currentPage < maxPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                  label: Text(isArabic ? 'التالي' : 'Next'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                children: [
                                  countText,
                                  const SizedBox(height: 8),
                                  buttonsRow,
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: countText),
                                const SizedBox(width: 8),
                                buttonsRow,
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Summary KPIs Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 550;
                    if (isCompact) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          _buildFooterMetric(
                            label: isArabic ? 'إجمالي المتغيرات' : 'Total Variations',
                            value: '${vars.length} SKU',
                            icon: Icons.hub_rounded,
                            color: color,
                          ),
                          _buildFooterMetric(
                            label: isArabic ? 'إجمالي الوحدات بالمخزن' : 'Total Units',
                            value: '$totalStock ${isArabic ? "قطعة" : "units"}',
                            icon: Icons.inventory_2_rounded,
                            color: AppColor.primary,
                          ),
                          _buildFooterMetric(
                            label: isArabic ? 'القيمة الإجمالية للمخزون' : 'Total Value',
                            value: AppFormatters.formatEGP(totalValue),
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColor.success,
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFooterMetric(
                          label: isArabic ? 'إجمالي المتغيرات' : 'Total Variations',
                          value: '${vars.length} SKU',
                          icon: Icons.hub_rounded,
                          color: color,
                        ),
                        _buildFooterMetric(
                          label: isArabic ? 'إجمالي الوحدات بالمخزن' : 'Total Units',
                          value: '$totalStock ${isArabic ? "قطعة" : "units"}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColor.primary,
                        ),
                        _buildFooterMetric(
                          label: isArabic ? 'القيمة الإجمالية للمخزون' : 'Total Value',
                          value: AppFormatters.formatEGP(totalValue),
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColor.success,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFooterMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttributeTag(String key, String value) {
    Color tagColor = AppColor.primary;
    final k = key.toLowerCase();
    final isColor = k.contains('color');

    if (k.contains('flavor') || k.contains('flavour')) {
      tagColor = const Color(0xFF10B981); // Emerald
    } else if (k.contains('style') || k.contains('mtl') || k.contains('dl')) {
      tagColor = const Color(0xFF8B5CF6); // Purple
    } else if (k.contains('nic')) {
      tagColor = const Color(0xFFF59E0B); // Amber
    } else if (k.contains('size') || k.contains('capacity')) {
      tagColor = const Color(0xFF0EA5E9); // Cyan
    } else if (isColor) {
      tagColor = const Color(0xFFEC4899); // Pink
    } else if (k.contains('res') || k.contains('ohm')) {
      tagColor = const Color(0xFFF97316); // Orange
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tagColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isColor) ...[
            ColorUtils.buildColorIndicator(value, size: 10),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              isColor ? ColorUtils.getReadableColorName(value) : '$key: $value',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

