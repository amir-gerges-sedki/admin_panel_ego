import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/stock_movement_cubit.dart';

class _StocktakeItem {
  final ProductModel product;
  final ProductVariationModel? variation;
  final int systemStock;
  int countedStock;
  final double costPrice;
  final double retailPrice;

  _StocktakeItem({
    required this.product,
    this.variation,
    required this.systemStock,
    required this.countedStock,
    required this.costPrice,
    required this.retailPrice,
  });

  int get variance => countedStock - systemStock;
  bool get hasDiscrepancy => variance != 0;
  double get varianceCostValue => variance * costPrice;
  double get varianceRetailValue => variance * retailPrice;

  String get sku => variation != null ? variation!.sku : product.id;
  String get title => product.displayTitle;
  String get variationDetails {
    if (variation == null || variation!.attributeValues.isEmpty) return '';
    return variation!.attributeValues.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(' | ');
  }
}

/// Comprehensive Physical Inventory Stocktake & Discrepancy Adjustment Dialog
class PhysicalStocktakeDialog extends StatefulWidget {
  final List<ProductModel> initialProducts;

  const PhysicalStocktakeDialog({
    super.key,
    required this.initialProducts,
  });

  static Future<bool?> show(BuildContext context) {
    final productsState = context.read<ProductCubit>().state;
    List<ProductModel> products = [];
    if (productsState is ProductLoaded) {
      products = productsState.products;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ProductCubit>()),
          BlocProvider.value(value: context.read<StockMovementCubit>()),
        ],
        child: PhysicalStocktakeDialog(initialProducts: products),
      ),
    );
  }

  @override
  State<PhysicalStocktakeDialog> createState() => _PhysicalStocktakeDialogState();
}

