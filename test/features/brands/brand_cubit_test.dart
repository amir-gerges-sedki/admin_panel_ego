import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/brands/data/models/brand_model.dart';
import 'package:admin_panel_ego/features/brands/data/repositories/brand_repository.dart';
import 'package:admin_panel_ego/features/brands/presentation/cubit/brand_cubit.dart';

class FakeBrandRepository implements BrandRepository {
  List<BrandModel> brands;
  FakeBrandRepository(this.brands);

  @override
  Future<List<BrandModel>> getBrands() async => List.from(brands);

  @override
  Future<BrandModel?> getBrandById(String id) async {
    final idx = brands.indexWhere((b) => b.id == id);
    return idx != -1 ? brands[idx] : null;
  }

  @override
  Future<BrandModel?> getBrandByName(String name) async {
    final idx = brands.indexWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
    );
    return idx != -1 ? brands[idx] : null;
  }

  @override
  Future<BrandModel> ensureBrandExists({
    required String name,
    String? id,
  }) async {
    final existing = await getBrandByName(name);
    if (existing != null) return existing;
    final created = BrandModel(id: id ?? name, name: name);
    brands.add(created);
    return created;
  }

  @override
  Future<void> addBrand(BrandModel brand) async {
    brands.add(brand);
  }

  @override
  Future<void> updateBrand(BrandModel brand) async {
    final idx = brands.indexWhere((b) => b.id == brand.id);
    if (idx != -1) {
      brands[idx] = brand;
    }
  }

  int updateBatchCalls = 0;

  @override
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders) async {
    updateBatchCalls++;
    for (final entry in brandOrders.entries) {
      final idx = brands.indexWhere((b) => b.id == entry.key);
      if (idx != -1) {
        brands[idx] = brands[idx].copyWith(sortOrder: entry.value);
      }
    }
  }

  @override
  Future<void> deleteBrand(String id) async {
    brands.removeWhere((b) => b.id == id);
  }
}

