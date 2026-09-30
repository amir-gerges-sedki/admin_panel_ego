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

  // Liquid Smart Tier Pricing Controllers (Base, Sale, Cost, and Stock)
  late TextEditingController _mtlStandardController;
  late TextEditingController _mtlStandardSaleController;
  late TextEditingController _mtlStandardCostController;
  late TextEditingController _mtlStandardStockController;

  late TextEditingController _mtl18mgController;
  late TextEditingController _mtl18mgSaleController;
  late TextEditingController _mtl18mgCostController;
  late TextEditingController _mtl18mgStockController;

  late TextEditingController _dl3mgController;
  late TextEditingController _dl3mgSaleController;
  late TextEditingController _dl3mgCostController;
  late TextEditingController _dl3mgStockController;

  late TextEditingController _dl6mgController;
  late TextEditingController _dl6mgSaleController;
  late TextEditingController _dl6mgCostController;
  late TextEditingController _dl6mgStockController;

  late TextEditingController _salt30mgController;
  late TextEditingController _salt30mgSaleController;
  late TextEditingController _salt30mgCostController;
  late TextEditingController _salt30mgStockController;

  late TextEditingController _salt50mgController;
  late TextEditingController _salt50mgSaleController;
  late TextEditingController _salt50mgCostController;
  late TextEditingController _salt50mgStockController;

  String _selectedSizeFilter = 'ALL';
  String _tableSizeFilter = 'ALL';
  int _currentPage = 0;
  static const int _pageSize = 25;
  int _lastSyncedVariationCount = -1;
  String? _lastSyncedSize;

  // In-memory persistent tier drafts per bottle size (e.g. '30ml', '60ml', '100ml')
  final Map<String, _LiquidTierValues> _sizeTierValues = {};

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
    _mtlStandardCostController = TextEditingController();
    _mtlStandardStockController = TextEditingController();

    _mtl18mgController = TextEditingController();
    _mtl18mgSaleController = TextEditingController();
    _mtl18mgCostController = TextEditingController();
    _mtl18mgStockController = TextEditingController();

    _dl3mgController = TextEditingController();
    _dl3mgSaleController = TextEditingController();
    _dl3mgCostController = TextEditingController();
    _dl3mgStockController = TextEditingController();

    _dl6mgController = TextEditingController();
    _dl6mgSaleController = TextEditingController();
    _dl6mgCostController = TextEditingController();
    _dl6mgStockController = TextEditingController();

    _salt30mgController = TextEditingController();
    _salt30mgSaleController = TextEditingController();
    _salt30mgCostController = TextEditingController();
    _salt30mgStockController = TextEditingController();

    _salt50mgController = TextEditingController();
    _salt50mgSaleController = TextEditingController();
    _salt50mgCostController = TextEditingController();
    _salt50mgStockController = TextEditingController();
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
    _mtlStandardCostController.dispose();
    _mtlStandardStockController.dispose();

    _mtl18mgController.dispose();
    _mtl18mgSaleController.dispose();
    _mtl18mgCostController.dispose();
    _mtl18mgStockController.dispose();

    _dl3mgController.dispose();
    _dl3mgSaleController.dispose();
    _dl3mgCostController.dispose();
    _dl3mgStockController.dispose();

    _dl6mgController.dispose();
    _dl6mgSaleController.dispose();
    _dl6mgCostController.dispose();
    _dl6mgStockController.dispose();

    _salt30mgController.dispose();
    _salt30mgSaleController.dispose();
    _salt30mgCostController.dispose();
    _salt30mgStockController.dispose();

    _salt50mgController.dispose();
    _salt50mgSaleController.dispose();
    _salt50mgCostController.dispose();
    _salt50mgStockController.dispose();
    super.dispose();
  }

  void _saveCurrentControllersToDraft(String size) {
    if (size.isEmpty) return;
    final draft = _sizeTierValues.putIfAbsent(size, () => _LiquidTierValues());
    draft.mtlPrice = _mtlStandardController.text;
    draft.mtlSale = _mtlStandardSaleController.text;
    draft.mtlCost = _mtlStandardCostController.text;
    draft.mtlStock = _mtlStandardStockController.text;

    draft.dl3Price = _dl3mgController.text;
    draft.dl3Sale = _dl3mgSaleController.text;
    draft.dl3Cost = _dl3mgCostController.text;
    draft.dl3Stock = _dl3mgStockController.text;

    draft.dl6Price = _dl6mgController.text;
    draft.dl6Sale = _dl6mgSaleController.text;
    draft.dl6Cost = _dl6mgCostController.text;
    draft.dl6Stock = _dl6mgStockController.text;

    draft.salt30Price = _salt30mgController.text;
    draft.salt30Sale = _salt30mgSaleController.text;
    draft.salt30Cost = _salt30mgCostController.text;
    draft.salt30Stock = _salt30mgStockController.text;

    draft.salt50Price = _salt50mgController.text;
    draft.salt50Sale = _salt50mgSaleController.text;
    draft.salt50Cost = _salt50mgCostController.text;
    draft.salt50Stock = _salt50mgStockController.text;

    draft.mtl18Price = _mtl18mgController.text;
    draft.mtl18Sale = _mtl18mgSaleController.text;
    draft.mtl18Cost = _mtl18mgCostController.text;
    draft.mtl18Stock = _mtl18mgStockController.text;
  }

  _LiquidTierValues _extractValuesFromVars(
    String size,
    List<ProductVariationModel> vars,
  ) {
    final cleanFilter = size.replaceAll(' ', '').toUpperCase();
    final targetVars = cleanFilter == 'ALL'
        ? vars
        : vars
              .where(
                (v) =>
                    (v.attributeValues['Size'] ?? '')
                        .replaceAll(' ', '')
                        .toUpperCase() ==
                    cleanFilter,
              )
              .toList();

    final searchPool = targetVars.isNotEmpty ? targetVars : vars;
    final val = _LiquidTierValues();

    for (final v in searchPool) {
      final style = (v.attributeValues['Style'] ?? '').toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();
      final p = v.price > 0 ? v.price : v.salePrice;
      final priceStr = p > 0 ? p.toStringAsFixed(0) : '';
      final saleStr = v.salePrice > 0 ? v.salePrice.toStringAsFixed(0) : '';
      final costStr = v.costPrice > 0 ? v.costPrice.toStringAsFixed(0) : '';
      final stockStr = v.stock > 0 ? v.stock.toString() : '';

      if (style == 'MTL' &&
          (nic.contains('6') ||
              nic.contains('9') ||
              nic.contains('12') ||
              nic.contains('3')) &&
          !nic.contains('18') &&
          !nic.contains('30') &&
          !nic.contains('50')) {
        if (val.mtlPrice.isEmpty) val.mtlPrice = priceStr;
        if (val.mtlSale.isEmpty) val.mtlSale = saleStr;
        if (val.mtlCost.isEmpty) val.mtlCost = costStr;
        if (val.mtlStock.isEmpty) val.mtlStock = stockStr;
      } else if (style == 'DL' && nic.contains('3')) {
        if (val.dl3Price.isEmpty) val.dl3Price = priceStr;
        if (val.dl3Sale.isEmpty) val.dl3Sale = saleStr;
        if (val.dl3Cost.isEmpty) val.dl3Cost = costStr;
        if (val.dl3Stock.isEmpty) val.dl3Stock = stockStr;
      } else if (style == 'DL' && nic.contains('6')) {
        if (val.dl6Price.isEmpty) val.dl6Price = priceStr;
        if (val.dl6Sale.isEmpty) val.dl6Sale = saleStr;
        if (val.dl6Cost.isEmpty) val.dl6Cost = costStr;
        if (val.dl6Stock.isEmpty) val.dl6Stock = stockStr;
      } else if (nic.contains('30') ||
          nic.contains('20') ||
          nic.contains('25')) {
        if (val.salt30Price.isEmpty) val.salt30Price = priceStr;
        if (val.salt30Sale.isEmpty) val.salt30Sale = saleStr;
        if (val.salt30Cost.isEmpty) val.salt30Cost = costStr;
        if (val.salt30Stock.isEmpty) val.salt30Stock = stockStr;
      } else if (nic.contains('50')) {
        if (val.salt50Price.isEmpty) val.salt50Price = priceStr;
        if (val.salt50Sale.isEmpty) val.salt50Sale = saleStr;
        if (val.salt50Cost.isEmpty) val.salt50Cost = costStr;
        if (val.salt50Stock.isEmpty) val.salt50Stock = stockStr;
      } else if (style == 'MTL' && nic.contains('18')) {
        if (val.mtl18Price.isEmpty) val.mtl18Price = priceStr;
        if (val.mtl18Sale.isEmpty) val.mtl18Sale = saleStr;
        if (val.mtl18Cost.isEmpty) val.mtl18Cost = costStr;
        if (val.mtl18Stock.isEmpty) val.mtl18Stock = stockStr;
      }
    }

    return val;
  }

  void _loadControllersFromDraftOrVars(
    String size,
    List<ProductVariationModel> vars,
  ) {
    final draft = _sizeTierValues.putIfAbsent(
      size,
      () => _extractValuesFromVars(size, vars),
    );

    _mtlStandardController.text = draft.mtlPrice;
    _mtlStandardSaleController.text = draft.mtlSale;
    _mtlStandardCostController.text = draft.mtlCost;
    _mtlStandardStockController.text = draft.mtlStock;

    _dl3mgController.text = draft.dl3Price;
    _dl3mgSaleController.text = draft.dl3Sale;
    _dl3mgCostController.text = draft.dl3Cost;
    _dl3mgStockController.text = draft.dl3Stock;

    _dl6mgController.text = draft.dl6Price;
    _dl6mgSaleController.text = draft.dl6Sale;
    _dl6mgCostController.text = draft.dl6Cost;
    _dl6mgStockController.text = draft.dl6Stock;

    _salt30mgController.text = draft.salt30Price;
    _salt30mgSaleController.text = draft.salt30Sale;
    _salt30mgCostController.text = draft.salt30Cost;
    _salt30mgStockController.text = draft.salt30Stock;

    _salt50mgController.text = draft.salt50Price;
    _salt50mgSaleController.text = draft.salt50Sale;
    _salt50mgCostController.text = draft.salt50Cost;
    _salt50mgStockController.text = draft.salt50Stock;

    _mtl18mgController.text = draft.mtl18Price;
    _mtl18mgSaleController.text = draft.mtl18Sale;
    _mtl18mgCostController.text = draft.mtl18Cost;
    _mtl18mgStockController.text = draft.mtl18Stock;
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

    if (_lastSyncedSize != null &&
        _lastSyncedSize!.isNotEmpty &&
        _lastSyncedSize != _selectedSizeFilter) {
      _saveCurrentControllersToDraft(_lastSyncedSize!);
    }

    _lastSyncedVariationCount = vars.length;
    _lastSyncedSize = _selectedSizeFilter;

    if (vars.isEmpty) return;
    _loadControllersFromDraftOrVars(_selectedSizeFilter, vars);
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
          return nic.contains('30') || nic.contains('20') || nic.contains('25');
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
    _saveCurrentControllersToDraft(_selectedSizeFilter);
    final mtlCost = double.tryParse(_mtlStandardCostController.text);
    final mtlPrice = double.tryParse(_mtlStandardController.text);
    final mtlSale = double.tryParse(_mtlStandardSaleController.text);
    final mtlStock = int.tryParse(_mtlStandardStockController.text);

    final dl3Cost = double.tryParse(_dl3mgCostController.text);
    final dl3Price = double.tryParse(_dl3mgController.text);
    final dl3Sale = double.tryParse(_dl3mgSaleController.text);
    final dl3Stock = int.tryParse(_dl3mgStockController.text);

    final dl6Cost = double.tryParse(_dl6mgCostController.text);
    final dl6Price = double.tryParse(_dl6mgController.text);
    final dl6Sale = double.tryParse(_dl6mgSaleController.text);
    final dl6Stock = int.tryParse(_dl6mgStockController.text);

    final salt30Cost = double.tryParse(_salt30mgCostController.text);
    final salt30Price = double.tryParse(_salt30mgController.text);
    final salt30Sale = double.tryParse(_salt30mgSaleController.text);
    final salt30Stock = int.tryParse(_salt30mgStockController.text);

    final salt50Cost = double.tryParse(_salt50mgCostController.text);
    final salt50Price = double.tryParse(_salt50mgController.text);
    final salt50Sale = double.tryParse(_salt50mgSaleController.text);
    final salt50Stock = int.tryParse(_salt50mgStockController.text);

    final mtl18Cost = double.tryParse(_mtl18mgCostController.text);
    final mtl18Price = double.tryParse(_mtl18mgController.text);
    final mtl18Sale = double.tryParse(_mtl18mgSaleController.text);
    final mtl18Stock = int.tryParse(_mtl18mgStockController.text);

    context.read<ProductFormCubit>().applyLiquidTierPrices(
      targetSize: _selectedSizeFilter == 'ALL' ? null : _selectedSizeFilter,
      mtlStandardCostPrice: mtlCost,
      mtlStandardPrice: mtlPrice,
      mtlStandardSalePrice: mtlSale,
      mtlStandardStock: mtlStock,
      dl3mgCostPrice: dl3Cost,
      dl3mgPrice: dl3Price,
      dl3mgSalePrice: dl3Sale,
      dl3mgStock: dl3Stock,
      dl6mgCostPrice: dl6Cost,
      dl6mgPrice: dl6Price,
      dl6mgSalePrice: dl6Sale,
      dl6mgStock: dl6Stock,
      salt30mgCostPrice: salt30Cost,
      salt30mgPrice: salt30Price,
      salt30mgSalePrice: salt30Sale,
      salt30mgStock: salt30Stock,
      salt50mgCostPrice: salt50Cost,
      salt50mgPrice: salt50Price,
      salt50mgSalePrice: salt50Sale,
      salt50mgStock: salt50Stock,
      mtl18mgCostPrice: mtl18Cost,
      mtl18mgPrice: mtl18Price,
      mtl18mgSalePrice: mtl18Sale,
      mtl18mgStock: mtl18Stock,
    );

    final sizeLabel = _selectedSizeFilter == 'ALL'
        ? (isArabic ? 'جميع الأحجام' : 'all sizes')
        : _selectedSizeFilter;

    HelperFun.successSnackbar(
      isArabic
          ? 'تم تحديث الأسعار والتكلفة والمخزون'
          : 'Tier Prices, Cost & Stock Applied',
      isArabic
          ? 'تم تطبيق أسعار وتكلفة ومخزون فئات النيكوتين بنجاح على عبوات ($sizeLabel).'
          : 'Nicotine tier prices, costs & stock applied successfully for ($sizeLabel).',
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
    required TextEditingController costController,
    required TextEditingController controller,
    required TextEditingController saleController,
    required TextEditingController stockController,
    required Color badgeColor,
    required bool isDark,
    required bool isArabic,
    bool isExcluded = false,
    String? tierKey,
    VoidCallback? onExclude,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isExcluded
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade100)
            : (isDark ? AppColor.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExcluded
              ? (isDark ? AppColor.darkBorder : AppColor.lightBorder)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
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
                  color: isExcluded ? Colors.grey : badgeColor.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExcluded
                        ? Colors.grey
                        : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                    decoration: isExcluded ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (_selectedSizeFilter != 'ALL' &&
                  onExclude != null &&
                  !isExcluded)
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
                ? (isArabic
                      ? 'غير متوفر بهذا الحجم'
                      : 'Not stocked for this size')
                : subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isExcluded ? FontWeight.w600 : FontWeight.normal,
              color: isExcluded
                  ? AppColor.error
                  : (isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 6),
          if (isExcluded)
            Container(
              height: 132,
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
                // 1. Cost Price (سعر التكلفة)
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (val) =>
                        _saveCurrentControllersToDraft(_selectedSizeFilter),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      prefixText: isArabic ? 'تكلفة ' : 'Cost ',
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
                        fontWeight: FontWeight.w600,
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
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white70 : AppColor.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 2. Base Price (السعر الأساسي)
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (val) =>
                        _saveCurrentControllersToDraft(_selectedSizeFilter),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
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
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white70 : AppColor.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 3. Sale Price (سعر العرض)
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: saleController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (val) =>
                        _saveCurrentControllersToDraft(_selectedSizeFilter),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669),
                    ),
                    decoration: InputDecoration(
                      prefixText: isArabic ? 'عرض ' : 'Sale ',
                      prefixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
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
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 4. Stock Quantity (الكمية / المخزون)
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (val) =>
                        _saveCurrentControllersToDraft(_selectedSizeFilter),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      prefixText: isArabic ? 'مخزون ' : 'Stock ',
                      prefixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                      suffixText: isArabic ? 'ق' : 'pcs',
                      suffixStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
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
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white70 : AppColor.primary,
                          width: 1.2,
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

        // Pre-fill general stock/price if empty from state or existing variations
        if (_bulkPriceController.text.isEmpty) {
          final p = state.basePrice > 0
              ? state.basePrice
              : (vars.any((v) => v.price > 0)
                    ? vars.firstWhere((v) => v.price > 0).price
                    : 0.0);
          if (p > 0) _bulkPriceController.text = p.toStringAsFixed(0);
        }
        if (_bulkSalePriceController.text.isEmpty) {
          final sp = state.salePrice > 0
              ? state.salePrice
              : (vars.any((v) => v.salePrice > 0)
                    ? vars.firstWhere((v) => v.salePrice > 0).salePrice
                    : 0.0);
          if (sp > 0) _bulkSalePriceController.text = sp.toStringAsFixed(0);
        }
        if (_bulkCostPriceController.text.isEmpty) {
          final cp = state.baseCostPrice > 0
              ? state.baseCostPrice
              : (vars.any((v) => v.costPrice > 0)
                    ? vars.firstWhere((v) => v.costPrice > 0).costPrice
                    : 0.0);
          if (cp > 0) _bulkCostPriceController.text = cp.toStringAsFixed(0);
        }
        if (_bulkStockController.text.isEmpty) {
          final st = state.baseStock > 0
              ? state.baseStock
              : (vars.any((v) => v.stock > 0)
                    ? vars.firstWhere((v) => v.stock > 0).stock
                    : 0);
          if (st > 0) _bulkStockController.text = st.toString();
        }

        // Available sizes in variations
        final availableSizes = vars
            .map((v) => v.attributeValues['Size'])
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (state.categoryType == ProductCategoryType.liquid) {
          if ((_selectedSizeFilter == 'ALL' ||
                  !availableSizes.contains(_selectedSizeFilter)) &&
              availableSizes.isNotEmpty) {
            _selectedSizeFilter = availableSizes.first;
          }
        } else {
          if (_selectedSizeFilter != 'ALL' &&
              !availableSizes.contains(_selectedSizeFilter)) {
            _selectedSizeFilter = 'ALL';
          }
        }

        if (_tableSizeFilter != 'ALL' &&
            !availableSizes.contains(_tableSizeFilter)) {
          _tableSizeFilter = 'ALL';
        }

        // Active tiers presence in variations (single high-performance pass)
        bool hasMtlStandard = false;
        bool hasDl3 = false;
        bool hasDl6 = false;
        bool hasSalt30 = false;
        bool hasSalt50 = false;
        bool hasMtl18 = false;

        for (final v in vars) {
          final style = (v.attributeValues['Style'] ?? '').toUpperCase();
          final nic = (v.attributeValues['Nicotine'] ?? '').toLowerCase();

          if (!hasMtlStandard &&
              style == 'MTL' &&
              (nic.contains('6') ||
                  nic.contains('9') ||
                  nic.contains('12') ||
                  nic.contains('3')) &&
              !nic.contains('18') &&
              !nic.contains('30') &&
              !nic.contains('50')) {
            hasMtlStandard = true;
          }
          if (!hasDl3 && style == 'DL' && nic.contains('3')) {
            hasDl3 = true;
          }
          if (!hasDl6 && style == 'DL' && nic.contains('6')) {
            hasDl6 = true;
          }
          if (!hasSalt30 &&
              (nic.contains('30') ||
                  nic.contains('20') ||
                  nic.contains('25'))) {
            hasSalt30 = true;
          }
          if (!hasSalt50 && nic.contains('50')) {
            hasSalt50 = true;
          }
          if (!hasMtl18 && style == 'MTL' && nic.contains('18')) {
            hasMtl18 = true;
          }
        }

        // Schedule liquid controllers sync without mutating during build
        if (state.categoryType == ProductCategoryType.liquid &&
            vars.isNotEmpty &&
            (vars.length != _lastSyncedVariationCount ||
                _selectedSizeFilter != _lastSyncedSize)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _syncLiquidTierControllers(vars);
            }
          });
        }

        // Filter variations by table size filter and search query
        final cleanTableFilter = _tableSizeFilter
            .replaceAll(' ', '')
            .toUpperCase();
        final indexedVars = vars.asMap().entries.toList();
        final sizeFilteredEntries = (cleanTableFilter == 'ALL')
            ? indexedVars
            : indexedVars.where((entry) {
                final vSize = (entry.value.attributeValues['Size'] ?? '')
                    .replaceAll(' ', '')
                    .toUpperCase();
                return vSize == cleanTableFilter;
              }).toList();

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
        final maxPages = totalFiltered > 0
            ? (totalFiltered / _pageSize).ceil()
            : 1;
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hub_rounded, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isArabic
                                    ? 'مصفوفة المتغيرات'
                                    : 'Variations Matrix',
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isArabic
                                    ? '${vars.length} SKU مفعل'
                                    : '${vars.length} Active SKUs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic
                              ? 'تم توليد المتغيرات تلقائياً بناءً على المواصفات — يمكنك تعديل الأسعار، الأكواد، أو المخزون مباشرة'
                              : 'Variations generated automatically based on specifications — edit prices, SKUs, or stock directly',
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
            ),
            const SizedBox(height: AppSizes.md),

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
                                      ? 'التحكم الذكي في أسعار وتكلفة الفئات والمخزون:'
                                      : 'Smart Tier Pricing, Cost & Stock Control:')
                                : (isArabic
                                      ? 'تعديل جماعي سريع:'
                                      : 'Quick Bulk Edit:'),
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
                                  if (state.thumbnail.isNotEmpty)
                                    state.thumbnail,
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
                          onPressed: () {
                            _sizeTierValues.clear();
                            cubit.clearVariations();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // 1. LIQUID SMART TIER PRICING PANEL
                    if (state.categoryType == ProductCategoryType.liquid) ...[
                      // Size Selector Filter (Direct Bottle Sizes without confusing 'All')
                      if (availableSizes.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isArabic
                                  ? 'سعة العبوة المستهدفة:'
                                  : 'Target Bottle Size:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColor.textSecondaryDark
                                    : AppColor.textSecondaryLight,
                              ),
                            ),
                            ...availableSizes.map(
                              (sz) => _buildSizeChoiceChip(
                                label: sz,
                                isSelected: _selectedSizeFilter == sz,
                                color: color,
                                isDark: isDark,
                                onSelected: () {
                                  _saveCurrentControllersToDraft(
                                    _selectedSizeFilter,
                                  );
                                  setState(() {
                                    _selectedSizeFilter = sz;
                                  });
                                  _syncLiquidTierControllers(vars, force: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                      ],

                      // Tier Price & Cost Inputs Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (hasMtlStandard)
                            _buildTierPriceCard(
                              title: 'MTL (6 / 9 / 12 mg)',
                              subtitle: isArabic
                                  ? 'فري بيز موحد'
                                  : 'Unified Freebase',
                              costController: _mtlStandardCostController,
                              controller: _mtlStandardController,
                              saleController: _mtlStandardSaleController,
                              stockController: _mtlStandardStockController,
                              badgeColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'mtl_standard',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة MTL (6 / 9 / 12 mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'MTL (6 / 9 / 12 mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasDl3)
                            _buildTierPriceCard(
                              title: 'DL (3mg)',
                              subtitle: isArabic
                                  ? 'سعر DL 3mg المستقل'
                                  : 'DL 3mg Tier',
                              costController: _dl3mgCostController,
                              controller: _dl3mgController,
                              saleController: _dl3mgSaleController,
                              stockController: _dl3mgStockController,
                              badgeColor: const Color(0xFF0EA5E9),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'dl3',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة DL (3mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'DL (3mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasDl6)
                            _buildTierPriceCard(
                              title: 'DL (6mg)',
                              subtitle: isArabic
                                  ? 'سعر DL 6mg المستقل'
                                  : 'DL 6mg Tier',
                              costController: _dl6mgCostController,
                              controller: _dl6mgController,
                              saleController: _dl6mgSaleController,
                              stockController: _dl6mgStockController,
                              badgeColor: const Color(0xFF0284C7),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'dl6',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة DL (6mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'DL (6mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasSalt30)
                            _buildTierPriceCard(
                              title: 'Salt Nic (30mg)',
                              subtitle: isArabic
                                  ? 'سولت نيكوتين'
                                  : 'Salt Nicotine',
                              costController: _salt30mgCostController,
                              controller: _salt30mgController,
                              saleController: _salt30mgSaleController,
                              stockController: _salt30mgStockController,
                              badgeColor: const Color(0xFFF59E0B),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'salt30',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة Salt Nic (30mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'Salt Nic (30mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasSalt50)
                            _buildTierPriceCard(
                              title: 'Salt Nic (50mg)',
                              subtitle: isArabic
                                  ? 'سولت نيكوتين عالي'
                                  : 'High Salt Nic',
                              costController: _salt50mgCostController,
                              controller: _salt50mgController,
                              saleController: _salt50mgSaleController,
                              stockController: _salt50mgStockController,
                              badgeColor: const Color(0xFFEF4444),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'salt50',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة Salt Nic (50mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'Salt Nic (50mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),
                          if (hasMtl18)
                            _buildTierPriceCard(
                              title: 'MTL (18mg)',
                              subtitle: isArabic
                                  ? 'فري بيز عالي'
                                  : 'High Freebase',
                              costController: _mtl18mgCostController,
                              controller: _mtl18mgController,
                              saleController: _mtl18mgSaleController,
                              stockController: _mtl18mgStockController,
                              badgeColor: const Color(0xFF6366F1),
                              isDark: isDark,
                              isArabic: isArabic,
                              tierKey: 'mtl18',
                              isExcluded:
                                  _selectedSizeFilter != 'ALL' &&
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
                                  isArabic
                                      ? 'تم استبعاد الفئة'
                                      : 'Tier Excluded',
                                  isArabic
                                      ? 'تم استبعاد فئة MTL (18mg) من عبوات ($_selectedSizeFilter) بنجاح.'
                                      : 'MTL (18mg) excluded from ($_selectedSizeFilter) successfully.',
                                );
                              },
                            ),

                          // Apply Tier Prices Button
                          ElevatedButton.icon(
                            onPressed: () =>
                                _applyLiquidTierPrices(context, isArabic),
                            icon: const Icon(
                              Icons.price_check_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _selectedSizeFilter == 'ALL'
                                  ? (isArabic
                                        ? 'تطبيق أسعار وتكلفة الفئات'
                                        : 'Apply Tier Prices & Cost')
                                  : (isArabic
                                        ? 'تطبيق أسعار وتكلفة ($_selectedSizeFilter)'
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
                                labelText: isArabic
                                    ? 'المخزون للكل'
                                    : 'Stock for All',
                                hintText: state.baseStock > 0
                                    ? '${state.baseStock}'
                                    : '0',
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
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 15,
                            ),
                            label: Text(
                              isArabic
                                  ? 'تطبيق المخزون على الكل'
                                  : 'Apply Stock to All',
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
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 16,
                                      ),
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
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
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
                            onChanged: (val) {
                              final c = double.tryParse(val.trim()) ?? 0.0;
                              cubit.updateBasicInfo(baseCostPrice: c);
                            },
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'سعر التكلفة'
                                  : 'Cost Price',
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
                            onChanged: (val) {
                              final p = double.tryParse(val.trim()) ?? 0.0;
                              cubit.updateBasicInfo(basePrice: p);
                            },
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'السعر الأساسي'
                                  : 'Base Price',
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
                            onChanged: (val) {
                              final sp = double.tryParse(val.trim()) ?? 0.0;
                              cubit.updateBasicInfo(salePrice: sp);
                            },
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
                            onChanged: (val) {
                              final s = int.tryParse(val.trim()) ?? 0;
                              cubit.updateBasicInfo(baseStock: s);
                            },
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'الكمية / المخزون'
                                  : 'Stock Quantity',
                              hintText: state.baseStock > 0
                                  ? '${state.baseStock}'
                                  : '0',
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
                            label: Text(
                              isArabic ? 'تطبيق على الكل' : 'Apply to All',
                            ),
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
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 16,
                                        ),
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
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
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
                      isArabic
                          ? 'لم يتم توليد مصفوفة المتغيرات بعد'
                          : 'Variations matrix not generated yet',
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
                      onPressed: () {
                        _sizeTierValues.clear();
                        cubit.generateDynamicVariations();
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: Text(
                        isArabic
                            ? 'توليد المصفوفة تلقائياً'
                            : 'Auto Generate Matrix',
                      ),
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
                    // 0. Premium Dropdown Table Filter Toolbar
                    if (availableSizes.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSizes.borderRadiusMd),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 600;

                            final dropdownButton = PopupMenuButton<String>(
                              initialValue: _tableSizeFilter,
                              tooltip: isArabic
                                  ? 'تصفية الجدول حسب الحجم'
                                  : 'Filter table by size',
                              offset: const Offset(0, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColor.darkBorder
                                      : AppColor.lightBorder,
                                ),
                              ),
                              color: isDark ? AppColor.darkCard : Colors.white,
                              elevation: 8,
                              onSelected: (val) {
                                setState(() {
                                  _tableSizeFilter = val;
                                  _currentPage = 0;
                                });
                              },
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'ALL',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.apps_rounded,
                                            size: 16,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            isArabic
                                                ? 'جميع الأحجام والسعات'
                                                : 'All Sizes & Capacities',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  _tableSizeFilter == 'ALL'
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: _tableSizeFilter == 'ALL'
                                                  ? color
                                                  : (isDark
                                                        ? AppColor
                                                              .textPrimaryDark
                                                        : AppColor
                                                              .textPrimaryLight),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${vars.length}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                        if (_tableSizeFilter == 'ALL') ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: color,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(height: 1),
                                  ...availableSizes.map((sz) {
                                    final count = vars.where((v) {
                                      final vSize =
                                          (v.attributeValues['Size'] ?? '')
                                              .replaceAll(' ', '')
                                              .toUpperCase();
                                      return vSize ==
                                          sz.replaceAll(' ', '').toUpperCase();
                                    }).length;
                                    final isSelected = _tableSizeFilter == sz;

                                    return PopupMenuItem<String>(
                                      value: sz,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? color.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : (isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.06,
                                                              )
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.04,
                                                              )),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.liquor_rounded,
                                              size: 16,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              isArabic
                                                  ? 'عبوة $sz'
                                                  : 'Size $sz',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? color
                                                    : (isDark
                                                          ? AppColor
                                                                .textPrimaryDark
                                                          : AppColor
                                                                .textPrimaryLight),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? color.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : (isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.08,
                                                              )
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.05,
                                                              )),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$count SKU',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? color
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: color,
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ];
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColor.darkCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _tableSizeFilter != 'ALL'
                                        ? color.withValues(alpha: 0.6)
                                        : (isDark
                                              ? AppColor.darkBorder
                                              : AppColor.lightBorder),
                                    width: _tableSizeFilter != 'ALL'
                                        ? 1.5
                                        : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_list_rounded,
                                      size: 16,
                                      color: _tableSizeFilter != 'ALL'
                                          ? color
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isArabic
                                          ? 'تصفية الحجم:'
                                          : 'Size Filter:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColor.textSecondaryDark
                                            : AppColor.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: isDark ? 0.22 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _tableSizeFilter == 'ALL'
                                            ? (isArabic
                                                  ? 'جميع الأحجام (${vars.length})'
                                                  : 'All Sizes (${vars.length})')
                                            : (isArabic
                                                  ? 'عبوة $_tableSizeFilter'
                                                  : _tableSizeFilter),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: isDark
                                          ? AppColor.textSecondaryDark
                                          : AppColor.textSecondaryLight,
                                    ),
                                  ],
                                ),
                              ),
                            );

                            final rightControls = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_tableSizeFilter != 'ALL')
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _tableSizeFilter = 'ALL';
                                        _currentPage = 0;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      margin: const EdgeInsetsDirectional.only(
                                        end: 8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColor.error.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.close_rounded,
                                            size: 12,
                                            color: AppColor.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isArabic
                                                ? 'إلغاء التصفية'
                                                : 'Reset Filter',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isArabic
                                        ? 'معروض: $totalFiltered من أصل ${vars.length} SKU'
                                        : 'Showing: $totalFiltered of ${vars.length} SKUs',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColor.textSecondaryDark
                                          : AppColor.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dropdownButton,
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: rightControls,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [dropdownButton, rightControls],
                            );
                          },
                        ),
                      ),

                    // 1. Table Content (Horizontally scrollable on small screens)
                    LayoutBuilder(
                      builder: (context, tableConstraints) {
                        final tableWidth = max(
                          tableConstraints.maxWidth,
                          760.0,
                        );
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
                                        ? AppColor.darkSubCard.withValues(
                                            alpha: 0.8,
                                          )
                                        : AppColor.lightSubCard,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                        availableSizes.length > 1
                                            ? 0
                                            : AppSizes.borderRadiusMd,
                                      ),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? AppColor.darkBorder
                                            : AppColor.lightBorder,
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
                                            isArabic
                                                ? 'التكلفة (ج.م)'
                                                : 'Cost (EGP)',
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

                                      // Column 4: Base Price Header
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            isArabic
                                                ? 'الأساسي (ج.م)'
                                                : 'Base (EGP)',
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
                                            isArabic
                                                ? 'العرض (ج.م)'
                                                : 'Sale (EGP)',
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

                                      // Column 6: Profit & Margin Header
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            isArabic
                                                ? 'الربح / الهامش'
                                                : 'Profit / Margin',
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
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
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
                                                  if (state
                                                      .thumbnail
                                                      .isNotEmpty)
                                                    state.thumbnail,
                                                  ...state.images,
                                                ],
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: v.image.isNotEmpty
                                                        ? const Color(
                                                            0xFF6366F1,
                                                          )
                                                        : (isDark
                                                              ? AppColor
                                                                    .darkBorder
                                                              : AppColor
                                                                    .lightBorder),
                                                    width: v.image.isNotEmpty
                                                        ? 1.5
                                                        : 1,
                                                  ),
                                                ),
                                                child: v.image.isNotEmpty
                                                    ? Stack(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  7,
                                                                ),
                                                            child: Image.network(
                                                              v.image,
                                                              width: 44,
                                                              height: 44,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) => const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .broken_image_rounded,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            bottom: 1,
                                                            right: 1,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.6,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons.edit,
                                                                size: 8,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_a_photo_outlined,
                                                            size: 16,
                                                            color: color,
                                                          ),
                                                          const SizedBox(
                                                            height: 1,
                                                          ),
                                                          Text(
                                                            isArabic
                                                                ? 'صورة'
                                                                : 'Image',
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(
                                                          alpha: 0.15,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '#${originalIndex + 1}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: color,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        v.sku,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.copy_rounded,
                                                        size: 14,
                                                      ),
                                                      tooltip: isArabic
                                                          ? 'نسخ رمز الـ SKU'
                                                          : 'Copy SKU',
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () {
                                                        Clipboard.setData(
                                                          ClipboardData(
                                                            text: v.sku,
                                                          ),
                                                        );
                                                        HelperFun.successSnackbar(
                                                          isArabic
                                                              ? 'تم النسخ'
                                                              : 'Copied',
                                                          isArabic
                                                              ? 'تم نسخ الـ SKU: ${v.sku}'
                                                              : 'SKU copied: ${v.sku}',
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: v
                                                      .attributeValues
                                                      .entries
                                                      .map((e) {
                                                        return _buildAttributeTag(
                                                          e.key,
                                                          e.value,
                                                        );
                                                      })
                                                      .toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Cost Price input
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              key: ValueKey(
                                                'cost_price_${v.id}_${v.sku}_${state.matrixRevision}',
                                              ),
                                              initialValue: v.costPrice > 0
                                                  ? v.costPrice.toStringAsFixed(
                                                      0,
                                                    )
                                                  : '',
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColor.textPrimaryDark
                                                    : AppColor.textPrimaryLight,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                hintText: '0',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          BorderSide(
                                                            color: isDark
                                                                ? Colors.white70
                                                                : AppColor.primary,
                                                            width: 1.2,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                final c =
                                                    double.tryParse(val) ?? 0.0;
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
                                              key: ValueKey(
                                                'base_price_${v.id}_${v.sku}_${state.matrixRevision}',
                                              ),
                                              initialValue:
                                                  (v.price > 0
                                                          ? v.price
                                                          : v.salePrice)
                                                      .toStringAsFixed(0),
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                hintText: '0',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: isDark
                                                            ? AppColor
                                                                  .darkBorder
                                                            : AppColor
                                                                  .lightBorder,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColor
                                                                .primary,
                                                            width: 1.5,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                final p =
                                                    double.tryParse(val) ??
                                                    (val.isEmpty
                                                        ? 0.0
                                                        : v.price);
                                                final sp =
                                                    (v.salePrice == 0 ||
                                                        v.salePrice == v.price)
                                                    ? p
                                                    : v.salePrice;
                                                cubit.updateVariationRow(
                                                  originalIndex,
                                                  v.copyWith(
                                                    price: p,
                                                    salePrice: sp,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 6),

                                          // Sale Price input
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              key: ValueKey(
                                                'sale_price_${v.id}_${v.sku}_${state.matrixRevision}',
                                              ),
                                              initialValue: v.salePrice
                                                  .toStringAsFixed(0),
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFF34D399)
                                                    : const Color(0xFF059669),
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                hintText: '0',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          BorderSide(
                                                            color: isDark
                                                                ? const Color(0xFF34D399)
                                                                : const Color(0xFF059669),
                                                            width: 1.2,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                final sp =
                                                    double.tryParse(val) ??
                                                    (val.isEmpty
                                                        ? 0.0
                                                        : v.salePrice);
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (v.effectivePrice >=
                                                              v.costPrice &&
                                                          v.costPrice > 0)
                                                      ? const Color(
                                                          0xFF10B981,
                                                        ).withValues(
                                                          alpha: 0.12,
                                                        )
                                                      : (v.costPrice >
                                                                v.effectivePrice
                                                            ? const Color(
                                                                0xFFEF4444,
                                                              ).withValues(
                                                                alpha: 0.12,
                                                              )
                                                            : Colors
                                                                  .transparent),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        (v.effectivePrice >=
                                                                v.costPrice &&
                                                            v.costPrice > 0)
                                                        ? const Color(
                                                            0xFF10B981,
                                                          ).withValues(
                                                            alpha: 0.3,
                                                          )
                                                        : (v.costPrice >
                                                                  v.effectivePrice
                                                              ? const Color(
                                                                  0xFFEF4444,
                                                                ).withValues(
                                                                  alpha: 0.3,
                                                                )
                                                              : Colors
                                                                    .transparent),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      v.costPrice > 0
                                                          ? '${(v.effectivePrice - v.costPrice) >= 0 ? '+' : ''}${(v.effectivePrice - v.costPrice).toStringAsFixed(0)} EGP'
                                                          : '-',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            (v.effectivePrice >=
                                                                    v.costPrice &&
                                                                v.costPrice > 0)
                                                            ? const Color(
                                                                0xFF10B981,
                                                              )
                                                            : (v.costPrice >
                                                                      v.effectivePrice
                                                                  ? const Color(
                                                                      0xFFEF4444,
                                                                    )
                                                                  : Colors
                                                                        .grey),
                                                      ),
                                                    ),
                                                    if (v.costPrice > 0 &&
                                                        v.effectivePrice > 0)
                                                      Text(
                                                        '${v.profitMarginPercent.toStringAsFixed(0)}%',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              v.profitMarginPercent >=
                                                                  0
                                                              ? const Color(
                                                                  0xFF10B981,
                                                                )
                                                              : const Color(
                                                                  0xFFEF4444,
                                                                ),
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
                                              key: ValueKey(
                                                'stock_${v.id}_${v.sku}_${state.matrixRevision}',
                                              ),
                                              initialValue: v.stock.toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                hintText: '0',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? AppColor.darkBorder
                                                        : AppColor.lightBorder,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: isDark
                                                            ? AppColor
                                                                  .darkBorder
                                                            : AppColor
                                                                  .lightBorder,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColor
                                                                .primary,
                                                            width: 1.5,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                final s =
                                                    int.tryParse(val) ??
                                                    (val.isEmpty ? 0 : v.stock);
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
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: AppColor.error,
                                              ),
                                              tooltip: isArabic
                                                  ? 'حذف هذا المتغير'
                                                  : 'Delete variation',
                                              onPressed: () =>
                                                  cubit.removeVariationRow(
                                                    originalIndex,
                                                  ),
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
                              color: isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder,
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
                                  icon: const Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 12,
                                  ),
                                  label: Text(isArabic ? 'السابق' : 'Prev'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
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
                                  icon: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                  ),
                                  label: Text(isArabic ? 'التالي' : 'Next'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
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
                            label: isArabic
                                ? 'إجمالي المتغيرات'
                                : 'Total Variations',
                            value: '${vars.length} SKU',
                            icon: Icons.hub_rounded,
                            color: color,
                          ),
                          _buildFooterMetric(
                            label: isArabic
                                ? 'إجمالي الوحدات بالمخزن'
                                : 'Total Units',
                            value: '$totalStock ${isArabic ? "قطعة" : "units"}',
                            icon: Icons.inventory_2_rounded,
                            color: AppColor.primary,
                          ),
                          _buildFooterMetric(
                            label: isArabic
                                ? 'القيمة الإجمالية للمخزون'
                                : 'Total Value',
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
                          label: isArabic
                              ? 'إجمالي المتغيرات'
                              : 'Total Variations',
                          value: '${vars.length} SKU',
                          icon: Icons.hub_rounded,
                          color: color,
                        ),
                        _buildFooterMetric(
                          label: isArabic
                              ? 'إجمالي الوحدات بالمخزن'
                              : 'Total Units',
                          value: '$totalStock ${isArabic ? "قطعة" : "units"}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColor.primary,
                        ),
                        _buildFooterMetric(
                          label: isArabic
                              ? 'القيمة الإجمالية للمخزون'
                              : 'Total Value',
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

class _LiquidTierValues {
  String mtlPrice = '';
  String mtlSale = '';
  String mtlCost = '';
  String mtlStock = '';

  String dl3Price = '';
  String dl3Sale = '';
  String dl3Cost = '';
  String dl3Stock = '';

  String dl6Price = '';
  String dl6Sale = '';
  String dl6Cost = '';
  String dl6Stock = '';

  String salt30Price = '';
  String salt30Sale = '';
  String salt30Cost = '';
  String salt30Stock = '';

  String salt50Price = '';
  String salt50Sale = '';
  String salt50Cost = '';
  String salt50Stock = '';

  String mtl18Price = '';
  String mtl18Sale = '';
  String mtl18Cost = '';
  String mtl18Stock = '';
}
