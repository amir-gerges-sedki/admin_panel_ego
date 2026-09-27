import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/widgets/quick_restock_dialog.dart';
import '../../../products/presentation/widgets/stock_movements_dialog.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class LowStockAlertCard extends StatelessWidget {
  const LowStockAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final int threshold = settingsState is SettingsLoaded
            ? settingsState.settings.lowStockThreshold
            : 10;

        return BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            final List<ProductModel> allProducts = state is ProductLoaded ? state.products : [];

            // Find products that either have total stock <= threshold OR any variation <= threshold
            final List<Map<String, dynamic>> urgentItems = [];

            for (final p in allProducts) {
              if (p.productVariations.isNotEmpty) {
                final lowVars = p.productVariations.where((v) {
                  final t = v.lowStockThreshold ?? p.lowStockThreshold ?? threshold;
                  return v.stock <= t;
                }).toList();

                if (lowVars.isNotEmpty || p.stock <= (p.lowStockThreshold ?? threshold)) {
                  urgentItems.add({
                    'product': p,
                    'lowVars': lowVars,
                    'totalStock': p.stock,
                    'isVariable': true,
                  });
                }
              } else {
                final t = p.lowStockThreshold ?? threshold;
                if (p.stock <= t) {
                  urgentItems.add({
                    'product': p,
                    'lowVars': <ProductVariationModel>[],
                    'totalStock': p.stock,
                    'isVariable': false,
                  });
                }
              }
            }

            return Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkCard : AppColor.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColor.warning.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.borderRadiusSm),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColor.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'kpi_low_stock_alerts'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColor.textPrimaryDark
                                  : AppColor.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.history_rounded, size: 14),
                            label: Text(
                              'audit_log'.tr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => StockMovementsDialog.show(context),
                          ),
                          const SizedBox(width: 6),
                          if (urgentItems.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'urgent_items_badge'.trParams({
                                  'count': urgentItems.length.toString(),
                                  'threshold': threshold.toString(),
                                }),
                                style: const TextStyle(
                                  color: AppColor.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'optimal_stock_badge'.tr,
                                style: const TextStyle(
                                  color: AppColor.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  if (urgentItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                      child: Center(
                        child: Text(
                          'healthy_stock_desc'.tr.replaceAll(
                                '{threshold}',
                                threshold.toString(),
                              ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: urgentItems.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, i) {
                        final item = urgentItems[i];
                        final ProductModel product = item['product'] as ProductModel;
                        final List<ProductVariationModel> lowVars =
                            item['lowVars'] as List<ProductVariationModel>;
                        final int totalStock = item['totalStock'] as int;
                        final bool isVariable = item['isVariable'] as bool;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColor.darkSubCard
                                    : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusSm,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$totalStock',
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
                                    product.displayTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColor.textPrimaryDark
                                          : AppColor.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product.brand.name.isNotEmpty ? product.brand.name : "general_brand".tr} • ${product.categoryType.displayName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColor.textMutedDark
                                          : AppColor.textMutedLight,
                                    ),
                                  ),
                                  if (isVariable && lowVars.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: lowVars.take(3).map((v) {
                                        final attrSummary = v.attributeValues.values.take(2).join(' ');
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColor.error.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${attrSummary.isNotEmpty ? attrSummary : v.sku} (${v.stock})',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.error,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                QuickRestockDialog.show(
                                  context,
                                  product: product,
                                  initialVariationSku: lowVars.isNotEmpty ? lowVars.first.sku : null,
                                  defaultThreshold: threshold,
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                              label: Text(
                                'restock_btn'.tr,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
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
      },
    );
  }
}
