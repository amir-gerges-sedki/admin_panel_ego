import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_cart_item_model.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_sale_model.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/pos_cubit.dart';
import 'package:admin_panel_ego/features/pos/utils/pos_receipt_printer.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

import 'staff_sales_attribution_test.dart';

void main() {
  group('POS Serial Number & Warranty Registration Tests', () {
    test(
      'PosCartItemModel correctly stores, copies, and serializes serialNumbers',
      () {
        const item = PosCartItemModel(
          productId: 'prod-mod-01',
          title: 'Vaporesso Target 200 Mod',
          unitPrice: 2200.0,
          costPrice: 1600.0,
          quantity: 2,
          serialNumbers: ['VP-TG-98214', 'VP-TG-98215'],
        );

        expect(item.serialNumbers.length, equals(2));
        expect(item.serialNumbers[0], equals('VP-TG-98214'));
        expect(item.serialNumbers[1], equals('VP-TG-98215'));

        // Test copyWith
        final updated = item.copyWith(serialNumbers: ['VP-TG-98214-NEW']);
        expect(updated.serialNumbers, equals(['VP-TG-98214-NEW']));

        // Test toJson and fromJson
        final json = item.toJson();
        expect(json['serialNumbers'], equals(['VP-TG-98214', 'VP-TG-98215']));
        expect(json['costPrice'], equals(1600.0));

        final restored = PosCartItemModel.fromJson(json);
        expect(restored.serialNumbers, equals(['VP-TG-98214', 'VP-TG-98215']));
        expect(restored.costPrice, equals(1600.0));
        expect(restored, equals(item));
      },
    );

    test(
      'PosCubit updateItemSerialNumbers updates the target item in state',
      () {
        final mockPosRepo = MockPosRepository();
        final mockEmpRepo = MockEmployeesRepository();
        final mockCustRepo = MockCustomerRepository();
        final cubit = PosCubit(
          repository: mockPosRepo,
          customerRepository: mockCustRepo,
          employeesRepository: mockEmpRepo,
        );

        const dummyProduct = ProductModel(
          id: 'prod-kit-01',
          title: 'Geekvape Aegis Legend 3 Kit',
          description: 'Vape Kit',
          price: 2800.0,
          salePrice: 2800.0,
          costPrice: 2100.0,
          stock: 10,
          brand: ProductBrand(id: 'b1', name: 'Geekvape'),
          categoryId: 'kits',
        );

        cubit.addToCart(dummyProduct);
        expect(cubit.state.cartItems.length, equals(1));
        expect(cubit.state.cartItems.first.serialNumbers, isEmpty);

        cubit.updateItemSerialNumbers(0, ['GK-LEG-77182']);
        expect(
          cubit.state.cartItems.first.serialNumbers,
          equals(['GK-LEG-77182']),
        );
      },
    );

    test(
      'PosReceiptPrinter prints serial numbers on customer thermal receipt',
      () {
        const item = PosCartItemModel(
          productId: 'prod-mod-01',
          title: 'Vaporesso Gen 200',
          brand: 'Vaporesso',
          unitPrice: 2000.0,
          costPrice: 1500.0,
          quantity: 1,
          serialNumbers: ['SN-VAPO-998822'],
        );

        final sale = PosSaleModel(
          id: 'sale-warranty-test',
          orderNumber: 'POS-WARRANTY-101',
          createdAt: DateTime(2026, 11, 23, 14, 0),
          items: const [item],
          subTotal: 2000.0,
          totalAmount: 2000.0,
        );

        final html = PosReceiptPrinter.generateThermalReceiptHtml(sale);
        expect(html, contains('سيريال / ضمان'));
        expect(html, contains('SN-VAPO-998822'));
      },
    );
  });
}
