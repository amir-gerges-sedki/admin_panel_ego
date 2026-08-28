import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/banner_cubit.dart';
import '../widgets/banner_form_dialog.dart';

class BannersScreen extends StatelessWidget {
  const BannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        DataCell(Text(b.targetScreen, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
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
                                onPressed: () => context.read<BannerCubit>().deleteBanner(b.id),
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
  }
}
