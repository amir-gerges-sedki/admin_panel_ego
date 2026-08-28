import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../products/presentation/cubit/product_cubit.dart';

class LowStockAlertCard extends StatelessWidget {
  const LowStockAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final lowStockProducts = state is ProductLoaded
            ? state.products.where((p) => p.stock <= 10).toList()
            : [];

        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : AppColor.lightCard,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColor.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColor.warning, size: 18),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        'Low Stock Warnings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  if (lowStockProducts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lowStockProducts.length} Urgent',
                        style: const TextStyle(
                          color: AppColor.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Optimal',
                        style: TextStyle(
                          color: AppColor.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              if (lowStockProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Center(
                    child: Text(
                      'All inventory levels are healthy (Stock > 10 units)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockProducts.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final product = lowStockProducts[i];
                    return Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          ),
                          child: Center(
                            child: Text(
                              '${product.stock}',
                              style: const TextStyle(
                                color: AppColor.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${product.brand?.name ?? "General"} • ${product.productType.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HelperFun.infoSnackbar(
                              title: 'Restock Request',
                              message: 'Restock requested for ${product.title}',
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColor.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Restock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
