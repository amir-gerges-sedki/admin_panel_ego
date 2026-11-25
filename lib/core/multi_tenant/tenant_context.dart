import 'package:flutter/foundation.dart';

/// Ambient Tenant Context provider ensuring every operation in the application
/// carries explicit Tenant, Store, and Branch scoping.
class TenantContext {
  final String tenantId;
  final String activeStoreId;
  final String activeBranchId;
  final List<String> accessibleStoreIds;
  final List<String> accessibleBranchIds;

  const TenantContext({
    required this.tenantId,
    required this.activeStoreId,
    required this.activeBranchId,
    this.accessibleStoreIds = const [],
    this.accessibleBranchIds = const [],
  });

  /// Default baseline context for backward compatibility
  static const TenantContext defaultContext = TenantContext(
    tenantId: 'ego_master',
    activeStoreId: 'store_main',
    activeBranchId: 'main_branch',
    accessibleStoreIds: ['store_main'],
    accessibleBranchIds: ['main_branch'],
  );

  bool canAccessStore(String storeId) {
    if (accessibleStoreIds.isEmpty) return true;
    return accessibleStoreIds.contains(storeId);
  }

  bool canAccessBranch(String branchId) {
    if (accessibleBranchIds.isEmpty) return true;
    return accessibleBranchIds.contains(branchId);
  }

  TenantContext copyWith({
    String? tenantId,
    String? activeStoreId,
    String? activeBranchId,
    List<String>? accessibleStoreIds,
    List<String>? accessibleBranchIds,
  }) {
    return TenantContext(
      tenantId: tenantId ?? this.tenantId,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      accessibleStoreIds: accessibleStoreIds ?? this.accessibleStoreIds,
      accessibleBranchIds: accessibleBranchIds ?? this.accessibleBranchIds,
    );
  }

  // ─── Global Ambient Singleton / Holder ───
  static TenantContext _current = defaultContext;

  static TenantContext get current => _current;

  static void setCurrent(TenantContext context) {
    _current = context;
    debugPrint('🏢 [TenantContext] Switched to tenant=${context.tenantId}, store=${context.activeStoreId}, branch=${context.activeBranchId}');
  }

  static void resetToDefault() {
    _current = defaultContext;
  }
}
