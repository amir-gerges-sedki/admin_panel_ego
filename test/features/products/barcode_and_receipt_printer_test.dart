import 'package:admin_panel_ego/features/orders/data/models/order_model.dart';
import 'package:admin_panel_ego/features/orders/utils/order_invoice_printer.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_sale_model.dart';
import 'package:admin_panel_ego/features/pos/utils/pos_receipt_printer.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';
import 'package:admin_panel_ego/features/products/utils/barcode_128_generator.dart';
import 'package:admin_panel_ego/features/products/utils/product_barcode_label_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Barcode128Generator Tests', () {
    test('generates valid SVG for standard alphanumeric SKU', () {
      final svg = Barcode128Generator.generateSvg('EGO-VAPE-001', width: 180, height: 50);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('rect'));
      expect(svg, contains('EGO-VAPE-001'));
      expect(svg, contains('viewBox='));
    });

    test('generates valid SVG without text when showText is false', () {
      final svg = Barcode128Generator.generateSvg('SKU123456', showText: false);
      expect(svg, contains('<svg'));
      expect(svg, isNot(contains('<text')));
    });

    test('handles empty or special character strings gracefully', () {
      final svgEmpty = Barcode128Generator.generateSvg('');
      expect(svgEmpty, contains('<svg'));
      expect(svgEmpty, contains('000000'));

      final svgSpecial = Barcode128Generator.generateSvg('CODE-128_#99');
      expect(svgSpecial, contains('<svg'));
    });
  });

  group('ProductBarcodeLabelPrinter Tests', () {
    const mockProduct = ProductModel(
      id: 'prod-100',
      title: 'Vaporesso XROS 4 Mini',
      description: 'Vape device description',
      price: 950.0,
      salePrice: 850.0,
      stock: 20,
      brand: ProductBrand(id: 'b1', name: 'Vaporesso'),
      categoryId: 'cat-devices',
      categoryType: ProductCategoryType.device,
      productVariations: [
        ProductVariationModel(
          id: 'var-1',
          sku: 'XROS4-BLK-01',
          price: 950.0,
          salePrice: 850.0,
          stock: 12,
          attributeValues: {'Color': 'Black Metallic'},
        ),
      ],
    );

    test('generates thermal roll label HTML with correct @page size and vector barcode', () {
      final items = [
        BarcodeLabelItem.fromProduct(
          mockProduct,
          variation: mockProduct.productVariations.first,
          copies: 2,
        ),
      ];

      final html = ProductBarcodeLabelPrinter.generateLabelsHtml(
        items: items,
        size: BarcodeLabelSize.standardRoll50x30,
      );

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('size: 50mm 30mm;'));
      expect(html, contains('XROS4-BLK-01'));
      expect(html, contains('Vaporesso'));
      expect(html, contains('850'));
      expect(html, contains('<svg'));
    });

    test('generates A4 sheet grid HTML with correct CSS grid layout', () {
      final items = [
        BarcodeLabelItem.fromProduct(mockProduct, copies: 4),
      ];

      final html = ProductBarcodeLabelPrinter.generateLabelsHtml(
        items: items,
        size: BarcodeLabelSize.a4SheetGrid,
      );

      expect(html, contains('size: A4 portrait;'));
      expect(html, contains('grid-template-columns: repeat(3, 1fr);'));
      expect(html, contains('Vaporesso XROS 4 Mini'));
    });
  });

  group('OrderInvoicePrinter & PosReceiptPrinter Thermal Tests', () {
    final mockOrder = OrderModel(
      id: 'ORD-9876',
      userId: 'user-123',
      orderDate: DateTime(2026, 9, 27, 10, 30),
      totalAmount: 1250.0,
      subTotal: 1200.0,
      shippingCost: 50.0,
      discount: 0.0,
      status: 'Processing',
      paymentMethod: 'Cash on Delivery',
      paymentStatus: 'Pending',
      shippingAddress: const ShippingAddressModel(
        name: 'Amir Gerges',
        phoneNumber: '01234567890',
        city: 'Cairo',
        governorate: 'Cairo',
        street: 'El Tahrir St',
        building: '15',
      ),
      items: const [
        OrderItemModel(
          productId: 'prod-1',
          title: 'Nasty Juice Cush Man 60ml',
          price: 600.0,
          quantity: 2,
          selectedVariation: {'Nicotine': '3mg'},
        ),
      ],
    );

    test('generateThermalOrderReceiptHtml produces palm-sized auto-height receipt with barcode', () {
      final html = OrderInvoicePrinter.generateThermalOrderReceiptHtml(mockOrder, widthMm: 80);
      expect(html, contains('size: 80mm auto;'));
      expect(html, contains('ORD-9876'));
      expect(html, contains('Amir Gerges'));
      expect(html, contains('01234567890'));
      expect(html, contains('Nasty Juice Cush Man 60ml'));
      expect(html, contains('1,250.00'));
      expect(html, contains('<svg'));
    });

    test('generateThermalReceiptHtml in PosReceiptPrinter produces valid receipt with barcode', () {
      final sale = PosSaleModel.fromOrder(mockOrder);
      final html = PosReceiptPrinter.generateThermalReceiptHtml(sale, widthMm: 80);
      expect(html, contains('size: 80mm auto;'));
      expect(html, contains('ORD-9876'));
      expect(html, contains('EGO VAPE STORE'));
      expect(html, contains('<svg'));
    });
  });
}
