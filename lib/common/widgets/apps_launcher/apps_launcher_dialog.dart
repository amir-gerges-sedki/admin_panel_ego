import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/helper/responsive_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/orders/presentation/cubit/order_cubit.dart';
import '../../../features/inventory_transfers/presentation/cubit/stock_transfer_cubit.dart';
import '../../../features/inventory_transfers/presentation/cubit/stock_transfer_state.dart';
import '../../../features/inventory_transfers/data/models/stock_transfer_model.dart';
import '../../../features/roles/domain/models/admin_role.dart';
import '../../../features/roles/presentation/cubit/auth_role_cubit.dart';

/// Single App definition for Apps Launcher Hub
class AppLauncherDef {
  final int index;
  final String titleKey;
  final String subtitleKey;
  final AdminPermission permission;
  final IconData icon;
  final Color color;
  final String categoryKey;

  const AppLauncherDef({
    required this.index,
    required this.titleKey,
    required this.subtitleKey,
    required this.permission,
    required this.icon,
    required this.color,
    required this.categoryKey,
  });
}

/// Official catalog of all EGO ERP & E-Commerce applications
class AppsLauncherCatalog {
  static const List<AppLauncherDef> apps = [
    // 0. Dashboard
    AppLauncherDef(
      index: 0,
      titleKey: 'dashboard',
      subtitleKey: 'desc_dashboard',
      permission: AdminPermission.dashboard,
      icon: Icons.speed_rounded,
      color: Color(0xFF6366F1), // Indigo
      categoryKey: 'app_cat_all',
    ),
    // 1. POS Cashier
    AppLauncherDef(
      index: 1,
      titleKey: 'pos_cashier',
      subtitleKey: 'desc_pos',
      permission: AdminPermission.pos,
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFF10B981), // Emerald
      categoryKey: 'app_cat_sales',
    ),
    // 2. Products
    AppLauncherDef(
      index: 2,
      titleKey: 'products',
      subtitleKey: 'desc_products',
      permission: AdminPermission.products,
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFF59E0B), // Amber
      categoryKey: 'app_cat_inventory',
    ),
    // 3. Brands
    AppLauncherDef(
      index: 3,
      titleKey: 'brands',
      subtitleKey: 'desc_brands',
      permission: AdminPermission.brands,
      icon: Icons.branding_watermark_rounded,
      color: Color(0xFFFB923C), // Orange
      categoryKey: 'app_cat_inventory',
    ),
    // 4. Orders
    AppLauncherDef(
      index: 4,
      titleKey: 'orders',
      subtitleKey: 'desc_orders',
      permission: AdminPermission.orders,
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF3B82F6), // Royal Blue
      categoryKey: 'app_cat_sales',
    ),
    // 5. Suppliers
    AppLauncherDef(
      index: 5,
      titleKey: 'suppliers',
      subtitleKey: 'desc_suppliers',
      permission: AdminPermission.suppliers,
      icon: Icons.business_rounded,
      color: Color(0xFF8B5CF6), // Violet
      categoryKey: 'app_cat_inventory',
    ),
    // 6. Expenses
    AppLauncherDef(
      index: 6,
      titleKey: 'expenses',
      subtitleKey: 'desc_expenses',
      permission: AdminPermission.expenses,
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFF43F5E), // Rose
      categoryKey: 'app_cat_finance',
    ),
    // 7. Accounting
    AppLauncherDef(
      index: 7,
      titleKey: 'accounting',
      subtitleKey: 'desc_accounting',
      permission: AdminPermission.accounting,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF14B8A6), // Teal
      categoryKey: 'app_cat_finance',
    ),
    // 8. Reports & Analytics
    AppLauncherDef(
      index: 8,
      titleKey: 'reports',
      subtitleKey: 'desc_reports',
      permission: AdminPermission.reports,
      icon: Icons.bar_chart_rounded,
      color: Color(0xFFA855F7), // Purple
      categoryKey: 'app_cat_finance',
    ),
    // 9. Shifts
    AppLauncherDef(
      index: 9,
      titleKey: 'cashier_shifts',
      subtitleKey: 'desc_shifts',
      permission: AdminPermission.shifts,
      icon: Icons.access_time_filled_rounded,
      color: Color(0xFF06B6D4), // Cyan
      categoryKey: 'app_cat_sales',
    ),
    // 10. Transfers
    AppLauncherDef(
      index: 10,
      titleKey: 'inventory_transfers',
      subtitleKey: 'desc_transfers',
      permission: AdminPermission.transfers,
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF7C3AED), // Deep Purple
      categoryKey: 'app_cat_inventory',
    ),
    // 11. Damaged Stock
    AppLauncherDef(
      index: 11,
      titleKey: 'damaged_stock',
      subtitleKey: 'desc_damaged',
      permission: AdminPermission.damagedStock,
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFFEF4444), // Red
      categoryKey: 'app_cat_inventory',
    ),
    // 12. Employees & HR
    AppLauncherDef(
      index: 12,
      titleKey: 'employees',
      subtitleKey: 'desc_employees',
      permission: AdminPermission.employees,
      icon: Icons.badge_rounded,
      color: Color(0xFF0284C7), // Sky Blue
      categoryKey: 'app_cat_system',
    ),
    // 13. Banners
    AppLauncherDef(
      index: 13,
      titleKey: 'banners',
      subtitleKey: 'desc_banners',
      permission: AdminPermission.banners,
      icon: Icons.view_carousel_rounded,
      color: Color(0xFFEC4899), // Pink
      categoryKey: 'app_cat_crm',
    ),
    // 14. Coupons
    AppLauncherDef(
      index: 14,
      titleKey: 'coupons',
      subtitleKey: 'desc_coupons',
      permission: AdminPermission.coupons,
      icon: Icons.local_offer_rounded,
      color: Color(0xFFD946EF), // Fuchsia
      categoryKey: 'app_cat_crm',
    ),
    // 15. Customers & CRM
    AppLauncherDef(
      index: 15,
      titleKey: 'customers',
      subtitleKey: 'desc_customers',
      permission: AdminPermission.customers,
      icon: Icons.people_rounded,
      color: Color(0xFF059669), // Emerald Dark
      categoryKey: 'app_cat_crm',
    ),
    // 16. Broadcasts
    AppLauncherDef(
      index: 16,
      titleKey: 'notifications',
      subtitleKey: 'desc_notifications',
      permission: AdminPermission.notifications,
      icon: Icons.campaign_rounded,
      color: Color(0xFFD97706), // Amber Dark
      categoryKey: 'app_cat_crm',
    ),
    // 17. Settings
    AppLauncherDef(
      index: 17,
      titleKey: 'settings',
      subtitleKey: 'desc_settings',
      permission: AdminPermission.settings,
      icon: Icons.settings_rounded,
      color: Color(0xFF64748B), // Slate
      categoryKey: 'app_cat_system',
    ),
    // 18. Roles & Permissions
    AppLauncherDef(
      index: 18,
      titleKey: 'roles_permissions',
      subtitleKey: 'desc_roles',
      permission: AdminPermission.roles,
      icon: Icons.shield_rounded,
      color: Color(0xFF7C3AED), // Deep Violet
      categoryKey: 'app_cat_system',
    ),
  ];

  static AppLauncherDef? getByIndex(int index) {
    for (final app in apps) {
      if (app.index == index) return app;
    }
    return null;
  }
}

