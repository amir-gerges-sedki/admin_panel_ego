import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/brand_model.dart';
import '../cubit/brand_cubit.dart';
import 'brand_form_dialog.dart';
import 'brand_table_row.dart';

class BrandTable extends StatefulWidget {
  final BrandLoaded state;

  const BrandTable({super.key, required this.state});

  @override
  State<BrandTable> createState() => _BrandTableState();
}

class _BrandTableState extends State<BrandTable> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<BrandCubit>();
    final brands = widget.state.filteredBrands;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header Toolbar
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Title and Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vape_brands_title'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'brands_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),

                // Actions: Search, Sort Dropdown & Add Button
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search field
                    SizedBox(
                      width: isDesktop ? 220 : 160,
                      height: 38,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _searchController,
                            onChanged: (q) => cubit.filterBrands(q),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'search_brands_hint'.tr,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        cubit.filterBrands('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              isDense: true,
                            ),
                          );
                        },
                      ),
                    ),

                    // Sort dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColor.darkSubCard
                            : AppColor.lightSubCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColor.darkBorder
                              : AppColor.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<BrandSortField>(
                              value: widget.state.sortField,
                              isDense: true,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColor.textPrimaryLight,
                              ),
                              dropdownColor: isDark
                                  ? AppColor.darkCard
                                  : AppColor.lightCard,
                              items: [
                                DropdownMenuItem(
                                  value: BrandSortField.sortOrder,
                                  child: Text('sort_order'.tr),
                                ),
                                DropdownMenuItem(
                                  value: BrandSortField.name,
                                  child: Text('sort_name'.tr),
                                ),
                                DropdownMenuItem(
                                  value: BrandSortField.productsCount,
                                  child: Text('sort_products_count'.tr),
                                ),
                                DropdownMenuItem(
                                  value: BrandSortField.status,
                                  child: Text('sort_status'.tr),
                                ),
                              ],
                              onChanged: (field) {
                                if (field != null) {
                                  cubit.sortBrands(field);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add Brand button
                    ElevatedButton.icon(
                      onPressed: () {
                        BrandFormDialog.show(
                          context,
                          onSave: (b) => cubit.addBrand(b),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text('add_brand'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Column Headers
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: 12,
            ),
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            child: Row(
              children: [
                // 1. Sort Order / Display Order (First column)
                SizedBox(
                  width: 120,
                  child: InkWell(
                    onTap: () => cubit.sortBrands(BrandSortField.sortOrder),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'sort_order'.tr,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 16,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                        if (widget.state.sortField ==
                            BrandSortField.sortOrder) ...[
                          const SizedBox(width: 2),
                          Icon(
                            widget.state.sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppColor.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 2. Brand Name (Logo + Name)
                Expanded(
                  flex: 4,
                  child: InkWell(
                    onTap: () => cubit.sortBrands(BrandSortField.name),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'brand_name'.tr,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ),
                        if (widget.state.sortField == BrandSortField.name) ...[
                          const SizedBox(width: 4),
                          Icon(
                            widget.state.sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppColor.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Catalog Products Count
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => cubit.sortBrands(BrandSortField.productsCount),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'catalog_items'.tr,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ),
                        if (widget.state.sortField ==
                            BrandSortField.productsCount) ...[
                          const SizedBox(width: 4),
                          Icon(
                            widget.state.sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppColor.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 4. Status Chip
                SizedBox(
                  width: 120,
                  child: InkWell(
                    onTap: () => cubit.sortBrands(BrandSortField.status),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'status'.tr,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColor.textSecondaryDark
                                  : AppColor.textSecondaryLight,
                            ),
                          ),
                        ),
                        if (widget.state.sortField ==
                            BrandSortField.status) ...[
                          const SizedBox(width: 4),
                          Icon(
                            widget.state.sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppColor.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 5. Actions
                SizedBox(
                  width: 90,
                  child: Text(
                    'actions'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reorderable Brand Rows
          if (brands.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Center(child: Text('no_brands_found'.tr)),
            )
          else
            ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brands.length,
              onReorderItem: (oldIndex, newIndex) {
                cubit.reorderBrands(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final b = brands[index];
                return BrandTableRow(
                  key: ValueKey(b.id),
                  brand: b,
                  index: index,
                  isDark: isDark,
                  onEdit: () {
                    BrandFormDialog.show(
                      context,
                      initialBrand: b,
                      onSave: (updated) => cubit.updateBrand(updated),
                    );
                  },
                  onDelete: () => _confirmDelete(context, b),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, BrandModel brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_brand_title'.tr),
        content: Text('delete_brand_confirm'.trParams({'name': brand.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColor.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<BrandCubit>().deleteBrand(brand.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('item_deleted'.tr),
            backgroundColor: AppColor.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
