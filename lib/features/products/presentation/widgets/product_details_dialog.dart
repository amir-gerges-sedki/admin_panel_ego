import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../badges/data/models/badge_model.dart';
import '../../../badges/data/repositories/badge_repository.dart';
import '../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../badges/presentation/cubit/badge_state.dart';
import '../../data/models/product_model.dart';

class ProductDetailsDialog extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsDialog({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedDisplayName = isArabic ? product.categoryType.arabicName : product.categoryType.displayName;
    final displayName = product.title.isNotEmpty ? product.title : (product.brand.name.isNotEmpty ? product.brand.name : 'Untitled');

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
    final displayName = product.title.isNotEmpty ? product.title : (product.brand.name.isNotEmpty ? product.brand.name : 'Untitled');

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
                  Row(
                    children: [
                      Text(
                        AppFormatters.formatEGP(product.salePrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      if (product.price > product.salePrice) ...[
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
                              (e) => e.id == product.badgeId,
                              orElse: () => BadgeModel(
                                id: product.badgeId,
                                name: product.badgeId,
                              ),
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusSm,
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '🏷️ ${b.name}',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                      if (product.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusSm,
                            ),
                          ),
                          child: Text(
                            'featured'.tr,
                            style: const TextStyle(
                              color: AppColor.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
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
              children: product.specifications.entries.map((e) {
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
                              children: v.attributeValues.entries.map((e) {
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
                                  child: Text(
                                    '${e.key}: ${e.value}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
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
                            Text(
                              AppFormatters.formatEGP(v.salePrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
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
