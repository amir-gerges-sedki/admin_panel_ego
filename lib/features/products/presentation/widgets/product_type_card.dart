import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';

/// Compact, low-profile product category card ("حاجات صغيرة وبسيطة").
class ProductTypeCard extends StatefulWidget {
  final ProductCategoryType type;
  final bool isSelected;
  final VoidCallback onSelect;

  const ProductTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<ProductTypeCard> createState() => _ProductTypeCardState();
}

class _ProductTypeCardState extends State<ProductTypeCard> {
  bool _isHovered = false;

  String _getSubtitle() {
    switch (widget.type) {
      case ProductCategoryType.liquid:
        return 'type_subtitle_liquid'.tr;
      case ProductCategoryType.disposable:
        return 'type_subtitle_disposable'.tr;
      case ProductCategoryType.device:
        return 'type_subtitle_device'.tr;
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'type_subtitle_pod'.tr;
      case ProductCategoryType.accessory:
        return 'type_subtitle_accessory'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = widget.type.accentColor;
    final isSel = widget.isSelected;

    final title = isArabic ? widget.type.arabicName : widget.type.displayName;
    final subtitle = _getSubtitle();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0.0,
          (_isHovered || isSel) ? -2.0 : 0.0,
          0.0,
        ),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 2,
            ),
            decoration: BoxDecoration(
              gradient: isSel
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: isDark ? 0.20 : 0.12),
                        color.withValues(alpha: isDark ? 0.07 : 0.03),
                      ],
                    )
                  : null,
              color: isSel
                  ? null
                  : (_isHovered
                        ? (isDark ? AppColor.darkSubCard : AppColor.lightSubCard)
                        : (isDark ? AppColor.darkCard : AppColor.lightCard)),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(
                color: isSel
                    ? color
                    : (_isHovered
                          ? color.withValues(alpha: 0.35)
                          : (isDark ? AppColor.darkBorder : AppColor.lightBorder)),
                width: isSel ? 1.4 : 1.0,
              ),
              boxShadow: (isSel || _isHovered) && !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Compact Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: isSel ? 0.35 : 0.18),
                        color.withValues(alpha: isSel ? 0.15 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: isSel ? 0.45 : 0.2),
                    ),
                  ),
                  child: Icon(
                    widget.type.icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.sm + 2),

                // Title & Localized Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
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
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Selection check indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSel ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel
                          ? color
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.2)),
                      width: isSel ? 1.5 : 1.2,
                    ),
                  ),
                  child: isSel
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

