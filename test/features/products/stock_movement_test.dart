import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';
import 'package:admin_panel_ego/features/products/data/repositories/product_repository.dart';
import 'package:admin_panel_ego/features/products/data/repositories/stock_movement_repository.dart';
import 'package:admin_panel_ego/features/products/data/datasources/stock_movement_remote_data_source.dart';
import 'package:admin_panel_ego/features/products/presentation/cubit/stock_movement_cubit.dart';
import 'package:admin_panel_ego/features/products/presentation/cubit/stock_movement_state.dart';
import 'package:admin_panel_ego/features/products/presentation/cubit/product_cubit.dart';
import 'package:admin_panel_ego/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:admin_panel_ego/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:admin_panel_ego/features/dashboard/data/models/dashboard_analytics_model.dart';
import 'package:admin_panel_ego/features/products/presentation/widgets/quick_restock_dialog.dart';

class MockProductRepo implements ProductRepository {
  ProductModel? lastUpdatedProduct;

  @override
  Future<List<ProductModel>> getProducts() async => [];
  @override
  Future<void> addProduct(ProductModel product) async {}
  @override
  Future<void> updateProduct(ProductModel product) async {
    lastUpdatedProduct = product;
  }
  @override
  Future<void> deleteProduct(String productId) async {}
}

class MockStockMovementRemoteDataSource implements StockMovementRemoteDataSource {
  final List<StockMovementModel> movements = [];

  @override
  Future<List<StockMovementModel>> getStockMovements({
    int limit = 100,
    String? productId,
    StockMovementType? type,
  }) async {
    return movements.where((m) {
      final matchesProd = productId == null || m.productId == productId;
      final matchesType = type == null || m.type == type;
      return matchesProd && matchesType;
    }).toList();
  }

  @override
  Future<void> recordStockMovement(StockMovementModel movement) async {
    movements.add(movement);
  }

  @override
  Future<void> recordBatchStockMovements(List<StockMovementModel> newMovements) async {
    movements.addAll(newMovements);
  }
}

