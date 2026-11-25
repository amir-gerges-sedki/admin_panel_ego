import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/multi_tenant/tenant_model.dart';
import 'package:admin_panel_ego/core/multi_tenant/store_model.dart';
import 'package:admin_panel_ego/core/multi_tenant/tenant_context.dart';

void main() {
  group('Multi-Tenant Framework Tests (Admin Panel)', () {
    setUp(() {
      TenantContext.resetToDefault();
    });

    tearDown(() {
      TenantContext.resetToDefault();
    });

    group('TenantModel Tests', () {
      test('defaultTenant provides correct baseline configuration', () {
        final tenant = TenantModel.defaultTenant;
        expect(tenant.tenantId, 'ego_master');
        expect(tenant.companyName, 'EGO Vape Store Group');
        expect(tenant.subscriptionPlan, 'enterprise');
        expect(tenant.subscriptionStatus, 'active');
        expect(tenant.isActive, isTrue);
        expect(tenant.maxStores, 999);
      });

      test('TenantModel toJson and fromJson roundtrip correctly', () {
        final now = DateTime(2026, 1, 15, 10, 30);
        final tenant = TenantModel(
          tenantId: 'tenant_123',
          companyName: 'Cloud Retail Ltd',
          taxNumber: 'TAX-998877',
          commercialRegister: 'CR-12345',
          ownerEmail: 'owner@cloudretail.com',
          ownerPhone: '+201012345678',
          subscriptionPlan: 'pro',
          subscriptionStatus: 'active',
          subscriptionExpiresAt: now.add(const Duration(days: 365)),
          maxStores: 3,
          maxBranches: 10,
          maxEmployees: 25,
          featureFlags: const {'loyalty_enabled': true, 'multi_currency': false},
          createdAt: now,
          isActive: true,
        );

        final json = tenant.toJson();
        final deserialized = TenantModel.fromJson(json);

        expect(deserialized.tenantId, tenant.tenantId);
        expect(deserialized.companyName, tenant.companyName);
        expect(deserialized.taxNumber, tenant.taxNumber);
        expect(deserialized.subscriptionPlan, tenant.subscriptionPlan);
        expect(deserialized.maxBranches, 10);
        expect(deserialized.featureFlags['loyalty_enabled'], isTrue);
      });

      test('TenantModel copyWith updates fields cleanly', () {
        final tenant = TenantModel.defaultTenant;
        final updated = tenant.copyWith(
          subscriptionPlan: 'pro',
          maxBranches: 5,
        );

        expect(updated.tenantId, tenant.tenantId);
        expect(updated.subscriptionPlan, 'pro');
        expect(updated.maxBranches, 5);
        expect(updated.companyName, tenant.companyName);
      });
    });

    group('StoreModel Tests', () {
      test('defaultStore provides expected baseline', () {
        final store = StoreModel.defaultStore;
        expect(store.storeId, 'store_main');
        expect(store.tenantId, 'ego_master');
        expect(store.name, 'EGO Main Store');
        expect(store.currency, 'EGP');
        expect(store.isOnlineStoreEnabled, isTrue);
        expect(store.isPosEnabled, isTrue);
      });

      test('StoreModel serialization and deserialization works seamlessly', () {
        final now = DateTime(2026, 2, 1);
        final store = StoreModel(
          storeId: 'store_cairo_hub',
          tenantId: 'tenant_egypt',
          name: 'Cairo Flagship Store',
          slug: 'cairo-flagship',
          currency: 'EGP',
          primaryColor: '#FF5500',
          isOnlineStoreEnabled: true,
          isPosEnabled: true,
          isActive: true,
          createdAt: now,
        );

        final json = store.toJson();
        final parsed = StoreModel.fromJson(json);

        expect(parsed.storeId, 'store_cairo_hub');
        expect(parsed.tenantId, 'tenant_egypt');
        expect(parsed.name, 'Cairo Flagship Store');
        expect(parsed.primaryColor, '#FF5500');
        expect(parsed.isActive, isTrue);
      });
    });

    group('TenantContext Ambient Scoping Tests', () {
      test('initializes with default context', () {
        expect(TenantContext.current.tenantId, 'ego_master');
        expect(TenantContext.current.activeStoreId, 'store_main');
        expect(TenantContext.current.activeBranchId, 'main_branch');
      });

      test('setCurrent switches ambient context and verifies permissions', () {
        const newContext = TenantContext(
          tenantId: 'tenant_alpha',
          activeStoreId: 'store_alex',
          activeBranchId: 'branch_san_stefano',
          accessibleStoreIds: ['store_alex', 'store_cairo'],
          accessibleBranchIds: ['branch_san_stefano'],
        );

        TenantContext.setCurrent(newContext);

        expect(TenantContext.current.tenantId, 'tenant_alpha');
        expect(TenantContext.current.activeStoreId, 'store_alex');
        expect(TenantContext.current.canAccessStore('store_alex'), isTrue);
        expect(TenantContext.current.canAccessStore('store_cairo'), isTrue);
        expect(TenantContext.current.canAccessStore('store_unauthorized'), isFalse);

        expect(TenantContext.current.canAccessBranch('branch_san_stefano'), isTrue);
        expect(TenantContext.current.canAccessBranch('branch_other'), isFalse);
      });

      test('resetToDefault resets context safely back to master tenant', () {
        const customContext = TenantContext(
          tenantId: 'custom_tenant',
          activeStoreId: 'custom_store',
          activeBranchId: 'custom_branch',
        );
        TenantContext.setCurrent(customContext);
        expect(TenantContext.current.tenantId, 'custom_tenant');

        TenantContext.resetToDefault();
        expect(TenantContext.current.tenantId, 'ego_master');
      });
    });
  });
}
