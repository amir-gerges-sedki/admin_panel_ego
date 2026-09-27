import 'package:flutter/material.dart';
import '../../../../common/widgets/badges/status_chip.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/brand_model.dart';

/// Single table row with a drag catch handle on the right, logo, name, status, and actions.
class BrandTableRow extends StatelessWidget {
  final BrandModel brand;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BrandTableRow({
    super.key,
    required this.brand,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColor.darkBorder.withValues(alpha: 0.6)
                : AppColor.lightBorder.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Sort Order (Catch handle on the first column)
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Tooltip(
                      message: 'drag_to_reorder'.tr,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColor.darkDragHandle,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColor.darkSubCard
                        : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? AppColor.darkBorder
                          : AppColor.lightBorder,
                    ),
                  ),
                  child: Text(
                    '#${brand.sortOrder}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Logo & Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                BrandLogoCell(imageUrl: brand.image, name: brand.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    brand.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Catalog Products Count
          Expanded(
            flex: 2,
            child: Text(
              'products_count_label'.trParams({
                'count': '${brand.productsCount}',
              }),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          // 4. Status Chip
          SizedBox(
            width: 120,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip.fromActive(brand.isFeatured),
            ),
          ),

          // 5. Actions (Edit & Delete)
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColor.primary,
                  ),
                  tooltip: 'edit_brand'.tr,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColor.error,
                  ),
                  tooltip: 'delete'.tr,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a brand logo thumbnail or initial letter fallback.
class BrandLogoCell extends StatelessWidget {
  final String imageUrl;
  final String name;

  const BrandLogoCell({super.key, required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.isEmpty) {
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColor.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkChip : AppColor.lightChip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.business_outlined, size: 18),
        ),
      ),
    );
  }
}
