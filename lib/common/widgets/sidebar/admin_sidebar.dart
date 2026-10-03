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

class SidebarSection {
  final String titleKey;
  final List<SidebarItem> items;

  const SidebarSection({
    required this.titleKey,
    required this.items,
  });
}

/// Collapsible responsive Sidebar navigation for EGO Admin Panel with Business Task Hierarchy & RBAC
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int pendingOrdersCount;
  final int pendingTransfersCount;
  final AdminWorkspaceMode workspaceMode;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.pendingOrdersCount = 0,
    this.pendingTransfersCount = 0,
    this.workspaceMode = AdminWorkspaceMode.all,
  });

  List<SidebarSection> get _sections => [
        SidebarSection(
          titleKey: 'nav_section_overview',
          items: const [
            SidebarItem(
              index: 0,
              titleKey: 'dashboard',
              permission: AdminPermission.dashboard,
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              domain: AdminItemDomain.common,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_sales',
          items: [
            const SidebarItem(
              index: 1,
              titleKey: 'pos_cashier',
              permission: AdminPermission.pos,
              icon: Icons.point_of_sale_outlined,
              selectedIcon: Icons.point_of_sale_rounded,
              domain: AdminItemDomain.erp,
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
              index: 15,
              titleKey: 'customers',
              permission: AdminPermission.customers,
              icon: Icons.people_outline_rounded,
              selectedIcon: Icons.people_rounded,
              domain: AdminItemDomain.ecommerce,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_inventory',
          items: [
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
              index: 10,
              titleKey: 'inventory_transfers',
              permission: AdminPermission.transfers,
              icon: Icons.swap_horiz_outlined,
              selectedIcon: Icons.swap_horiz_rounded,
              badgeCount: pendingTransfersCount > 0 ? pendingTransfersCount : null,
              domain: AdminItemDomain.erp,
            ),
            const SidebarItem(
              index: 11,
              titleKey: 'damaged_stock',
              permission: AdminPermission.damagedStock,
              icon: Icons.delete_sweep_outlined,
              selectedIcon: Icons.delete_sweep_rounded,
              domain: AdminItemDomain.erp,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_purchasing',
          items: const [
            SidebarItem(
              index: 5,
              titleKey: 'suppliers',
              permission: AdminPermission.suppliers,
              icon: Icons.business_outlined,
              selectedIcon: Icons.business_rounded,
              domain: AdminItemDomain.erp,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_finance',
          items: const [
            SidebarItem(
              index: 9,
              titleKey: 'cashier_shifts',
              permission: AdminPermission.shifts,
              icon: Icons.access_time_outlined,
              selectedIcon: Icons.access_time_filled_rounded,
              domain: AdminItemDomain.erp,
            ),
            SidebarItem(
              index: 6,
              titleKey: 'expenses',
              permission: AdminPermission.expenses,
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long_rounded,
              domain: AdminItemDomain.erp,
            ),
            SidebarItem(
              index: 7,
              titleKey: 'accounting',
              permission: AdminPermission.accounting,
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet_rounded,
              domain: AdminItemDomain.erp,
            ),
            SidebarItem(
              index: 8,
              titleKey: 'reports',
              permission: AdminPermission.reports,
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart_rounded,
              domain: AdminItemDomain.erp,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_marketing',
          items: const [
            SidebarItem(
              index: 13,
              titleKey: 'banners',
              permission: AdminPermission.banners,
              icon: Icons.view_carousel_outlined,
              selectedIcon: Icons.view_carousel_rounded,
              domain: AdminItemDomain.ecommerce,
            ),
            SidebarItem(
              index: 14,
              titleKey: 'coupons',
              permission: AdminPermission.coupons,
              icon: Icons.local_offer_outlined,
              selectedIcon: Icons.local_offer_rounded,
              domain: AdminItemDomain.ecommerce,
            ),
            SidebarItem(
              index: 16,
              titleKey: 'notifications',
              permission: AdminPermission.notifications,
              icon: Icons.campaign_outlined,
              selectedIcon: Icons.campaign_rounded,
              domain: AdminItemDomain.ecommerce,
            ),
          ],
        ),
        SidebarSection(
          titleKey: 'nav_section_system',
          items: const [
            SidebarItem(
              index: 12,
              titleKey: 'employees',
              permission: AdminPermission.employees,
              icon: Icons.badge_outlined,
              selectedIcon: Icons.badge_rounded,
              domain: AdminItemDomain.erp,
            ),
            SidebarItem(
              index: 18,
              titleKey: 'roles_permissions',
              permission: AdminPermission.roles,
              icon: Icons.shield_outlined,
              selectedIcon: Icons.shield_rounded,
              domain: AdminItemDomain.common,
            ),
            SidebarItem(
              index: 17,
              titleKey: 'settings',
              permission: AdminPermission.settings,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              domain: AdminItemDomain.common,
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = isCollapsed ? AppSizes.sidebarCollapsedWidth : AppSizes.sidebarWidth;

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        // Build filtered sections based on role permissions and workspace mode
        final visibleSections = <SidebarSection>[];

        for (final section in _sections) {
          final permittedItems = section.items
              .where((item) => authState.hasPermission(item.permission))
              .toList();
          final allowedItems = _filterItemsByMode(permittedItems);

          if (allowedItems.isNotEmpty) {
            visibleSections.add(SidebarSection(
              titleKey: section.titleKey,
              items: allowedItems,
            ));
          }
        }

        return ClipRect(
          child: AnimatedContainer(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isExpandedLayout = !isCollapsed && constraints.maxWidth > 120;

                return Column(
                  children: [
                    // Logo & App Name Header
                    _buildBrandHeader(isDark, authState, isExpandedLayout),

                    // Nav Sections List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSizes.sm + 2,
                          horizontal: isExpandedLayout ? AppSizes.sm + 2 : 6,
                        ),
                        itemCount: visibleSections.length,
                        itemBuilder: (context, sIndex) {
                          final section = visibleSections[sIndex];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isExpandedLayout) ...[
                                if (sIndex > 0) const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    section.titleKey.tr.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark
                                          ? AppColor.textMutedDark.withValues(alpha: 0.7)
                                          : AppColor.textMutedLight.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ] else if (sIndex > 0) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: isDark
                                        ? AppColor.darkBorder.withValues(alpha: 0.4)
                                        : AppColor.lightBorder.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              ...section.items.map((item) {
                                final isSelected = selectedIndex == item.index;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: _buildNavTile(context, item, isSelected, isDark, isExpandedLayout),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),

                    // Footer Collapse Button & Version
                    _buildFooter(context, isDark, authState, isExpandedLayout),
                  ],
                );
              },
            ),
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

  Widget _buildBrandHeader(bool isDark, AuthRoleState authState, bool isExpandedLayout) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isExpandedLayout ? AppSizes.md : 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
      ),
      alignment: isExpandedLayout ? AlignmentDirectional.centerStart : Alignment.center,
      child: isExpandedLayout
          ? Row(
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
                      const SizedBox(height: 2),
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
            )
          : _buildCollapsedLogo(),
    );
  }

  Widget _buildCollapsedLogo() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.storefront_rounded,
            color: AppColor.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, SidebarItem item, bool isSelected, bool isDark, bool isExpandedLayout) {
    final textColor = isSelected
        ? AppColor.primary
        : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight);

    final bgColor = isSelected
        ? AppColor.primary.withValues(alpha: isDark ? 0.12 : 0.08)
        : Colors.transparent;

    return Tooltip(
      message: !isExpandedLayout ? item.titleKey.tr : '',
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(item.index),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: isExpandedLayout ? 12 : 0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
            child: Row(
              mainAxisAlignment: isExpandedLayout ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: textColor,
                  size: 20,
                ),
                if (isExpandedLayout) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.titleKey.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, AuthRoleState authState, bool isExpandedLayout) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: isExpandedLayout ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (isExpandedLayout)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authState.activeAdminName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: AnimatedRotation(
              turns: isCollapsed ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
            tooltip: isCollapsed ? 'expand_sidebar'.tr : 'collapse_sidebar'.tr,
            onPressed: onToggleCollapse,
          ),
        ],
      ),
    );
  }
}
