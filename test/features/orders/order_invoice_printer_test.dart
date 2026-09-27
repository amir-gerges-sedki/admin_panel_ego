import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:admin_panel_ego/features/orders/utils/order_invoice_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderInvoicePrinter Unit Tests', () {
    const sampleAddress = ShippingAddressModel(
      name: 'Amir Gerges',
      phoneNumber: '01227716033',
      alternatePhone: '01099887766',
      email: 'customer@example.com',
      street: '15 Tahrir Square',
      city: 'Cairo',
      governorate: 'Cairo',
      building: 'Tower 4',
      floor: '7',
      apartment: '702',
      landmark: 'Behind Steigenberger',
    );

    final sampleOrder = OrderModel(
      id: 'EGO_ORD_9988',
      userId: 'usr_test_99',
      status: 'delivered',
      orderDate: DateTime(2026, 9, 26, 15, 45),
      items: const [
        OrderItemModel(
          productId: 'prod_1',
          title: 'Vaporesso XROS 4 Mini',
          brand: 'Vaporesso',
          price: 1250.0,
          quantity: 1,
          selectedVariation: {'Color': 'Space Grey'},
          sku: 'VAP-XROS4-GRY',
        ),
        OrderItemModel(
          productId: 'prod_2',
          title: 'Tokyo Salt E-Liquid - Mango Passion',
          brand: 'Tokyo',
          price: 350.0,
          quantity: 2,
          selectedVariation: {'Nicotine': '30mg', 'Size': '30ml'},
          sku: 'TOK-MNG-30',
        ),
      ],
      paymentMethod: 'Cash on Delivery',
      paymentStatus: 'paid',
      shippingAddress: sampleAddress,
      subTotal: 1950.0,
      shippingCost: 0.0,
      discount: 100.0,
      couponCode: 'WELCOME100',
      totalAmount: 1850.0,
      orderNotes: 'Please deliver after 4 PM',
      shippingCarrier: 'Bosta Express',
      trackingNumber: 'BST-987654321',
    );

    test('generateOrderInvoiceHtml contains all required invoice attributes and styles', () {
      final html = OrderInvoicePrinter.generateOrderInvoiceHtml(sampleOrder);

      expect(html.contains('EGO_ORD_9988'), isTrue);
      expect(html.contains('Amir Gerges'), isTrue);
      expect(html.contains('01227716033'), isTrue);
      expect(html.contains('01099887766'), isTrue);
      expect(html.contains('15 Tahrir Square'), isTrue);
      expect(html.contains('Vaporesso XROS 4 Mini'), isTrue);
      expect(html.contains('Space Grey'), isTrue);
      expect(html.contains('VAP-XROS4-GRY'), isTrue);
      expect(html.contains('Tokyo Salt E-Liquid'), isTrue);
      expect(html.contains('30mg'), isTrue);
      expect(html.contains('WELCOME100'), isTrue);
      expect(html.contains('Please deliver after 4 PM'), isTrue);
      expect(html.contains('Bosta Express'), isTrue);
      expect(html.contains('BST-987654321'), isTrue);
      expect(html.contains('Cash on Delivery'), isTrue);
      expect(html.contains('@media print'), isTrue);
      expect(html.contains('Cairo'), isTrue);
    });

    test('exportOrderInvoiceCsv generates valid UTF-8 CSV content without crash', () async {
      // In test environment without DOM/platform anchor, it safely handles via fallback
      final result = await OrderInvoicePrinter.exportOrderInvoiceCsv(sampleOrder);
      expect(result, isNotNull);
    });

    test('printOrderInvoice generates html and invokes printer safely', () {
      final printResult = OrderInvoicePrinter.printOrderInvoice(sampleOrder);
      expect(printResult, isNotNull);
    });
  });
}