/// Apps Launcher Modal Dialog
class AppsLauncherDialog extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  final int? currentTabIndex;

  const AppsLauncherDialog({
    super.key,
    required this.onSelectTab,
    this.currentTabIndex,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onSelectTab,
    int? currentTabIndex,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AppsLauncherDialog(
        onSelectTab: onSelectTab,
        currentTabIndex: currentTabIndex,
      ),
    );
  }

  @override
  State<AppsLauncherDialog> createState() => _AppsLauncherDialogState();
}

class _AppsLauncherDialogState extends State<AppsLauncherDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'app_cat_all';
  String _searchQuery = '';

  final List<String> _categories = [
    'app_cat_all',
    'app_cat_sales',
    'app_cat_inventory',
    'app_cat_finance',
    'app_cat_crm',
    'app_cat_system',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        return BlocBuilder<OrderCubit, OrderState>(
          builder: (context, orderState) {
            int pendingOrders = 0;
            if (orderState is OrderLoaded) {
              pendingOrders = orderState.orders
                  .where((o) => o.status.toLowerCase() == 'pending')
                  .length;
            }

            return BlocBuilder<StockTransferCubit, StockTransferState>(
              builder: (context, transferState) {
                final pendingTransfers = transferState.transfers
                    .where((t) =>
                        t.status == StockTransferStatus.pending ||
                        t.status == StockTransferStatus.inTransit)
                    .length;

                // Filter apps by category and search query
                final filteredApps = AppsLauncherCatalog.apps.where((app) {
                  // Category match
                  if (_selectedCategory != 'app_cat_all' &&
                      app.categoryKey != _selectedCategory) {
                    return false;
                  }
                  // Search query match
                  if (_searchQuery.isNotEmpty) {
                    final title = app.titleKey.tr.toLowerCase();
                    final subtitle = app.subtitleKey.tr.toLowerCase();
                    final q = _searchQuery.toLowerCase();
                    if (!title.contains(q) && !subtitle.contains(q)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 12,
                    vertical: isDesktop ? 36 : 16,
                  ),
                  child: Container(
                    width: isDesktop ? 960 : size.width,
                    constraints: BoxConstraints(
                      maxHeight: size.height * 0.90,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkCard : AppColor.lightCard,
                      borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg + 6),
                      border: Border.all(
                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Header with Waffle Icon & Search
                        _buildLauncherHeader(isDark, isDesktop),

                        // 2. Category Filter Pills
                        _buildCategoryPills(isDark),

                        const Divider(height: 1, thickness: 1),

                        // 3. Responsive App Tiles Grid
                        Flexible(
                          child: filteredApps.isEmpty
                              ? _buildEmptyState(isDark)
                              : _buildAppsGrid(
                                  filteredApps,
                                  authState,
                                  pendingOrders,
                                  pendingTransfers,
                                  isDark,
                                  isDesktop,
                                ),
                        ),

                        // 4. Subtle Footer with Shortcuts & Elevation info
                        _buildLauncherFooter(authState, isDark),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLauncherHeader(bool isDark, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          // Apps Waffle Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.apps_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'apps_launcher_title'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'EGO ERP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColor.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'apps_launcher_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          // Quick Search Bar
          if (isDesktop) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'search_apps_hint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 14),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Close Button
          IconButton(
            tooltip: 'close'.tr,
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: _categories.map((catKey) {
          final isSelected = _selectedCategory == catKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = catKey),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary
                      : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColor.primary
                        : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColor.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  catKey.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppsGrid(
    List<AppLauncherDef> apps,
    AuthRoleState authState,
    int pendingOrders,
    int pendingTransfers,
    bool isDark,
    bool isDesktop,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    int crossAxisCount = 4;
    if (screenWidth > 1200) {
      crossAxisCount = 5;
    } else if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.05 : 0.95,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isAllowed = authState.hasPermission(app.permission);
        final isCurrent = widget.currentTabIndex == app.index;

        int? badge;
        if (app.index == 4 && pendingOrders > 0) {
          badge = pendingOrders;
        } else if (app.index == 10 && pendingTransfers > 0) {
          badge = pendingTransfers;
        }

        return _AppLauncherTile(
          app: app,
          isAllowed: isAllowed,
          isCurrent: isCurrent,
          badgeCount: badge,
          isDark: isDark,
          onTap: () {
            if (isAllowed) {
              Navigator.of(context).pop();
              widget.onSelectTab(app.index);
            } else {
              HelperFun.errorSnackbar(
                title: 'access_denied_title'.tr,
                message: 'app_locked_tooltip'.tr,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'no_results'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'try_adjusting_filters'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLauncherFooter(AuthRoleState authState, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard.withValues(alpha: 0.5) : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSizes.cardRadiusLg + 6)),
      ),
      child: Row(
        children: [
          Icon(
            authState.activeRole.icon,
            size: 15,
            color: authState.activeRole.color,
          ),
          const SizedBox(width: 6),
          Text(
            '${'current_active_role'.tr}: ',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
          Text(
            authState.activeRole.labelKey.tr,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: authState.activeRole.color,
            ),
          ),
          const Spacer(),
          Text(
            '${AppsLauncherCatalog.apps.length} ${'apps_launcher_title'.tr}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// An individual App Squircle Tile
class _AppLauncherTile extends StatefulWidget {
  final AppLauncherDef app;
  final bool isAllowed;
  final bool isCurrent;
  final int? badgeCount;
  final bool isDark;
  final VoidCallback onTap;

  const _AppLauncherTile({
    required this.app,
    required this.isAllowed,
    required this.isCurrent,
    this.badgeCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AppLauncherTile> createState() => _AppLauncherTileState();
}

class _AppLauncherTileState extends State<_AppLauncherTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isAllowed ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? app.color.withValues(alpha: isDark ? 0.16 : 0.10)
                : (_isHovered
                    ? (isDark ? AppColor.darkSubCard : Colors.white)
                    : (isDark
                        ? AppColor.darkSubCard.withValues(alpha: 0.5)
                        : AppColor.lightSubCard)),
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
            border: Border.all(
              color: widget.isCurrent
                  ? app.color
                  : (_isHovered
                      ? app.color.withValues(alpha: 0.5)
                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder)),
              width: widget.isCurrent ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: app.color.withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Tile Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Vibrant Icon Container
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            app.color,
                            app.color.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: app.color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        app.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // App Title
                    Text(
                      app.titleKey.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // App Subtitle / Description
                    Text(
                      app.subtitleKey.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Active App Marker
              if (widget.isCurrent)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: app.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // Lock Badge for unpermitted apps
              if (!widget.isAllowed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),

              // Notification Count Badge
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.error,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.error.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