class MockDashboardRepo implements DashboardRepository {
  @override
  Future<DashboardAnalyticsModel> getDashboardAnalytics({
    DashboardPeriodType periodType = DashboardPeriodType.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    return const DashboardAnalyticsModel.empty();
  }
}

void main() {
  group('StockMovementModel Tests', () {
    test('Correctly serializes and deserializes StockMovementModel', () {
      final movement = StockMovementModel(
        id: 'SM-001',
        productId: 'PROD-1',
        productTitle: 'Ego Salt Liquid',
        productCategory: 'E-Liquids',
        variationSku: 'EGO-SALT-MANGO-30ML-50MG',
        variationAttributes: const {'Flavor': 'Mango', 'Nicotine': '50mg', 'Size': '30ml'},
        type: StockMovementType.restock,
        quantity: 50,
        previousStock: 5,
        newStock: 55,
        costPricePerUnit: 120.0,
        totalCost: 6000.0,
        supplierName: 'Ego Labs',
        invoiceNumber: 'INV-2026-09',
        notes: 'Monthly bulk inflow',
        performedBy: 'Amir Admin',
        createdAt: DateTime(2026, 9, 26, 12, 0),
      );

      final json = movement.toJson();
      final fromJson = StockMovementModel.fromJson(json);

      expect(fromJson.id, 'SM-001');
      expect(fromJson.productId, 'PROD-1');
      expect(fromJson.productTitle, 'Ego Salt Liquid');
      expect(fromJson.variationSku, 'EGO-SALT-MANGO-30ML-50MG');
      expect(fromJson.type, StockMovementType.restock);
      expect(fromJson.quantity, 50);
      expect(fromJson.previousStock, 5);
      expect(fromJson.newStock, 55);
      expect(fromJson.costPricePerUnit, 120.0);
      expect(fromJson.totalCost, 6000.0);
      expect(fromJson.supplierName, 'Ego Labs');
      expect(fromJson.invoiceNumber, 'INV-2026-09');
      expect(fromJson.isInflow, true);
      expect(fromJson.isOutflow, false);
    });

    test('Handles all movement types parsing accurately', () {
      expect(StockMovementType.fromString('restock'), StockMovementType.restock);
      expect(StockMovementType.fromString('sale'), StockMovementType.sale);
      expect(StockMovementType.fromString('damage'), StockMovementType.damage);
      expect(StockMovementType.fromString('adjustment'), StockMovementType.adjustment);
      expect(StockMovementType.fromString('return'), StockMovementType.returnItem);
      expect(StockMovementType.fromString('unknown'), StockMovementType.adjustment);
    });
  });

  group('StockMovementRepository Tests', () {
    late MockProductRepo mockProductRepo;
    late MockStockMovementRemoteDataSource mockDataSource;
    late StockMovementRepository repository;

    final testProduct = ProductModel(
      id: 'P-100',
      title: 'Vaporesso XROS 4',
      description: 'Pod system',
      price: 1500.0,
      salePrice: 1350.0,
      costPrice: 950.0,
      stock: 10,
      brand: const ProductBrand(id: '1', name: 'Vaporesso'),
      categoryId: 'device',
      categoryType: ProductCategoryType.device,
      productVariations: const [
        ProductVariationModel(
          id: 'v1',
          sku: 'XROS4-BLK',
          price: 1500,
          salePrice: 1350,
          costPrice: 950,
          stock: 4,
          attributeValues: {'Color': 'Black'},
        ),
        ProductVariationModel(
          id: 'v2',
          sku: 'XROS4-SLV',
          price: 1500,
          salePrice: 1350,
          costPrice: 950,
          stock: 6,
          attributeValues: {'Color': 'Silver'},
        ),
      ],
    );

    setUp(() {
      mockProductRepo = MockProductRepo();
      mockDataSource = MockStockMovementRemoteDataSource();
      repository = StockMovementRepositoryImpl(
        remoteDataSource: mockDataSource,
        productRepository: mockProductRepo,
      );
    });

    test('executeRestock updates specific variation stock and logs movement', () async {
      final updated = await repository.executeRestock(
        product: testProduct,
        variationSku: 'XROS4-BLK',
        quantityAdded: 20,
        costPrice: 920.0,
        supplier: 'Vaporesso Dist',
        invoiceNumber: 'INV-441',
      );

      // Verify Product Updated
      final blackVar = updated.productVariations.firstWhere((v) => v.sku == 'XROS4-BLK');
      expect(blackVar.stock, 24); // 4 + 20
      expect(blackVar.costPrice, 920.0);
      expect(updated.stock, 30); // 24 + 6

      // Verify Movement Logged
      expect(mockDataSource.movements.length, 1);
      final logged = mockDataSource.movements.first;
      expect(logged.variationSku, 'XROS4-BLK');
      expect(logged.quantity, 20);
      expect(logged.previousStock, 4);
      expect(logged.newStock, 24);
      expect(logged.costPricePerUnit, 920.0);
      expect(logged.totalCost, 20 * 920.0);
      expect(logged.supplierName, 'Vaporesso Dist');
    });

    test('executeBatchRestock updates multiple variations simultaneously', () async {
      final updated = await repository.executeBatchRestock(
        product: testProduct,
        skuQuantities: {'XROS4-BLK': 10, 'XROS4-SLV': 15},
        skuCostPrices: {'XROS4-BLK': 930.0, 'XROS4-SLV': 940.0},
        supplier: 'Global Imports',
      );

      final blackVar = updated.productVariations.firstWhere((v) => v.sku == 'XROS4-BLK');
      final silverVar = updated.productVariations.firstWhere((v) => v.sku == 'XROS4-SLV');

      expect(blackVar.stock, 14); // 4 + 10
      expect(silverVar.stock, 21); // 6 + 15
      expect(updated.stock, 35);

      expect(mockDataSource.movements.length, 2);
    });

    test('executeStockAdjustment handles inventory write-offs and audits', () async {
      final updated = await repository.executeStockAdjustment(
        product: testProduct,
        variationSku: 'XROS4-BLK',
        newExactStock: 2, // 2 damaged
        type: StockMovementType.damage,
        reason: 'Water damaged in warehouse',
      );

      final blackVar = updated.productVariations.firstWhere((v) => v.sku == 'XROS4-BLK');
      expect(blackVar.stock, 2);
      expect(updated.stock, 8); // 2 + 6

      expect(mockDataSource.movements.length, 1);
      final logged = mockDataSource.movements.first;
      expect(logged.type, StockMovementType.damage);
      expect(logged.quantity, -2); // 2 - 4 = -2
    });
  });

  group('StockMovementCubit Tests', () {
    late MockProductRepo mockProductRepo;
    late MockStockMovementRemoteDataSource mockDataSource;
    late StockMovementRepository repository;
    late StockMovementCubit cubit;

    setUp(() {
      mockProductRepo = MockProductRepo();
      mockDataSource = MockStockMovementRemoteDataSource();
      repository = StockMovementRepositoryImpl(
        remoteDataSource: mockDataSource,
        productRepository: mockProductRepo,
      );
      cubit = StockMovementCubit(repository);
    });

    test('Loads and filters movements by query and type', () async {
      mockDataSource.movements.addAll([
        StockMovementModel(
          id: '1',
          productId: 'P1',
          productTitle: 'Mango Ice Liquid',
          variationSku: 'MANGO-30ML',
          type: StockMovementType.restock,
          quantity: 20,
          previousStock: 0,
          newStock: 20,
          costPricePerUnit: 100,
          totalCost: 2000,
          supplierName: 'Egypt Vapes',
          createdAt: DateTime.now(),
        ),
        StockMovementModel(
          id: '2',
          productId: 'P2',
          productTitle: 'Caliburn G3',
          variationSku: 'G3-BLK',
          type: StockMovementType.sale,
          quantity: -1,
          previousStock: 5,
          newStock: 4,
          costPricePerUnit: 800,
          totalCost: 800,
          createdAt: DateTime.now(),
        ),
      ]);

      await cubit.loadStockMovements();
      expect(cubit.state, isA<StockMovementLoaded>());
      final loaded = cubit.state as StockMovementLoaded;
      expect(loaded.allMovements.length, 2);
      expect(loaded.totalInflowCount, 20);
      expect(loaded.totalInflowValue, 2000.0);
      expect(loaded.totalOutflowCount, 1);

      // Filter by Search Query
      cubit.filterMovements(query: 'Mango');
      final filteredState = cubit.state as StockMovementLoaded;
      expect(filteredState.filteredMovements.length, 1);
      expect(filteredState.filteredMovements.first.productTitle, 'Mango Ice Liquid');

      // Filter by Type
      cubit.filterMovements(query: '', type: StockMovementType.sale);
      final typeFiltered = cubit.state as StockMovementLoaded;
      expect(typeFiltered.filteredMovements.length, 1);
      expect(typeFiltered.filteredMovements.first.variationSku, 'G3-BLK');
    });
  });

  group('QuickRestockDialog UI Test', () {
    testWidgets('Renders QuickRestockDialog and displays variation options cleanly', (WidgetTester tester) async {
      final mockProductRepo = MockProductRepo();
      final mockStockDataSource = MockStockMovementRemoteDataSource();
      final stockRepo = StockMovementRepositoryImpl(
        remoteDataSource: mockStockDataSource,
        productRepository: mockProductRepo,
      );

      final stockCubit = StockMovementCubit(stockRepo);
      final productCubit = ProductCubit(mockProductRepo);
      final dashboardCubit = DashboardCubit(MockDashboardRepo());

      const product = ProductModel(
        id: 'TEST-P',
        title: 'Dinner Lady Lemon Tart',
        description: 'Vape e-liquid',
        price: 450,
        salePrice: 400,
        costPrice: 280,
        stock: 8,
        brand: ProductBrand(id: 'dl', name: 'Dinner Lady'),
        categoryId: 'liquid',
        categoryType: ProductCategoryType.liquid,
        productVariations: [
          ProductVariationModel(
            id: 'v1',
            sku: 'DL-LT-60ML-3MG',
            price: 450,
            salePrice: 400,
            costPrice: 280,
            stock: 3,
            attributeValues: {'Size': '60ml', 'Nicotine': '3mg'},
          ),
          ProductVariationModel(
            id: 'v2',
            sku: 'DL-LT-60ML-6MG',
            price: 450,
            salePrice: 400,
            costPrice: 280,
            stock: 5,
            attributeValues: {'Size': '60ml', 'Nicotine': '6mg'},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<StockMovementCubit>.value(value: stockCubit),
                BlocProvider<ProductCubit>.value(value: productCubit),
                BlocProvider<DashboardCubit>.value(value: dashboardCubit),
              ],
              child: const QuickRestockDialog(product: product),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dinner Lady Lemon Tart • Dinner Lady'), findsOneWidget);
      expect(find.text('+20'), findsWidgets);
    });
  });
}
