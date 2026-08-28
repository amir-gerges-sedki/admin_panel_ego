import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/product_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final color = widget.type.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, (_isHovered || widget.isSelected) ? -4.0 : 0.0, 0.0),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (_isHovered
                      ? (isDark ? AppColor.darkSubCard : AppColor.lightSubCard)
                      : (isDark ? AppColor.darkCard : AppColor.lightCard)),
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
              border: Border.all(
                color: widget.isSelected
                    ? color
                    : (_isHovered
                        ? color.withValues(alpha: 0.5)
                        : (isDark ? AppColor.darkBorder : AppColor.lightBorder)),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: widget.isSelected || _isHovered
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Icon with soft background and Selection Checkmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.25),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: color,
                        size: 26,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Center Title & Arabic subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.type.arabicName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.type.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.sm),

                // Bottom category tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                  child: Text(
                    widget.type.id,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
