import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_panel_ego/features/products/presentation/widgets/product_creation_wizard.dart';
import 'package:admin_panel_ego/features/products/presentation/cubit/product_form_cubit.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';
import 'package:admin_panel_ego/features/products/data/repositories/product_repository.dart';
import 'package:admin_panel_ego/features/brands/presentation/cubit/brand_cubit.dart';
import 'package:admin_panel_ego/features/brands/data/repositories/brand_repository.dart';
import 'package:admin_panel_ego/features/brands/data/models/brand_model.dart';
import 'package:admin_panel_ego/features/badges/presentation/cubit/badge_cubit.dart';
import 'package:admin_panel_ego/features/badges/data/repositories/badge_repository.dart';
import 'package:admin_panel_ego/features/badges/data/models/badge_model.dart';

class MockProductRepo implements ProductRepository {
  @override
  Future<List<ProductModel>> getProducts() async => [];
  @override
  Future<void> addProduct(ProductModel product) async {}
  @override
  Future<void> updateProduct(ProductModel product) async {}
  @override
  Future<void> deleteProduct(String productId) async {}
}

class MockBrandRepo implements BrandRepository {
  @override
  Future<List<BrandModel>> getBrands() async => [
        BrandModel(id: '1', name: 'Vaporesso'),
        BrandModel(id: '2', name: 'Smok'),
      ];
  @override
  Future<BrandModel?> getBrandById(String id) async => null;
  @override
  Future<BrandModel?> getBrandByName(String name) async => null;
  @override
  Future<BrandModel> ensureBrandExists({required String name, String? id}) async =>
      BrandModel(id: id ?? '1', name: name);
  @override
  Future<void> addBrand(BrandModel brand) async {}
  @override
  Future<void> updateBrand(BrandModel brand) async {}
  @override
  Future<void> deleteBrand(String brandId) async {}
  @override
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders) async {}
}

class MockBadgeRepo implements BadgeRepository {
  @override
  Future<List<BadgeModel>> getBadges() async => [
        BadgeModel(id: 'HOT', name: 'HOT DEAL', colorHex: '#F59E0B'),
      ];
  @override
  Future<void> addBadge(BadgeModel badge) async {}
  @override
  Future<void> updateBadge(BadgeModel badge) async {}
  @override
  Future<void> deleteBadge(String badgeId) async {}
}

void main() {
  group('ProductCreationWizard Overflow-free Layout Tests', () {
    for (final width in [360.0, 444.0, 768.0]) {
      for (final type in ProductCategoryType.visibleTypes) {
        testWidgets(
            'Step 2 renders cleanly without RenderFlex overflow at ${width}px width for $type',
            (WidgetTester tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final productCubit = ProductFormCubit(MockProductRepo());
          productCubit.initForNewProduct();
          productCubit.selectCategoryType(type);
          // Now on Step 1 (Step 2 in UI: Dynamic Specs)

          final brandCubit = BrandCubit(MockBrandRepo());
          final badgeCubit = BadgeCubit(MockBadgeRepo());

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<ProductFormCubit>.value(value: productCubit),
                      BlocProvider<BrandCubit>.value(value: brandCubit),
                      BlocProvider<BadgeCubit>.value(value: badgeCubit),
                    ],
                    child: const ProductCreationWizard(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('step_2_specs')), findsOneWidget);
        });

        testWidgets(
            'Step 3 renders cleanly without RenderFlex overflow at ${width}px width for $type',
            (WidgetTester tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final productCubit = ProductFormCubit(MockProductRepo());
          productCubit.initForNewProduct();
          productCubit.selectCategoryType(type);
          productCubit.generateDynamicVariations();
          productCubit.setStep(2); // Step 3: Variations Matrix

          final brandCubit = BrandCubit(MockBrandRepo());
          final badgeCubit = BadgeCubit(MockBadgeRepo());

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<ProductFormCubit>.value(value: productCubit),
                      BlocProvider<BrandCubit>.value(value: brandCubit),
                      BlocProvider<BadgeCubit>.value(value: badgeCubit),
                    ],
                    child: const ProductCreationWizard(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('step_3_matrix')), findsOneWidget);
        });

        testWidgets(
            'Step 4 renders cleanly without RenderFlex overflow at ${width}px width for $type',
            (WidgetTester tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final productCubit = ProductFormCubit(MockProductRepo());
          productCubit.initForNewProduct();
          productCubit.selectCategoryType(type);
          productCubit.generateDynamicVariations();
          productCubit.setStep(3); // Step 4: Review & Publish

          final brandCubit = BrandCubit(MockBrandRepo());
          final badgeCubit = BadgeCubit(MockBadgeRepo());

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<ProductFormCubit>.value(value: productCubit),
                      BlocProvider<BrandCubit>.value(value: brandCubit),
                      BlocProvider<BadgeCubit>.value(value: badgeCubit),
                    ],
                    child: const ProductCreationWizard(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('step_4_review')), findsOneWidget);
        });
      }
    }
  });
}
