import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';

/// Modal dialog allowing cashiers to quickly search, filter and select product variations
class PosVariationSelectorDialog extends StatefulWidget {
  final ProductModel product;
  final String initialQuery;
  final ValueChanged<ProductVariationModel> onVariationSelected;

  const PosVariationSelectorDialog({
    super.key,
    required this.product,
    this.initialQuery = '',
    required this.onVariationSelected,
  });

  static Future<ProductVariationModel?> show(
    BuildContext context,
    ProductModel product, {
    String initialQuery = '',
  }) {
    return showDialog<ProductVariationModel>(
      context: context,
      builder: (ctx) => PosVariationSelectorDialog(
        product: product,
        initialQuery: initialQuery,
        onVariationSelected: (variation) => Navigator.of(ctx).pop(variation),
      ),
    );
  }

  @override
  State<PosVariationSelectorDialog> createState() => _PosVariationSelectorDialogState();
}

class _PosVariationSelectorDialogState extends State<PosVariationSelectorDialog> {
  late final TextEditingController _searchController;
  ProductVariationModel? _selectedVariation;
  String _activeAttributeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectInitialVariation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectInitialVariation() {
    final filtered = _getFilteredVariations();
    if (filtered.isNotEmpty) {
      // Pick first in-stock variation if available
      _selectedVariation = filtered.where((v) => v.stock > 0).firstOrNull ?? filtered.first;
    } else if (widget.product.productVariations.isNotEmpty) {
      _selectedVariation = widget.product.productVariations.where((v) => v.stock > 0).firstOrNull ??
          widget.product.productVariations.first;
    }
  }

  List<ProductVariationModel> _getFilteredVariations() {
    final query = _searchController.text.trim().toLowerCase();
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    return widget.product.productVariations.where((v) {
      // 1. Check active attribute pill filter
      if (_activeAttributeFilter != 'ALL') {
        final matchesAttribute = v.attributeValues.values
            .any((val) => val.toLowerCase() == _activeAttributeFilter.toLowerCase());
        if (!matchesAttribute) return false;
      }

      // 2. Check search query across SKU, attribute keys, and attribute values
      if (queryWords.isEmpty) return true;

      final searchable = <String>[
        v.sku.toLowerCase(),
        v.id.toLowerCase(),
        ...v.attributeValues.entries.map((e) => '${e.key} ${e.value}'.toLowerCase()),
        ...v.attributeValues.values.map((val) => val.toString().toLowerCase()),
      ].join(' ');

      return queryWords.every((word) => searchable.contains(word));
    }).toList();
  }

  Set<String> _extractQuickFilterAttributes() {
    final values = <String>{};
    for (final v in widget.product.productVariations) {
      for (final val in v.attributeValues.values) {
        if (val.trim().isNotEmpty && values.length < 15) {
          values.add(val.trim());
        }
      }
    }
    return values;
  }

  void _confirmSelection(ProductVariationModel variation) {
    if (variation.stock > 0) {
      widget.onVariationSelected(variation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final filteredVariations = _getFilteredVariations();
    final quickFilters = _extractQuickFilterAttributes();

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
          maxHeight: 640,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColor.primary, size: 22),
                  ),
                  const SizedBox(width: AppSizes.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.product.brand.name} • ${'available_options_count'.trParams({'count': '${widget.product.productVariations.length}'})}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'close'.tr,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Search Bar for Variations
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_variations_hint'.tr,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColor.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectInitialVariation();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectInitialVariation();
                    });
                  },
                  onSubmitted: (_) {
                    if (_selectedVariation != null && _selectedVariation!.stock > 0) {
                      _confirmSelection(_selectedVariation!);
                    }
                  },
                ),
              ),

              // Quick Attribute Filter Chips
              if (quickFilters.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickFilterChip(
                        label: 'all_variations_count'.trParams({'count': '${widget.product.productVariations.length}'}),
                        isSelected: _activeAttributeFilter == 'ALL',
                        isDark: isDark,
                        onTap: () => setState(() {
                          _activeAttributeFilter = 'ALL';
                          _selectInitialVariation();
                        }),
                      ),
                      const SizedBox(width: 6),
                      ...quickFilters.map((attrVal) {
                        final isSelected = _activeAttributeFilter == attrVal;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildQuickFilterChip(
                            label: attrVal,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => setState(() {
                              _activeAttributeFilter = isSelected ? 'ALL' : attrVal;
                              _selectInitialVariation();
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const Divider(height: 18),

              // Variation Options List
              Expanded(
                child: filteredVariations.isEmpty
                    ? _buildNoResultsState(isDark)
                    : ListView.separated(
                        itemCount: filteredVariations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final variation = filteredVariations[index];
                          final isSelected = _selectedVariation?.id == variation.id;
                          final isOutOfStock = variation.stock <= 0;

                          return InkWell(
                            onTap: isOutOfStock
                                ? null
                                : () {
                                    setState(() => _selectedVariation = variation);
                                  },
                            onDoubleTap: isOutOfStock
                                ? null
                                : () => _confirmSelection(variation),
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.primary.withValues(alpha: 0.12)
                                    : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColor.primary
                                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Selection Radio Circle
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColor.primary
                                            : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Variation Image / Icon if available
                                  if (variation.image.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        variation.image,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],

                                  // Variation Attributes & SKU
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (variation.attributeValues.isNotEmpty)
                                          _buildAttributeBadges(variation.attributeValues, isDark)
                                        else
                                          Text(
                                            variation.sku.isNotEmpty ? variation.sku : 'SKU: ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isOutOfStock
                                                  ? (isDark ? AppColor.textMutedDark : AppColor.textMutedLight)
                                                  : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                                            ),
                                          ),
                                        if (variation.sku.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'SKU: ${variation.sku}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Price and Stock status
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.formatEGP(variation.effectivePrice),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isOutOfStock ? AppColor.error : AppColor.success).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isOutOfStock
                                              ? 'out_of_stock'.tr
                                              : 'available_stock_count'.trParams({'count': '${variation.stock}'}),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isOutOfStock ? AppColor.error : AppColor.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Divider(height: 20),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'filtered_of_total_options'.trParams({
                      'filtered': '${filteredVariations.length}',
                      'total': '${widget.product.productVariations.length}',
                    }),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                        ),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectedVariation == null || _selectedVariation!.stock <= 0
                            ? null
                            : () => _confirmSelection(_selectedVariation!),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: Text('add_to_cart'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeBadges(Map<String, String> attributeValues, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: attributeValues.entries.map((e) {
        final isColor = e.key.toLowerCase().contains('color') ||
            e.key.contains('لون') ||
            e.value.contains('#');

        if (isColor) {
          return ColorUtils.buildColorBadge(
            e.value,
            size: 14,
            isDark: isDark,
            showLabel: true,
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            '${e.key}: ${e.value}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 8),
          Text(
            'no_matching_variations'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _activeAttributeFilter = 'ALL';
                _selectInitialVariation();
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text('show_all_variations'.tr),
          ),
        ],
      ),
    );
  }
}
