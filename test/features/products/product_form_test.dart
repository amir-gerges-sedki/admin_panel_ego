import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/products/data/models/product_model.dart';
import 'package:admin_panel_ego/features/products/data/repositories/product_repository.dart';
import 'package:admin_panel_ego/features/products/presentation/cubit/product_form_cubit.dart';

class MockProductRepository implements ProductRepository {
  final List<ProductModel> storedProducts = [];

  @override
  Future<List<ProductModel>> getProducts() async => storedProducts;

  @override
  Future<void> addProduct(ProductModel product) async {
    storedProducts.add(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final index = storedProducts.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      storedProducts[index] = product;
    } else {
      storedProducts.add(product);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    storedProducts.removeWhere((p) => p.id == productId);
  }
}

void main() {
  group('ProductFormCubit & Clean Architecture Flow Tests', () {
    late MockProductRepository mockRepo;
    late ProductFormCubit cubit;

    setUp(() {
      mockRepo = MockProductRepository();
      cubit = ProductFormCubit(mockRepo);
    });

    test('Initial state starts at Step 0 with clean empty state', () {
      cubit.initForNewProduct();
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.categoryType, ProductCategoryType.liquid);
      expect(cubit.state.availableFlavors.isEmpty, isTrue);
      expect(cubit.state.selectedFlavors.isEmpty, isTrue);
      expect(cubit.state.brandName.isEmpty, isTrue);
      expect(cubit.state.isBadgeEnabled, isFalse);
      expect(cubit.state.badgeId.isEmpty, isTrue);
    });

    test('Selecting Category Type transitions smoothly to Step 1 without hardcoded mock brands', () {
      cubit.selectCategoryType(ProductCategoryType.device);
      expect(cubit.state.categoryType, ProductCategoryType.device);
      expect(cubit.state.currentStep, 1);

      cubit.selectCategoryType(ProductCategoryType.liquid);
      expect(cubit.state.categoryType, ProductCategoryType.liquid);
      expect(cubit.state.currentStep, 1);
    });

    test('Homepage Badge handlers toggle and store badgeId reference only', () {
      cubit.initForNewProduct();
      expect(cubit.state.isBadgeEnabled, isFalse);

      cubit.setBadgeEnabled(true);
      expect(cubit.state.isBadgeEnabled, isTrue);

      cubit.setBadgeId('BADGE_HOT_DEAL');
      expect(cubit.state.badgeId, 'BADGE_HOT_DEAL');

      final product = cubit.buildProductModel();
      expect(product.isBadgeEnabled, isTrue);
      expect(product.badgeId, 'BADGE_HOT_DEAL');

      final json = product.toJson();
      expect(json['isBadgeEnabled'], isTrue);
      expect(json['badgeId'], 'BADGE_HOT_DEAL');

      final fromJson = ProductModel.fromJson(json);
      expect(fromJson.isBadgeEnabled, isTrue);
      expect(fromJson.badgeId, 'BADGE_HOT_DEAL');
    });

    test('Adding custom flavor dynamically updates available and selected flavors', () {
      cubit.initForNewProduct();
      expect(cubit.state.availableFlavors.isEmpty, isTrue);
      cubit.addCustomFlavor('Watermelon Ice');
      expect(cubit.state.availableFlavors.contains('Watermelon Ice'), isTrue);
      expect(cubit.state.selectedFlavors.contains('Watermelon Ice'), isTrue);
      expect(cubit.state.activeFlavor, 'Watermelon Ice');
    });

    test('Generating dynamic variations for Liquid with DL only produces 3mg and 6mg nicotines', () {
      cubit.initForNewProduct();
      cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 500, salePrice: 450);
      cubit.addCustomFlavor('Grape');
      cubit.setVapeStyle('DL');
      expect(cubit.state.availableNicotines, ['3mg', '6mg']);
      expect(cubit.state.selectedNicotines, ['3mg', '6mg']);

      cubit.generateDynamicVariations();
      expect(cubit.state.variations.isNotEmpty, isTrue);

      for (final v in cubit.state.variations) {
        expect(v.attributeValues['Style'], 'DL');
        final nic = v.attributeValues['Nicotine'];
        expect(nic == '3mg' || nic == '6mg', isTrue);
      }
    });

    test('Generating dynamic variations for Liquid with MTL only produces 6mg to 50mg nicotines', () {
      cubit.initForNewProduct();
      cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 500, salePrice: 450);
      cubit.addCustomFlavor('Grape');
      cubit.setVapeStyle('MTL');
      expect(cubit.state.availableNicotines.contains('3mg'), isFalse);
      expect(cubit.state.availableNicotines.contains('6mg'), isTrue);
      expect(cubit.state.availableNicotines.contains('50mg'), isTrue);

      cubit.generateDynamicVariations();
      expect(cubit.state.variations.isNotEmpty, isTrue);

      for (final v in cubit.state.variations) {
        expect(v.attributeValues['Style'], 'MTL');
        final nic = v.attributeValues['Nicotine']!;
        expect(nic, isNot('3mg'));
        final val = ProductFormCubit.parseNicotineValue(nic);
        expect(val != null && val >= 6 && val <= 50, isTrue);
      }
    });

