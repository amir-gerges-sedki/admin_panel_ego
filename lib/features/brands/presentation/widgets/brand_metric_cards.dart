import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';

/// KPI summary cards displaying registered brands, featured brands, and linked products.
class BrandMetricCards extends StatelessWidget {
  final bool isDesktop;
  final int totalBrands;
  final int featuredBrands;
  final int totalProducts;

  const BrandMetricCards({
    super.key,
    required this.isDesktop,
    required this.totalBrands,
    required this.featuredBrands,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      BrandMetricCard(
        title: 'total_registered_brands'.tr,
        value: '$totalBrands',
        icon: Icons.branding_watermark_rounded,
        color: AppColor.primary,
      ),
      BrandMetricCard(
        title: 'featured_active_brands'.tr,
        value: '$featuredBrands',
        icon: Icons.verified_outlined,
        color: Colors.green,
      ),
      BrandMetricCard(
        title: 'total_linked_products'.tr,
        value: '$totalProducts',
        icon: Icons.inventory_2_outlined,
        color: Colors.amber.shade700,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
          )
          .toList(),
    );
  }
}

/// An individual metric card displaying an icon, title, and count value.
class BrandMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const BrandMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
