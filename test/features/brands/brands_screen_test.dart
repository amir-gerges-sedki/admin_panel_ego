import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_panel_ego/features/brands/presentation/screens/brands_screen.dart';
import 'package:admin_panel_ego/features/brands/presentation/cubit/brand_cubit.dart';
import 'package:admin_panel_ego/features/brands/data/models/brand_model.dart';
import 'package:admin_panel_ego/features/brands/data/repositories/brand_repository.dart';

class TestBrandRepo implements BrandRepository {
  List<BrandModel> brands = [
    const BrandModel(
      id: 'b1',
      name: 'Voopoo',
      sortOrder: 1,
      isFeatured: true,
      productsCount: 10,
    ),
    const BrandModel(
      id: 'b2',
      name: 'Smok',
      sortOrder: 2,
      isFeatured: false,
      productsCount: 20,
    ),
  ];

  @override
  Future<List<BrandModel>> getBrands() async => brands;
  @override
  Future<BrandModel?> getBrandById(String id) async => null;
  @override
  Future<BrandModel?> getBrandByName(String name) async => null;
  @override
  Future<BrandModel> ensureBrandExists({
    required String name,
    String? id,
  }) async => brands.first;
  @override
  Future<void> addBrand(BrandModel brand) async {}
  @override
  Future<void> updateBrand(BrandModel brand) async {}
  @override
  @override
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders) async {}
  @override
  Future<void> deleteBrand(String id) async {}
}

void main() {
  testWidgets('reproduce mouse hover in BrandsScreen', (tester) async {
    final repo = TestBrandRepo();
    final cubit = BrandCubit(repo);
    await cubit.loadBrands();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BrandCubit>.value(
            value: cubit,
            child: const BrandsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dragHandleFinder = find.byIcon(Icons.drag_handle_rounded).first;
    expect(dragHandleFinder, findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(dragHandleFinder));
    await tester.pump();
    await gesture.down(tester.getCenter(dragHandleFinder));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
