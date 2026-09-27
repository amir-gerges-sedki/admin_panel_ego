import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/localization/app_localizations.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_cart_item_model.dart';
import 'package:admin_panel_ego/features/pos/data/models/pos_sale_model.dart';
import 'package:admin_panel_ego/features/pos/data/repositories/pos_repository.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/pos_cubit.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/pos_state.dart';
import 'package:admin_panel_ego/features/pos/presentation/widgets/pos_product_grid.dart';
import 'package:admin_panel_ego/features/pos/utils/pos_receipt_printer.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';

class MockPosRepository implements PosRepository {
  final StreamController<List<ProductModel>> _streamController =
      StreamController<List<ProductModel>>.broadcast();
  List<ProductModel> _products = [];
  final List<PosSaleModel> submittedSales = [];

  MockPosRepository([List<ProductModel>? initial]) {
    if (initial != null) {
      _products = List.from(initial);
    }
  }

  void emitProducts(List<ProductModel> products) {
    _products = products;
    _streamController.add(products);
  }

  @override
  Stream<List<ProductModel>> getProductsStream() async* {
    if (_products.isNotEmpty) {
      yield _products;
    }
    yield* _streamController.stream;
  }

  @override
  Future<List<ProductModel>> getProducts() async => _products;

  @override
  Future<PosSaleModel> submitPosSale(PosSaleModel sale) async {
    final completed = sale.copyWith(
      id: sale.id.isNotEmpty ? sale.id : 'sale_${submittedSales.length + 1}',
      orderNumber: sale.orderNumber.isNotEmpty ? sale.orderNumber : 'POS-TEST-1234',
      status: 'completed',
    );
    submittedSales.add(completed);
    return completed;
  }

  void dispose() {
    _streamController.close();
  }
}

