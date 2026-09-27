import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';
import 'pos_variation_selector_dialog.dart';

/// Product Catalog grid with fast category filtering and quick touch add-to-cart
class PosProductGrid extends StatelessWidget {
  const PosProductGrid({super.key});

  static const List<ProductCategoryType> posCategories = [
    ProductCategoryType.liquid,
    ProductCategoryType.disposable,
    ProductCategoryType.device,
    ProductCategoryType.accessory,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        final products = state.filteredProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                children: [
                  _buildCategoryChip(
                    context: context,
                    label: 'all_categories_filter'.trParams({'count': '${state.allProducts.length}'}),
                    isSelected: state.selectedCategory == null,
                    onTap: () => context.read<PosCubit>().filterProducts(clearCategory: true),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  ...posCategories.map((cat) {
                    final isSelected = state.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCategoryChip(
                        context: context,
                        label: _getCategoryLabel(cat),
                        isSelected: isSelected,
                        onTap: () => context.read<PosCubit>().filterProducts(category: cat),
                        isDark: isDark,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm + 2),

            // Products Grid
            Expanded(
              child: products.isEmpty
                  ? _buildEmptyState(isDark)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 1100
                            ? 5
                            : (width > 850
                                ? 4
                                : (width > 600 ? 3 : 2));

                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(context, product, isDark, state.searchQuery);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColor.primary,
      backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, bool isDark, String currentSearchQuery) {
    final isOutOfStock = product.stock <= 0;
    final isVariable = product.isVariable && product.productVariations.length > 1;

    // Check if any specific variation matched current search query
    final matchingVarCount = currentSearchQuery.trim().isEmpty || !isVariable
        ? 0
        : product.productVariations.where((v) {
            final queryWords = currentSearchQuery.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
            final searchable = <String>[
              v.sku.toLowerCase(),
              v.id.toLowerCase(),
              ...v.attributeValues.entries.map((e) => '${e.key} ${e.value}'.toLowerCase()),
              ...v.attributeValues.values.map((val) => val.toString().toLowerCase()),
            ].join(' ');
            return queryWords.every((w) => searchable.contains(w));
          }).length;

    return InkWell(
      onTap: isOutOfStock
          ? null
          : () async {
              if (isVariable) {
                final variation = await PosVariationSelectorDialog.show(
                  context,
                  product,
                  initialQuery: currentSearchQuery,
                );
                if (variation != null && context.mounted) {
                  context.read<PosCubit>().addToCart(product, variation: variation);
                }
              } else {
                final singleVar = product.productVariations.isNotEmpty ? product.productVariations.first : null;
                context.read<PosCubit>().addToCart(product, variation: singleVar);
              }
            },
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image & Stock Badge
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusMd - 1)),
                    ),
                    child: product.thumbnail.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusMd - 1)),
                            child: Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildFallbackIcon(product.categoryType),
                            ),
                          )
                        : _buildFallbackIcon(product.categoryType),
                  ),

                  // Stock Badge (Top End)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOutOfStock ? AppColor.error : AppColor.success).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOutOfStock ? 'out_of_stock_badge'.tr : '${product.stock}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),

                  // Multi-variant indicator (Top Right)
                  if (isVariable)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: matchingVarCount > 0
                              ? const Color(0xFFF59E0B)
                              : AppColor.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          matchingVarCount > 0
                              ? 'matching_vars_count'.trParams({'count': '$matchingVarCount', 'total': '${product.productVariations.length}'})
                              : 'options_count_badge'.trParams({'count': '${product.productVariations.length}'}),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details Footer
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.title,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.formatEGP(product.effectivePrice),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColor.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add_rounded, size: 14, color: AppColor.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ProductCategoryType type) {
    IconData icon = switch (type) {
      ProductCategoryType.liquid => Icons.water_drop_outlined,
      ProductCategoryType.disposable => Icons.battery_charging_full_rounded,
      ProductCategoryType.device => Icons.vaping_rooms_outlined,
      ProductCategoryType.pod => Icons.extension_outlined,
      ProductCategoryType.coil => Icons.flash_on_outlined,
      ProductCategoryType.accessory => Icons.cable_outlined,
    };
    return Center(child: Icon(icon, size: 32, color: Colors.grey.withValues(alpha: 0.4)));
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: AppSizes.md),
            Text(
              'no_matching_products'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'no_matching_products_desc'.tr,
              style: TextStyle(fontSize: 12, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(ProductCategoryType type) {
    return switch (type) {
      ProductCategoryType.liquid => 'category_liquids'.tr,
      ProductCategoryType.disposable => 'category_disposable'.tr,
      ProductCategoryType.device => 'category_devices'.tr,
      ProductCategoryType.pod => 'category_pods'.tr,
      ProductCategoryType.coil => 'category_coils'.tr,
      ProductCategoryType.accessory => 'category_accessories'.tr,
    };
  }
}