    test('Generating dynamic variations for Liquid with BOTH (MTL & DL) produces correct style-nicotine pairs', () {
      cubit.initForNewProduct();
      cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 500, salePrice: 450);
      cubit.addCustomFlavor('Mint');
      cubit.setVapeStyle('BOTH');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.isNotEmpty, isTrue);
      final mtlVars = cubit.state.variations.where((v) => v.attributeValues['Style'] == 'MTL').toList();
      final dlVars = cubit.state.variations.where((v) => v.attributeValues['Style'] == 'DL').toList();

      expect(mtlVars.isNotEmpty, isTrue);
      expect(dlVars.isNotEmpty, isTrue);

      // DL variations only have 3mg or 6mg
      for (final v in dlVars) {
        final nic = v.attributeValues['Nicotine'];
        expect(nic == '3mg' || nic == '6mg', isTrue);
      }

      // MTL variations have 6mg to 50mg and no 3mg
      for (final v in mtlVars) {
        final nic = v.attributeValues['Nicotine']!;
        expect(nic, isNot('3mg'));
        final val = ProductFormCubit.parseNicotineValue(nic);
        expect(val != null && val >= 6 && val <= 50, isTrue);
      }
    });

    test('Generating dynamic variations for Device produces Color variations only (no Wattage attribute)', () {
      cubit.selectCategoryType(ProductCategoryType.device);
      cubit.updateBasicInfo(baseSku: 'MOD', basePrice: 1450, salePrice: 1450);
      cubit.updateDeviceSpecs(maxWattage: '80W');
      cubit.addCustomColor('Black');
      cubit.addCustomColor('Silver');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.isNotEmpty, isTrue);
      for (final v in cubit.state.variations) {
        expect(v.attributeValues.containsKey('Color'), isTrue);
        expect(v.attributeValues.containsKey('Wattage'), isFalse);
        expect(v.sku.startsWith('MOD-'), isTrue);
      }
    });

    test('Setting variation images and bulk applying by color or to all works correctly', () {
      cubit.selectCategoryType(ProductCategoryType.device);
      cubit.updateBasicInfo(baseSku: 'DEV', basePrice: 1000, salePrice: 1000);
      cubit.addCustomColor('Red');
      cubit.addCustomColor('Blue');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.length, 2);

      // Single variation image update
      cubit.setVariationImage(0, 'https://example.com/red.png');
      expect(cubit.state.variations[0].image, 'https://example.com/red.png');
      expect(cubit.state.variations[1].image, '');

      // Bulk apply by color attribute
      cubit.applyImageToColorVariations('Blue', 'https://example.com/blue.png');
      expect(cubit.state.variations[0].image, 'https://example.com/red.png');
      expect(cubit.state.variations[1].image, 'https://example.com/blue.png');

      // Bulk apply to all variations
      cubit.applyImageToAllVariations('https://example.com/universal.png');
      expect(cubit.state.variations[0].image, 'https://example.com/universal.png');
      expect(cubit.state.variations[1].image, 'https://example.com/universal.png');
    });

    test('Saving product persists product in repository with clean specs', () async {
      cubit.initForNewProduct();
      cubit.updateBasicInfo(title: 'E-Liquid 30ml', brandName: 'BrandX');
      cubit.addCustomFlavor('Mango');
      cubit.setBadgeEnabled(true);
      cubit.setBadgeId('BADGE_BEST_SELLER');
      cubit.generateDynamicVariations();

      final success = await cubit.saveProduct();
      expect(success, isTrue);
      expect(mockRepo.storedProducts.length, 1);
      expect(mockRepo.storedProducts.first.title, '');
      expect(mockRepo.storedProducts.first.categoryType, ProductCategoryType.liquid);
      expect(mockRepo.storedProducts.first.isBadgeEnabled, isTrue);
      expect(mockRepo.storedProducts.first.badgeId, 'BADGE_BEST_SELLER');

      // Verify JSON serialization round-trip
      final json = mockRepo.storedProducts.first.toJson();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('name'), isFalse);
      final fromJson = ProductModel.fromJson(json);
      expect(fromJson.title, '');
      expect(fromJson.categoryType, ProductCategoryType.liquid);
      expect(fromJson.isBadgeEnabled, isTrue);
      expect(fromJson.badgeId, 'BADGE_BEST_SELLER');
    });

    test('Coils & Cartridges generates Resistance-only variations and formats wattage into description', () async {
      cubit.selectCategoryType(ProductCategoryType.pod);
      cubit.updateBasicInfo(
        title: 'XLIM V3 Top-Fill Cartridge',
        baseSku: 'XLIM',
        basePrice: 150,
        salePrice: 150,
        description: 'Original replacement pods with anti-leak design.',
      );
      cubit.updatePodSpecs(compatibleDevices: 'OXVA XLIM Pro, SQ Pro, SE');
      cubit.togglePodResistance('0.6Ω');
      cubit.togglePodResistance('0.8Ω');
      cubit.togglePodResistance('1.2Ω');
      cubit.updatePodResistanceWattage('0.6Ω', '20W - 25W');

      // Check suggested and customized wattages
      expect(cubit.state.podResistanceWattages['0.6Ω'], '20W - 25W');
      expect(cubit.state.podResistanceWattages['0.8Ω'], '12W - 16W');

      // Auto format wattage into description
      cubit.autoFormatWattageIntoDescription();
      expect(cubit.state.description.contains('Recommended Wattage'), isTrue);
      expect(cubit.state.description.contains('0.6Ω Mesh (20W - 25W)'), isTrue);
      expect(cubit.state.description.contains('0.8Ω Mesh (12W - 16W)'), isTrue);

      // Generate variations: should ONLY be the 3 resistances when no capacity/fillType selected
      cubit.generateDynamicVariations();
      expect(cubit.state.variations.length, 3);
      expect(cubit.state.variations[0].sku, 'XLIM-R06');
      expect(cubit.state.variations[0].attributeValues, {'Resistance': '0.6Ω'});
      expect(cubit.state.variations[1].sku, 'XLIM-R08');
      expect(cubit.state.variations[1].attributeValues, {'Resistance': '0.8Ω'});
      expect(cubit.state.variations[2].sku, 'XLIM-R12');
      expect(cubit.state.variations[2].attributeValues, {'Resistance': '1.2Ω'});

      // Save and verify Firestore model
      final product = cubit.buildProductModel();
      expect(product.categoryType, ProductCategoryType.pod);
      expect(product.productAttributes.length, 1);
      expect(product.productAttributes.first.name, 'Resistance');
      expect(product.productAttributes.first.values, ['0.6Ω', '0.8Ω', '1.2Ω']);
      expect(product.specifications['0.6Ω Wattage'], '20W - 25W');
    });

    test('Coils & Cartridges generates multi-dimensional variations with Resistance, Capacity, and Fill Type', () {
      cubit.selectCategoryType(ProductCategoryType.pod);
      cubit.updateBasicInfo(
        title: 'XLIM Pod Cartridge',
        baseSku: 'XLIM',
        basePrice: 150,
        salePrice: 150,
      );
      cubit.togglePodResistance('0.6Ω');
      cubit.togglePodResistance('0.8Ω');
      cubit.togglePodCapacity('2.0ml');
      cubit.togglePodCapacity('3.0ml');
      cubit.togglePodFillType('Top Fill');
      cubit.togglePodFillType('Side Fill');

      // 2 resistances * 2 capacities * 2 fillTypes = 8 variations
      cubit.generateDynamicVariations();
      expect(cubit.state.variations.length, 8);

      for (final v in cubit.state.variations) {
        expect(v.attributeValues.containsKey('Resistance'), isTrue);
        expect(v.attributeValues.containsKey('Capacity'), isTrue);
        expect(v.attributeValues.containsKey('FillType'), isTrue);
      }

      expect(cubit.state.variations[0].sku, 'XLIM-R06-20ML-TOP');
      expect(cubit.state.variations[0].attributeValues, {
        'Resistance': '0.6Ω',
        'Capacity': '2.0ml',
        'FillType': 'Top Fill',
      });

      // Build model and verify product attributes and specifications
      final product = cubit.buildProductModel();
      expect(product.categoryType, ProductCategoryType.pod);
      expect(product.productAttributes.length, 3);
      expect(product.productAttributes.any((a) => a.name == 'Resistance' && a.values.length == 2), isTrue);
      expect(product.productAttributes.any((a) => a.name == 'Capacity' && a.values.contains('2.0ml')), isTrue);
      expect(product.productAttributes.any((a) => a.name == 'FillType' && a.values.contains('Top Fill')), isTrue);
      expect(product.specifications['capacities'], ['2.0ml', '3.0ml']);
      expect(product.specifications['fillTypes'], ['Top Fill', 'Side Fill']);
    });


    test('Liquid origin classification toggles between Local and Premium and persists in specs and variations', () {
      cubit.initForNewProduct();
      expect(cubit.state.liquidOrigin, 'Local');

      cubit.setLiquidOrigin('Premium');
      expect(cubit.state.liquidOrigin, 'Premium');

      cubit.updateBasicInfo(brandName: 'Nasty Juice');
      cubit.addCustomFlavor('Mango');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.first.attributeValues['Type'], 'Premium');

      final product = cubit.buildProductModel();
      expect(product.title, '');
      expect(product.categoryType, ProductCategoryType.liquid);
      expect(product.productAttributes.any((a) => a.name == 'Type' && a.values.contains('Premium Liquid')), isTrue);
      expect(product.specifications['liquidOrigin'], 'Premium');
      expect(product.specifications['liquidType'], 'Premium');
      expect(product.specifications['isLocal'], isFalse);

      final json = product.toJson();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('name'), isFalse);
      expect(json['category'], 'Premium Liquid');

      cubit.setLiquidOrigin('Local');
      cubit.generateDynamicVariations();
      expect(cubit.state.variations.first.attributeValues['Type'], 'Local');

      final localProduct = cubit.buildProductModel();
      expect(localProduct.title, '');
      expect(localProduct.specifications['liquidOrigin'], 'Local');
      expect(localProduct.specifications['isLocal'], isTrue);

      final localJson = localProduct.toJson();
      expect(localJson.containsKey('title'), isFalse);
      expect(localJson['category'], 'Local Liquid');
    });
  });
}
