import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/variation_matrix_engine.dart';
import 'product_form_state.dart';

export 'product_form_state.dart';

/// Global memory pool of liquid flavors that persists across products during the admin session.
/// Populated ONLY from products existing in Firestore and user entries.
class GlobalFlavorsPool {
  GlobalFlavorsPool._();

  static final Set<String> _flavors = <String>{};

  static List<String> get flavors => _flavors.toList()..sort();

  static void addFlavor(String flavor) {
    final clean = flavor.trim();
    if (clean.isNotEmpty) {
      _flavors.add(clean);
    }
  }

  static void addFlavors(Iterable<String> newFlavors) {
    for (final f in newFlavors) {
      addFlavor(f);
    }
  }

  /// Automatically harvests flavors from all loaded catalog products in Firestore.
  static void harvestFromProducts(Iterable<ProductModel> products) {
    for (final p in products) {
      if (p.flavors.isNotEmpty) {
        addFlavors(p.flavors);
      }
      final specFlavors = (p.specifications['flavors'] as List<dynamic>?)
          ?.map((e) => e.toString());
      if (specFlavors != null) {
        addFlavors(specFlavors);
      }
      for (final v in p.productVariations) {
        final f = v.attributeValues['Flavour'] ??
            v.attributeValues['flavor'] ??
            v.attributeValues['Flavor'];
        if (f != null && f.trim().isNotEmpty) {
          addFlavor(f);
        }
      }
    }
  }

  static void resetForTesting() {
    _flavors.clear();
  }
}

/// Global session-persistent pool for device hardware spec options.
/// Works exactly like [GlobalFlavorsPool] — options added during one product
/// creation survive to the next product, and the pool is seeded automatically
/// from existing Firestore products when loaded.
class GlobalDeviceSpecsPool {
  GlobalDeviceSpecsPool._();

  // All collections start EMPTY.
  // Values come exclusively from:
  //   1. Firestore products harvested on session start (harvestFromProducts)
  //   2. Values the admin manually adds via Quick-Add dialogs during this session

  // --- Wattage ---
  static final Set<String> _wattageOptions = {};
  static List<String> get wattageOptions =>
      (_wattageOptions.toList()..sort(_numericSort));
  static void addWattage(String v) {
    final c = v.trim();
    if (c.isNotEmpty) _wattageOptions.add(c);
  }

  // --- Battery Capacity ---
  static final Set<String> _batteryCapacities = {};
  static List<String> get batteryCapacities =>
      (_batteryCapacities.toList()..sort(_mAhSort));
  static void addBatteryCapacity(String v) {
    final c = v.trim();
    if (c.isNotEmpty) _batteryCapacities.add(c);
  }

  // --- Battery System ---
  static final Map<String, String> _batterySystems = {};
  static Map<String, String> get batterySystems =>
      Map<String, String>.from(_batterySystems);
  static void addBatterySystem(String key, String label) {
    if (key.trim().isNotEmpty) _batterySystems[key.trim()] = label.trim();
  }

  // --- Charging Port ---
  static final Map<String, String> _chargingPorts = {};
  static Map<String, String> get chargingPorts =>
      Map<String, String>.from(_chargingPorts);
  static void addChargingPort(String key, String label) {
    if (key.trim().isNotEmpty) _chargingPorts[key.trim()] = label.trim();
  }

  // --- Screen Type ---
  static final Map<String, String> _screenTypes = {};
  static Map<String, String> get screenTypes =>
      Map<String, String>.from(_screenTypes);
  static void addScreenType(String key, String label) {
    if (key.trim().isNotEmpty) _screenTypes[key.trim()] = label.trim();
  }

  // --- Airflow ---
  static final Map<String, String> _airflowTypes = {};
  static Map<String, String> get airflowTypes =>
      Map<String, String>.from(_airflowTypes);
  static void addAirflowType(String key, String label) {
    if (key.trim().isNotEmpty) _airflowTypes[key.trim()] = label.trim();
  }

  /// Harvest device spec values from existing Firestore products into the pool.
  static void harvestFromProducts(Iterable<ProductModel> products) {
    for (final p in products) {
      if (p.categoryType != ProductCategoryType.device) continue;
      final specs = p.specifications;
      final w = specs['maxWattage']?.toString() ?? '';
      if (w.isNotEmpty) addWattage(w);
      final bc = specs['batteryCapacity']?.toString() ?? '';
      if (bc.isNotEmpty) addBatteryCapacity(bc);
      final bt = specs['batteryType']?.toString() ?? '';
      if (bt.isNotEmpty) addBatterySystem(bt, bt);
      final cp = specs['chargingPort']?.toString() ?? '';
      if (cp.isNotEmpty) addChargingPort(cp, cp);
      final st = specs['screenType']?.toString() ?? '';
      if (st.isNotEmpty) addScreenType(st, st);
      final af = specs['airflowType']?.toString() ?? '';
      if (af.isNotEmpty) addAirflowType(af, af);
    }
  }

