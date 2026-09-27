import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_bloc.dart';
import '../../data/models/banner_model.dart';
import '../cubit/banner_cubit.dart';
import '../widgets/banner_form_dialog.dart';
import '../../../products/presentation/cubit/product_cubit.dart';

class BannersScreen extends StatelessWidget {
  const BannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, localeState) {
        return BlocBuilder<BannerCubit, BannerState>(
          builder: (context, state) {
            if (state is BannerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BannerLoaded) {
              final banners = state.filteredBanners;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomDataTable(
                      title: 'banners_title'.tr,
                      subtitle: 'banners_subtitle'.tr,
                      searchHint: 'search_banners_hint'.tr,
                      onSearchChanged: (q) => context.read<BannerCubit>().filterBanners(q),
                      emptyMessage: 'no_banners_found'.tr,
                      emptyIcon: Icons.view_carousel_outlined,
                      emptyAction: ElevatedButton.icon(
                        onPressed: () {
                          BannerFormDialog.show(
                            context,
                            onSave: (b) => context.read<BannerCubit>().addBanner(b),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('add_banner'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      trailingHeaderAction: ElevatedButton.icon(
                        onPressed: () {
                          BannerFormDialog.show(
                            context,
                            onSave: (b) => context.read<BannerCubit>().addBanner(b),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('add_banner'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                        ),
                      ),
                      columns: [
                        DataTableColumn(label: 'preview'.tr, width: 120),
                        DataTableColumn(label: 'banner_title_col'.tr),
                        DataTableColumn(label: 'target_destination'.tr),
                        DataTableColumn(label: 'status'.tr),
                        DataTableColumn(label: 'actions'.tr),
                      ],
                      rows: banners.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  b.imageUrl,
                                  width: 80,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 80,
                                    height: 36,
                                    color: AppColor.darkSubCard,
                                    child: const Icon(Icons.image_outlined, size: 16),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(_buildDestinationCell(context, b)),
                            DataCell(StatusChip.fromActive(b.active)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.primary),
                                    tooltip: 'edit'.tr,
                                    onPressed: () {
                                      BannerFormDialog.show(
                                        context,
                                        initialBanner: b,
                                        onSave: (updated) => context.read<BannerCubit>().updateBanner(updated),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                                    tooltip: 'delete'.tr,
                                    onPressed: () => _confirmDelete(context, b),
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
                onPressed: () => context.read<BannerCubit>().loadBanners(),
                child: Text('reload'.tr),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDestinationCell(BuildContext context, BannerModel b) {
    if (b.isProductTarget) {
      return Builder(
        builder: (context) {
          final productState = context.watch<ProductCubit>().state;
          String? productTitle;
          if (productState is ProductLoaded && b.productId != null) {
            final prod = productState.products
                .where((p) => p.id == b.productId)
                .firstOrNull;
            if (prod != null) {
              productTitle = prod.displayTitle;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 13, color: AppColor.primary),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        productTitle ?? b.productTitle ?? b.productId ?? 'product_details_dest'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${'target_product_short'.tr} • #${b.productId ?? ""}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        },
      );
    }

    final destLabel = _resolveDestinationLabel(b);
    final destIcon = _resolveDestinationIcon(b);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(destIcon, size: 14, color: AppColor.primary),
        const SizedBox(width: 6),
        Text(
          destLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  String _resolveDestinationLabel(BannerModel b) {
    final t = (b.targetType ?? b.targetScreen).trim().toLowerCase();
    final s = b.targetScreen.trim().toLowerCase();

    if (t.contains('new') || s.contains('new')) {
      return 'route_new_arrivals'.tr;
    }
    if (t.contains('popular') || t.contains('best') || s.contains('popular') || s.contains('best')) {
      return 'route_popular'.tr;
    }
    if (t.contains('deal') || t.contains('sale') || t.contains('offer') || s.contains('deal') || s.contains('sale')) {
      return 'route_deals'.tr;
    }
    if (t.contains('shop') || s.contains('shop') || s.contains('store')) {
      return 'route_shop'.tr;
    }
    if (t.contains('brand') || s.contains('brand')) {
      return 'route_brands'.tr;
    }
    if (t.contains('categor') || s.contains('categor')) {
      return 'route_categories'.tr;
    }
    if (t.contains('cart') || s.contains('cart')) {
      return 'route_cart'.tr;
    }
    if (t.contains('profile') || s.contains('profile') || s.contains('account')) {
      return 'route_profile'.tr;
    }
    if (t.contains('custom') || s.startsWith('http')) {
      return 'route_custom'.tr;
    }
    if (b.targetScreen.isNotEmpty) {
      final translated = b.targetScreen.tr;
      if (translated != b.targetScreen) return translated;
    }
    return 'target_destination'.tr;
  }

  IconData _resolveDestinationIcon(BannerModel b) {
    final t = (b.targetType ?? b.targetScreen).trim().toLowerCase();
    final s = b.targetScreen.trim().toLowerCase();

    if (t.contains('new') || s.contains('new')) return Icons.auto_awesome_outlined;
    if (t.contains('popular') || t.contains('best') || s.contains('popular')) return Icons.star_outline_rounded;
    if (t.contains('deal') || t.contains('sale') || s.contains('deal')) return Icons.local_offer_outlined;
    if (t.contains('brand') || s.contains('brand')) return Icons.branding_watermark_outlined;
    if (t.contains('categor') || s.contains('categor')) return Icons.category_outlined;
    if (t.contains('cart') || s.contains('cart')) return Icons.shopping_cart_outlined;
    if (t.contains('profile') || s.contains('profile')) return Icons.person_outline_rounded;
    if (t.contains('shop') || s.contains('shop')) return Icons.storefront_outlined;
    return Icons.alt_route_rounded;
  }

  void _confirmDelete(BuildContext context, BannerModel banner) {
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_banner_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          banner.title.trim().isNotEmpty
              ? 'delete_banner_confirm_with_title'.trParams({'title': banner.title})
              : 'delete_banner_confirm'.tr,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BannerCubit>().deleteBanner(banner.id);
              HelperFun.successSnackbar('success'.tr, 'item_deleted'.tr);
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
