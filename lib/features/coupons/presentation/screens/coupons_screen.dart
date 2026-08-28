import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/coupon_cubit.dart';
import '../widgets/coupon_form_dialog.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CouponCubit, CouponState>(
      builder: (context, state) {
        if (state is CouponLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CouponLoaded) {
          final coupons = state.filteredCoupons;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDataTable(
                  title: 'coupons_title'.tr,
                  subtitle: 'coupons_subtitle'.tr,
                  searchHint: 'search_coupons_hint'.tr,
                  onSearchChanged: (q) => context.read<CouponCubit>().filterCoupons(q),
                  emptyMessage: 'no_coupons_found'.tr,
                  emptyIcon: Icons.discount_outlined,
                  emptyAction: ElevatedButton.icon(
                    onPressed: () {
                      CouponFormDialog.show(
                        context,
                        onSave: (c) => context.read<CouponCubit>().addCoupon(c),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('add_coupon'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  trailingHeaderAction: ElevatedButton.icon(
                    onPressed: () {
                      CouponFormDialog.show(
                        context,
                        onSave: (c) => context.read<CouponCubit>().addCoupon(c),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('add_coupon'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                  ),
                  columns: [
                    DataTableColumn(label: 'coupon_code'.tr),
                    DataTableColumn(label: 'discount_percentage'.tr),
                    DataTableColumn(label: 'min_cart_requirement'.tr),
                    DataTableColumn(label: 'redemptions'.tr),
                    DataTableColumn(label: 'expiry_date'.tr),
                    DataTableColumn(label: 'status'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: coupons.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              c.code,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColor.primary),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'off_discount'.trParams({'percent': '${c.discountPercentage.toInt()}'}),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColor.success),
                          ),
                        ),
                        DataCell(Text(c.minOrderAmount > 0 ? AppFormatters.formatEGP(c.minOrderAmount) : 'no_minimum'.tr)),
                        DataCell(Text('times_used'.trParams({'count': '${c.usageCount}'}))),
                        DataCell(Text(AppFormatters.formatDate(c.expiryDate))),
                        DataCell(StatusChip.fromActive(c.isActive)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.primary),
                                tooltip: 'edit'.tr,
                                onPressed: () {
                                  CouponFormDialog.show(
                                    context,
                                    initialCoupon: c,
                                    onSave: (updated) => context.read<CouponCubit>().updateCoupon(updated),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                                tooltip: 'delete'.tr,
                                onPressed: () => context.read<CouponCubit>().deleteCoupon(c.id),
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
            onPressed: () => context.read<CouponCubit>().loadCoupons(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }
}
