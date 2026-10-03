import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/coupon_model.dart';
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  columns: [
                    DataTableColumn(label: 'coupon_code'.tr),
                    DataTableColumn(label: 'discount_percentage'.tr),
                    DataTableColumn(label: 'min_purchase_amount'.tr),
                    DataTableColumn(label: 'redemptions'.tr),
                    DataTableColumn(label: 'start_date'.tr),
                    DataTableColumn(label: 'end_date'.tr),
                    DataTableColumn(label: 'status'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: coupons.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColor.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColor.primary),
                                const SizedBox(width: 5),
                                Text(
                                  c.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
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
                        DataCell(Text(AppFormatters.formatDate(c.startDate))),
                        DataCell(Text(AppFormatters.formatDate(c.expiryDate))),
                        DataCell(
                          StatusChip.fromCoupon(
                            isActive: c.isActive,
                            isExpired: c.isExpired,
                            isStarted: c.isStarted,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.primary),
                                tooltip: 'edit_coupon'.tr,
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
                                tooltip: 'delete_coupon'.tr,
                                onPressed: () => _confirmDelete(context, c),
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

  void _confirmDelete(BuildContext context, CouponModel coupon) {
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
                'delete_coupon_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          coupon.code.trim().isNotEmpty
              ? 'delete_coupon_confirm_with_code'.trParams({'code': coupon.code})
              : 'delete_coupon_confirm'.tr,
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
              context.read<CouponCubit>().deleteCoupon(coupon.id);
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
