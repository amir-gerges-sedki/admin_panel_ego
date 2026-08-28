import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:admin_panel_ego/features/orders/utils/order_share_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderShareHelper Unit Tests', () {
    const sampleAddress = ShippingAddressModel(
      name: 'Ahmed Hassan',
      phoneNumber: '01012345678',
      street: '14 Mosaddak St',
      city: 'Dokki',
      governorate: 'Giza',
      building: '12B',
      floor: '3rd',
      apartment: '6',
      landmark: 'Next to Vodafone store',
    );

    final sampleOrder = OrderModel(
      id: 'ORD_12345',
      userId: 'usr_1',
      status: 'pending',
      orderDate: DateTime(2026, 8, 27, 10, 30),
      items: const [
        OrderItemModel(
          productId: 'p1',
          title: 'Cush Man Mango',
          brand: 'Nasty Juice',
          price: 450.0,
          quantity: 2,
          selectedVariation: {'Flavor': 'Mango', 'Nicotine': '50mg'},
        ),
      ],
      paymentMethod: 'Cash on Delivery',
      shippingAddress: sampleAddress,
      subTotal: 900.0,
      shippingCost: 50.0,
      totalAmount: 950.0,
    );

    test('generateCourierSlipText formats all required sections and includes brand name', () {
      final text = OrderShareHelper.generateCourierSlipText(sampleOrder);

      expect(text.contains('#ORD_12345'), isTrue);
      expect(text.contains('Ahmed Hassan'), isTrue);
      expect(text.contains('01012345678'), isTrue);
      expect(text.contains('14 Mosaddak St'), isTrue);
      expect(text.contains('Nasty Juice - Cush Man Mango'), isTrue);
      expect(text.contains('950'), isTrue);
      expect(text.contains('maps/search'), isTrue);
    });

    test('OrderItemModel formattedTitleWithBrand returns title when brand is already in title', () {
      const item = OrderItemModel(
        productId: 'p1',
        title: 'Geekvape Aegis Legend 3',
        brand: 'Geekvape',
        price: 1000.0,
        quantity: 1,
      );

      expect(item.formattedTitleWithBrand, equals('Geekvape Aegis Legend 3'));
    });

    test('OrderItemModel formattedTitleWithBrand prepends brand when not in title', () {
      const item = OrderItemModel(
        productId: 'p1',
        title: 'Aegis Legend 3',
        brand: 'Geekvape',
        price: 1000.0,
        quantity: 1,
      );

      expect(item.formattedTitleWithBrand, equals('Geekvape - Aegis Legend 3'));
    });

    test('buildGoogleMapsUrl produces a valid URL', () {
      final url = OrderShareHelper.buildGoogleMapsUrl(sampleAddress);
      final uri = Uri.parse(url);

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('www.google.com'));
      expect(uri.queryParameters.containsKey('query'), isTrue);
    });
  });
}