  // Sort helpers — numeric ascending (e.g. 15W < 80W < 200W)
  static int _numericSort(String a, String b) {
    final numA = double.tryParse(a.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    final numB = double.tryParse(b.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    return numA.compareTo(numB);
  }

  static int _mAhSort(String a, String b) {
    if (a.toLowerCase().startsWith('external')) return 1;
    if (b.toLowerCase().startsWith('external')) return -1;
    return _numericSort(a, b);
  }

  static void resetForTesting() {
    _wattageOptions.clear();
    _batteryCapacities.clear();
    _batterySystems.clear();
    _chargingPorts.clear();
    _screenTypes.clear();
    _airflowTypes.clear();
  }
}

/// Global session-persistent pool for disposable vape spec options (Puffs & Battery Capacity).
/// Works exactly like [GlobalFlavorsPool] and [GlobalDeviceSpecsPool].
/// Starts completely EMPTY (no hardcoded presets).
/// Populated exclusively from:
///   1. Firestore products harvested on session start (harvestFromProducts)
///   2. Values the admin manually inputs / saves during this session
class GlobalDisposableSpecsPool {
  GlobalDisposableSpecsPool._();

  static final Set<String> _puffOptions = <String>{};
  static final Set<String> _batteryOptions = <String>{};

  static List<String> get puffOptions =>
      (_puffOptions.toList()..sort(_numericSort));

  static List<String> get batteryOptions =>
      (_batteryOptions.toList()..sort(_numericSort));

  static void addPuff(String val) {
    final c = val.trim();
    if (c.isNotEmpty) {
      _puffOptions.add(c);
    }
  }

  static void addPuffs(Iterable<String> vals) {
    for (final v in vals) {
      addPuff(v);
    }
  }

  static void addBattery(String val) {
    final c = val.trim();
    if (c.isNotEmpty) {
      _batteryOptions.add(c);
    }
  }

  static void addBatteries(Iterable<String> vals) {
    for (final v in vals) {
      addBattery(v);
    }
  }

  /// Harvests puffs and battery capacity from existing products into the pool.
  static void harvestFromProducts(Iterable<ProductModel> products) {
    for (final p in products) {
      final specs = p.specifications;
      final puffVal = specs['puffs']?.toString() ??
          specs['puffsCount']?.toString() ??
          specs['numberOfPuffs']?.toString() ??
          '';
      if (puffVal.isNotEmpty) {
        addPuff(puffVal);
      }

      // Check product attributes
      for (final attr in p.productAttributes) {
        final name = attr.name.toLowerCase();
        if (name.contains('puff')) {
          addPuffs(attr.values);
        }
        if (name.contains('battery') &&
            p.categoryType == ProductCategoryType.disposable) {
          addBatteries(attr.values);
        }
      }

      // Check variations
      for (final v in p.productVariations) {
        final pVal = v.attributeValues['Puffs'] ??
            v.attributeValues['puffs'] ??
            v.attributeValues['Puff'];
        if (pVal != null && pVal.trim().isNotEmpty) {
          addPuff(pVal);
        }
      }

      final isDisposable = p.categoryType == ProductCategoryType.disposable ||
          specs['categoryType']?.toString().toLowerCase() == 'disposable' ||
          p.categoryId.toLowerCase().contains('disp') ||
          puffVal.isNotEmpty;

      // Battery specs for disposable
      if (isDisposable) {
        final batVal = specs['batteryCapacity']?.toString() ??
            specs['battery']?.toString() ??
            '';
        if (batVal.isNotEmpty) {
          addBattery(batVal);
        }
      }
    }
  }

  static int _numericSort(String a, String b) {
    final numA = double.tryParse(a.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    final numB = double.tryParse(b.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    if (numA != numB) {
      return numA.compareTo(numB);
    }
    return a.compareTo(b);
  }

  static void resetForTesting() {
    _puffOptions.clear();
    _batteryOptions.clear();
  }
}

class ProductFormCubit extends Cubit<ProductFormState> {
  final ProductRepository productRepository;

  ProductFormCubit(this.productRepository) : super(const ProductFormState());

  void initForNewProduct([ProductCategoryType? initialType]) {
    final generatedId = 'PROD_${DateTime.now().millisecondsSinceEpoch}';
    emit(
      ProductFormState(
        initialProductId: generatedId,
        categoryType: initialType ?? ProductCategoryType.liquid,
        currentStep: 0,
        isEditMode: false,
        isBadgeEnabled: false,
        badgeId: '',
        availableFlavors: GlobalFlavorsPool.flavors,
      ),
    );

    // Harvest from Firestore whenever either flavor, device, or disposable spec pools are empty
    if (GlobalFlavorsPool.flavors.isEmpty ||
        GlobalDeviceSpecsPool.wattageOptions.isEmpty ||
        GlobalDisposableSpecsPool.puffOptions.isEmpty) {
      loadFlavorsFromFirestore();
    }
  }

  Future<void> loadFlavorsFromFirestore() async {
    try {
      final products = await productRepository.getProducts();
      GlobalFlavorsPool.harvestFromProducts(products);
      GlobalDeviceSpecsPool.harvestFromProducts(products);
      GlobalDisposableSpecsPool.harvestFromProducts(products);
      if (state.categoryType == ProductCategoryType.liquid ||
          state.categoryType == ProductCategoryType.disposable) {
        emit(
          state.copyWith(
            availableFlavors: _resolveAvailableFlavors(state.selectedFlavors),
          ),
        );
      }
    } catch (_) {}
  }

  void initForEditProduct(ProductModel product) {
    final specs = product.specifications;
    final flavsFromAttrs = product.productAttributes
        .firstWhere(
          (a) => a.name.toLowerCase().contains('flav'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final flavsFromVars = product.productVariations
        .map((v) =>
            v.attributeValues['Flavour'] ??
            v.attributeValues['flavor'] ??
            v.attributeValues['Flavor'])
        .where((f) => f != null && f.isNotEmpty)
        .cast<String>()
        .toList();
    final flavs = {
      ...product.flavors,
      ...(specs['flavors'] as List<dynamic>? ?? []).map((e) => e.toString()),
      ...flavsFromAttrs,
      ...flavsFromVars,
    }.where((f) => f.trim().isNotEmpty).toList();

    final activeFlav = flavs.isNotEmpty ? flavs.first : '';

    // Extract colors from attributes, specs, or variations
    final colorsFromAttrs = product.productAttributes
        .firstWhere(
          (a) => a.name.toLowerCase().contains('color'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final colorsFromSpecs =
        (specs['colors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final colorsFromVars = product.productVariations
        .map((v) => v.attributeValues['Color'] ?? v.attributeValues['color'])
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();
    final allColors = {
      ...colorsFromAttrs,
      ...colorsFromSpecs,
      ...colorsFromVars,
    }.toList();

    // Extract colorImages from specifications or variations
    final Map<String, String> extractedColorImages = {};
    if (specs['colorImages'] is Map) {
      (specs['colorImages'] as Map).forEach((k, v) {
        if (k != null && v != null && v.toString().trim().isNotEmpty) {
          extractedColorImages[k.toString().trim()] = v.toString().trim();
        }
      });
    }
    for (final v in product.productVariations) {
      final color = v.attributeValues['Color'] ?? v.attributeValues['color'];
      if (color != null && color.isNotEmpty && v.image.trim().isNotEmpty) {
        extractedColorImages[color] ??= v.image.trim();
      }
    }

    // Extract nicotines and sizes
    final nicsFromAttrs = product.productAttributes
        .firstWhere(
          (a) => a.name.toLowerCase().contains('nic'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final nicsFromSpecs =
        (specs['nicotines'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final nicsFromVars = product.productVariations
        .map((v) =>
            v.attributeValues['Nicotine'] ??
            v.attributeValues['nicotine'] ??
            v.attributeValues['Nic'])
        .where((n) => n != null && n.isNotEmpty)
        .cast<String>()
        .toList();
    final allNics = {
      ...nicsFromAttrs,
      ...nicsFromSpecs,
      ...nicsFromVars,
    }.where((n) => n.trim().isNotEmpty).toList();

    final sizesFromAttrs = product.productAttributes
        .firstWhere(
          (a) => a.name.toLowerCase().contains('size'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final sizesFromSpecs =
        (specs['sizes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    final allSizes = {...sizesFromAttrs, ...sizesFromSpecs}.toList();

    final resFromSpecs =
        (specs['resistances'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final packFromSpecs =
        (specs['packSizes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    // Extract resistances & wattage mappings
    final resFromAttrs = product.productAttributes
        .firstWhere(
          (a) =>
              a.name.toLowerCase().contains('res') ||
              a.name.toLowerCase().contains('ohm'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final resFromVars = product.productVariations
        .map(
          (v) =>
              v.attributeValues['Resistance'] ??
              v.attributeValues['resistance'],
        )
        .where((r) => r != null && r.isNotEmpty)
        .cast<String>()
        .toList();
    final List<String> allResistances = {
      ...resFromAttrs,
      ...resFromSpecs,
      ...resFromVars,
    }.cast<String>().toList();

    final Map<String, String> extractedWattages = {};
    for (final res in allResistances) {
      final key1 = '$res Wattage';
      final key2 = '${res}Wattage';
      final key3 = '$res Recommended Wattage';
      final found = specs[key1] ?? specs[key2] ?? specs[key3];
      if (found != null && found.toString().isNotEmpty) {
        extractedWattages[res] = found.toString();
      } else {
        extractedWattages[res] = getSuggestedWattage(res);
      }
    }

    // Extract capacities
    final capFromAttrs = product.productAttributes
        .firstWhere(
          (a) =>
              a.name.toLowerCase().contains('cap') ||
              a.name.toLowerCase().contains('سعة'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final capFromSpecs = (specs['capacities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final capFromVars = product.productVariations
        .map((v) => v.attributeValues['Capacity'] ?? v.attributeValues['capacity'])
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();
    final allCapacities = {
      ...capFromAttrs,
      ...capFromSpecs,
      ...capFromVars,
    }.toList();

    // Extract fill types
    final fillFromAttrs = product.productAttributes
        .firstWhere(
          (a) =>
              a.name.toLowerCase().contains('fill') ||
              a.name.toLowerCase().contains('ملء'),
          orElse: () => const ProductAttribute(name: '', values: []),
        )
        .values;
    final fillFromSpecs = (specs['fillTypes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final fillFromVars = product.productVariations
        .map((v) =>
            v.attributeValues['FillType'] ??
            v.attributeValues['fillType'] ??
            v.attributeValues['Fill'] ??
            v.attributeValues['fill'])
        .where((f) => f != null && f.isNotEmpty)
        .cast<String>()
        .toList();
    final allFillTypes = {
      ...fillFromAttrs,
      ...fillFromSpecs,
      ...fillFromVars,
    }.toList();

    final List<String> availCaps = {
      ...const ['2.0ml', '3.0ml', '4.0ml', '4.5ml', '5.0ml'],
      ...allCapacities,
    }.cast<String>().toList();

    final List<String> availFills = {
      ...const ['Top Fill', 'Side Fill', 'Bottom Fill'],
      ...allFillTypes,
    }.cast<String>().toList();

    final List<String> availRes = {
      ...const [
        '0.15Ω',
        '0.2Ω',
        '0.3Ω',
        '0.4Ω',
        '0.6Ω',
        '0.7Ω',
        '0.8Ω',
        '1.0Ω',
        '1.2Ω',
      ],
      ...allResistances,
    }.cast<String>().toList();

    final List<String> availColors = List<String>.from(allColors);

    final List<String> extractedCompatIds = [];
    final rawCompat = specs['compatibleProductIds'] ??
        specs['relatedProductIds'] ??
        specs['compatibleProducts'];
    if (rawCompat is List) {
      for (final id in rawCompat) {
        if (id != null && id.toString().trim().isNotEmpty) {
          extractedCompatIds.add(id.toString().trim());
        }
      }
    }

    emit(
      ProductFormState(
        currentStep: 1, // Jump directly to Specs form
        isEditMode: true,
        initialProductId: product.id,
        categoryType: product.categoryType,
        title: product.title.toLowerCase().contains('untitled') ? '' : product.title,
        description: product.description,
        brandId: product.brand.id,
        brandName: product.brand.name,
        basePrice: product.price,
        salePrice: product.salePrice,
        baseCostPrice: product.costPrice,
        baseStock: product.stock,
        baseSku: product.productVariations.isNotEmpty
            ? product.productVariations.first.sku.split('-').first
            : '',
        thumbnail: product.thumbnail,
        images: product.images,
        isBadgeEnabled: product.isBadgeEnabled,
        badgeId: product.badgeId,
        isOnline: product.isOnline,
        variations: product.productVariations,
        liquidOrigin: specs['liquidOrigin']?.toString() ??
            (specs['isLocal'] == true
                ? 'Local'
                : (specs['isLocal'] == false ? 'Premium' : 'Local')),
        availableFlavors: () {
          GlobalFlavorsPool.addFlavors(flavs);
          return (Set<String>.from(GlobalFlavorsPool.flavors)..addAll(flavs)).toList()..sort();
        }(),
        selectedFlavors: flavs,
        activeFlavor: activeFlav,
        vapeStyle: specs['vapeStyle']?.toString() ?? 'MTL',
        availableNicotines: allNics.isNotEmpty
            ? allNics
            : (specs['vapeStyle'] == 'DL'
                  ? const ['3mg', '6mg']
                  : const ['20mg', '25mg', '30mg', '50mg']),
        selectedNicotines: allNics,
        selectedSizes: allSizes,
        availableColors: availColors,
        selectedColors: allColors,
        colorImages: extractedColorImages,
        maxWattage: specs['maxWattage']?.toString() ?? '',
        batteryType: specs['batteryType']?.toString() ?? 'Built-in Battery',
        batteryCapacity: specs['batteryCapacity']?.toString() ?? '',
        chargingPort: specs['chargingPort']?.toString() ?? '',
        screenType: specs['screenType']?.toString() ?? '',
        airflowType: specs['airflowType']?.toString() ?? '',
        podCompatibleDevices:
            specs['compatibleDevices']?.toString() ??
            specs['compatibleTanks']?.toString() ??
            '',
        podCapacity: specs['capacity']?.toString() ?? '',
        availablePodCapacities: availCaps,
        selectedPodCapacities: allCapacities,
        availablePodFillTypes: availFills,
        selectedPodFillTypes: allFillTypes,
        availablePodResistances: availRes,
        selectedPodResistances: allResistances,
        podResistanceWattages: extractedWattages,
        selectedPodPackSizes: packFromSpecs,
        coilCompatibleTanks: specs['compatibleTanks']?.toString() ?? '',
        wireMaterial: specs['wireMaterial']?.toString() ?? '',
        recommendedWattage: specs['recommendedWattage']?.toString() ?? '',
        availableCoilResistances: availRes,
        selectedCoilResistances: allResistances,
        selectedCoilPackSizes: packFromSpecs,
        accessoryCategory: specs['accessoryCategory']?.toString() ?? '',
        accessoryCompatibility:
            specs['accessoryCompatibility']?.toString() ?? '',
        accessoryMaterial: specs['accessoryMaterial']?.toString() ?? '',
        puffsCount: specs['puffs']?.toString() ??
            specs['puffsCount']?.toString() ??
            specs['numberOfPuffs']?.toString() ??
            '',
        disposableBatteryCapacity: specs['batteryCapacity']?.toString() ?? '',
        compatibleProductIds: extractedCompatIds,
      ),
    );

    // Feed this product's custom device & disposable spec values back into the shared pools
    GlobalDeviceSpecsPool.harvestFromProducts([product]);
    GlobalDisposableSpecsPool.harvestFromProducts([product]);
  }

  // Step Navigation
  void setStep(int step) {
    if (step >= 0 && step <= 3) {
      emit(state.copyWith(currentStep: step));
    }
  }

  void nextStep() {
    if (state.currentStep < 3) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  static List<String> _resolveAvailableFlavors([List<String> currentSelected = const []]) {
    final set = Set<String>.from(GlobalFlavorsPool.flavors)..addAll(currentSelected);
    final list = set.toList()..sort();
    return list;
  }

  void selectCategoryType(ProductCategoryType type) {
    final isFlavorCategory =
        type == ProductCategoryType.liquid || type == ProductCategoryType.disposable;
    emit(
      state.copyWith(
        categoryType: type,
        currentStep: 1, // Advance to step 2 (Specs)
        selectedFlavors: isFlavorCategory
            ? state.selectedFlavors
            : const [],
        availableFlavors: isFlavorCategory
            ? _resolveAvailableFlavors(state.selectedFlavors)
            : const [],
        selectedNicotines: (type == ProductCategoryType.liquid ||
                type == ProductCategoryType.disposable)
            ? state.selectedNicotines
            : const [],
        selectedSizes: type == ProductCategoryType.liquid
            ? state.selectedSizes
            : const [],
        selectedColors: (type == ProductCategoryType.device ||
                type == ProductCategoryType.accessory)
            ? state.selectedColors
            : const [],
        colorImages: (type == ProductCategoryType.device ||
                type == ProductCategoryType.accessory)
            ? state.colorImages
            : const {},
        selectedPodResistances: type == ProductCategoryType.pod
            ? state.selectedPodResistances
            : const [],
        selectedCoilResistances: type == ProductCategoryType.coil
            ? state.selectedCoilResistances
            : const [],
      ),
    );
  }

  void updateDisposableSpecs({
    String? puffsCount,
    String? batteryCapacity,
    String? vapeStyle,
  }) {
    emit(
      state.copyWith(
        puffsCount: puffsCount,
        disposableBatteryCapacity: batteryCapacity,
        vapeStyle: vapeStyle,
      ),
    );
  }

  // Basic Info setters
  void updateBasicInfo({
    String? title,
    String? description,
    String? brandId,
    String? brandName,
    double? basePrice,
    double? salePrice,
    double? baseCostPrice,
    int? baseStock,
    String? baseSku,
    String? thumbnail,
    List<String>? images,
    bool? isBadgeEnabled,
    String? badgeId,
    bool? isOnline,
  }) {
    List<String>? updatedImages =
        images != null ? List<String>.from(images) : List<String>.from(state.images);
    if (thumbnail != null) {
      final oldThumb = state.thumbnail.trim();
      final newThumb = thumbnail.trim();
      if (oldThumb.isNotEmpty && newThumb != oldThumb) {
        updatedImages.removeWhere((img) => img.trim() == oldThumb);
      }
      if (newThumb.isNotEmpty && !updatedImages.contains(newThumb)) {
        updatedImages.insert(0, newThumb);
      }
    }

    emit(
      state.copyWith(
        title: title,
        description: description,
        brandId: brandId,
        brandName: brandName,
        basePrice: basePrice,
        salePrice: salePrice,
        baseCostPrice: baseCostPrice,
        baseStock: baseStock,
        baseSku: baseSku,
        thumbnail: thumbnail,
        images: updatedImages,
        isBadgeEnabled: isBadgeEnabled,
        badgeId: badgeId,
        isOnline: isOnline,
      ),
    );
  }

  void setIsOnline(bool isOnline) {
    emit(state.copyWith(isOnline: isOnline));
  }

  void setThumbnail(String url) {
    final clean = url.trim();
    final oldThumb = state.thumbnail.trim();
    final updatedImages = List<String>.from(state.images);
    if (oldThumb.isNotEmpty && clean != oldThumb) {
      updatedImages.removeWhere((img) => img.trim() == oldThumb);
    }
    if (clean.isNotEmpty && !updatedImages.contains(clean)) {
      updatedImages.insert(0, clean);
    }
    emit(state.copyWith(thumbnail: clean, images: updatedImages));
  }

  void addProductImage(String url) {
    final clean = url.trim();
    if (clean.isNotEmpty && !state.images.contains(clean)) {
      final list = List<String>.from(state.images)..add(clean);
      emit(state.copyWith(images: list));
    }
  }

  void removeProductImage(int index) {
    if (index >= 0 && index < state.images.length) {
      final removed = state.images[index];
      final list = List<String>.from(state.images)..removeAt(index);
      final newColorImages = Map<String, String>.from(state.colorImages)
        ..removeWhere((k, v) => v == removed);
      final newThumb = state.thumbnail == removed
          ? (list.isNotEmpty ? list.first : '')
          : state.thumbnail;
      emit(state.copyWith(
        images: list,
        colorImages: newColorImages,
        thumbnail: newThumb,
      ));
    }
  }

  void removeProductImageUrl(String url) {
    final clean = url.trim();
    final list = List<String>.from(state.images)..removeWhere((e) => e == clean);
    final newColorImages = Map<String, String>.from(state.colorImages)
      ..removeWhere((k, v) => v == clean);
    final newThumb = state.thumbnail == clean
        ? (list.isNotEmpty ? list.first : '')
        : state.thumbnail;
    emit(state.copyWith(
      images: list,
      colorImages: newColorImages,
      thumbnail: newThumb,
    ));
  }

  // Badge Handlers
  void setBadgeEnabled(bool enabled) {
    emit(
      state.copyWith(
        isBadgeEnabled: enabled,
        badgeId: enabled ? state.badgeId : '',
      ),
    );
  }

  void setBadgeId(String id) {
    emit(
      state.copyWith(
        badgeId: id,
      ),
    );
  }

  // 1. LIQUID HANDLERS
  void addCustomFlavor(String flavor) {
    final clean = flavor.trim();
    if (clean.isEmpty) return;

    GlobalFlavorsPool.addFlavor(clean);

    final updatedAvailable = List<String>.from(state.availableFlavors);
    if (!updatedAvailable.contains(clean)) {
      updatedAvailable.add(clean);
    }

    final updatedSelected = List<String>.from(state.selectedFlavors);
    if (!updatedSelected.contains(clean)) {
      updatedSelected.add(clean);
    }

    emit(
      state.copyWith(
        availableFlavors: updatedAvailable,
        selectedFlavors: updatedSelected,
        activeFlavor: clean,
      ),
    );
  }

  void setActiveFlavor(String flavor) {
    emit(state.copyWith(activeFlavor: flavor));
  }

  void toggleFlavorSelection(String flavor) {
    final list = List<String>.from(state.selectedFlavors);
    if (list.contains(flavor)) {
      if (list.length > 1) list.remove(flavor);
    } else {
      list.add(flavor);
    }
    emit(
      state.copyWith(
        selectedFlavors: list,
        activeFlavor: list.contains(state.activeFlavor)
            ? state.activeFlavor
            : (list.isNotEmpty ? list.first : ''),
      ),
    );
  }

  static int? parseNicotineValue(String nic) {
    final clean = nic.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean);
  }

  static bool isDlNicotine(String nic) {
    final val = parseNicotineValue(nic);
    if (val != null) return val == 3 || val == 6;
    final lower = nic.trim().toLowerCase();
    return lower == '3mg' || lower == '6mg' || lower == '3' || lower == '6';
  }

  static bool isMtlNicotine(String nic) {
    final val = parseNicotineValue(nic);
    if (val != null) return val >= 6 && val <= 50;
    final lower = nic.trim().toLowerCase();
    return lower != '3mg' && lower != '3';
  }

  static List<String> getNicotinesForStyle(
    String style,
    List<String> selected,
  ) {
    if (style == 'DL') {
      final list = selected.where(isDlNicotine).toList();
      return list.isNotEmpty ? list : const ['3mg', '6mg'];
    } else if (style == 'MTL') {
      final list = selected.where(isMtlNicotine).toList();
      return list.isNotEmpty
          ? list
          : const [
              '6mg',
              '9mg',
              '12mg',
              '18mg',
              '20mg',
              '25mg',
              '30mg',
              '50mg',
            ];
    } else {
      return selected.isNotEmpty
          ? selected
          : const [
              '3mg',
              '6mg',
              '9mg',
              '12mg',
              '18mg',
              '20mg',
              '25mg',
              '30mg',
              '50mg',
            ];
    }
  }

  void setLiquidOrigin(String origin) {
    emit(state.copyWith(liquidOrigin: origin));
  }

  void setVapeStyle(String style) {
    if (state.categoryType == ProductCategoryType.disposable) {
      emit(state.copyWith(vapeStyle: style));
      return;
    }

    List<String> availNics;
    List<String> selNics;

    if (style == 'DL') {
      availNics = const ['3mg', '6mg'];
      selNics = state.selectedNicotines.where(isDlNicotine).toList();
      if (selNics.isEmpty) {
        selNics = const ['3mg', '6mg'];
      }
    } else if (style == 'MTL') {
      availNics = const [
        '6mg',
        '9mg',
        '12mg',
        '18mg',
        '20mg',
        '25mg',
        '30mg',
        '50mg',
      ];
      selNics = state.selectedNicotines.where(isMtlNicotine).toList();
      if (selNics.isEmpty) {
        selNics = const ['20mg', '25mg', '30mg', '50mg'];
      }
    } else {
      availNics = const [
        '3mg',
        '6mg',
        '9mg',
        '12mg',
        '18mg',
        '20mg',
        '25mg',
        '30mg',
        '50mg',
      ];
      selNics = List<String>.from(state.selectedNicotines);
      if (selNics.isEmpty) {
        selNics = const ['3mg', '6mg', '20mg', '30mg', '50mg'];
      }
    }

    emit(
      state.copyWith(
        vapeStyle: style,
        availableNicotines: availNics,
        selectedNicotines: selNics,
      ),
    );
  }

  /// Toggles individual vape style option ('MTL' or 'DL') via checkboxes.
  /// If both are active, sets style to 'BOTH'.
  /// Prevents unchecking both to ensure at least one style is selected.
  void toggleVapeStyleOption(String styleOption) {
    final opt = styleOption.toUpperCase().trim();
    final bool currentHasMtl = state.vapeStyle == 'MTL' || state.vapeStyle == 'BOTH';
    final bool currentHasDl = state.vapeStyle == 'DL' || state.vapeStyle == 'BOTH';

    if (opt == 'MTL') {
      final newHasMtl = !currentHasMtl;
      if (!newHasMtl && !currentHasDl) {
        return; // Keep at least one active
      }
      if (newHasMtl && currentHasDl) {
        setVapeStyle('BOTH');
      } else if (newHasMtl) {
        setVapeStyle('MTL');
      } else {
        setVapeStyle('DL');
      }
    } else if (opt == 'DL') {
      final newHasDl = !currentHasDl;
      if (!newHasDl && !currentHasMtl) {
        return; // Keep at least one active
      }
      if (newHasDl && currentHasMtl) {
        setVapeStyle('BOTH');
      } else if (newHasDl) {
        setVapeStyle('DL');
      } else {
        setVapeStyle('MTL');
      }
    }
  }

  void toggleNicotine(String nic) {
    final list = List<String>.from(state.selectedNicotines);
    if (list.contains(nic)) {
      list.remove(nic);
    } else {
      list.add(nic);
    }
    emit(state.copyWith(selectedNicotines: list));
  }

  void addCustomNicotine(String nic) {
    final clean = nic.trim();
    if (clean.isEmpty) return;
    final avail = List<String>.from(state.availableNicotines);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedNicotines);
    if (!sel.contains(clean)) sel.add(clean);
    emit(state.copyWith(availableNicotines: avail, selectedNicotines: sel));
  }

  void toggleSize(String size) {
    final list = List<String>.from(state.selectedSizes);
    if (list.contains(size)) {
      list.remove(size);
    } else {
      list.add(size);
    }
    emit(state.copyWith(selectedSizes: list));
  }

  void addCustomSize(String size) {
    final clean = size.trim();
    if (clean.isEmpty) return;
    final avail = List<String>.from(state.availableSizes);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedSizes);
    if (!sel.contains(clean)) sel.add(clean);
    emit(state.copyWith(availableSizes: avail, selectedSizes: sel));
  }

  // 2. DEVICE HANDLERS
  void updateDeviceSpecs({
    String? maxWattage,
    String? batteryType,
    String? batteryCapacity,
    String? chargingPort,
    String? screenType,
    String? airflowType,
  }) {
    // Feed new values into the shared pool so they persist for next products
    if (maxWattage != null && maxWattage.isNotEmpty) {
      GlobalDeviceSpecsPool.addWattage(maxWattage);
    }
    if (batteryCapacity != null && batteryCapacity.isNotEmpty) {
      GlobalDeviceSpecsPool.addBatteryCapacity(batteryCapacity);
    }
    if (batteryType != null && batteryType.isNotEmpty) {
      GlobalDeviceSpecsPool.addBatterySystem(batteryType, batteryType);
    }
    if (chargingPort != null && chargingPort.isNotEmpty) {
      GlobalDeviceSpecsPool.addChargingPort(chargingPort, chargingPort);
    }
    if (screenType != null && screenType.isNotEmpty) {
      GlobalDeviceSpecsPool.addScreenType(screenType, screenType);
    }
    if (airflowType != null && airflowType.isNotEmpty) {
      GlobalDeviceSpecsPool.addAirflowType(airflowType, airflowType);
    }
    emit(
      state.copyWith(
        maxWattage: maxWattage,
        batteryType: batteryType,
        batteryCapacity: batteryCapacity,
        chargingPort: chargingPort,
        screenType: screenType,
        airflowType: airflowType,
      ),
    );
  }


  void toggleColor(String color) {
    final list = List<String>.from(state.selectedColors);
    if (list.contains(color)) {
      list.remove(color);
    } else {
      list.add(color);
    }
    emit(state.copyWith(selectedColors: list));
  }

  void addCustomColor(String color) {
    final clean = color.trim();
    if (clean.isEmpty) return;
    final avail = List<String>.from(state.availableColors);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedColors);
    if (!sel.contains(clean)) sel.add(clean);
    emit(state.copyWith(availableColors: avail, selectedColors: sel));
  }

  void setColorImage(String color, String imageUrl) {
    final cleanColor = color.trim();
    final cleanUrl = imageUrl.trim();
    if (cleanColor.isEmpty) return;

    final updatedMap = Map<String, String>.from(state.colorImages);
    if (cleanUrl.isEmpty) {
      updatedMap.remove(cleanColor);
    } else {
      updatedMap[cleanColor] = cleanUrl;
    }

    // Also update any existing variations that match this color
    final updatedVars = state.variations.map((v) {
      final c = v.attributeValues['Color'] ?? v.attributeValues['color'];
      if (c == cleanColor) {
        return v.copyWith(image: cleanUrl);
      }
      return v;
    }).toList();

    emit(state.copyWith(colorImages: updatedMap, variations: updatedVars));
  }

  // 3. POD & COILS HANDLERS (COILS & CARTRIDGES)
  static String getSuggestedWattage(String resStr) {
    final clean = resStr
        .replaceAll('Ω', '')
        .replaceAll('ohm', '')
        .replaceAll(' ', '')
        .trim();
    final val = double.tryParse(clean);
    if (val == null) return '15W - 25W';
    if (val <= 0.15) return '60W - 80W';
    if (val <= 0.2) return '50W - 70W';
    if (val <= 0.3) return '30W - 40W';
    if (val <= 0.4) return '25W - 35W';
    if (val <= 0.6) return '18W - 25W';
    if (val <= 0.7) return '16W - 22W';
    if (val <= 0.8) return '12W - 16W';
    if (val <= 1.0) return '10W - 15W';
    if (val <= 1.2) return '9W - 12W';
    return '8W - 11W';
  }

  static String getSuggestedVapingStyle(String resStr) {
    final clean = resStr
        .replaceAll('Ω', '')
        .replaceAll('ohm', '')
        .replaceAll(' ', '')
        .trim();
    final val = double.tryParse(clean);
    if (val == null) return 'RDL / MTL';
    if (val <= 0.2) return 'DTL / سحب مباشر كثيف (Freebase)';
    if (val <= 0.4) return 'RDL / سحب سلس نكهة ممتازة (Freebase & Low Salt)';
    if (val <= 0.6) return 'RDL / متوازن (Freebase & Nic Salt)';
    if (val <= 0.8) return 'MTL / سولت نيكوتين متوازن (20mg - 30mg)';
    if (val <= 1.2) return 'Tight MTL / سولت عالي وسحب ضيق (30mg - 50mg)';
    return 'Tight MTL / سولت نيكوتين عالي';
  }

  void updatePodSpecs({
    String? compatibleDevices,
    String? capacity,
    bool? isPrefilled,
  }) {
    emit(
      state.copyWith(
        podCompatibleDevices: compatibleDevices,
        podCapacity: capacity,
        isPrefilledPod: isPrefilled,
      ),
    );
  }

  void togglePodCapacity(String cap) {
    final list = List<String>.from(state.selectedPodCapacities);
    if (list.contains(cap)) {
      list.remove(cap);
    } else {
      list.add(cap);
    }
    emit(state.copyWith(selectedPodCapacities: list));
  }

  void addCustomPodCapacity(String cap) {
    String clean = cap.trim();
    if (clean.isEmpty) return;
    if (!clean.toLowerCase().contains('ml') && !clean.contains('مل')) {
      clean = '${clean}ml';
    }
    final avail = List<String>.from(state.availablePodCapacities);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedPodCapacities);
    if (!sel.contains(clean)) sel.add(clean);
    emit(state.copyWith(availablePodCapacities: avail, selectedPodCapacities: sel));
  }

  void togglePodFillType(String fill) {
    final list = List<String>.from(state.selectedPodFillTypes);
    if (list.contains(fill)) {
      list.remove(fill);
    } else {
      list.add(fill);
    }
    emit(state.copyWith(selectedPodFillTypes: list));
  }

  void addCustomPodFillType(String fill) {
    String clean = fill.trim();
    if (clean.isEmpty) return;
    final avail = List<String>.from(state.availablePodFillTypes);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedPodFillTypes);
    if (!sel.contains(clean)) sel.add(clean);
    emit(state.copyWith(availablePodFillTypes: avail, selectedPodFillTypes: sel));
  }


  void togglePodResistance(String res) {
    final list = List<String>.from(state.selectedPodResistances);
    final wattMap = Map<String, String>.from(state.podResistanceWattages);
    if (list.contains(res)) {
      list.remove(res);
    } else {
      list.add(res);
      if (!wattMap.containsKey(res) || wattMap[res]!.isEmpty) {
        wattMap[res] = getSuggestedWattage(res);
      }
    }
    emit(
      state.copyWith(
        selectedPodResistances: list,
        podResistanceWattages: wattMap,
      ),
    );
  }

  void addCustomPodResistance(String res) {
    String clean = res.trim();
    if (clean.isEmpty) return;
    if (!clean.contains('Ω') && !clean.toLowerCase().contains('ohm')) {
      clean = '$cleanΩ';
    }
    final avail = List<String>.from(state.availablePodResistances);
    if (!avail.contains(clean)) avail.add(clean);
    final sel = List<String>.from(state.selectedPodResistances);
    if (!sel.contains(clean)) sel.add(clean);
    final wattMap = Map<String, String>.from(state.podResistanceWattages);
    if (!wattMap.containsKey(clean) || wattMap[clean]!.isEmpty) {
      wattMap[clean] = getSuggestedWattage(clean);
    }
    emit(
      state.copyWith(
        availablePodResistances: avail,
        selectedPodResistances: sel,
        podResistanceWattages: wattMap,
      ),
    );
  }

  void updatePodResistanceWattage(String res, String wattage) {
    final wattMap = Map<String, String>.from(state.podResistanceWattages);
    wattMap[res] = wattage.trim();
    emit(state.copyWith(podResistanceWattages: wattMap));
  }

  void autoFormatWattageIntoDescription() {
    final buffer = StringBuffer();
    if (state.description.trim().isNotEmpty) {
      final lines = state.description.split('\n');
      final filteredLines = <String>[];
      bool skipping = false;
      for (final line in lines) {
        if (line.contains('مواصفات المقاومات والواط الموصى به') ||
            line.contains('Recommended Wattage:')) {
          skipping = true;
          continue;
        }
        if (skipping && (line.startsWith('•') || line.startsWith('-') || line.trim().isEmpty)) {
          continue;
        } else {
          skipping = false;
        }
        filteredLines.add(line);
      }
      final cleanOld = filteredLines.join('\n').trim();
      if (cleanOld.isNotEmpty) {
        buffer.writeln(cleanOld);
        buffer.writeln();
      }
    }

    buffer.writeln('📋 مواصفات المقاومات والواط الموصى به (Recommended Wattage):');
    final resList = state.selectedPodResistances.isNotEmpty
        ? state.selectedPodResistances
        : state.availablePodResistances;
    for (final res in resList) {
      final watt = state.podResistanceWattages[res] ?? getSuggestedWattage(res);
      final style = getSuggestedVapingStyle(res);
      buffer.writeln('• $res Mesh ($watt) - $style');
    }

    emit(state.copyWith(description: buffer.toString().trim()));
  }

  void togglePodPackSize(String pack) {
    final list = List<String>.from(state.selectedPodPackSizes);
    if (list.contains(pack)) {
      list.remove(pack);
    } else {
      list.add(pack);
    }
    emit(state.copyWith(selectedPodPackSizes: list));
  }

  // 4. COIL HANDLERS (MAPPED TO COILS & CARTRIDGES)
  void updateCoilSpecs({
    String? compatibleTanks,
    String? wireMaterial,
    String? recommendedWattage,
  }) {
    emit(
      state.copyWith(
        coilCompatibleTanks: compatibleTanks,
        wireMaterial: wireMaterial,
        recommendedWattage: recommendedWattage,
      ),
    );
  }

  void toggleCoilResistance(String res) => togglePodResistance(res);
  void addCustomCoilResistance(String res) => addCustomPodResistance(res);
  void toggleCoilPackSize(String pack) => togglePodPackSize(pack);

  // 5. ACCESSORY HANDLERS
  void updateAccessorySpecs({
    String? category,
    String? compatibility,
    String? material,
    String? quantityPerPack,
  }) {
    emit(
      state.copyWith(
        accessoryCategory: category,
        accessoryCompatibility: compatibility,
        accessoryMaterial: material,
        accessoryQuantityPerPack: quantityPerPack,
      ),
    );
  }

  void toggleAccessoryTag(String tag) {
    final current = List<String>.from(state.selectedAccessoryTags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    emit(state.copyWith(selectedAccessoryTags: current));
  }

  // 6. COMPATIBLE / RELATED PRODUCTS HANDLERS
  void setCompatibleProducts(List<ProductModel> products) {
    emit(
      state.copyWith(
        compatibleProducts: products,
        compatibleProductIds: products.map((p) => p.id).toList(),
      ),
    );
  }

  void addCompatibleProduct(ProductModel product) {
    if (!state.compatibleProductIds.contains(product.id)) {
      final newIds = List<String>.from(state.compatibleProductIds)..add(product.id);
      final newProducts = List<ProductModel>.from(state.compatibleProducts)..add(product);
      emit(
        state.copyWith(
          compatibleProductIds: newIds,
          compatibleProducts: newProducts,
        ),
      );
    }
  }

  void removeCompatibleProduct(String productId) {
    final newIds = state.compatibleProductIds.where((id) => id != productId).toList();
    final newProducts = state.compatibleProducts.where((p) => p.id != productId).toList();
    emit(
      state.copyWith(
        compatibleProductIds: newIds,
        compatibleProducts: newProducts,
      ),
    );
  }

  // DYNAMIC VARIATIONS MATRIX GENERATOR (Delegated to VariationMatrixEngine)
  void generateDynamicVariations() {
    final newVars = VariationMatrixEngine.generateVariations(state);
    emit(state.copyWith(
      variations: newVars,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  /// Atomically generates variations and advances from Dynamic Specs (Step 1) to Variations Matrix (Step 2)
  /// in a single smooth frame to eliminate any transition lag.
  void advanceFromSpecsToMatrix() {
    final newVars = state.variations.isNotEmpty
        ? state.variations
        : VariationMatrixEngine.generateVariations(state);
    emit(state.copyWith(
      variations: newVars,
      currentStep: 2,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void updateVariation(int index, ProductVariationModel updated) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list[index] = updated;
      double newBase = state.basePrice;
      double newSale = state.salePrice;
      double newCost = state.baseCostPrice;
      if (newBase == 0 && updated.price > 0) newBase = updated.price;
      if (newSale == 0 && updated.salePrice > 0) newSale = updated.salePrice;
      if (newCost == 0 && updated.costPrice > 0) newCost = updated.costPrice;
      emit(state.copyWith(
        variations: list,
        basePrice: newBase,
        salePrice: newSale,
        baseCostPrice: newCost,
      ));
    }
  }

  void updateVariationRow(int index, ProductVariationModel updated) {
    updateVariation(index, updated);
  }

  void removeVariation(int index) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list.removeAt(index);
      emit(state.copyWith(
        variations: list,
        matrixRevision: state.matrixRevision + 1,
      ));
    }
  }

  void removeVariationRow(int index) {
    removeVariation(index);
  }

  void clearVariations() {
    emit(state.copyWith(
      variations: const [],
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void applyBulkPriceAndStock(double basePrice, double salePrice, int stock, [double? costPrice]) {
    final list = VariationMatrixEngine.applyBulkPriceAndStock(
      variations: state.variations,
      basePrice: basePrice,
      salePrice: salePrice,
      costPrice: costPrice,
      stock: stock,
    );
    emit(state.copyWith(
      variations: list,
      basePrice: basePrice > 0 ? basePrice : state.basePrice,
      salePrice: salePrice > 0 ? salePrice : state.salePrice,
      baseCostPrice: (costPrice != null && costPrice > 0) ? costPrice : state.baseCostPrice,
      baseStock: stock >= 0 ? stock : state.baseStock,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void bulkUpdateCostPrice(double costPrice) {
    final list = state.variations
        .map((v) => v.copyWith(costPrice: costPrice))
        .toList();
    emit(state.copyWith(
      variations: list,
      baseCostPrice: costPrice > 0 ? costPrice : state.baseCostPrice,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void applyLiquidTierPrices({
    String? targetSize,
    double? mtlStandardPrice,
    double? mtlStandardSalePrice,
    double? mtlStandardCostPrice,
    int? mtlStandardStock,
    double? dl3mgPrice,
    double? dl3mgSalePrice,
    double? dl3mgCostPrice,
    int? dl3mgStock,
    double? dl6mgPrice,
    double? dl6mgSalePrice,
    double? dl6mgCostPrice,
    int? dl6mgStock,
    double? mtl18mgPrice,
    double? mtl18mgSalePrice,
    double? mtl18mgCostPrice,
    int? mtl18mgStock,
    double? salt30mgPrice,
    double? salt30mgSalePrice,
    double? salt30mgCostPrice,
    int? salt30mgStock,
    double? salt50mgPrice,
    double? salt50mgSalePrice,
    double? salt50mgCostPrice,
    int? salt50mgStock,
  }) {
    final list = VariationMatrixEngine.applyLiquidTierPrices(
      variations: state.variations,
      targetSize: targetSize,
      mtlStandardPrice: mtlStandardPrice,
      mtlStandardSalePrice: mtlStandardSalePrice,
      mtlStandardCostPrice: mtlStandardCostPrice,
      mtlStandardStock: mtlStandardStock,
      dl3mgPrice: dl3mgPrice,
      dl3mgSalePrice: dl3mgSalePrice,
      dl3mgCostPrice: dl3mgCostPrice,
      dl3mgStock: dl3mgStock,
      dl6mgPrice: dl6mgPrice,
      dl6mgSalePrice: dl6mgSalePrice,
      dl6mgCostPrice: dl6mgCostPrice,
      dl6mgStock: dl6mgStock,
      mtl18mgPrice: mtl18mgPrice,
      mtl18mgSalePrice: mtl18mgSalePrice,
      mtl18mgCostPrice: mtl18mgCostPrice,
      mtl18mgStock: mtl18mgStock,
      salt30mgPrice: salt30mgPrice,
      salt30mgSalePrice: salt30mgSalePrice,
      salt30mgCostPrice: salt30mgCostPrice,
      salt30mgStock: salt30mgStock,
      salt50mgPrice: salt50mgPrice,
      salt50mgSalePrice: salt50mgSalePrice,
      salt50mgCostPrice: salt50mgCostPrice,
      salt50mgStock: salt50mgStock,
    );

    double newBasePrice = state.basePrice;
    double newSalePrice = state.salePrice;
    double newCostPrice = state.baseCostPrice;

    final prices = [
      mtlStandardPrice,
      dl3mgPrice,
      dl6mgPrice,
      salt30mgPrice,
      salt50mgPrice,
      mtl18mgPrice,
    ].where((p) => p != null && p > 0).cast<double>().toList();
    if (prices.isNotEmpty) {
      newBasePrice = prices.first;
    }

    final salePrices = [
      mtlStandardSalePrice,
      dl3mgSalePrice,
      dl6mgSalePrice,
      salt30mgSalePrice,
      salt50mgSalePrice,
      mtl18mgSalePrice,
    ].where((p) => p != null && p > 0).cast<double>().toList();
    if (salePrices.isNotEmpty) {
      newSalePrice = salePrices.first;
    }

    final costPrices = [
      mtlStandardCostPrice,
      dl3mgCostPrice,
      dl6mgCostPrice,
      salt30mgCostPrice,
      salt50mgCostPrice,
      mtl18mgCostPrice,
    ].where((p) => p != null && p > 0).cast<double>().toList();
    if (costPrices.isNotEmpty) {
      newCostPrice = costPrices.first;
    }

    emit(state.copyWith(
      variations: list,
      basePrice: newBasePrice > 0 ? newBasePrice : state.basePrice,
      salePrice: newSalePrice > 0 ? newSalePrice : state.salePrice,
      baseCostPrice: newCostPrice > 0 ? newCostPrice : state.baseCostPrice,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void removeLiquidTierVariations({
    required String targetSize,
    required String tierKey,
  }) {
    final list = VariationMatrixEngine.removeLiquidTierVariations(
      variations: state.variations,
      targetSize: targetSize,
      tierKey: tierKey,
    );
    emit(state.copyWith(
      variations: list,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void bulkUpdatePrice(double price) {
    final list = state.variations
        .map((v) => v.copyWith(salePrice: price, price: price))
        .toList();
    emit(state.copyWith(
      variations: list,
      basePrice: price > 0 ? price : state.basePrice,
      salePrice: price > 0 ? price : state.salePrice,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void bulkUpdateStock(int stock) {
    final list = state.variations.map((v) => v.copyWith(stock: stock)).toList();
    emit(state.copyWith(
      variations: list,
      baseStock: stock >= 0 ? stock : state.baseStock,
      matrixRevision: state.matrixRevision + 1,
    ));
  }

  void setVariationImage(int index, String imageUrl) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list[index] = list[index].copyWith(image: imageUrl.trim());
      emit(state.copyWith(variations: list));
    }
  }

  void applyImageToAllVariations(String imageUrl) {
    final list = state.variations
        .map((v) => v.copyWith(image: imageUrl.trim()))
        .toList();
    emit(state.copyWith(variations: list));
  }

  void applyImageToColorVariations(String colorValue, String imageUrl) {
    final list = VariationMatrixEngine.applyImageByAttribute(
      variations: state.variations,
      attributeKey: 'Color',
      targetValue: colorValue,
      imageUrl: imageUrl,
    );
    final updatedColorImages = Map<String, String>.from(state.colorImages);
    if (imageUrl.trim().isNotEmpty) {
      updatedColorImages[colorValue] = imageUrl.trim();
    } else {
      updatedColorImages.remove(colorValue);
    }
    emit(state.copyWith(variations: list, colorImages: updatedColorImages));
  }

  void applyImageToFlavorVariations(String flavorValue, String imageUrl) {
    final list = VariationMatrixEngine.applyImageByAttribute(
      variations: state.variations,
      attributeKey: 'Flavour',
      targetValue: flavorValue,
      imageUrl: imageUrl,
    );
    emit(state.copyWith(variations: list));
  }

  // BUILD & SAVE PRODUCT TO FIRESTORE (Delegated to VariationMatrixEngine)
  ProductModel buildProductModel() {
    return VariationMatrixEngine.buildProductModel(state);
  }

  Future<bool> saveProduct() async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final product = buildProductModel();
      if (state.selectedFlavors.isNotEmpty) {
        GlobalFlavorsPool.addFlavors(state.selectedFlavors);
      }
      GlobalFlavorsPool.harvestFromProducts([product]);
      GlobalDisposableSpecsPool.harvestFromProducts([product]);
      if (state.puffsCount.trim().isNotEmpty) {
        GlobalDisposableSpecsPool.addPuff(state.puffsCount.trim());
      }
      if (state.disposableBatteryCapacity.trim().isNotEmpty) {
        GlobalDisposableSpecsPool.addBattery(state.disposableBatteryCapacity.trim());
      }

      if (state.isEditMode) {
        await productRepository.updateProduct(product);
      } else {
        await productRepository.addProduct(product);
      }
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'فشل في حفظ المنتج إلى قاعدة البيانات: $e',
        ),
      );
      return false;
    }
  }
}

