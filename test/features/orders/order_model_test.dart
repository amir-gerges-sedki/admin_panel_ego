import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderModel and Submodel Comprehensive Parsing Tests', () {
    test('Correctly parses complex order with various field naming conventions', () {
      final sampleOrderJson = {
        'orderId': 'ORD_991823',
        'userId': 'usr_4412',
        'customerEmail': 'vaper@example.com',
        'orderStatus': 'processing',
        'createdAt': '2026-08-26T07:00:00Z',
        'payment_method': 'Cash on Delivery',
        'paymentStatus': 'pending',
        'subTotal': 1450.0,
        'deliveryFee': 50.0,
        'discountAmount': 100.0,
        'couponCode': 'SAVE100',
        'totalAmount': 1400.0,
        'orderNotes': 'Please call before delivery',
        'shippingAddress': {
          'customerName': 'Ahmed Hassan',
          'phoneNumber': '01012345678',
          'alternatePhone': '01198765432',
          'governorate': 'Giza',
          'city': 'Dokki',
          'street': '14 Mosaddak St',
          'building': '12B',
          'floor': '3rd',
          'apartment': '6',
          'landmark': 'Next to Vodafone store',
        },
        'orderItems': [
          {
            'productId': 'prod_771',
            'productName': 'Nasty Juice Cush Man Mango',
            'price': 450.0,
            'originalPrice': 500.0,
            'quantity': 2,
            'image': 'https://example.com/cushman.png',
            'brand': 'Nasty Juice',
            'sku': 'NJ-MAN-50',
            'selectedVariation': {
              'Flavor': 'Mango',
              'Nicotine': '50mg',
              'Size': '30ml',
            },
          },
          {
            'id': 'prod_882',
            'title': 'Geekvape Aegis Legend 3 Kit',
            'price': 1000.0,
            'qty': 1,
            'image': 'https://example.com/aegis.png',
            'color': 'Titanium Gray',
            'type': 'DL Sub-Ohm',
            'resistance': '0.15 ohm',
          },
        ],
      };

      final order = OrderModel.fromJson(sampleOrderJson);

      // Verify root order fields
      expect(order.id, equals('ORD_991823'));
      expect(order.userId, equals('usr_4412'));
      expect(order.customerEmail, equals('vaper@example.com'));
      expect(order.status, equals('processing'));
      expect(order.paymentMethod, equals('Cash on Delivery'));
      expect(order.subTotal, equals(1450.0));
      expect(order.shippingCost, equals(50.0));
      expect(order.discount, equals(100.0));
      expect(order.couponCode, equals('SAVE100'));
      expect(order.totalAmount, equals(1400.0));
      expect(order.orderNotes, equals('Please call before delivery'));

      // Verify shipping address
      expect(order.shippingAddress.name, equals('Ahmed Hassan'));
      expect(order.shippingAddress.phoneNumber, equals('01012345678'));
      expect(order.shippingAddress.alternatePhone, equals('01198765432'));
      expect(order.shippingAddress.governorate, equals('Giza'));
      expect(order.shippingAddress.city, equals('Dokki'));
      expect(order.shippingAddress.building, equals('12B'));
      expect(order.shippingAddress.floor, equals('3rd'));
      expect(order.shippingAddress.apartment, equals('6'));
      expect(order.shippingAddress.landmark, equals('Next to Vodafone store'));
      expect(order.shippingAddress.formattedFullAddress, contains('Giza - Dokki - 14 Mosaddak St'));

      // Verify items
      expect(order.items.length, equals(2));

      // Item 1
      final item1 = order.items[0];
      expect(item1.productId, equals('prod_771'));
      expect(item1.title, equals('Nasty Juice Cush Man Mango'));
      expect(item1.price, equals(450.0));
      expect(item1.originalPrice, equals(500.0));
      expect(item1.quantity, equals(2));
      expect(item1.totalItemPrice, equals(900.0));
      expect(item1.brand, equals('Nasty Juice'));
      expect(item1.sku, equals('NJ-MAN-50'));
      expect(item1.selectedVariation['Flavor'], equals('Mango'));
      expect(item1.selectedVariation['Nicotine'], equals('50mg'));

      // Item 2 (auto-detected standalone variation keys: color, style, resistance)
      final item2 = order.items[1];
      expect(item2.productId, equals('prod_882'));
      expect(item2.title, equals('Geekvape Aegis Legend 3 Kit'));
      expect(item2.price, equals(1000.0));
      expect(item2.quantity, equals(1));
      expect(item2.totalItemPrice, equals(1000.0));
      expect(item2.selectedVariation['Style'], equals('DL Sub-Ohm'));
      expect(item2.selectedVariation['Color'], equals('Titanium Gray'));
      expect(item2.selectedVariation['Resistance'], equals('0.15 ohm'));
    });

    test('Correctly calculates fallback totals when root total is zero but items have prices', () {
      final jsonWithZeroTotal = {
        'orderId': 'ORD_FALLBACK_1',
        'items': [
          {'title': 'Item A', 'price': 300.0, 'quantity': 2},
          {'title': 'Item B', 'price': 200.0, 'quantity': 1},
        ],
        'shippingCost': 50.0,
        'discount': 50.0,
      };

      final order = OrderModel.fromJson(jsonWithZeroTotal);
      expect(order.items.length, equals(2));
      expect(order.subTotal, equals(800.0));
      expect(order.totalAmount, equals(800.0)); // (300*2 + 200*1) + 50 - 50 = 800
    });

    test('Detects delivery fee from various field names and nested objects', () {
      final jsonWithDeliveryPrice = {
        'orderId': 'ORD_FEE_1',
        'items': [{'title': 'Item', 'price': 100.0, 'quantity': 1}],
        'delivery_fee': 45.0,
        'totalAmount': 145.0,
      };

      final order = OrderModel.fromJson(jsonWithDeliveryPrice);
      expect(order.shippingCost, equals(45.0));

      final jsonWithNestedShipping = {
        'orderId': 'ORD_FEE_2',
        'items': [{'title': 'Item', 'price': 100.0, 'quantity': 1}],
        'shipping': {'cost': 60.0},
        'totalAmount': 160.0,
      };

      final order2 = OrderModel.fromJson(jsonWithNestedShipping);
      expect(order2.shippingCost, equals(60.0));
    });

    test('Auto-infers delivery fee when total exceeds subtotal without explicit shipping field', () {
      final jsonWithImplicitShipping = {
        'orderId': 'ORD_INFERRED_1',
        'items': [{'title': 'Item A', 'price': 200.0, 'quantity': 1}],
        'subTotal': 200.0,
        'totalAmount': 250.0, // 250 - 200 = 50 delivery fee
      };

      final order = OrderModel.fromJson(jsonWithImplicitShipping);
      expect(order.subTotal, equals(200.0));
      expect(order.shippingCost, equals(50.0));
      expect(order.totalAmount, equals(250.0));
    });
  });
}