ProductModel createDummyProduct({
  required String id,
  required String title,
  required ProductCategoryType categoryType,
  double price = 500.0,
  int stock = 10,
  bool isVariable = false,
  List<ProductVariationModel> variations = const [],
}) {
  return ProductModel(
    id: id,
    title: title,
    stock: stock,
    price: price,
    salePrice: 0.0,
    description: 'Test product description',
    brand: const ProductBrand(id: 'b1', name: 'Vaporesso'),
    categoryId: categoryType.id,
    categoryType: categoryType,
    productType: isVariable ? 'variable' : 'simple',
    productVariations: variations,
    specifications: {'barcode': 'BC-$id'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLocalizations.setLocale(const Locale('ar'));

  group('POS Models Tests', () {
    test('PosCartItemModel computes prices, line discounts, and totals accurately', () {
      const item = PosCartItemModel(
        productId: 'p_01',
        variationId: 'v_01',
        title: 'Nasty Juice Cush Man',
        brand: 'Nasty Juice',
        image: 'https://example.com/cushman.png',
        sku: 'NJ-CM-30',
        unitPrice: 450.0,
        quantity: 3,
        discount: 50.0, // 50 EGP discount per unit
        selectedVariation: {'Flavor': 'Mango Low Mint', 'Nicotine': '30mg'},
      );

      expect(item.effectiveUnitPrice, 400.0);
      expect(item.totalLineDiscount, 150.0); // 50 * 3
      expect(item.lineTotal, 1200.0); // 400 * 3
      expect(item.variationSummary, 'Flavor: Mango Low Mint, Nicotine: 30mg');
      expect(item.fullTitle, 'Nasty Juice Cush Man');

      final json = item.toJson();
      expect(json['sku'], 'NJ-CM-30');
      expect(json['quantity'], 3);
      expect(json['discount'], 50.0);

      final fromJson = PosCartItemModel.fromJson(json);
      expect(fromJson.productId, 'p_01');
      expect(fromJson.lineTotal, 1200.0);
      expect(fromJson.selectedVariation['Flavor'], 'Mango Low Mint');
    });

    test('PosSaleModel serialization & deserialization works correctly', () {
      final now = DateTime(2026, 9, 26, 15, 30);
      final sale = PosSaleModel(
        id: 'pos_sale_001',
        orderNumber: 'POS-900214',
        createdAt: now,
        cashierName: 'Mohamed Ali',
        cashierId: 'c_01',
        customerName: 'Ahmed Omar',
        customerPhone: '01001234567',
        items: const [
          PosCartItemModel(
            productId: 'p_01',
            title: 'Vaporesso XROS 4',
            brand: 'Vaporesso',
            image: '',
            sku: 'XROS4-BLK',
            unitPrice: 850.0,
            quantity: 2,
            discount: 50.0,
            selectedVariation: {'Color': 'Black'},
          ),
        ],
        subTotal: 1700.0,
        discount: 100.0,
        taxFee: 0.0,
        totalAmount: 1600.0,
        paidAmount: 2000.0,
        changeAmount: 400.0,
        paymentMethod: 'cash',
        notes: 'VIP customer discount applied',
        status: 'completed',
      );

      expect(sale.totalItemsCount, 2);
      expect(sale.totalAmount, 1600.0);
      expect(sale.changeAmount, 400.0);

      final json = sale.toJson();
      expect(json['orderNumber'], 'POS-900214');
      expect(json['customerName'], 'Ahmed Omar');
      expect(json['paidAmount'], 2000.0);
      expect(json['changeAmount'], 400.0);

      final fromJson = PosSaleModel.fromJson(json);
      expect(fromJson.id, 'pos_sale_001');
      expect(fromJson.items.length, 1);
      expect(fromJson.items.first.title, 'Vaporesso XROS 4');
    });
  });

  group('PosCubit State & Logic Tests', () {
    late MockPosRepository mockRepository;
    late PosCubit cubit;

    final dummyProducts = [
      createDummyProduct(
        id: 'p_liq',
        title: 'Dinner Lady Lemon Tart',
        categoryType: ProductCategoryType.liquid,
        price: 350.0,
      ),
      createDummyProduct(
        id: 'p_disp',
        title: 'Elfbar BC5000 Watermelon',
        categoryType: ProductCategoryType.disposable,
        price: 450.0,
      ),
      createDummyProduct(
        id: 'p_mod',
        title: 'Vaporesso Gen 200 Mod',
        categoryType: ProductCategoryType.device,
        price: 1800.0,
        isVariable: true,
        variations: [
          const ProductVariationModel(
            id: 'v_silver',
            sku: 'GEN200-SLV',
            price: 1800.0,
            salePrice: 0.0,
            stock: 5,
            attributeValues: {'Color': 'Silver'},
          ),
          const ProductVariationModel(
            id: 'v_black',
            sku: 'GEN200-BLK',
            price: 1800.0,
            salePrice: 0.0,
            stock: 3,
            attributeValues: {'Color': 'Matte Black'},
          ),
        ],
      ),
    ];

    setUp(() {
      mockRepository = MockPosRepository(dummyProducts);
      cubit = PosCubit(repository: mockRepository);
    });

    tearDown(() {
      cubit.close();
      mockRepository.dispose();
    });

    test('Loads and syncs catalog products into state', () async {
      await pumpEventQueue();
      expect(cubit.state.allProducts.length, 3);
      expect(cubit.state.filteredProducts.length, 3);
    });

    test('Filters products by query and category', () async {
      await pumpEventQueue();

      // Search by title
      cubit.filterProducts(query: 'Lemon');
      expect(cubit.state.filteredProducts.length, 1);
      expect(cubit.state.filteredProducts.first.id, 'p_liq');

      // Search by variation SKU
      cubit.filterProducts(query: 'GEN200-BLK');
      expect(cubit.state.filteredProducts.length, 1);
      expect(cubit.state.filteredProducts.first.id, 'p_mod');

      // Search by variation attribute value (Color: Matte Black)
      cubit.filterProducts(query: 'Matte Black');
      expect(cubit.state.filteredProducts.length, 1);
      expect(cubit.state.filteredProducts.first.id, 'p_mod');

      // Search by multi-word query (Brand + Attribute)
      cubit.filterProducts(query: 'Vaporesso Silver');
      expect(cubit.state.filteredProducts.length, 1);
      expect(cubit.state.filteredProducts.first.id, 'p_mod');

      // Clear search and filter by category
      cubit.filterProducts(query: '', category: ProductCategoryType.disposable);
      expect(cubit.state.filteredProducts.length, 1);
      expect(cubit.state.filteredProducts.first.id, 'p_disp');

      // Clear category
      cubit.filterProducts(clearCategory: true);
      expect(cubit.state.filteredProducts.length, 3);
    });

    test('PosProductGrid category list contains required categories and excludes Pods/Coils', () {
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.liquid), true);
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.disposable), true);
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.device), true);
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.accessory), true);
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.pod), false);
      expect(PosProductGrid.posCategories.contains(ProductCategoryType.coil), false);
    });

    test('Adds products to cart and stacks identical items', () async {
      await pumpEventQueue();

      final p = dummyProducts[0];
      cubit.addToCart(p, quantity: 1);
      expect(cubit.state.cartItems.length, 1);
      expect(cubit.state.cartItems.first.quantity, 1);
      expect(cubit.state.subTotal, 350.0);

      // Add same product again -> stacks
      cubit.addToCart(p, quantity: 2);
      expect(cubit.state.cartItems.length, 1);
      expect(cubit.state.cartItems.first.quantity, 3);
      expect(cubit.state.subTotal, 1050.0);
    });

    test('Updates quantity with steppers and removes item when quantity reaches 0', () async {
      await pumpEventQueue();

      cubit.addToCart(dummyProducts[0], quantity: 2);
      expect(cubit.state.cartItems.first.quantity, 2);

      // Increment
      cubit.updateQuantity(0, 3);
      expect(cubit.state.cartItems.first.quantity, 3);
      expect(cubit.state.subTotal, 1050.0);

      // Decrement to 0 -> removes item
      cubit.updateQuantity(0, 0);
      expect(cubit.state.cartItems.isEmpty, true);
    });

    test('Strict stock enforcement caps quantity and warns user when stock is exceeded', () async {
      await pumpEventQueue();

      final modProduct = dummyProducts[2]; // GEN 200 Mod
      final blackVar = modProduct.productVariations[1]; // Stock = 3

      // 1. Add up to available stock (3)
      cubit.addToCart(modProduct, variation: blackVar, quantity: 2);
      expect(cubit.state.cartItems.first.quantity, 2);

      cubit.addToCart(modProduct, variation: blackVar, quantity: 1);
      expect(cubit.state.cartItems.first.quantity, 3);

      // 2. Try adding a 4th unit -> blocked at 3 with warning message
      cubit.addToCart(modProduct, variation: blackVar, quantity: 1);
      expect(cubit.state.cartItems.first.quantity, 3);
      expect(cubit.state.barcodeFeedbackMessage?.contains('3 فقط'), true);

      // 3. Try updating quantity with stepper beyond available stock (e.g. 5) -> clamped to 3 with warning
      cubit.updateQuantity(0, 5);
      expect(cubit.state.cartItems.first.quantity, 3);
      expect(cubit.state.barcodeFeedbackMessage?.contains('3 فقط'), true);

      // 4. Zero stock product cannot be added
      final zeroStockProduct = createDummyProduct(
        id: 'p_empty',
        title: 'Empty Stock Item',
        categoryType: ProductCategoryType.liquid,
        stock: 0,
      );
      cubit.addToCart(zeroStockProduct);
      expect(cubit.state.cartItems.length, 1); // Only the previous item exists
      expect(cubit.state.barcodeFeedbackMessage?.contains('نفذ من المخزون'), true);
    });

    test('Applies item discounts and cart overall discounts accurately', () async {
      await pumpEventQueue();

      cubit.addToCart(dummyProducts[0], quantity: 2); // 2 * 350 = 700
      expect(cubit.state.grandTotal, 700.0);

      // Item discount: 50 EGP per unit (100 total discount)
      cubit.updateItemDiscount(0, 50.0);
      expect(cubit.state.totalDiscount, 100.0);
      expect(cubit.state.grandTotal, 600.0);

      // Whole cart discount: 100 EGP
      cubit.setCartDiscount(100.0);
      expect(cubit.state.totalDiscount, 200.0);
      expect(cubit.state.grandTotal, 500.0);
    });

    test('Calculates cash payment change return', () async {
      await pumpEventQueue();

      cubit.addToCart(dummyProducts[0], quantity: 2); // 700 EGP
      cubit.setPaymentMethod('cash');
      cubit.setPaidAmount(1000.0);

      expect(cubit.state.paidAmount, 1000.0);
      expect(cubit.state.changeAmount, 300.0);
    });

    test('Hardware Barcode scanning matches variation SKU directly', () async {
      await pumpEventQueue();

      // Scan variation SKU "GEN200-BLK"
      final result = cubit.handleBarcodeScanned('GEN200-BLK');
      expect(result, isNull); // Added directly to cart
      expect(cubit.state.cartItems.length, 1);
      expect(cubit.state.cartItems.first.sku, 'GEN200-BLK');
      expect(cubit.state.cartItems.first.unitPrice, 1800.0);
      expect(cubit.state.barcodeFeedbackMessage?.contains('GEN200-BLK'), true);
    });

    test('Hardware Barcode scanning matches multi-variable product and requests dialog', () async {
      await pumpEventQueue();

      // Scan product ID 'p_mod' which has 2 variations
      final result = cubit.handleBarcodeScanned('p_mod');
      expect(result, isNotNull);
      expect(result!.id, 'p_mod');
    });

    test('Completes sale transaction and resets cart', () async {
      await pumpEventQueue();

      cubit.addToCart(dummyProducts[0], quantity: 2);
      cubit.setCustomerInfo(name: 'Karim Hassan', phone: '01222222222');
      cubit.setPaymentMethod('cash');
      cubit.setPaidAmount(800.0);

      final success = await cubit.completeSale(
        cashierName: 'Amir Gerges',
        cashierId: 'usr_admin',
        autoPrint: false,
      );

      expect(success, true);
      expect(cubit.state.saleStatus, PosSaleStatus.success);
      expect(cubit.state.cartItems.isEmpty, true);
      expect(cubit.state.lastCompletedSale, isNotNull);
      expect(cubit.state.lastCompletedSale!.customerName, 'Karim Hassan');
      expect(cubit.state.lastCompletedSale!.paidAmount, 800.0);
      expect(cubit.state.lastCompletedSale!.changeAmount, 100.0);
      expect(mockRepository.submittedSales.length, 1);
    });
  });

  group('PosReceiptPrinter HTML Generator Tests', () {
    final testSale = PosSaleModel(
      id: 'sale_999',
      orderNumber: 'POS-889900',
      createdAt: DateTime(2026, 9, 26, 16, 45),
      cashierName: 'Staff Store 1',
      cashierId: 'st_01',
      customerName: 'Ziad Mansour',
      customerPhone: '01155554444',
      items: const [
        PosCartItemModel(
          productId: 'p_01',
          variationId: 'v_01',
          title: 'Vaporesso Luxe XR Max',
          brand: 'Vaporesso',
          image: '',
          sku: 'LUXE-XR-BLK',
          unitPrice: 1650.0,
          quantity: 1,
          discount: 50.0,
          selectedVariation: {'Color': 'Black Carbon'},
        ),
      ],
      subTotal: 1650.0,
      discount: 50.0,
      taxFee: 0.0,
      totalAmount: 1600.0,
      paidAmount: 2000.0,
      changeAmount: 400.0,
      paymentMethod: 'cash',
      notes: 'Customer warranty card stamped',
      status: 'completed',
    );

    test('generateThermalReceiptHtml outputs 80mm format with all transaction metadata', () {
      final html = PosReceiptPrinter.generateThermalReceiptHtml(testSale, widthMm: 80);

      expect(html.contains('POS-889900'), true);
      expect(html.contains('EGO VAPE STORE'), true);
      expect(html.contains('Vaporesso Luxe XR Max'), true);
      expect(html.contains('Black Carbon'), true);
      expect(html.contains('1,600.00'), true);
      expect(html.contains('2,000.00'), true);
      expect(html.contains('400.00'), true);
      expect(html.contains('Staff Store 1'), true);
      expect(html.contains('Ziad Mansour'), true);
      expect(html.contains('80mm'), true);
    });

    test('generateThermalReceiptHtml outputs 58mm format cleanly', () {
      final html = PosReceiptPrinter.generateThermalReceiptHtml(testSale, widthMm: 58);

      expect(html.contains('POS-889900'), true);
      expect(html.contains('58mm'), true);
    });
  });
}
