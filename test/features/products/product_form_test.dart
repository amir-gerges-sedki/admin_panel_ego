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
      GlobalFlavorsPool.resetForTesting();
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

    test(
      'Selecting Category Type transitions smoothly to Step 1 without hardcoded mock brands',
      () {
        cubit.selectCategoryType(ProductCategoryType.device);
        expect(cubit.state.categoryType, ProductCategoryType.device);
        expect(cubit.state.currentStep, 1);

        cubit.selectCategoryType(ProductCategoryType.liquid);
        expect(cubit.state.categoryType, ProductCategoryType.liquid);
        expect(cubit.state.currentStep, 1);
      },
    );

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

    test(
      'Adding custom flavor dynamically updates available and selected flavors',
      () {
        cubit.initForNewProduct();
        expect(cubit.state.availableFlavors.isEmpty, isTrue);
        cubit.addCustomFlavor('Watermelon Ice');
        expect(cubit.state.availableFlavors.contains('Watermelon Ice'), isTrue);
        expect(cubit.state.selectedFlavors.contains('Watermelon Ice'), isTrue);
        expect(cubit.state.activeFlavor, 'Watermelon Ice');
      },
    );

    test(
      'Generating dynamic variations for Liquid with DL only produces 3mg and 6mg nicotines',
      () {
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
      },
    );

    test(
      'Generating dynamic variations for Liquid with MTL only produces 6mg to 50mg nicotines',
      () {
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
      },
    );

    test(
      'Generating dynamic variations for Liquid with BOTH (MTL & DL) produces correct style-nicotine pairs',
      () {
        cubit.initForNewProduct();
        cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 500, salePrice: 450);
        cubit.addCustomFlavor('Mint');
        cubit.setVapeStyle('BOTH');
        cubit.generateDynamicVariations();

        expect(cubit.state.variations.isNotEmpty, isTrue);
        final mtlVars = cubit.state.variations
            .where((v) => v.attributeValues['Style'] == 'MTL')
            .toList();
        final dlVars = cubit.state.variations
            .where((v) => v.attributeValues['Style'] == 'DL')
            .toList();

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
      },
    );

    test(
      'Generating dynamic variations for Device produces Color variations only (no Wattage attribute)',
      () {
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
      },
    );

    test(
      'Device products do NOT include vapeStyle, style, or duplicate brandName in specifications and toJson',
      () {
        cubit.selectCategoryType(ProductCategoryType.device);
        cubit.updateBasicInfo(
          title: 'Target 200 Mod',
          brandName: 'Vaporesso',
          baseSku: 'T200',
          basePrice: 1600,
          salePrice: 1600,
        );
        cubit.updateDeviceSpecs(maxWattage: '200W', batteryType: 'Dual 18650');
        cubit.addCustomColor('Carbon Black');
        cubit.generateDynamicVariations();

        final product = cubit.buildProductModel();
        expect(product.categoryType, ProductCategoryType.device);
        expect(product.title, 'Target 200 Mod');
        expect(product.productType, 'variable');

        // Verify specifications do NOT contain vapeStyle
        expect(product.specifications.containsKey('vapeStyle'), isFalse);
        expect(product.specifications['maxWattage'], '200W');
        expect(product.specifications['batteryType'], 'Dual 18650');
        expect(
          product.specifications.containsKey('screenType'),
          isFalse,
        ); // empty omitted

        // Verify JSON serialization
        final json = product.toJson();
        expect(json.containsKey('style'), isFalse);
        expect(json.containsKey('vapeStyle'), isFalse);
        expect(json.containsKey('subCategory'), isFalse);
        expect(json.containsKey('liquidOrigin'), isFalse);
        expect(json.containsKey('brandName'), isFalse);
        expect(json['brand'], isA<Map>());
        expect(json['brand']['id'], 'BRAND_VAPORESSO');
        expect(json['brand']['name'], 'Vaporesso');
        expect(json['brand'].containsKey('image'), isFalse);
        expect(json['brand'].containsKey('productsCount'), isFalse);
      },
    );

    test(
      'Setting variation images and bulk applying by color or to all works correctly',
      () {
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
        cubit.applyImageToColorVariations(
          'Blue',
          'https://example.com/blue.png',
        );
        expect(cubit.state.variations[0].image, 'https://example.com/red.png');
        expect(cubit.state.variations[1].image, 'https://example.com/blue.png');

        // Bulk apply to all variations
        cubit.applyImageToAllVariations('https://example.com/universal.png');
        expect(
          cubit.state.variations[0].image,
          'https://example.com/universal.png',
        );
        expect(
          cubit.state.variations[1].image,
          'https://example.com/universal.png',
        );
      },
    );

    test(
      'Saving product persists product in repository with clean specs',
      () async {
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
        expect(
          mockRepo.storedProducts.first.categoryType,
          ProductCategoryType.liquid,
        );
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
      },
    );

    test(
      'Coils & Cartridges generates Resistance-only variations and formats wattage into description',
      () async {
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
        expect(
          cubit.state.description.contains('0.6Ω Mesh (20W - 25W)'),
          isTrue,
        );
        expect(
          cubit.state.description.contains('0.8Ω Mesh (12W - 16W)'),
          isTrue,
        );

        // Generate variations: should ONLY be the 3 resistances when no capacity/fillType selected
        cubit.generateDynamicVariations();
        expect(cubit.state.variations.length, 3);
        expect(cubit.state.variations[0].sku, 'XLIM-R06');
        expect(cubit.state.variations[0].attributeValues, {
          'Resistance': '0.6Ω',
        });
        expect(cubit.state.variations[1].sku, 'XLIM-R08');
        expect(cubit.state.variations[1].attributeValues, {
          'Resistance': '0.8Ω',
        });
        expect(cubit.state.variations[2].sku, 'XLIM-R12');
        expect(cubit.state.variations[2].attributeValues, {
          'Resistance': '1.2Ω',
        });

        // Save and verify Firestore model
        final product = cubit.buildProductModel();
        expect(product.categoryType, ProductCategoryType.pod);
        expect(product.productAttributes.length, 1);
        expect(product.productAttributes.first.name, 'Resistance');
        expect(product.productAttributes.first.values, [
          '0.6Ω',
          '0.8Ω',
          '1.2Ω',
        ]);
        expect(product.specifications['0.6Ω Wattage'], '20W - 25W');
      },
    );

    test(
      'Coils & Cartridges generates multi-dimensional variations with Resistance, Capacity, and Fill Type',
      () {
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
        expect(
          product.productAttributes.any(
            (a) => a.name == 'Resistance' && a.values.length == 2,
          ),
          isTrue,
        );
        expect(
          product.productAttributes.any(
            (a) => a.name == 'Capacity' && a.values.contains('2.0ml'),
          ),
          isTrue,
        );
        expect(
          product.productAttributes.any(
            (a) => a.name == 'FillType' && a.values.contains('Top Fill'),
          ),
          isTrue,
        );
        expect(product.specifications['capacities'], ['2.0ml', '3.0ml']);
        expect(product.specifications['fillTypes'], ['Top Fill', 'Side Fill']);
      },
    );

    test(
      'Liquid origin classification toggles between Local and Premium and persists in specs and variations',
      () {
        cubit.initForNewProduct();
        expect(cubit.state.liquidOrigin, 'Local');

        cubit.setLiquidOrigin('Premium');
        expect(cubit.state.liquidOrigin, 'Premium');

        cubit.updateBasicInfo(brandName: 'Nasty Juice');
        cubit.addCustomFlavor('Mango');
        cubit.generateDynamicVariations();

        expect(
          cubit.state.variations.first.attributeValues.containsKey('Type'),
          isFalse,
        );
        expect(
          cubit.state.variations.first.attributeValues.containsKey('Flavour'),
          isTrue,
        );

        final product = cubit.buildProductModel();
        expect(product.title, '');
        expect(product.categoryType, ProductCategoryType.liquid);
        expect(product.productAttributes.any((a) => a.name == 'Type'), isFalse);
        expect(product.specifications['liquidOrigin'], 'Premium');
        expect(product.specifications.containsKey('liquidType'), isFalse);
        expect(product.specifications.containsKey('type'), isFalse);
        expect(product.specifications['isLocal'], isFalse);

        final json = product.toJson();
        expect(json.containsKey('title'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json['categoryId'], 'CAT_LIQUIDS');
        expect(json['categoryType'], 'Premium Liquid');
        expect(json.containsKey('subCategory'), isFalse);
        expect(json.containsKey('liquidOrigin'), isFalse);
        expect(json.containsKey('style'), isFalse);
        expect(json.containsKey('vapeStyle'), isFalse);
        expect(json.containsKey('category'), isFalse);
        expect(json.containsKey('ProductAttributes'), isFalse);
        expect(json.containsKey('ProductVariations'), isFalse);
        expect(json.containsKey('Images'), isFalse);
        expect(json.containsKey('Thumbnail'), isFalse);
        expect(product.productAttributes.any((a) => a.name == 'Style'), isTrue);

        cubit.setLiquidOrigin('Local');
        cubit.generateDynamicVariations();
        expect(
          cubit.state.variations.first.attributeValues.containsKey('Type'),
          isFalse,
        );
        expect(
          cubit.state.variations.first.attributeValues.containsKey('Flavour'),
          isTrue,
        );

        final localProduct = cubit.buildProductModel();
        expect(localProduct.title, '');
        expect(localProduct.categoryId, 'CAT_LIQUIDS');
        expect(localProduct.specifications['liquidOrigin'], 'Local');
        expect(localProduct.specifications['isLocal'], isTrue);
        expect(
          localProduct.productAttributes.any((a) => a.name == 'Style'),
          isTrue,
        );
        expect(
          localProduct.productAttributes.any((a) => a.name == 'Type'),
          isFalse,
        );

        final localJson = localProduct.toJson();
        expect(localJson.containsKey('title'), isFalse);
        expect(localJson['categoryId'], 'CAT_LIQUIDS');
        expect(localJson['categoryType'], 'Local Liquid');
        expect(localJson.containsKey('subCategory'), isFalse);
        expect(localJson.containsKey('liquidOrigin'), isFalse);
        expect(localJson.containsKey('style'), isFalse);
        expect(localJson.containsKey('vapeStyle'), isFalse);
        expect(localJson.containsKey('category'), isFalse);
        expect(localJson.containsKey('ProductAttributes'), isFalse);
        expect(localJson.containsKey('ProductVariations'), isFalse);
      },
    );

    test('Nicotine pricing equality: 6mg, 9mg, and 12mg have identical prices', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);
      cubit.updateBasicInfo(
        title: 'Equality Test Liquid',
        brandName: 'Nasty',
        basePrice: 500,
      );
      cubit.setVapeStyle('BOTH');
      cubit.emit(cubit.state.copyWith(
        selectedSizes: ['60ml'],
        selectedNicotines: ['3mg', '6mg', '9mg', '12mg', '18mg', '30mg', '50mg'],
      ));
      cubit.addCustomFlavor('Mango');

      cubit.generateDynamicVariations();

      final variations = cubit.state.variations;
      expect(variations.isNotEmpty, isTrue);

      final v3mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '3mg');
      final v6mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '6mg');
      final v9mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '9mg');
      final v12mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '12mg');
      final v18mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '18mg');
      final v30mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '30mg');
      final v50mg = variations.firstWhere((v) => v.attributeValues['Nicotine'] == '50mg');

      // CRITICAL RULE: 6mg, 9mg, and 12mg MUST have the exact same price
      expect(v6mg.salePrice, equals(v9mg.salePrice));
      expect(v9mg.salePrice, equals(v12mg.salePrice));

      // 3mg is lowest base tier
      expect(v3mg.salePrice, lessThan(v6mg.salePrice));

      // 18mg is slightly higher than 12mg
      expect(v18mg.salePrice, greaterThan(v12mg.salePrice));

      // 30mg and 50mg are higher salt nic tiers
      expect(v30mg.salePrice, greaterThan(v18mg.salePrice));
      expect(v50mg.salePrice, greaterThan(v30mg.salePrice));
    });

    test('Dual-checkbox vape style toggle manages MTL and DL simultaneously', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);

      // Default is MTL
      expect(cubit.state.vapeStyle, 'MTL');

      // Toggling DL on enables both MTL & DL ('BOTH')
      cubit.toggleVapeStyleOption('DL');
      expect(cubit.state.vapeStyle, 'BOTH');

      // Toggling off MTL leaves only DL
      cubit.toggleVapeStyleOption('MTL');
      expect(cubit.state.vapeStyle, 'DL');

      // Cannot toggle off the last remaining option (at least one must stay active)
      cubit.toggleVapeStyleOption('DL');
      expect(cubit.state.vapeStyle, 'DL');

      // Toggling MTL back on returns to 'BOTH'
      cubit.toggleVapeStyleOption('MTL');
      expect(cubit.state.vapeStyle, 'BOTH');

      // Toggling DL off returns to 'MTL'
      cubit.toggleVapeStyleOption('DL');
      expect(cubit.state.vapeStyle, 'MTL');
    });

    test('Global flavors pool persists custom flavors across products in the session', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);

      cubit.addCustomFlavor('Blueberry Pomegranate Ice');
      expect(cubit.state.availableFlavors.contains('Blueberry Pomegranate Ice'), isTrue);

      // Create a brand new second product in the same session
      final secondCubit = ProductFormCubit(mockRepo);
      secondCubit.initForNewProduct();
      secondCubit.selectCategoryType(ProductCategoryType.liquid);

      // The second product should immediately have the previously entered custom flavor!
      expect(secondCubit.state.availableFlavors.contains('Blueberry Pomegranate Ice'), isTrue);
    });

    test(
      'applyLiquidTierPrices updates MTL 6/9/12mg uniformly, DL 3mg and DL 6mg independently, and Salt Nic 30/50mg independently',
      () {
        cubit.initForNewProduct();
        cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 400, salePrice: 400, baseStock: 10);
        cubit.setVapeStyle('BOTH');
        cubit.addCustomSize('60ml');
        cubit.addCustomFlavor('Mango');
        cubit.addCustomNicotine('3mg');
        cubit.addCustomNicotine('6mg');
        cubit.addCustomNicotine('9mg');
        cubit.addCustomNicotine('12mg');
        cubit.addCustomNicotine('30mg');
        cubit.addCustomNicotine('50mg');
        cubit.generateDynamicVariations();

        expect(cubit.state.variations.isNotEmpty, isTrue);

        // Apply distinct tier prices
        cubit.applyLiquidTierPrices(
          targetSize: '60ml',
          mtlStandardPrice: 480, // for MTL 6mg, 9mg, 12mg
          dl3mgPrice: 430, // independent DL 3mg
          dl6mgPrice: 460, // independent DL 6mg
          salt30mgPrice: 550, // independent Salt 30mg
          salt50mgPrice: 600, // independent Salt 50mg
        );

        final vars = cubit.state.variations;

        // MTL 6mg, 9mg, 12mg must all be 480
        final mtl6 = vars.firstWhere((v) => v.attributeValues['Style'] == 'MTL' && v.attributeValues['Nicotine'] == '6mg');
        final mtl9 = vars.firstWhere((v) => v.attributeValues['Style'] == 'MTL' && v.attributeValues['Nicotine'] == '9mg');
        final mtl12 = vars.firstWhere((v) => v.attributeValues['Style'] == 'MTL' && v.attributeValues['Nicotine'] == '12mg');
        expect(mtl6.salePrice, 480);
        expect(mtl9.salePrice, 480);
        expect(mtl12.salePrice, 480);

        // DL 3mg must be 430
        final dl3 = vars.firstWhere((v) => v.attributeValues['Style'] == 'DL' && v.attributeValues['Nicotine'] == '3mg');
        expect(dl3.salePrice, 430);

        // DL 6mg must be 460
        final dl6 = vars.firstWhere((v) => v.attributeValues['Style'] == 'DL' && v.attributeValues['Nicotine'] == '6mg');
        expect(dl6.salePrice, 460);

        // Salt Nic 30mg must be 550
        final salt30 = vars.firstWhere((v) => v.attributeValues['Nicotine'] == '30mg');
        expect(salt30.salePrice, 550);

        // Salt Nic 50mg must be 600
        final salt50 = vars.firstWhere((v) => v.attributeValues['Nicotine'] == '50mg');
        expect(salt50.salePrice, 600);
      },
    );

    test(
      'applyLiquidTierPrices updates both basePrice and salePrice independently when sale prices are provided',
      () {
        cubit.initForNewProduct();
        cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 400, salePrice: 400, baseStock: 10);
        cubit.setVapeStyle('BOTH');
        cubit.addCustomSize('60ml');
        cubit.addCustomFlavor('Mango');
        cubit.addCustomNicotine('3mg');
        cubit.addCustomNicotine('6mg');
        cubit.addCustomNicotine('30mg');
        cubit.generateDynamicVariations();

        // Apply distinct base price and sale price
        cubit.applyLiquidTierPrices(
          targetSize: '60ml',
          mtlStandardPrice: 500,
          mtlStandardSalePrice: 450,
          dl3mgPrice: 460,
          dl3mgSalePrice: 420,
          salt30mgPrice: 600,
          salt30mgSalePrice: 540,
        );

        final vars = cubit.state.variations;

        // MTL 6mg: price 500, salePrice 450
        final mtl6 = vars.firstWhere((v) => v.attributeValues['Style'] == 'MTL' && v.attributeValues['Nicotine'] == '6mg');
        expect(mtl6.price, 500);
        expect(mtl6.salePrice, 450);

        // DL 3mg: price 460, salePrice 420
        final dl3 = vars.firstWhere((v) => v.attributeValues['Style'] == 'DL' && v.attributeValues['Nicotine'] == '3mg');
        expect(dl3.price, 460);
        expect(dl3.salePrice, 420);

        // Salt 30mg: price 600, salePrice 540
        final salt30 = vars.firstWhere((v) => v.attributeValues['Nicotine'] == '30mg');
        expect(salt30.price, 600);
        expect(salt30.salePrice, 540);
      },
    );

    test('applyLiquidTierPrices respects targetSize and leaves other sizes intact', () {
      cubit.initForNewProduct();
      cubit.updateBasicInfo(baseSku: 'EGO', basePrice: 400, salePrice: 400, baseStock: 10);
      cubit.setVapeStyle('DL');
      cubit.addCustomSize('30ml');
      cubit.addCustomSize('60ml');
      cubit.addCustomFlavor('Berry');
      cubit.generateDynamicVariations();

      final initial30mlPrice = cubit.state.variations
          .firstWhere((v) => v.attributeValues['Size'] == '30ml' && v.attributeValues['Nicotine'] == '3mg')
          .salePrice;

      // Apply price update ONLY to 60ml
      cubit.applyLiquidTierPrices(
        targetSize: '60ml',
        dl3mgPrice: 520,
        dl6mgPrice: 550,
      );

      // 60ml DL 3mg should be updated to 520
      final var60 = cubit.state.variations
          .firstWhere((v) => v.attributeValues['Size'] == '60ml' && v.attributeValues['Nicotine'] == '3mg');
      expect(var60.salePrice, 520);

      // 30ml DL 3mg should be completely untouched
      final var30 = cubit.state.variations
          .firstWhere((v) => v.attributeValues['Size'] == '30ml' && v.attributeValues['Nicotine'] == '3mg');
      expect(var30.salePrice, initial30mlPrice);
    });

    test('bulkUpdateStock applies stock across all variations', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.device);
      cubit.updateBasicInfo(baseSku: 'MOD', basePrice: 1500, salePrice: 1500, baseStock: 5);
      cubit.addCustomColor('Black');
      cubit.addCustomColor('Silver');
      cubit.addCustomColor('Gold');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.every((v) => v.stock == 5), isTrue);

      cubit.bulkUpdateStock(35);
      expect(cubit.state.variations.every((v) => v.stock == 35), isTrue);
    });

    test('removeLiquidTierVariations excludes non-existent nicotines for a specific bottle size only', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);
      cubit.setVapeStyle('BOTH');
      cubit.addCustomFlavor('Grape');
      cubit.addCustomSize('30ml');
      cubit.addCustomSize('60ml');
      cubit.addCustomSize('100ml');
      cubit.generateDynamicVariations();

      // Verify that 100ml initially has 6mg MTL
      expect(
        cubit.state.variations.any(
          (v) =>
              v.attributeValues['Size'] == '100ml' &&
              v.attributeValues['Style'] == 'MTL' &&
              v.attributeValues['Nicotine'] == '6mg',
        ),
        isTrue,
      );

      // Admin states: 100ml does NOT have 6/9/12mg nicotine in stock -> Exclude tier!
      cubit.removeLiquidTierVariations(targetSize: '100ml', tierKey: 'mtl_standard');

      // 100ml MTL 6mg, 9mg, 12mg must be completely removed from variations
      expect(
        cubit.state.variations.any(
          (v) =>
              v.attributeValues['Size'] == '100ml' &&
              v.attributeValues['Style'] == 'MTL' &&
              (v.attributeValues['Nicotine'] == '6mg' ||
                  v.attributeValues['Nicotine'] == '9mg' ||
                  v.attributeValues['Nicotine'] == '12mg'),
        ),
        isFalse,
      );

      // 30ml and 60ml MTL 6mg must remain completely intact!
      expect(
        cubit.state.variations.any(
          (v) =>
              v.attributeValues['Size'] == '30ml' &&
              v.attributeValues['Style'] == 'MTL' &&
              v.attributeValues['Nicotine'] == '6mg',
        ),
        isTrue,
      );
      expect(
        cubit.state.variations.any(
          (v) =>
              v.attributeValues['Size'] == '60ml' &&
              v.attributeValues['Style'] == 'MTL' &&
              v.attributeValues['Nicotine'] == '6mg',
        ),
        isTrue,
      );
    });

    test('applyLiquidTierPrices supports setting 0.0 EGP and whitespace-insensitive size matching', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);
      cubit.setVapeStyle('DL');
      cubit.addCustomFlavor('Berry');
      cubit.addCustomSize('100ml');
      cubit.generateDynamicVariations();

      // Pass targetSize with different casing and spaces: '100 ML'
      cubit.applyLiquidTierPrices(
        targetSize: '100 ML',
        dl3mgPrice: 0.0, // Explicit 0 price
      );

      final dl3Var = cubit.state.variations.firstWhere(
        (v) => v.attributeValues['Size'] == '100ml' && v.attributeValues['Nicotine'] == '3mg',
      );
      expect(dl3Var.salePrice, 0.0);
      expect(dl3Var.price, 0.0);
    });

    test('buildProductModel automatically aggregates lowest price and total stock from variations for storefront card', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);
      cubit.updateBasicInfo(
        title: 'Tiered Price Test Liquid',
        brandName: 'Nasty Juice',
      );
      cubit.setVapeStyle('DL');
      cubit.addCustomFlavor('Grape');
      cubit.addCustomSize('30ml');
      cubit.addCustomSize('60ml');
      cubit.addCustomSize('100ml');
      cubit.generateDynamicVariations();

      // Apply distinct prices per size
      cubit.applyLiquidTierPrices(
        targetSize: '30ml',
        dl3mgPrice: 350,
      );
      cubit.applyLiquidTierPrices(
        targetSize: '60ml',
        dl3mgPrice: 500,
      );
      cubit.applyLiquidTierPrices(
        targetSize: '100ml',
        dl3mgPrice: 750,
      );

      // Set stocks: 5 per variation
      cubit.bulkUpdateStock(5);

      final product = cubit.buildProductModel();

      // Storefront root price must be the lowest variation price: 350 EGP!
      expect(product.price, 350.0);
      expect(product.salePrice, 0.0);

      // Total stock must be sum of all variations (6 variations * 5 = 30)
      expect(product.stock, cubit.state.variations.length * 5);
    });

    test('buildProductModel resolves discounted lowest variation price accurately', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.device);
      cubit.updateBasicInfo(
        title: 'Device Price Test',
        brandName: 'Voopoo',
      );
      cubit.addCustomColor('Black');
      cubit.addCustomColor('Silver');
      cubit.generateDynamicVariations();

      // Set Black: 1000 EGP regular, 850 EGP sale
      // Set Silver: 1200 EGP regular, 0 EGP sale
      final vars = List<ProductVariationModel>.from(cubit.state.variations);
      vars[0] = vars[0].copyWith(price: 1000, salePrice: 850, stock: 10);
      vars[1] = vars[1].copyWith(price: 1200, salePrice: 0, stock: 15);
      cubit.emit(cubit.state.copyWith(variations: vars));

      final product = cubit.buildProductModel();

      // Lowest effective is Black at 850 (discount from 1000)
      expect(product.price, 1000.0);
      expect(product.salePrice, 850.0);
      expect(product.stock, 25);
    });

    test('Auto-generated SKU uses brand name when baseSku is omitted', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.liquid);
      cubit.updateBasicInfo(
        title: 'Brand SKU Test',
        brandName: 'Riot Squad', // spaces should be stripped
      );
      cubit.setVapeStyle('DL');
      cubit.addCustomFlavor('Mango');
      cubit.addCustomSize('60ml');
      cubit.generateDynamicVariations();

      expect(cubit.state.variations.isNotEmpty, isTrue);
      for (final v in cubit.state.variations) {
        // SKU should start with RIOTSQUAD
        expect(v.sku.startsWith('RIOTSQUAD-'), isTrue);
      }
    });

    test('GlobalFlavorsPool.harvestFromProducts harvests flavors across loaded products into the pool', () {
      GlobalFlavorsPool.resetForTesting();
      expect(GlobalFlavorsPool.flavors.isEmpty, isTrue);

      final mockProduct = ProductModel(
        id: 'P1',
        title: 'Test Liquid',
        description: '',
        price: 300,
        salePrice: 0,
        stock: 10,
        brand: const ProductBrand(id: 'B1', name: 'Brand1'),
        categoryId: 'CAT_LIQUIDS',
        specifications: const {
          'flavors': ['Watermelon Mint', 'Pineapple Coconut'],
        },
        productVariations: const [
          ProductVariationModel(
            id: 'V1',
            sku: 'SKU1',
            price: 300,
            salePrice: 0,
            stock: 5,
            attributeValues: {'Flavour': 'Dragon Fruit'},
          ),
        ],
      );

      GlobalFlavorsPool.harvestFromProducts([mockProduct]);

      final harvested = GlobalFlavorsPool.flavors;
      expect(harvested.contains('Watermelon Mint'), isTrue);
      expect(harvested.contains('Pineapple Coconut'), isTrue);
      expect(harvested.contains('Dragon Fruit'), isTrue);
    });

    test('GlobalDisposableSpecsPool starts empty, sorts numerically, and harvests specs', () {
      GlobalDisposableSpecsPool.resetForTesting();
      expect(GlobalDisposableSpecsPool.puffOptions.isEmpty, isTrue);
      expect(GlobalDisposableSpecsPool.batteryOptions.isEmpty, isTrue);

      // Test numeric sort
      GlobalDisposableSpecsPool.addPuff('12000');
      GlobalDisposableSpecsPool.addPuff('800');
      GlobalDisposableSpecsPool.addPuff('5000');
      GlobalDisposableSpecsPool.addPuff('25000');

      expect(GlobalDisposableSpecsPool.puffOptions, ['800', '5000', '12000', '25000']);

      GlobalDisposableSpecsPool.addBattery('1000mAh');
      GlobalDisposableSpecsPool.addBattery('500mAh');
      GlobalDisposableSpecsPool.addBattery('650mAh');

      expect(GlobalDisposableSpecsPool.batteryOptions, ['500mAh', '650mAh', '1000mAh']);

      // Reset and test harvesting from mock products
      GlobalDisposableSpecsPool.resetForTesting();

      final mockDisposable = ProductModel(
        id: 'D1',
        title: 'ElfBar 5000',
        description: '',
        price: 450,
        salePrice: 0,
        stock: 20,
        brand: const ProductBrand(id: 'B2', name: 'ElfBar'),
        categoryId: 'CAT_DISPOSABLES',
        categoryType: ProductCategoryType.disposable,
        specifications: const {
          'puffs': '5000',
          'batteryCapacity': '650mAh',
        },
        productAttributes: const [
          ProductAttribute(name: 'Puffs', values: ['7000']),
        ],
        productVariations: const [
          ProductVariationModel(
            id: 'VD1',
            sku: 'ELF-9000',
            price: 450,
            salePrice: 0,
            stock: 10,
            attributeValues: {'Puffs': '9000'},
          ),
        ],
      );

      GlobalDisposableSpecsPool.harvestFromProducts([mockDisposable]);

      expect(GlobalDisposableSpecsPool.puffOptions, containsAll(['5000', '7000', '9000']));
      expect(GlobalDisposableSpecsPool.batteryOptions, contains('650mAh'));
    });

    test('Disposable product title resolution auto-resolves flavor for single-flavor and brand for multi-flavor', () {
      // 1. Single Flavor Disposable -> title is flavor name
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.disposable);
      cubit.updateBasicInfo(
        title: '', // User did not input title (field removed)
        brandName: 'Nasty Bar',
      );
      cubit.addCustomFlavor('Mango Ice');
      cubit.updateDisposableSpecs(puffsCount: '8500', batteryCapacity: '500mAh');
      cubit.generateDynamicVariations();

      final singleFlavorProduct = cubit.buildProductModel();
      expect(singleFlavorProduct.title, 'Mango Ice');
      expect(singleFlavorProduct.brand.name, 'Nasty Bar');
      expect(singleFlavorProduct.specifications['puffs'], '8500');

      // 2. Multi-Flavor Disposable -> title is brand name
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.disposable);
      cubit.updateBasicInfo(
        title: '',
        brandName: 'Elf Bar',
      );
      cubit.addCustomFlavor('Blue Razz');
      cubit.addCustomFlavor('Watermelon Ice');
      cubit.updateDisposableSpecs(puffsCount: '10000', batteryCapacity: '650mAh');
      cubit.generateDynamicVariations();

      final multiFlavorProduct = cubit.buildProductModel();
      expect(multiFlavorProduct.title, 'Elf Bar');
      expect(multiFlavorProduct.brand.name, 'Elf Bar');
      expect(multiFlavorProduct.specifications['puffs'], '10000');
    });

    test('ProductModel.displayTitle safely ignores "Untitled Product" and resolves dynamically', () {
      final legacyProduct = ProductModel(
        id: 'LEGACY_1',
        title: 'Untitled Product', // stored in older records
        description: '',
        price: 350,
        salePrice: 0,
        stock: 10,
        brand: const ProductBrand(id: 'B1', name: 'Nasty Juice'),
        categoryId: 'CAT_LIQUIDS',
        categoryType: ProductCategoryType.liquid,
        productAttributes: const [
          ProductAttribute(name: 'Flavour', values: ['Mango Cush Man']),
        ],
      );

      // Must never display "Untitled Product"!
      expect(legacyProduct.displayTitle, 'Mango Cush Man');

      // Deserialization from JSON with Untitled Product strips it cleanly
      final deserialized = ProductModel.fromJson({
        'id': 'LEGACY_2',
        'title': 'Untitled Product',
        'categoryType': 'liquid',
        'brand': {'name': 'Riot Squad'},
        'flavors': ['Cherry Fizz'],
      });
      expect(deserialized.title, '');
      expect(deserialized.displayTitle, 'Cherry Fizz');

      // Hardware with string brand and untitled title resolves to Brand
      final hardwareWithUntitled = ProductModel.fromJson({
        'id': 'LEGACY_3',
        'title': 'Untitled Product',
        'categoryType': 'device',
        'brand': 'Vaporesso',
      });
      expect(hardwareWithUntitled.title, '');
      expect(hardwareWithUntitled.brand.name, 'Vaporesso');
      expect(hardwareWithUntitled.displayTitle, 'Vaporesso');
    });

    test(
      'Disposable variations include Nicotine strengths alongside Flavors and Vaping Style',
      () {
        cubit.initForNewProduct();
        cubit.selectCategoryType(ProductCategoryType.disposable);
        cubit.updateBasicInfo(
          brandName: 'ElfBar',
          basePrice: 400,
          salePrice: 380,
          baseStock: 15,
        );
        cubit.updateDisposableSpecs(puffsCount: '6000', batteryCapacity: '650mAh');
        cubit.addCustomFlavor('Blue Razz Ice');
        cubit.addCustomFlavor('Watermelon Bubblegum');
        cubit.addCustomNicotine('20mg');
        cubit.addCustomNicotine('50mg');
        cubit.setVapeStyle('MTL');

        cubit.generateDynamicVariations();

        // 2 flavors * 2 nicotines * 1 style = 4 variations
        expect(cubit.state.variations.length, 4);

        for (final v in cubit.state.variations) {
          expect(v.attributeValues.containsKey('Flavour'), isTrue);
          expect(v.attributeValues.containsKey('Nicotine'), isTrue);
          expect(v.attributeValues.containsKey('Style'), isTrue);
          expect(v.attributeValues['Style'], 'MTL');
          expect(v.price, 400.0);
          expect(v.salePrice, 380.0);
          expect(v.stock, 15);
        }

        final product = cubit.buildProductModel();
        expect(product.categoryType, ProductCategoryType.disposable);
        expect(
          product.productAttributes.any(
            (a) => a.name == 'Nicotine' && a.values.contains('20mg') && a.values.contains('50mg'),
          ),
          isTrue,
        );
        expect(product.specifications['nicotines'], ['20mg', '50mg']);
        expect(product.specifications['puffs'], '6000');
        expect(product.specifications['batteryCapacity'], '650mAh');
      },
    );

    test(
      'Dynamic variation regeneration preserves custom prices and stocks across flavor additions/changes',
      () {
        cubit.initForNewProduct();
        cubit.selectCategoryType(ProductCategoryType.disposable);
        cubit.updateBasicInfo(brandName: 'Nasty Bar', basePrice: 350);
        cubit.addCustomFlavor('Mango');
        cubit.setVapeStyle('MTL');
        cubit.generateDynamicVariations();

        expect(cubit.state.variations.length, 1);
        expect(cubit.state.variations.first.attributeValues['Flavour'], 'Mango');

        // Admin customizes price and stock for Mango in Step 3
        cubit.updateVariation(
          0,
          cubit.state.variations.first.copyWith(price: 420, salePrice: 390, stock: 99),
        );
        expect(cubit.state.variations.first.price, 420);
        expect(cubit.state.variations.first.stock, 99);

        // Admin returns to Step 2 and adds Peach flavor
        cubit.addCustomFlavor('Peach');

        // Regenerate variations (auto-triggered on Step 2 -> Step 3 transition)
        cubit.generateDynamicVariations();

        expect(cubit.state.variations.length, 2);

        // Mango must retain its customized price 420, salePrice 390, and stock 99!
        final mangoVar = cubit.state.variations.firstWhere(
          (v) => v.attributeValues['Flavour'] == 'Mango',
        );
        expect(mangoVar.price, 420);
        expect(mangoVar.salePrice, 390);
        expect(mangoVar.stock, 99);

        // Peach has base defaults
        final peachVar = cubit.state.variations.firstWhere(
          (v) => v.attributeValues['Flavour'] == 'Peach',
        );
        expect(peachVar.price, 350);
        expect(peachVar.stock, 0);
      },
    );

    test('Accessory color variations generation with SKU and image mapping', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.accessory);
      cubit.updateBasicInfo(
        brandName: 'GeekVape',
        title: '810 Drip Tip',
        basePrice: 150,
      );
      cubit.updateAccessorySpecs(
        category: 'Drip Tips',
        material: 'Resin',
        quantityPerPack: '1 pcs',
      );
      cubit.addCustomColor('Red Resin');
      cubit.addCustomColor('Blue Resin');
      cubit.addCustomColor('Matte Black');

      cubit.setColorImage('Red Resin', 'https://example.com/red.png');

      cubit.generateDynamicVariations();

      final vars = cubit.state.variations;
      expect(vars.length, 3);

      final redVar = vars.firstWhere((v) => v.attributeValues['Color'] == 'Red Resin');
      final blueVar = vars.firstWhere((v) => v.attributeValues['Color'] == 'Blue Resin');
      final blackVar = vars.firstWhere((v) => v.attributeValues['Color'] == 'Matte Black');

      expect(redVar.sku, 'GEEKVAPE-REDRESIN');
      expect(redVar.image, 'https://example.com/red.png');
      expect(redVar.attributeValues['Color'], 'Red Resin');

      expect(blueVar.sku, 'GEEKVAPE-BLUERESIN');
      expect(blueVar.image, isEmpty);

      expect(blackVar.sku, 'GEEKVAPE-MATTEBLACK');

      final product = cubit.buildProductModel();
      expect(product.categoryType, ProductCategoryType.accessory);
      expect(product.productAttributes.any((a) => a.name == 'Color'), isTrue);
      expect(product.specifications['colors'], contains('Red Resin'));
      expect(product.specifications['colorImages']['Red Resin'], 'https://example.com/red.png');

      final json = product.toJson();
      final deserialized = ProductModel.fromJson(json);
      expect(deserialized.categoryType, ProductCategoryType.accessory);
      expect(deserialized.productVariations.length, 3);
      expect(
        deserialized.productVariations.firstWhere((v) => v.attributeValues['Color'] == 'Red Resin').image,
        'https://example.com/red.png',
      );
    });

    test('Accessory fallback standard variation when no colors are selected', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.accessory);
      cubit.updateBasicInfo(
        brandName: 'Vandy Vape',
        title: 'Cotton Bacon',
        basePrice: 120,
      );

      cubit.generateDynamicVariations();

      final vars = cubit.state.variations;
      expect(vars.length, 1);
      expect(vars.first.sku, 'VANDYVAPE-STD');
      expect(vars.first.attributeValues.containsKey('Color'), isFalse);
      expect(vars.first.attributeValues.isEmpty, isTrue);
    });

    test('Accessory generates variations per image when multiple images are uploaded without colors', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.accessory);
      cubit.updateBasicInfo(
        brandName: 'Uwell',
        title: 'Caliburn Lanyard',
        basePrice: 50,
      );
      cubit.setThumbnail('https://example.com/lanyard_black.png');
      cubit.addProductImage('https://example.com/lanyard_red.png');

      cubit.generateDynamicVariations();

      final vars = cubit.state.variations;
      expect(vars.length, 2);
      expect(vars[0].sku, 'UWELL-OPT-1');
      expect(vars[0].image, 'https://example.com/lanyard_black.png');
      expect(vars[0].attributeValues['Option'], 'Option 1');

      expect(vars[1].sku, 'UWELL-OPT-2');
      expect(vars[1].image, 'https://example.com/lanyard_red.png');
      expect(vars[1].attributeValues['Option'], 'Option 2');

      final product = cubit.buildProductModel();
      expect(product.productAttributes.length, 1);
      expect(product.productAttributes.first.name, 'Option');
      expect(product.productAttributes.first.values, ['Option 1', 'Option 2']);
    });

    test('Accessory category switching preserves selectedColors and colorImages', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.device);
      cubit.addCustomColor('Matte Black');
      cubit.setColorImage('Matte Black', 'https://example.com/black.png');

      // Switch to Accessory
      cubit.selectCategoryType(ProductCategoryType.accessory);

      expect(cubit.state.selectedColors, contains('Matte Black'));
      expect(cubit.state.colorImages['Matte Black'], 'https://example.com/black.png');
    });

    test('Compatible products linking persists across state, specs, and model serialization', () {
      cubit.initForNewProduct();
      cubit.selectCategoryType(ProductCategoryType.accessory);
      cubit.updateBasicInfo(
        brandName: 'GeekVape',
        title: 'Replacement Glass Tube',
        basePrice: 90,
      );

      const device1 = ProductModel(
        id: 'PROD_DEV_1',
        title: 'Aegis Legend 2 (L200)',
        description: 'Dual 18650 200W Box Mod',
        price: 2400,
        salePrice: 2200,
        stock: 15,
        brand: ProductBrand(id: 'BR_GV', name: 'GeekVape'),
        categoryId: 'CAT_DEVICES',
        categoryType: ProductCategoryType.device,
      );

      const device2 = ProductModel(
        id: 'PROD_DEV_2',
        title: 'Zeus Sub-Ohm Tank',
        description: '5ml Top Airflow Leakproof Tank',
        price: 950,
        salePrice: 850,
        stock: 20,
        brand: ProductBrand(id: 'BR_GV', name: 'GeekVape'),
        categoryId: 'CAT_POD_SYSTEMS',
        categoryType: ProductCategoryType.pod,
      );

      cubit.setCompatibleProducts([device1, device2]);
      expect(cubit.state.compatibleProductIds, containsAll(['PROD_DEV_1', 'PROD_DEV_2']));
      expect(cubit.state.compatibleProducts.length, 2);

      // Remove device2
      cubit.removeCompatibleProduct('PROD_DEV_2');
      expect(cubit.state.compatibleProductIds, ['PROD_DEV_1']);

      // Add device2 back
      cubit.addCompatibleProduct(device2);
      expect(cubit.state.compatibleProductIds, ['PROD_DEV_1', 'PROD_DEV_2']);

      final product = cubit.buildProductModel();
      expect(product.specifications['compatibleProductIds'], containsAll(['PROD_DEV_1', 'PROD_DEV_2']));
      expect(product.specifications['relatedProductIds'], containsAll(['PROD_DEV_1', 'PROD_DEV_2']));

      final json = product.toJson();
      final deserialized = ProductModel.fromJson(json);
      expect(deserialized.specifications['compatibleProductIds'], containsAll(['PROD_DEV_1', 'PROD_DEV_2']));

      // Re-init cubit for editing deserialized product
      cubit.initForEditProduct(deserialized);
      expect(cubit.state.compatibleProductIds, containsAll(['PROD_DEV_1', 'PROD_DEV_2']));
    });
  });
}

