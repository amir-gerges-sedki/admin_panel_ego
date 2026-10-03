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
import '../cubit/product_cubit.dart';
import '../widgets/branch_stock_matrix_dialog.dart';
import '../widgets/physical_stocktake_dialog.dart';
import '../widgets/product_barcode_print_dialog.dart';
import '../widgets/product_creation_wizard.dart';
import '../widgets/product_details_dialog.dart';
import '../widgets/quick_restock_dialog.dart';
import '../widgets/stock_adjustment_dialog.dart';
import '../widgets/stock_movements_dialog.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductLoaded) {
          final products = state.filteredProducts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: CustomDataTable(
              title: 'products'.tr,
              subtitle: 'products_subtitle'.tr,
              searchHint: 'search_products_hint'.tr,
              onSearchChanged: (q) => context.read<ProductCubit>().filterProducts(query: q),
              filterWidget: Builder(
                builder: (context) {
                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                  final List<DropdownMenuItem<String>> catItems = [
                    DropdownMenuItem(value: 'ALL', child: Text('all_categories'.tr)),
                    ...ProductCategoryType.visibleTypes.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(isArabic ? t.arabicName : t.displayName)),
                    ),
                  ];

                  final validValue = catItems.any((item) => item.value == state.selectedCategory)
                      ? state.selectedCategory
                      : 'ALL';

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Branch / Store Selector Filter
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, settingsState) {
                          List<StoreBranchModel> branches = [];
                          if (settingsState is SettingsLoaded) {
                            branches = settingsState.settings.branches;
                          }

                          return Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: state.selectedBranchId != 'all'
                                    ? const Color(0xFF06B6D4)
                                    : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 15,
                                  color: state.selectedBranchId != 'all'
                                      ? const Color(0xFF06B6D4)
                                      : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                                ),
                                const SizedBox(width: 6),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: state.selectedBranchId,
                                    isDense: true,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: state.selectedBranchId != 'all'
                                          ? const Color(0xFF06B6D4)
                                          : (isDark ? Colors.white : AppColor.textPrimaryLight),
                                    ),
                                    dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('all_branches_warehouses'.tr),
                                      ),
                                      ...branches.map((b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  b.isWarehouse ? Icons.warehouse_rounded : Icons.store_rounded,
                                                  size: 14,
                                                  color: b.isWarehouse ? const Color(0xFF06B6D4) : AppColor.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(b.name),
                                              ],
                                            ),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        context.read<ProductCubit>().filterByBranch(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),

                      // 2. Category Selector Filter
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 15,
                              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: validValue,
                                isDense: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColor.textPrimaryLight,
                                ),
                                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                                items: catItems,
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<ProductCubit>().filterProducts(categoryId: val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              trailingHeaderAction: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => PhysicalStocktakeDialog.show(context),
                    icon: const Icon(Icons.fact_check_rounded, size: 15),
                    label: Text('physical_stocktake_btn'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () => StockMovementsDialog.show(context),
                    icon: const Icon(Icons.history_rounded, size: 15),
                    label: Text('stock_movements_btn'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () {
                      ProductCreationWizard.show(context);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('add_product'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
                  columns: [
                    DataTableColumn(label: 'product_title'.tr, width: 220),
                    DataTableColumn(label: 'product_type_col'.tr),
                    DataTableColumn(label: 'product_brand_col'.tr),
                    DataTableColumn(label: 'product_price_col'.tr, width: 175),
                    DataTableColumn(label: 'product_stock_col'.tr),
                    DataTableColumn(label: 'product_vars_col'.tr),
                    DataTableColumn(label: 'product_actions_col'.tr),
                  ],
                  rows: products.map((p) {
                    final typeColor = p.categoryType.accentColor;
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    final resolvedDisplayName = isArabic ? p.categoryType.arabicName : p.categoryType.displayName;
                    final displayName = p.displayTitle;

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
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: const Text(
                                                '⭐ BADGE',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                                              ),
                                            ),
                                          if (!p.isOnline)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.point_of_sale_rounded, size: 10, color: Color(0xFFF59E0B)),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'pos_only'.tr,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                                                  ),
                                                ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: typeColor.withValues(alpha: 0.20)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(p.categoryType.icon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  resolvedDisplayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              p.brand.name.isNotEmpty ? p.brand.name : 'General',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
                            ),
                          ),
                        ),
                        // Price
                        DataCell(
                          Builder(
                            builder: (context) {
                              final variations = p.productVariations;
                              final List<double> effectivePrices = [];
                              final List<double> regularPrices = [];

                              if (variations.isNotEmpty) {
                                for (final v in variations) {
                                  final hasVarDisc = v.salePrice > 0 && v.salePrice < v.price;
                                  final eff = hasVarDisc ? v.salePrice : (v.price > 0 ? v.price : v.salePrice);
                                  final reg = v.price > 0 ? v.price : v.salePrice;
                                  if (eff > 0) effectivePrices.add(eff);
                                  if (reg > 0) regularPrices.add(reg);
                                }
                              }

                              final double minEff = effectivePrices.isNotEmpty
                                  ? effectivePrices.reduce((a, b) => a < b ? a : b)
                                  : (p.salePrice > 0 && p.salePrice < p.price ? p.salePrice : (p.price > 0 ? p.price : p.salePrice));
                              final double maxEff = effectivePrices.isNotEmpty
                                  ? effectivePrices.reduce((a, b) => a > b ? a : b)
                                  : minEff;

                              final double minReg = regularPrices.isNotEmpty
                                  ? regularPrices.reduce((a, b) => a < b ? a : b)
                                  : (p.price > 0 ? p.price : p.salePrice);
                              final double maxReg = regularPrices.isNotEmpty
                                  ? regularPrices.reduce((a, b) => a > b ? a : b)
                                  : minReg;

                              final bool hasRange = minEff < maxEff;
                              final bool hasAnyDiscount = variations.isNotEmpty
                                  ? variations.any((v) => v.salePrice > 0 && v.salePrice < v.price)
                                  : (p.salePrice > 0 && p.salePrice < p.price);

                              if (hasRange) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppFormatters.formatEGP(minEff)} - ${AppFormatters.formatEGP(maxEff)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: hasAnyDiscount ? const Color(0xFF10B981) : null,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    if (hasAnyDiscount && (minReg > minEff || maxReg > maxEff))
                                      Text(
                                        '${AppFormatters.formatEGP(minReg)} - ${AppFormatters.formatEGP(maxReg)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.lineThrough,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      )
                                    else
                                      Text(
                                        'min_max_price'.tr,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                        ),
                                      ),
                                  ],
                                );
                              }

                              if (hasAnyDiscount) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppFormatters.formatEGP(minEff),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatEGP(minReg),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.lineThrough,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Text(
                                AppFormatters.formatEGP(minEff),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              );
                            },
                          ),
                        ),
                        // Stock
                        DataCell(
                          InkWell(
                            onTap: () => BranchStockMatrixDialog.show(context, p),
                            borderRadius: BorderRadius.circular(6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip.fromStock(p.getStockForBranch(state.selectedBranchId)),
                                if (state.selectedBranchId != 'all') ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'branch_stock_label'.tr,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18),
                                tooltip: 'actions'.tr,
                                color: isDark ? AppColor.darkCard : AppColor.lightCard,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                                  side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                ),
                                onSelected: (val) {
                                  switch (val) {
                                    case 'toggle_online':
                                      _toggleOnlineStatus(context, p);
                                      break;
                                    case 'branch_stock':
                                      BranchStockMatrixDialog.show(context, p);
                                      break;
                                    case 'stock_audit':
                                      showDialog(
                                        context: context,
                                        builder: (_) => StockAdjustmentDialog(product: p),
                                      );
                                      break;
                                    case 'print_barcode':
                                      ProductBarcodePrintDialog.show(context, product: p);
                                      break;
                                    case 'quick_restock':
                                      QuickRestockDialog.show(context, product: p);
                                      break;
                                    case 'delete':
                                      _confirmDelete(context, p);
                                      break;
                                  }
                                },
                                itemBuilder: (context) {
                                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                                  return [
                                    PopupMenuItem(
                                      value: 'toggle_online',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          Icon(
                                            p.isOnline ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            size: 16,
                                            color: p.isOnline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            p.isOnline
                                                ? (isArabic ? 'إطفاء المنتج أونلاين (كاشير فقط)' : 'Disable Online (POS Only)')
                                                : (isArabic ? 'تفعيل المنتج أونلاين' : 'Enable Online Store'),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: p.isOnline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 6),
                                    PopupMenuItem(
                                      value: 'branch_stock',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.store_mall_directory_rounded, size: 16, color: Color(0xFF06B6D4)),
                                          const SizedBox(width: 8),
                                          Text('branch_stock_action_tooltip'.tr, style: const TextStyle(fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'stock_audit',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF8B5CF6)),
                                          const SizedBox(width: 8),
                                          Text('quick_action_stock_audit'.tr, style: const TextStyle(fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'print_barcode',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFFF97316)),
                                          const SizedBox(width: 8),
                                          Text('print_barcode_stickers'.tr, style: const TextStyle(fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'quick_restock',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Color(0xFF10B981)),
                                          const SizedBox(width: 8),
                                          Text('quick_restock'.tr, style: const TextStyle(fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 8),
                                    PopupMenuItem(
                                      value: 'delete',
                                      height: 36,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline_rounded, size: 16, color: AppColor.error),
                                          const SizedBox(width: 8),
                                          Text('delete_product'.tr, style: const TextStyle(fontSize: 12.5, color: AppColor.error)),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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

  void _toggleOnlineStatus(BuildContext context, ProductModel product) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final newStatus = !product.isOnline;
    final updated = product.copyWith(isOnline: newStatus);
    context.read<ProductCubit>().updateProduct(updated);

    HelperFun.successSnackbar(
      isArabic ? 'حالة توفر المنتج' : 'Product Availability',
      newStatus
          ? (isArabic
              ? 'تم تفعيل ظهور "${product.title}" في تطبيق المتجر أونلاين والكاشير'
              : 'Product "${product.title}" is now active in Online store and POS')
          : (isArabic
              ? 'تم إطفاء "${product.title}" عن تطبيق المتجر (متاح كاشير فقط)'
              : 'Product "${product.title}" is now POS only (hidden online)'),
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
