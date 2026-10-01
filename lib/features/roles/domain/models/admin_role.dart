import 'package:flutter/material.dart';

/// Available administrative and staff roles
enum AdminRole {
  superAdmin('super_admin', 'super_admin', 'super_admin_desc'),
  admin('admin', 'admin_role', 'admin_role_desc'),
  staff('staff', 'staff_role', 'staff_role_desc');

  final String id;
  final String labelKey;
  final String descriptionKey;

  const AdminRole(this.id, this.labelKey, this.descriptionKey);

  static AdminRole fromString(String? val) {
    if (val == null) return AdminRole.staff;
    final clean = val.trim().toLowerCase();
    if (clean == 'super_admin' || clean == 'superadmin' || clean == 'owner') {
      return AdminRole.superAdmin;
    }
    if (clean == 'admin' || clean == 'manager') {
      return AdminRole.admin;
    }
    return AdminRole.staff;
  }

  Color get color {
    switch (this) {
      case AdminRole.superAdmin:
        return const Color(0xFF8B5CF6); // Purple / Violet
      case AdminRole.admin:
        return const Color(0xFF3B82F6); // Blue / Primary
      case AdminRole.staff:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  IconData get icon {
    switch (this) {
      case AdminRole.superAdmin:
        return Icons.verified_user_rounded;
      case AdminRole.admin:
        return Icons.admin_panel_settings_rounded;
      case AdminRole.staff:
        return Icons.storefront_rounded;
    }
  }
}

/// Granular system permissions across administrative modules
enum AdminPermission {
  dashboard('dashboard', 'permission_dashboard', Icons.grid_view_rounded),
  pos('pos', 'permission_pos', Icons.point_of_sale_rounded),
  products('products', 'permission_products', Icons.inventory_2_rounded),
  brands('brands', 'permission_brands', Icons.branding_watermark_rounded),
  orders('orders', 'permission_orders', Icons.local_shipping_rounded),
  banners('banners', 'permission_banners', Icons.view_carousel_rounded),
  coupons('coupons', 'permission_coupons', Icons.local_offer_rounded),
  customers('customers', 'permission_customers', Icons.people_rounded),
  notifications('notifications', 'permission_notifications', Icons.campaign_rounded),
  suppliers('suppliers', 'permission_suppliers', Icons.business_rounded),
  expenses('expenses', 'permission_expenses', Icons.receipt_long_rounded),
  accounting('accounting', 'permission_accounting', Icons.account_balance_wallet_rounded),
  reports('reports', 'permission_reports', Icons.bar_chart_rounded),
  shifts('shifts', 'permission_shifts', Icons.access_time_filled_rounded),
  transfers('transfers', 'permission_transfers', Icons.swap_horiz_rounded),
  stockAudit('stock_audit', 'permission_stock_audit', Icons.fact_check_rounded),
  damagedStock('damaged_stock', 'permission_damaged_stock', Icons.delete_sweep_rounded),
  employees('employees', 'permission_employees', Icons.badge_rounded),
  settings('settings', 'permission_settings', Icons.settings_rounded),
  roles('roles', 'permission_roles', Icons.shield_rounded),
  viewCostPrice('view_cost_price', 'permission_view_cost_price', Icons.attach_money_rounded);

  final String id;
  final String labelKey;
  final IconData icon;

  const AdminPermission(this.id, this.labelKey, this.icon);

  static AdminPermission? fromString(String id) {
    for (final perm in AdminPermission.values) {
      if (perm.id == id.trim().toLowerCase()) return perm;
    }
    return null;
  }
}

/// Stored configuration mapping each role to its granted permissions
class RolePermissionsModel {
  final Map<AdminRole, Set<AdminPermission>> permissions;

  const RolePermissionsModel({required this.permissions});

  /// Default predefined permission configuration:
  /// - superAdmin: All modules
  /// - admin: POS, Products, Brands, Orders, Suppliers, Expenses, Accounting, Reports, Shifts, Transfers, StockAudit, DamagedStock, Employees, Banners, Coupons, Customers, Notifications, ViewCostPrice
  /// - staff / guest: POS, Shifts & Orders
  factory RolePermissionsModel.defaultPermissions() {
    return RolePermissionsModel(
      permissions: {
        AdminRole.superAdmin: Set<AdminPermission>.from(AdminPermission.values),
        AdminRole.admin: {
          AdminPermission.pos,
          AdminPermission.products,
          AdminPermission.brands,
          AdminPermission.orders,
          AdminPermission.suppliers,
          AdminPermission.expenses,
          AdminPermission.accounting,
          AdminPermission.reports,
          AdminPermission.shifts,
          AdminPermission.transfers,
          AdminPermission.stockAudit,
          AdminPermission.damagedStock,
          AdminPermission.employees,
          AdminPermission.banners,
          AdminPermission.coupons,
          AdminPermission.customers,
          AdminPermission.notifications,
          AdminPermission.viewCostPrice,
        },
        AdminRole.staff: {
          AdminPermission.pos,
          AdminPermission.shifts,
          AdminPermission.transfers,
          AdminPermission.orders,
        },
      },
    );
  }

  bool hasPermission(AdminRole role, AdminPermission permission) {
    if (role == AdminRole.superAdmin) return true;
    final rolePerms = permissions[role];
    return rolePerms != null && rolePerms.contains(permission);
  }

  RolePermissionsModel copyWithUpdatedRole(
    AdminRole role,
    Set<AdminPermission> newPerms,
  ) {
    final updated = Map<AdminRole, Set<AdminPermission>>.from(permissions);
    updated[role] = Set<AdminPermission>.from(newPerms);
    return RolePermissionsModel(permissions: updated);
  }

  Map<String, dynamic> toJson() {
    return {
      'super_admin': permissions[AdminRole.superAdmin]
          ?.map((p) => p.id)
          .toList() ??
          AdminPermission.values.map((p) => p.id).toList(),
      'admin': permissions[AdminRole.admin]
          ?.map((p) => p.id)
          .toList() ??
          [],
      'staff': permissions[AdminRole.staff]
          ?.map((p) => p.id)
          .toList() ??
          ['orders'],
    };
  }

  factory RolePermissionsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return RolePermissionsModel.defaultPermissions();
    }

    final Map<AdminRole, Set<AdminPermission>> map = {};

    // Super Admin always has full access
    map[AdminRole.superAdmin] = Set<AdminPermission>.from(AdminPermission.values);

    // Admin permissions
    final rawAdmin = json['admin'];
    if (rawAdmin is List) {
      map[AdminRole.admin] = rawAdmin
          .map((id) => AdminPermission.fromString(id.toString()))
          .whereType<AdminPermission>()
          .toSet();
    } else {
      map[AdminRole.admin] = RolePermissionsModel.defaultPermissions().permissions[AdminRole.admin]!;
    }

    // Staff / Guest permissions
    final rawStaff = json['staff'] ?? json['guest'];
    if (rawStaff is List) {
      map[AdminRole.staff] = rawStaff
          .map((id) => AdminPermission.fromString(id.toString()))
          .whereType<AdminPermission>()
          .toSet();
    } else {
      map[AdminRole.staff] = {AdminPermission.orders};
    }

    return RolePermissionsModel(permissions: map);
  }
}