void main() {
  late FakeBrandRepository fakeRepo;
  late BrandCubit cubit;

  final sampleBrands = [
    const BrandModel(
      id: 'b1',
      name: 'Voopoo',
      productsCount: 15,
      isFeatured: false,
      sortOrder: 3,
    ),
    const BrandModel(
      id: 'b2',
      name: 'Smok',
      productsCount: 42,
      isFeatured: true,
      sortOrder: 1,
    ),
    const BrandModel(
      id: 'b3',
      name: 'Geekvape',
      productsCount: 8,
      isFeatured: true,
      sortOrder: 2,
    ),
    const BrandModel(
      id: 'b4',
      name: 'Aspire',
      productsCount: 25,
      isFeatured: false,
      sortOrder: 5,
    ),
    const BrandModel(
      id: 'b5',
      name: 'Vaporesso',
      productsCount: 42,
      isFeatured: false,
      sortOrder: 4,
    ),
  ];

  setUp(() {
    fakeRepo = FakeBrandRepository(List.from(sampleBrands));
    cubit = BrandCubit(fakeRepo, reorderDebounceDuration: Duration.zero);
  });

  tearDown(() {
    cubit.close();
  });

  test('loadBrands defaults to manual sortOrder ascending', () async {
    await cubit.loadBrands();

    expect(cubit.state, isA<BrandLoaded>());
    final state = cubit.state as BrandLoaded;
    expect(state.sortField, BrandSortField.sortOrder);
    expect(state.sortAscending, true);

    final names = state.filteredBrands.map((b) => b.name).toList();
    // 1: Smok, 2: Geekvape, 3: Voopoo, 4: Vaporesso, 5: Aspire
    expect(names, ['Smok', 'Geekvape', 'Voopoo', 'Vaporesso', 'Aspire']);
  });

  test('moveBrandUp moves brand up and updates order in repository', () async {
    await cubit.loadBrands();
    // Geekvape is at index 1. Move it up to index 0.
    await cubit.moveBrandUp(1);

    final state = cubit.state as BrandLoaded;
    final names = state.filteredBrands.map((b) => b.name).toList();
    expect(names[0], 'Geekvape');
    expect(names[1], 'Smok');
  });

  test(
    'moveBrandDown moves brand down and updates order in repository',
    () async {
      await cubit.loadBrands();
      // Smok is at index 0. Move it down to index 1.
      await cubit.moveBrandDown(0);

      final state = cubit.state as BrandLoaded;
      final names = state.filteredBrands.map((b) => b.name).toList();
      expect(names[0], 'Geekvape');
      expect(names[1], 'Smok');
    },
  );

  test(
    'reorderBrands moves an item down and assigns sequential sortOrder in batch',
    () async {
      await cubit.loadBrands();
      // Initial order: Smok(1), Geekvape(2), Voopoo(3), Vaporesso(4), Aspire(5)
      // Move Smok (index 0) to target index 2 (after Voopoo)
      await cubit.reorderBrands(0, 2);

      final state = cubit.state as BrandLoaded;
      final names = state.filteredBrands.map((b) => b.name).toList();
      // Expected order: Geekvape (#1), Voopoo (#2), Smok (#3), Vaporesso (#4), Aspire (#5)
      expect(names, ['Geekvape', 'Voopoo', 'Smok', 'Vaporesso', 'Aspire']);

      // Check sortOrders in repo
      expect(
        fakeRepo.brands.firstWhere((b) => b.name == 'Geekvape').sortOrder,
        1,
      );
      expect(
        fakeRepo.brands.firstWhere((b) => b.name == 'Voopoo').sortOrder,
        2,
      );
      expect(fakeRepo.brands.firstWhere((b) => b.name == 'Smok').sortOrder, 3);
    },
  );

  test(
    'reorderBrands moves an item up to the top like playlist catch and drag',
    () async {
      await cubit.loadBrands();
      // Initial order: Smok, Geekvape, Voopoo, Vaporesso, Aspire
      // Drag Aspire (index 4) to top (newIndex = 0)
      await cubit.reorderBrands(4, 0);

      final state = cubit.state as BrandLoaded;
      final names = state.filteredBrands.map((b) => b.name).toList();
      expect(names, ['Aspire', 'Smok', 'Geekvape', 'Voopoo', 'Vaporesso']);

      // Check sortOrders in repo
      expect(
        fakeRepo.brands.firstWhere((b) => b.name == 'Aspire').sortOrder,
        1,
      );
      expect(fakeRepo.brands.firstWhere((b) => b.name == 'Smok').sortOrder, 2);
    },
  );

  test(
    'reorderBrands debounces multiple rapid drags into a single batch write',
    () async {
      fakeRepo.updateBatchCalls = 0;
      final debouncedCubit = BrandCubit(
        fakeRepo,
        reorderDebounceDuration: const Duration(milliseconds: 100),
      );
      await debouncedCubit.loadBrands();

      // Drag 1
      await debouncedCubit.reorderBrands(0, 2);
      expect(fakeRepo.updateBatchCalls, 0);

      // Drag 2 quickly
      await debouncedCubit.reorderBrands(1, 0);
      expect(fakeRepo.updateBatchCalls, 0);

      // Wait for debounce timer to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Both drags should be committed together in exactly 1 batch write
      expect(fakeRepo.updateBatchCalls, 1);
      await debouncedCubit.close();
    },
  );

  test(
    'reorderBrands does not write to repository if an item is moved and restored to original position',
    () async {
      fakeRepo.updateBatchCalls = 0;
      final debouncedCubit = BrandCubit(
        fakeRepo,
        reorderDebounceDuration: const Duration(milliseconds: 100),
      );
      await debouncedCubit.loadBrands();

      // Move brand at index 2 to index 4
      await debouncedCubit.reorderBrands(2, 4);

      // Restore brand back to its original index 2
      await debouncedCubit.reorderBrands(4, 2);

      // Wait for debounce timer to fire
      await Future.delayed(const Duration(milliseconds: 150));

      // Everything is back in its original position -> ZERO batch writes to repository!
      expect(fakeRepo.updateBatchCalls, 0);
      await debouncedCubit.close();
    },
  );

  test('sortBrands by Name ascending', () async {
    await cubit.loadBrands();
    cubit.sortBrands(BrandSortField.name, ascending: true);

    final state = cubit.state as BrandLoaded;
    expect(state.sortField, BrandSortField.name);
    expect(state.sortAscending, true);

    final names = state.filteredBrands.map((b) => b.name).toList();
    expect(names, ['Aspire', 'Geekvape', 'Smok', 'Vaporesso', 'Voopoo']);
  });

  test('sortBrands by Name descending', () async {
    await cubit.loadBrands();
    cubit.sortBrands(BrandSortField.name, ascending: false);

    final state = cubit.state as BrandLoaded;
    expect(state.sortField, BrandSortField.name);
    expect(state.sortAscending, false);

    final names = state.filteredBrands.map((b) => b.name).toList();
    expect(names, ['Voopoo', 'Vaporesso', 'Smok', 'Geekvape', 'Aspire']);
  });

  test('sortBrands by ProductsCount descending (highest first)', () async {
    await cubit.loadBrands();
    cubit.sortBrands(BrandSortField.productsCount, ascending: false);

    final state = cubit.state as BrandLoaded;
    expect(state.sortField, BrandSortField.productsCount);
    expect(state.sortAscending, false);

    // Smok and Vaporesso both have 42. Secondary sort is name ascending
    final names = state.filteredBrands.map((b) => b.name).toList();
    expect(names[0], anyOf('Smok', 'Vaporesso'));
    expect(names[1], anyOf('Smok', 'Vaporesso'));
    expect(names[2], 'Aspire'); // 25
    expect(names[3], 'Voopoo'); // 15
    expect(names[4], 'Geekvape'); // 8
  });

  test('sortBrands by ProductsCount ascending (lowest first)', () async {
    await cubit.loadBrands();
    cubit.sortBrands(BrandSortField.productsCount, ascending: true);

    final state = cubit.state as BrandLoaded;
    final counts = state.filteredBrands.map((b) => b.productsCount).toList();
    expect(counts, [8, 15, 25, 42, 42]);
  });

  test('sortBrands by Status ascending places featured brands first', () async {
    await cubit.loadBrands();
    cubit.sortBrands(BrandSortField.status, ascending: true);

    final state = cubit.state as BrandLoaded;
    final featuredStatuses = state.filteredBrands
        .map((b) => b.isFeatured)
        .toList();
    expect(featuredStatuses.take(2).every((f) => f == true), true);
    expect(featuredStatuses.skip(2).every((f) => f == false), true);

    // Geekvape and Smok are featured, sorted alphabetically
    expect(state.filteredBrands[0].name, 'Geekvape');
    expect(state.filteredBrands[1].name, 'Smok');
  });

  test(
    'sortBrands by Status descending places non-featured brands first',
    () async {
      await cubit.loadBrands();
      cubit.sortBrands(BrandSortField.status, ascending: false);

      final state = cubit.state as BrandLoaded;
      final featuredStatuses = state.filteredBrands
          .map((b) => b.isFeatured)
          .toList();
      expect(featuredStatuses.take(3).every((f) => f == false), true);
      expect(featuredStatuses.skip(3).every((f) => f == true), true);
    },
  );

  test(
    'sortBrands toggles ascending automatically when clicking the same field',
    () async {
      await cubit.loadBrands();
      expect((cubit.state as BrandLoaded).sortField, BrandSortField.sortOrder);
      expect((cubit.state as BrandLoaded).sortAscending, true);

      cubit.sortBrands(BrandSortField.sortOrder);
      expect((cubit.state as BrandLoaded).sortAscending, false);

      cubit.sortBrands(BrandSortField.sortOrder);
      expect((cubit.state as BrandLoaded).sortAscending, true);
    },
  );

  test('filterBrands preserves active sort order', () async {
    await cubit.loadBrands();
    // Sort descending by name
    cubit.sortBrands(BrandSortField.name, ascending: false);

    // Filter with 're' -> Vaporesso, Aspire
    cubit.filterBrands('re');
    final state = cubit.state as BrandLoaded;
    final names = state.filteredBrands.map((b) => b.name).toList();

    // In descending order: Vaporesso before Aspire
    expect(names, ['Vaporesso', 'Aspire']);
  });

  test('sortBrands preserves active query filter', () async {
    await cubit.loadBrands();
    cubit.filterBrands('re'); // Vaporesso (42), Aspire (25)

    // Sort ascending by product count -> Aspire (25), Vaporesso (42)
    cubit.sortBrands(BrandSortField.productsCount, ascending: true);
    final state = cubit.state as BrandLoaded;
    final names = state.filteredBrands.map((b) => b.name).toList();

    expect(names, ['Aspire', 'Vaporesso']);

    // Sort descending by product count -> Vaporesso (42), Aspire (25)
    cubit.sortBrands(BrandSortField.productsCount, ascending: false);
    final stateDesc = cubit.state as BrandLoaded;
    final namesDesc = stateDesc.filteredBrands.map((b) => b.name).toList();

    expect(namesDesc, ['Vaporesso', 'Aspire']);
  });

  test(
    'addBrand auto-assigns next sortOrder at end of list when sortOrder is 0',
    () async {
      await cubit.loadBrands();
      // Initially 5 brands with max sortOrder = 5
      const newBrand = BrandModel(id: 'b6', name: 'Uwell', sortOrder: 0);
      await cubit.addBrand(newBrand);

      final addedInRepo = fakeRepo.brands.firstWhere((b) => b.id == 'b6');
      expect(addedInRepo.sortOrder, 6);
    },
  );

  test('updateBrand preserves existing brand properties', () async {
    await cubit.loadBrands();
    final brandToUpdate = fakeRepo.brands.firstWhere((b) => b.id == 'b1');
    final updated = brandToUpdate.copyWith(name: 'Voopoo Updated');
    await cubit.updateBrand(updated);

    final inRepo = fakeRepo.brands.firstWhere((b) => b.id == 'b1');
    expect(inRepo.name, 'Voopoo Updated');
    expect(inRepo.sortOrder, 3);
  });
}
