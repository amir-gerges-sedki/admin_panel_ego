import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/roles/domain/models/admin_role.dart';
import '../../../features/roles/presentation/cubit/auth_role_cubit.dart';

enum AdminWorkspaceMode {
  all,
  ecommerce,
  erp,
}

enum AdminItemDomain {
  common,
  ecommerce,
  erp,
}

class SidebarItem {
  final int index;
  final String titleKey;
  final AdminPermission permission;
  final IconData icon;
  final IconData selectedIcon;
  final int? badgeCount;
  final AdminItemDomain domain;

  const SidebarItem({
    required this.index,
    required this.titleKey,
    required this.permission,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount,
    this.domain = AdminItemDomain.common,
  });
}

/// Collapsible responsive Sidebar navigation for EGO Admin Panel with RBAC & Workspace Mode support
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int pendingOrdersCount;
  final AdminWorkspaceMode workspaceMode;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.pendingOrdersCount = 0,
    this.workspaceMode = AdminWorkspaceMode.all,
  });

  List<SidebarItem> get _allItems => [
        const SidebarItem(
          index: 0,
          titleKey: 'dashboard',
          permission: AdminPermission.dashboard,
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          domain: AdminItemDomain.common,
        ),
        const SidebarItem(
          index: 1,
          titleKey: 'pos_cashier',
          permission: AdminPermission.pos,
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale_rounded,
          domain: AdminItemDomain.erp,
        ),
        const SidebarItem(
          index: 2,
          titleKey: 'products',
          permission: AdminPermission.products,
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
          domain: AdminItemDomain.common,
        ),
        const SidebarItem(
          index: 3,
          titleKey: 'brands',
          permission: AdminPermission.brands,
          icon: Icons.branding_watermark_outlined,
          selectedIcon: Icons.branding_watermark_rounded,
          domain: AdminItemDomain.ecommerce,
        ),
        SidebarItem(
          index: 4,
          titleKey: 'orders',
          permission: AdminPermission.orders,
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping_rounded,
          badgeCount: pendingOrdersCount > 0 ? pendingOrdersCount : null,
          domain: AdminItemDomain.ecommerce,
        ),
        const SidebarItem(
          index: 5,
          titleKey: 'suppliers',
          permission: AdminPermission.suppliers,
          icon: Icons.business_outlined,
          selectedIcon: Icons.business_rounded,
          domain: AdminItemDomain.erp,
        ),
        const SidebarItem(
          index: 6,
          titleKey: 'expenses',
          permission: AdminPermission.expenses,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          domain: AdminItemDomain.erp,
        ),
        const SidebarItem(
          index: 7,
          titleKey: 'damaged_stock',
          permission: AdminPermission.damagedStock,
          icon: Icons.delete_sweep_outlined,
          selectedIcon: Icons.delete_sweep_rounded,
          domain: AdminItemDomain.erp,
        ),
        const SidebarItem(
          index: 8,
          titleKey: 'employees',
          permission: AdminPermission.employees,
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge_rounded,
          domain: AdminItemDomain.erp,
        ),
        const SidebarItem(
          index: 9,
          titleKey: 'banners',
          permission: AdminPermission.banners,
          icon: Icons.view_carousel_outlined,
          selectedIcon: Icons.view_carousel_rounded,
          domain: AdminItemDomain.ecommerce,
        ),
        const SidebarItem(
          index: 10,
          titleKey: 'coupons',
          permission: AdminPermission.coupons,
          icon: Icons.local_offer_outlined,
          selectedIcon: Icons.local_offer_rounded,
          domain: AdminItemDomain.ecommerce,
        ),
        const SidebarItem(
          index: 11,
          titleKey: 'customers',
          permission: AdminPermission.customers,
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          domain: AdminItemDomain.ecommerce,
        ),
        const SidebarItem(
          index: 12,
          titleKey: 'notifications',
          permission: AdminPermission.notifications,
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign_rounded,
          domain: AdminItemDomain.ecommerce,
        ),
        const SidebarItem(
          index: 13,
          titleKey: 'settings',
          permission: AdminPermission.settings,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          domain: AdminItemDomain.common,
        ),
        const SidebarItem(
          index: 14,
          titleKey: 'roles_permissions',
          permission: AdminPermission.roles,
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield_rounded,
          domain: AdminItemDomain.common,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = isCollapsed ? AppSizes.sidebarCollapsedWidth : AppSizes.sidebarWidth;

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        // Filter items dynamically according to active role permissions & active workspace mode
        final permittedItems = _allItems
            .where((item) => authState.hasPermission(item.permission))
            .toList();

        final allowedItems = _filterItemsByMode(permittedItems);

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
              _buildBrandHeader(isDark, authState),
              const Divider(height: 1),

              // Nav Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.sm,
                    horizontal: AppSizes.sm,
                  ),
                  itemCount: allowedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final item = allowedItems[i];
                    final isSelected = selectedIndex == item.index;
                    return _buildNavTile(context, item, isSelected, isDark);
                  },
                ),
              ),

              const Divider(height: 1),
              // Footer Collapse Button & Version
              _buildFooter(context, isDark, authState),
            ],
          ),
        );
      },
    );
  }

  List<SidebarItem> _filterItemsByMode(List<SidebarItem> items) {
    switch (workspaceMode) {
      case AdminWorkspaceMode.ecommerce:
        return items
            .where((item) =>
                item.domain == AdminItemDomain.ecommerce ||
                item.domain == AdminItemDomain.common)
            .toList();
      case AdminWorkspaceMode.erp:
        return items
            .where((item) =>
                item.domain == AdminItemDomain.erp ||
                item.domain == AdminItemDomain.common)
            .toList();
      case AdminWorkspaceMode.all:
        return items;
    }
  }

  Widget _buildBrandHeader(bool isDark, AuthRoleState authState) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : AppSizes.md),
      alignment: isCollapsed ? Alignment.center : AlignmentDirectional.centerStart,
      child: isCollapsed
          ? _buildCollapsedLogo()
          : Row(
              children: [
                _buildCollapsedLogo(),
                const SizedBox(width: AppSizes.sm + 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'app_name'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: authState.activeRole.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              authState.activeRole.labelKey.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: authState.activeRole.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCollapsedLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.storefront_rounded,
            color: AppColor.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, SidebarItem item, bool isSelected, bool isDark) {
    final textColor = isSelected
        ? AppColor.primary
        : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight);

    final bgColor = isSelected
        ? AppColor.primary.withValues(alpha: isDark ? 0.15 : 0.1)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(item.index),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : AppSizes.sm + 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: isSelected
                ? Border.all(color: AppColor.primary.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: textColor,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: AppSizes.sm + 2),
                Expanded(
                  child: Text(
                    item.titleKey.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.statusPending,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, AuthRoleState authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EGO Admin v1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
                  Text(
                    authState.activeAdminName,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: authState.activeRole.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              size: 20,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
            tooltip: isCollapsed ? 'expand_sidebar'.tr : 'collapse_sidebar'.tr,
            onPressed: onToggleCollapse,
          ),
        ],
      ),
    );
  }
}
