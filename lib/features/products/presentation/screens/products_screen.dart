import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../cubit/product_cubit.dart';
import '../widgets/product_creation_wizard.dart';
import '../widgets/product_details_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _activeTypeFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductLoaded) {
          final allProducts = state.filteredProducts;
          final products = _activeTypeFilter == 'ALL'
              ? allProducts
              : allProducts.where((p) {
                  return p.categoryType.name.toLowerCase() == _activeTypeFilter.toLowerCase() ||
                      p.categoryId.toLowerCase().contains(_activeTypeFilter.toLowerCase());
                }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Folder-like Type Segment Selector
                _buildFolderTypeTabs(context, state.products, isDark),
                const SizedBox(height: AppSizes.md),

                CustomDataTable(
                  title: 'products'.tr,
                  subtitle: 'products_subtitle'.tr,
                  searchHint: 'search_products_hint'.tr,
                  onSearchChanged: (q) => context.read<ProductCubit>().filterProducts(query: q),
                  trailingHeaderAction: ElevatedButton.icon(
                    onPressed: () {
                      ProductCreationWizard.show(context);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('add_product'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                    ),
                  ),
                  emptyMessage: 'no_products_found'.tr,
                  emptyIcon: Icons.inventory_2_outlined,
                  emptyAction: ElevatedButton.icon(
                    onPressed: () {
                      ProductCreationWizard.show(context);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('add_product'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  filterWidget: BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (context, catState) {
                      final List<DropdownMenuItem<String>> catItems = [
                        DropdownMenuItem(value: 'ALL', child: Text('all_categories'.tr)),
                      ];

                      if (catState is CategoryLoaded) {
                        for (final c in catState.categories) {
                          if (c.name.isNotEmpty) {
                            catItems.add(DropdownMenuItem(value: c.id, child: Text(c.name)));
                          }
                        }
                      }

                      final validValue = catItems.any((item) => item.value == state.selectedCategory)
                          ? state.selectedCategory
                          : 'ALL';

                      return DropdownButton<String>(
                        value: validValue,
                        underline: const SizedBox.shrink(),
                        style: TextStyle(
                          fontSize: 12,
                          color: HelperFun.isDarkMode(context) ? Colors.white : Colors.black,
                        ),
                        items: catItems,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<ProductCubit>().filterProducts(categoryId: val);
                          }
                        },
                      );
                    },
                  ),
                  columns: [
                    DataTableColumn(label: 'product_title'.tr, width: 220),
                    DataTableColumn(label: 'product_type_col'.tr),
                    DataTableColumn(label: 'product_brand_col'.tr),
                    DataTableColumn(label: 'product_price_col'.tr),
                    DataTableColumn(label: 'product_stock_col'.tr),
                    DataTableColumn(label: 'product_vars_col'.tr),
                    DataTableColumn(label: 'product_actions_col'.tr),
                  ],
                  rows: products.map((p) {
                    final typeColor = p.categoryType.accentColor;
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    final resolvedDisplayName = isArabic ? p.categoryType.arabicName : p.categoryType.displayName;
                    final displayName = p.title.isNotEmpty ? p.title : (p.brand.name.isNotEmpty ? p.brand.name : 'Untitled');

                    return DataRow(
                      cells: [
                        DataCell(
                          InkWell(
                            onTap: () => ProductDetailsDialog.show(context, p),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    p.thumbnail,
                                    width: 34,
                                    height: 34,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 34,
                                      height: 34,
                                      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                      child: Icon(p.categoryType.icon, size: 18, color: typeColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (p.isBadgeEnabled && p.badgeId.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(3),
                                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                                              ),
                                              child: const Text(
                                                '⭐ BADGE',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (p.flavors.isNotEmpty)
                                        Text(
                                          '${'flavors_label'.tr} ${p.flavors.take(2).join(', ')}${p.flavors.length > 2 ? ' +${p.flavors.length - 2}' : ''}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Type Badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(p.categoryType.icon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  resolvedDisplayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Brand
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            ),
                            child: Text(
                              p.brand.name.isNotEmpty ? p.brand.name : 'General',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                        // Price
                        DataCell(
                          Text(
                            AppFormatters.formatEGP(p.salePrice),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        // Stock
                        DataCell(StatusChip.fromStock(p.stock)),
                        // Variations Count
                        DataCell(
                          Text(
                            p.productVariations.isNotEmpty
                                ? 'skus_count'.trParams({'count': '${p.productVariations.length}'})
                                : 'simple_product'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: p.productVariations.isNotEmpty ? FontWeight.w700 : FontWeight.normal,
                              color: p.productVariations.isNotEmpty ? const Color(0xFF8B5CF6) : null,
                            ),
                          ),
                        ),
                        // Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                tooltip: 'view_product_details'.tr,
                                onPressed: () => ProductDetailsDialog.show(context, p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.primary),
                                tooltip: 'edit_product'.tr,
                                onPressed: () {
                                  ProductCreationWizard.show(
                                    context,
                                    initialProduct: p,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                                tooltip: 'delete_product'.tr,
                                onPressed: () {
                                  _confirmDelete(context, p);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<ProductCubit>().loadProducts(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }

  Widget _buildFolderTypeTabs(BuildContext context, List<ProductModel> allProducts, bool isDark) {
    final types = [
      {'key': 'ALL', 'label': 'all_items'.tr, 'icon': Icons.apps_rounded, 'color': AppColor.primary},
      {'key': 'liquid', 'label': 'type_liquid_short'.tr, 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF0EA5E9)},
      {'key': 'device', 'label': 'type_device_short'.tr, 'icon': Icons.vape_free_rounded, 'color': const Color(0xFF6366F1)},
      {'key': 'pod', 'label': 'type_pod_short'.tr, 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFF10B981)},
      {'key': 'coil', 'label': 'type_coil_short'.tr, 'icon': Icons.flash_on_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'accessory', 'label': 'type_accessory_short'.tr, 'icon': Icons.handyman_rounded, 'color': const Color(0xFFEC4899)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((t) {
          final key = t['key'] as String;
          final isSelected = _activeTypeFilter == key;
          final color = t['color'] as Color;

          int count = 0;
          if (key == 'ALL') {
            count = allProducts.length;
          } else {
            count = allProducts.where((p) => p.categoryType.name.toLowerCase() == key).length;
          }

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => setState(() => _activeTypeFilter = key),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                      : (isDark ? AppColor.darkCard : AppColor.lightCard),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t['icon'] as IconData, size: 16, color: isSelected ? color : null),
                    const SizedBox(width: 8),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? color : (isDark ? AppColor.darkChip : AppColor.lightChip),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_product'.tr),
        content: Text('delete_product_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductCubit>().deleteProduct(product.id);
              HelperFun.successSnackbar('success'.tr, 'item_deleted'.tr);
            },
            child: Text('confirm'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
