import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/services/inventory_stock_manager.dart';

void main() {
  group('InventoryStockManager Data Structures & Exception Tests', () {
    test('StockAdjustmentItem creates correctly with all parameters', () {
      const item = StockAdjustmentItem(
        productId: 'prod_101',
        quantity: 3,
        variationId: 'var_blue_m',
        sku: 'SKU-BLUE-M',
        selectedAttributes: {'Color': 'Blue', 'Size': 'M'},
        title: 'T-Shirt',
      );

      expect(item.productId, equals('prod_101'));
      expect(item.quantity, equals(3));
      expect(item.variationId, equals('var_blue_m'));
      expect(item.sku, equals('SKU-BLUE-M'));
      expect(item.selectedAttributes?['Color'], equals('Blue'));
      expect(item.title, equals('T-Shirt'));
    });

    test('StockAdjustmentItem creates correctly with minimal parameters', () {
      const item = StockAdjustmentItem(
        productId: 'prod_202',
        quantity: 1,
      );

      expect(item.productId, equals('prod_202'));
      expect(item.quantity, equals(1));
      expect(item.variationId, isNull);
      expect(item.sku, isNull);
      expect(item.selectedAttributes, isNull);
      expect(item.title, isNull);
    });

    test('InsufficientStockException produces detailed informative message', () {
      final exception = InsufficientStockException(
        productId: 'prod_303',
        title: 'Sneakers Nike Air (42)',
        requestedQuantity: 5,
        availableStock: 2,
      );

      expect(exception.productId, equals('prod_303'));
      expect(exception.title, equals('Sneakers Nike Air (42)'));
      expect(exception.requestedQuantity, equals(5));
      expect(exception.availableStock, equals(2));

      final message = exception.toString();
      expect(message, contains('Sneakers Nike Air (42)'));
      expect(message, contains('2'));
      expect(message, contains('5'));
      expect(message, contains('غير متوفرة في المخزون'));
    });

    test('InsufficientStockException can be caught as Exception', () {
      expect(
        () => throw InsufficientStockException(
          productId: 'p1',
          title: 'Item',
          requestedQuantity: 10,
          availableStock: 0,
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('Stock calculation preserves non-negative clamps on high deductions', () {
      int calculateNewStock(int current, int deduct) {
        return (current - deduct).clamp(0, 999999).toInt();
      }

      expect(calculateNewStock(5, 3), equals(2));
      expect(calculateNewStock(5, 5), equals(0));
      expect(calculateNewStock(5, 10), equals(0));
    });

    test('Branch transfer stock preserves total company inventory', () {
      const fromBranch = 'branch_a';
      const toBranch = 'branch_b';
      final Map<String, int> branchStock = {
        fromBranch: 10,
        toBranch: 2,
      };
      const transferQty = 4;

      // Transfer logic simulation
      final fromQty = branchStock[fromBranch]!;
      final toQty = branchStock[toBranch]!;

      branchStock[fromBranch] = (fromQty - transferQty).clamp(0, 999999).toInt();
      branchStock[toBranch] = (toQty + transferQty).clamp(0, 999999).toInt();

      expect(branchStock[fromBranch], equals(6));
      expect(branchStock[toBranch], equals(6));
      // Total company inventory remains exactly 12
      final total = branchStock.values.fold<int>(0, (a, b) => a + b);
      expect(total, equals(12));
    });
  });
}
