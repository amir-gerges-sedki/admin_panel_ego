import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';

class SidebarItem {
  final int index;
  final String titleKey;
  final IconData icon;
  final IconData selectedIcon;
  final int? badgeCount;

  const SidebarItem({
    required this.index,
    required this.titleKey,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount,
  });
}

/// Collapsible responsive Sidebar navigation for EGO Admin Panel
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int pendingOrdersCount;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.pendingOrdersCount = 0,
  });

  List<SidebarItem> get _items => [
        const SidebarItem(
          index: 0,
          titleKey: 'dashboard',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
        ),
        const SidebarItem(
          index: 1,
          titleKey: 'products',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
        ),
        const SidebarItem(
          index: 2,
          titleKey: 'categories',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category_rounded,
        ),
        SidebarItem(
          index: 3,
          titleKey: 'orders',
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping_rounded,
          badgeCount: pendingOrdersCount > 0 ? pendingOrdersCount : null,
        ),
        const SidebarItem(
          index: 4,
          titleKey: 'banners',
          icon: Icons.view_carousel_outlined,
          selectedIcon: Icons.view_carousel_rounded,
        ),
        const SidebarItem(
          index: 5,
          titleKey: 'coupons',
          icon: Icons.local_offer_outlined,
          selectedIcon: Icons.local_offer_rounded,
        ),
        const SidebarItem(
          index: 6,
          titleKey: 'customers',
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
        ),
        const SidebarItem(
          index: 7,
          titleKey: 'notifications',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign_rounded,
        ),
        const SidebarItem(
          index: 8,
          titleKey: 'settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = isCollapsed ? AppSizes.sidebarCollapsedWidth : AppSizes.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        border: BorderDirectional(
          end: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo & App Name Header
          _buildBrandHeader(isDark),
          const Divider(height: 1),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.md,
                horizontal: AppSizes.sm,
              ),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final item = _items[i];
                final isSelected = selectedIndex == item.index;
                return _buildNavTile(context, item, isSelected, isDark);
              },
            ),
          ),

          const Divider(height: 1),
          // Footer Collapse Button & Version
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(bool isDark) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : AppSizes.md),
      alignment: isCollapsed ? Alignment.center : AlignmentDirectional.centerStart,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColor.primary, Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: AppSizes.sm + 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EGO STORE',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1.0,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColor.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Vape Admin Suite',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    SidebarItem item,
    bool isSelected,
    bool isDark,
  ) {
    final title = item.titleKey.tr;

    return InkWell(
      onTap: () => onItemSelected(item.index),
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 0 : AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary.withValues(alpha: isDark ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: isSelected
              ? Border.all(color: AppColor.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 20,
              color: isSelected
                  ? AppColor.primary
                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColor.primary
                        : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                  ),
                ),
              ),
              if (item.badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColor.statusPending,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            Expanded(
              child: Text(
                'v1.2.0 • Pro Suite',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          IconButton(
            icon: Icon(
              isCollapsed
                  ? (isRtl ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded)
                  : (isRtl ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded),
              size: 20,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
            onPressed: onToggleCollapse,
            tooltip: isCollapsed ? 'expand_sidebar'.tr : 'collapse_sidebar'.tr,
          ),
        ],
      ),
    );
  }
}
