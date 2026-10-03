import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/inventory_audit/data/models/inventory_audit_model.dart';
import 'package:admin_panel_ego/features/inventory_audit/data/repositories/inventory_audit_repository.dart';
import 'package:admin_panel_ego/features/inventory_audit/presentation/cubit/inventory_audit_cubit.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

class MockInventoryAuditRepository implements InventoryAuditRepository {
  InventoryAuditModel? lastSavedAudit;
  bool reconcileCalled = false;

  @override
  Future<List<InventoryAuditModel>> getAudits({String? branchId}) async =>
      lastSavedAudit != null ? [lastSavedAudit!] : [];

  @override
  Future<String> saveAuditDraft(InventoryAuditModel audit) async {
    lastSavedAudit = audit;
    return 'draft_01';
  }

  @override
  Future<void> reconcileAndCompleteAudit(InventoryAuditModel audit, {required String performedBy}) async {
    lastSavedAudit = audit.copyWith(status: 'completed');
    reconcileCalled = true;
  }

  @override
  Future<void> deleteAudit(String auditId) async {
    lastSavedAudit = null;
  }
}

void main() {
  group('InventoryAuditModel Tests', () {
    test('Calculates system units, counted units, variances, and financial cost impact', () {
      final items = [
        const InventoryAuditItemModel(
          productId: 'p1',
          productTitle: 'Nasty Cush Man',
          systemQuantity: 10,
          physicalQuantity: 8, // Deficit of 2
          unitCost: 150.0,
        ),
        const InventoryAuditItemModel(
          productId: 'p2',
          productTitle: 'Vaporesso XROS Pods 0.8',
          systemQuantity: 5,
          physicalQuantity: 7, // Surplus of 2
          unitCost: 50.0,
        ),
        const InventoryAuditItemModel(
          productId: 'p3',
          productTitle: 'Voopoo Drag 4 Mod',
          systemQuantity: 4,
          physicalQuantity: 4, // Exact match
          unitCost: 800.0,
        ),
      ];

      final audit = InventoryAuditModel(
        id: 'audit_01',
        auditNumber: 'AUD-20261001-001',
        branchId: 'branch_dokki',
        branchName: 'فرع الدقي',
        auditDate: DateTime(2026, 10, 1),
        auditedBy: 'admin',
        items: items,
        createdAt: DateTime(2026, 10, 1),
      );

      expect(audit.totalSystemUnits, 19);
      expect(audit.totalCountedUnits, 19);
      expect(audit.totalVarianceUnits, 0);
      expect(audit.deficitUnitsCount, 2);
      expect(audit.surplusUnitsCount, 2);
      // Deficit: -2 * 150 = -300, Surplus: +2 * 50 = +100 -> Total Variance Cost = -200
      expect(audit.totalVarianceCost, -200.0);
    });

    test('Serialization and deserialization fromJson and toJson preserves all fields', () {
      final item = const InventoryAuditItemModel(
        productId: 'p1',
        productTitle: 'Nasty Juice',
        variationSku: 'NJ-CM-60-3',
        variationAttributes: {'Flavour': 'Mango', 'Size': '60ml'},
        systemQuantity: 20,
        physicalQuantity: 18,
        unitCost: 200.0,
        notes: 'Discrepancy in bottom shelf',
      );

      final json = item.toJson();
      final fromJson = InventoryAuditItemModel.fromJson(json);

      expect(fromJson.productId, 'p1');
      expect(fromJson.variationSku, 'NJ-CM-60-3');
      expect(fromJson.systemQuantity, 20);
      expect(fromJson.physicalQuantity, 18);
      expect(fromJson.variance, -2);
      expect(fromJson.varianceCost, -400.0);
    });
  });

  group('InventoryAuditCubit Tests', () {
    late MockInventoryAuditRepository mockRepo;
    late InventoryAuditCubit cubit;

    final List<ProductModel> mockProducts = [
      const ProductModel(
        id: 'prod_1',
        title: 'Nasty Cush Man',
        description: '',
        brand: ProductBrand(id: 'b1', name: 'Nasty Juice'),
        categoryId: 'liquids',
        price: 350,
        salePrice: 350,
        costPrice: 200,
        stock: 15,
        branchStock: {'branch_main': 10, 'branch_dokki': 5},
        productVariations: [],
      ),
      const ProductModel(
        id: 'prod_2',
        title: 'Vaporesso XROS 3',
        description: '',
        brand: ProductBrand(id: 'b2', name: 'Vaporesso'),
        categoryId: 'devices',
        price: 950,
        salePrice: 950,
        costPrice: 600,
        stock: 8,
        branchStock: {'branch_main': 8, 'branch_dokki': 0},
        productVariations: [],
      ),
    ];

    setUp(() {
      mockRepo = MockInventoryAuditRepository();
      cubit = InventoryAuditCubit(repository: mockRepo);
    });

    test('startNewAudit initializes items with specific branch stock quantities', () {
      cubit.startNewAudit(
        branchId: 'branch_dokki',
        branchName: 'فرع الدقي',
        allProducts: mockProducts,
      );

      final items = cubit.state.currentAuditItems;
      expect(items.length, 2);

      final p1 = items.firstWhere((i) => i.productId == 'prod_1');
      expect(p1.systemQuantity, 5); // Branch dokki has 5
      expect(p1.physicalQuantity, 5); // Defaults to system qty for easy verification

      final p2 = items.firstWhere((i) => i.productId == 'prod_2');
      expect(p2.systemQuantity, 0); // Branch dokki has 0
      expect(p2.physicalQuantity, 0);
    });

    test('updatePhysicalQuantity updates counted stock and recalculates variance', () {
      cubit.startNewAudit(
        branchId: 'branch_dokki',
        branchName: 'فرع الدقي',
        allProducts: mockProducts,
      );

      cubit.updatePhysicalQuantity(0, 8); // Changed from 5 to 8

      final p1 = cubit.state.currentAuditItems[0];
      expect(p1.physicalQuantity, 8);
      expect(p1.variance, 3); // 8 - 5 = +3
      expect(p1.varianceCost, 600.0); // 3 * 200 = 600
    });

    test('handleBarcodeScanned increments physical quantity and returns true if found', () {
      cubit.startNewAudit(
        branchId: 'branch_dokki',
        branchName: 'فرع الدقي',
        allProducts: mockProducts,
      );

      final matched = cubit.handleBarcodeScanned('prod_1');
      expect(matched, isTrue);

      final p1 = cubit.state.currentAuditItems.firstWhere((i) => i.productId == 'prod_1');
      expect(p1.physicalQuantity, 6); // Incremented from 5 to 6

      final unknownMatch = cubit.handleBarcodeScanned('non_existent_sku');
      expect(unknownMatch, isFalse);
    });

    test('reconcileAndComplete completes audit and updates repository', () async {
      cubit.startNewAudit(
        branchId: 'branch_dokki',
        branchName: 'فرع الدقي',
        allProducts: mockProducts,
      );

      final success = await cubit.reconcileAndComplete(auditedBy: 'admin');

      expect(success, isTrue);
      expect(mockRepo.reconcileCalled, isTrue);
      expect(cubit.state.successMessage != null, isTrue);
    });
  });
}