/// Security PIN / Passcode Configuration for Role Elevation
class SecurityPasscodesModel {
  final String superAdminPasscode;
  final String adminPasscode;
  final bool defaultToStaff;

  const SecurityPasscodesModel({
    required this.superAdminPasscode,
    required this.adminPasscode,
    this.defaultToStaff = true,
  });

  factory SecurityPasscodesModel.defaults() {
    return const SecurityPasscodesModel(
      superAdminPasscode: '999999',
      adminPasscode: '123456',
      defaultToStaff: true,
    );
  }

  bool verifyPasscode(AdminRole targetRole, String input) {
    final clean = input.trim();
    if (targetRole == AdminRole.superAdmin) {
      return clean == superAdminPasscode.trim();
    }
    if (targetRole == AdminRole.admin) {
      return clean == adminPasscode.trim() || clean == superAdminPasscode.trim();
    }
    if (targetRole == AdminRole.staff) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'superAdminPasscode': superAdminPasscode,
        'adminPasscode': adminPasscode,
        'defaultToStaff': defaultToStaff,
      };

  factory SecurityPasscodesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return SecurityPasscodesModel.defaults();
    }
    return SecurityPasscodesModel(
      superAdminPasscode: (json['superAdminPasscode'] ?? json['super_admin_passcode'] ?? '999999').toString(),
      adminPasscode: (json['adminPasscode'] ?? json['admin_passcode'] ?? '123456').toString(),
      defaultToStaff: json['defaultToStaff'] as bool? ?? true,
    );
  }

  SecurityPasscodesModel copyWith({
    String? superAdminPasscode,
    String? adminPasscode,
    bool? defaultToStaff,
  }) {
    return SecurityPasscodesModel(
      superAdminPasscode: superAdminPasscode ?? this.superAdminPasscode,
      adminPasscode: adminPasscode ?? this.adminPasscode,
      defaultToStaff: defaultToStaff ?? this.defaultToStaff,
    );
  }
}