class _PhysicalStocktakeDialogState extends State<PhysicalStocktakeDialog> {
  final List<_StocktakeItem> _allItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  bool _showOnlyDiscrepancies = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    _allItems.clear();
    for (final product in widget.initialProducts) {
      if (product.productVariations.isNotEmpty) {
        for (final variation in product.productVariations) {
          _allItems.add(_StocktakeItem(
            product: product,
            variation: variation,
            systemStock: variation.stock,
            countedStock: variation.stock,
            costPrice: product.costPrice > 0 ? product.costPrice : (product.price * 0.7),
            retailPrice: variation.price > 0 ? variation.price : product.price,
          ));
        }
      } else {
        _allItems.add(_StocktakeItem(
          product: product,
          variation: null,
          systemStock: product.stock,
          countedStock: product.stock,
          costPrice: product.costPrice > 0 ? product.costPrice : (product.price * 0.7),
          retailPrice: product.price,
        ));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<_StocktakeItem> get _filteredItems {
    return _allItems.where((item) {
      if (_showOnlyDiscrepancies && !item.hasDiscrepancy) {
        return false;
      }

      if (_selectedCategory != 'ALL' && item.product.categoryType.id != _selectedCategory) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesSku = item.sku.toLowerCase().contains(q);
        final matchesBrand = item.product.brand.name.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSku && !matchesBrand) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get _discrepanciesCount => _allItems.where((i) => i.hasDiscrepancy).length;
  int get _netUnitsVariance => _allItems.fold(0, (acc, i) => acc + i.variance);
  double get _netCostImpact => _allItems.fold(0.0, (acc, i) => acc + i.varianceCostValue);

  Future<void> _submitAllAdjustments() async {
    final modifiedItems = _allItems.where((i) => i.hasDiscrepancy).toList();
    if (modifiedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('no_discrepancies_found')),
          backgroundColor: AppColor.primary,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auditBatchId = 'AUDIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final stockCubit = context.read<StockMovementCubit>();
      final productCubit = context.read<ProductCubit>();

      // Group adjustments by product to avoid racing updates on the same product model
      final Map<String, List<_StocktakeItem>> groupedByProduct = {};
      for (final item in modifiedItems) {
        groupedByProduct.putIfAbsent(item.product.id, () => []).add(item);
      }

      for (final entry in groupedByProduct.entries) {
        final productAdjustments = entry.value;
        ProductModel currentProd = productAdjustments.first.product;

        for (final adj in productAdjustments) {
          currentProd = await stockCubit.executeStockAdjustment(
            product: currentProd,
            variationSku: adj.variation?.sku,
            newExactStock: adj.countedStock,
            type: StockMovementType.adjustment,
            reason: 'جرد فعلي دوري ($auditBatchId)',
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : 'تسوية فروق جرد مخزني',
            performedBy: 'Admin / Stocktake Auditor',
          );
        }
        productCubit.updateProduct(currentProd);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('stocktake_completed_success'),
            ),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error')}: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final filtered = _filteredItems;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: 1080,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: 14),

              // KPI Summary Bar
              _buildKpiSummaryBar(isDark),
              const SizedBox(height: 14),

              // Filters & Search Bar
              _buildFilterBar(isDark, isArabic),
              const SizedBox(height: 14),

              // Items Table
              Expanded(
                child: _buildStocktakeTable(filtered, isDark),
              ),
              const SizedBox(height: 14),

              // Bottom Actions Bar
              _buildBottomActionBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fact_check_rounded, color: AppColor.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('physical_stocktake_audit_title'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context).translate('physical_stocktake_audit_subtitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 22),
        ),
      ],
    );
  }

  Widget _buildKpiSummaryBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Row(
        children: [
          _buildKpiStat(
            title: AppLocalizations.of(context).translate('audited_items_count'),
            value: '${_allItems.length}',
            icon: Icons.inventory_2_rounded,
            color: AppColor.primary,
          ),
          _buildVerticalDivider(isDark),
          _buildKpiStat(
            title: AppLocalizations.of(context).translate('discrepancy_items_count'),
            value: '$_discrepanciesCount',
            icon: Icons.difference_rounded,
            color: _discrepanciesCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
          _buildVerticalDivider(isDark),
          _buildKpiStat(
            title: AppLocalizations.of(context).translate('net_variance_units'),
            value: '${_netUnitsVariance > 0 ? '+' : ''}$_netUnitsVariance ${AppLocalizations.of(context).translate('units')}',
            icon: Icons.swap_vert_rounded,
            color: _netUnitsVariance == 0
                ? AppColor.primary
                : (_netUnitsVariance > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
          _buildVerticalDivider(isDark),
          _buildKpiStat(
            title: AppLocalizations.of(context).translate('net_cost_impact'),
            value: AppFormatters.formatEGP(_netCostImpact),
            icon: Icons.monetization_on_rounded,
            color: _netCostImpact >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
    );
  }

  Widget _buildFilterBar(bool isDark, bool isArabic) {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate('search_stocktake_hint'),
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
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
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Category Filter
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                items: [
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text(
                      AppLocalizations.of(context).translate('all_categories'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ...ProductCategoryType.visibleTypes.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          isArabic ? t.arabicName : t.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Discrepancy Toggle
        FilterChip(
          label: Text(
            AppLocalizations.of(context).translate('show_discrepancies_only'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: _showOnlyDiscrepancies ? FontWeight.bold : FontWeight.normal,
              color: _showOnlyDiscrepancies
                  ? Colors.white
                  : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
            ),
          ),
          selected: _showOnlyDiscrepancies,
          selectedColor: const Color(0xFFF59E0B),
          backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
          onSelected: (val) => setState(() => _showOnlyDiscrepancies = val),
        ),
      ],
    );
  }

  Widget _buildStocktakeTable(List<_StocktakeItem> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('no_matching_stocktake_items'),
              style: TextStyle(
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildTableHeader(isDark);
            }
            final item = items[index - 1];
            return _buildTableRow(item, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(AppLocalizations.of(context).translate('product_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 3, child: Text(AppLocalizations.of(context).translate('sku_spec'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Center(child: Text(AppLocalizations.of(context).translate('system_stock'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 3, child: Center(child: Text(AppLocalizations.of(context).translate('counted_stock'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 2, child: Center(child: Text(AppLocalizations.of(context).translate('variance_diff'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 2, child: Center(child: Text(AppLocalizations.of(context).translate('cost_impact'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(_StocktakeItem item, bool isDark) {
    final variance = item.variance;
    final hasDiscrepancy = item.hasDiscrepancy;

    return Container(
      color: hasDiscrepancy
          ? (variance > 0
              ? const Color(0xFF10B981).withValues(alpha: 0.06)
              : const Color(0xFFEF4444).withValues(alpha: 0.06))
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Product Name & Brand
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.product.brand.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // SKU & Variations
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.sku,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
                if (item.variationDetails.isNotEmpty)
                  Text(
                    item.variationDetails,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // System Recorded Stock
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.systemStock}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // Physical Counted Stock (Editable with +/- steppers)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: item.countedStock > 0
                      ? () => setState(() => item.countedStock--)
                      : null,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 55,
                  height: 32,
                  child: TextFormField(
                    key: ValueKey('${item.sku}_${item.countedStock}'),
                    initialValue: '${item.countedStock}',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      filled: true,
                      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed >= 0) {
                        setState(() => item.countedStock = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => item.countedStock++),
                ),
              ],
            ),
          ),

          // Variance Diff Chip
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: variance == 0
                      ? Colors.grey.withValues(alpha: 0.1)
                      : (variance > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${variance > 0 ? '+' : ''}$variance',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: variance == 0
                        ? Colors.grey
                        : (variance > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                ),
              ),
            ),
          ),

          // Cost Impact (EGP)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                AppFormatters.formatEGP(item.varianceCostValue),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: variance == 0
                      ? Colors.grey
                      : (variance > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Row(
      children: [
        // Audit Notes input
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate('audit_notes_hint'),
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Cancel Button
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Confirm & Apply Button
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _submitAllAdjustments,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(
            _isSaving
                ? AppLocalizations.of(context).translate('processing')
                : '${AppLocalizations.of(context).translate('apply_stock_adjustments')} ($_discrepanciesCount)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _discrepanciesCount > 0 ? AppColor.primary : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
