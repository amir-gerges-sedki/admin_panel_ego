import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../badges/data/models/badge_model.dart';
import '../../../badges/data/repositories/badge_repository.dart';
import '../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../badges/presentation/cubit/badge_state.dart';
import '../../data/models/product_model.dart';
import 'product_barcode_print_dialog.dart';

class ProductDetailsDialog extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsDialog({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedDisplayName = isArabic ? product.categoryType.arabicName : product.categoryType.displayName;
    final displayName = product.displayTitle;

    UnifiedModalSheet.show(
      context: context,
      title: displayName,
      subtitle: '$resolvedDisplayName • ${product.brand.name.isNotEmpty ? product.brand.name : "General"}',
      icon: product.categoryType.icon,
      maxWidth: 750,
      content: BlocProvider<BadgeCubit>(
        create: (ctx) {
          if (sl.isRegistered<BadgeCubit>()) {
            return sl<BadgeCubit>();
          }
          final repo = sl.isRegistered<BadgeRepository>()
              ? sl<BadgeRepository>()
              : BadgeRepositoryImpl();
          return BadgeCubit(repo)..loadBadges();
        },
        child: ProductDetailsDialog(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = product.categoryType.accentColor;
    final resolvedDisplayName = isArabic ? product.categoryType.arabicName : product.categoryType.displayName;
    final displayName = product.displayTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Image & Summary Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              child: Image.network(
                product.thumbnail,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 110,
                  height: 110,
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  child: Icon(
                    product.categoryType.icon,
                    size: 36,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColor.textPrimaryDark
                          : AppColor.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final variations = product.productVariations;
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
                          : (product.salePrice > 0 && product.salePrice < product.price ? product.salePrice : (product.price > 0 ? product.price : product.salePrice));
                      final double maxEff = effectivePrices.isNotEmpty
                          ? effectivePrices.reduce((a, b) => a > b ? a : b)
                          : minEff;

                      final double minReg = regularPrices.isNotEmpty
                          ? regularPrices.reduce((a, b) => a < b ? a : b)
                          : (product.price > 0 ? product.price : product.salePrice);
                      final double maxReg = regularPrices.isNotEmpty
                          ? regularPrices.reduce((a, b) => a > b ? a : b)
                          : minReg;

                      final bool hasRange = minEff < maxEff;
                      final bool hasAnyDiscount = variations.isNotEmpty
                          ? variations.any((v) => v.salePrice > 0 && v.salePrice < v.price)
                          : (product.salePrice > 0 && product.salePrice < product.price);

                      if (hasRange) {
                        return Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              '${AppFormatters.formatEGP(minEff)} - ${AppFormatters.formatEGP(maxEff)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: hasAnyDiscount ? const Color(0xFF10B981) : color,
                              ),
                            ),
                            if (hasAnyDiscount && (minReg > minEff || maxReg > maxEff))
                              Text(
                                '${AppFormatters.formatEGP(minReg)} - ${AppFormatters.formatEGP(maxReg)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColor.textMutedDark,
                                ),
                              ),
                          ],
                        );
                      }

                      final displayPrice = hasAnyDiscount
                          ? product.salePrice
                          : (product.price > 0 ? product.price : product.salePrice);

                      return Row(
                        children: [
                          Text(
                            AppFormatters.formatEGP(displayPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: hasAnyDiscount ? const Color(0xFF10B981) : color,
                            ),
                          ),
                          if (hasAnyDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatEGP(product.price),
                              style: const TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                color: AppColor.textMutedDark,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Category Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusSm,
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.categoryType.icon,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resolvedDisplayName,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip.fromStock(product.stock),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusSm,
                          ),
                        ),
                        child: Text(
                          product.brand.name.isNotEmpty
                              ? product.brand.name
                              : 'General',
                          style: const TextStyle(
                            color: AppColor.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.isBadgeEnabled && product.badgeId.isNotEmpty)
                        BlocBuilder<BadgeCubit, BadgeState>(
                          builder: (context, bState) {
                            final badges = bState is BadgeLoaded
                                ? bState.badges
                                : <BadgeModel>[];
                            final b = badges.firstWhere(
                              (e) =>
                                  e.id == product.badgeId ||
                                  e.name.toUpperCase() ==
                                      product.badgeId.toUpperCase(),
                              orElse: () => BadgeModel(
                                id: product.badgeId,
                                name: product.badgeId,
                              ),
                            );
                            Color bColor;
                            try {
                              final clean =
                                  b.colorHex.replaceAll('#', '').trim();
                              bColor =
                                  Color(int.parse('FF$clean', radix: 16));
                            } catch (_) {
                              bColor = const Color(0xFFF59E0B);
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusSm,
                                ),
                                border: Border.all(
                                  color: bColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '🏷️ ${b.name}',
                                style: TextStyle(
                                  color: bColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () => ProductBarcodePrintDialog.show(context, product: product),
              icon: const Icon(Icons.qr_code_2_rounded, size: 16),
              label: Text(
                isArabic ? 'طباعة استيكرات الباركود' : 'Print Barcode Labels',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSizes.md),

        // Description
        if (product.description.isNotEmpty) ...[
          Text(
            'product_description_col'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColor.textPrimaryDark
                  : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Flavors List (If available)
        if (product.flavors.isNotEmpty) ...[
          Text(
            'flavors_available_label'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColor.textPrimaryDark
                  : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: product.flavors.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.icecream_outlined,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Specifications
        if (product.specifications.isNotEmpty) ...[
          Text(
            'technical_specs'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColor.textPrimaryDark
                  : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(AppSizes.sm + 4),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: product.specifications.entries
                  .where((e) {
                    final k = e.key.toLowerCase();
                    return k != 'type' && k != 'liquidtype';
                  })
                  .map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${e.key}: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                    Text(
                      e.value.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Variations List
        if (product.productVariations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'variation_matrix'.tr} (${product.productVariations.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColor.textPrimaryDark
                      : AppColor.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${product.productVariations.length} Active SKUs',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: product.productVariations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = product.productVariations[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.sku,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: v.attributeValues.entries
                                  .where((e) {
                                    final k = e.key.toLowerCase();
                                    return k != 'type' && k != 'liquidtype';
                                  })
                                  .map((e) {
                                final isColor = e.key.toLowerCase().contains('color') ||
                                    e.key.contains('لون') ||
                                    e.value.contains('#');
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isColor) ...[
                                        ColorUtils.buildColorIndicator(e.value, size: 10),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        isColor ? ColorUtils.getReadableColorName(e.value) : '${e.key}: ${e.value}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Builder(
                              builder: (context) {
                                final hasVarDiscount = v.salePrice > 0 && v.salePrice < v.price;
                                final varDisplayPrice = hasVarDiscount
                                    ? v.salePrice
                                    : (v.price > 0 ? v.price : v.salePrice);

                                if (hasVarDiscount) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.formatEGP(varDisplayPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.formatEGP(v.price),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                          color: AppColor.textMutedDark,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Text(
                                  AppFormatters.formatEGP(varDisplayPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                );
                              },
                            ),
                            Text(
                              '${'stock'.tr}: ${v.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: v.stock < 5
                                    ? AppColor.warning
                                    : AppColor.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
