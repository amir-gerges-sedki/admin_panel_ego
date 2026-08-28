import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/category_cubit.dart';
import '../widgets/brand_form_dialog.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_image_seed_dialog.dart';

class CategoriesBrandsScreen extends StatelessWidget {
  const CategoriesBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoryLoaded) {
          final categories = state.filteredCategories;
          final brands = state.filteredBrands;

          final categoryTable = CustomDataTable(
            title: 'vape_categories_title'.tr,
            subtitle: 'categories_subtitle'.tr,
            searchHint: 'search_categories_hint'.tr,
            onSearchChanged: (q) => context.read<CategoryCubit>().filterCategories(q),
            emptyMessage: 'no_categories_found'.tr,
            emptyIcon: Icons.category_outlined,
            emptyAction: ElevatedButton.icon(
              onPressed: () {
                CategoryFormDialog.show(
                  context,
                  onSave: (cat) => context.read<CategoryCubit>().addCategory(cat),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('add_category'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
            ),
            trailingHeaderAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    CategoryImageSeedDialog.show(
                      context,
                      onComplete: () => context.read<CategoryCubit>().loadData(),
                    );
                  },
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('صور الأقسام'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.info,
                    side: const BorderSide(color: AppColor.info),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    CategoryFormDialog.show(
                      context,
                      onSave: (cat) => context.read<CategoryCubit>().addCategory(cat),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('add_category'.tr),
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
            columns: [
              DataTableColumn(label: 'صورة'),
              DataTableColumn(label: 'category_name'.tr),
              DataTableColumn(label: 'products_count'.tr),
              DataTableColumn(label: 'featured'.tr),
              DataTableColumn(label: 'actions'.tr),
            ],
            rows: categories.map((cat) {
              return DataRow(
                cells: [
                  DataCell(
                    _CategoryImageCell(imageUrl: cat.image),
                  ),
                  DataCell(
                    Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text('items_count'.trParams({'count': '${cat.productsCount}'}))),
                  DataCell(StatusChip.fromActive(cat.isFeatured)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColor.primary,
                          ),
                          tooltip: 'edit_category'.tr,
                          onPressed: () {
                            CategoryFormDialog.show(
                              context,
                              initialCategory: cat,
                              onSave: (updated) => context
                                  .read<CategoryCubit>()
                                  .updateCategory(updated),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColor.error,
                          ),
                          tooltip: 'delete'.tr,
                          onPressed: () => context
                              .read<CategoryCubit>()
                              .deleteCategory(cat.id),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          );

          final brandTable = CustomDataTable(
            title: 'vape_brands_title'.tr,
            subtitle: 'brands_subtitle'.tr,
            searchHint: 'search_brands_hint'.tr,
            onSearchChanged: (q) => context.read<CategoryCubit>().filterBrands(q),
            emptyMessage: 'no_brands_found'.tr,
            emptyIcon: Icons.business_outlined,
            emptyAction: ElevatedButton.icon(
              onPressed: () {
                BrandFormDialog.show(
                  context,
                  onSave: (b) => context.read<CategoryCubit>().addBrand(b),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('add_brand'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.secondary,
                foregroundColor: Colors.black,
              ),
            ),
            trailingHeaderAction: ElevatedButton.icon(
              onPressed: () {
                BrandFormDialog.show(
                  context,
                  onSave: (b) => context.read<CategoryCubit>().addBrand(b),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('add_brand'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.secondary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
              ),
            ),
            columns: [
              DataTableColumn(label: 'brand_name'.tr),
              DataTableColumn(label: 'catalog_items'.tr),
              DataTableColumn(label: 'status'.tr),
              DataTableColumn(label: 'actions'.tr),
            ],
            rows: brands.map((b) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      b.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text('products_count_label'.trParams({'count': '${b.productsCount}'}))),
                  DataCell(StatusChip.fromActive(b.isFeatured)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColor.primary,
                          ),
                          tooltip: 'edit_brand'.tr,
                          onPressed: () {
                            BrandFormDialog.show(
                              context,
                              initialBrand: b,
                              onSave: (updated) => context
                                  .read<CategoryCubit>()
                                  .updateBrand(updated),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColor.error,
                          ),
                          tooltip: 'delete'.tr,
                          onPressed: () =>
                              context.read<CategoryCubit>().deleteBrand(b.id),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: categoryTable),
                      const SizedBox(width: AppSizes.lg),
                      Expanded(child: brandTable),
                    ],
                  )
                : Column(
                    children: [
                      categoryTable,
                      const SizedBox(height: AppSizes.lg),
                      brandTable,
                    ],
                  ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<CategoryCubit>().loadData(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }
}

/// Displays a category image as a rounded thumbnail in the data table.
/// Falls back to a category icon when no image URL is available.
class _CategoryImageCell extends StatelessWidget {
  final String imageUrl;

  const _CategoryImageCell({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkChip : AppColor.lightChip,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkChip : AppColor.lightChip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: AppColor.error,
            ),
          );
        },
      ),
    );
  }
}
