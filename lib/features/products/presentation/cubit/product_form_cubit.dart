import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helper/color_utils.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductFormState extends Equatable {
  final int currentStep; // 0: Type, 1: Specs, 2: Matrix, 3: Review
  final ProductCategoryType categoryType;
  final bool isEditMode;
  final String? initialProductId;

  // Basic Info
  final String title;
  final String description;
  final String brandName;
  final double basePrice;
  final double salePrice;
  final int baseStock;
  final String baseSku;
  final String thumbnail;
  final List<String> images;
  final bool isFeatured;
  final bool isBadgeEnabled;
  final String badgeId;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  // 1. Liquid Specs
  final String liquidOrigin; // 'Local' or 'Premium'
  final List<String> availableFlavors;
  final List<String> selectedFlavors;
  final String activeFlavor;
  final String vapeStyle; // 'MTL', 'DL', 'BOTH'
  final List<String> availableNicotines;
  final List<String> selectedNicotines;
  final List<String> availableSizes;
  final List<String> selectedSizes;
  final String vgPgRatio;

  // 2. Device Specs
  final String maxWattage;
  final String batteryType;
  final String batteryCapacity;
  final String chargingPort;
  final String screenType;
  final String airflowType;
  final List<String> availableColors;
  final List<String> selectedColors;

  // 3. Pod & Coil Specs (Coils & Cartridges)
  final String podCompatibleDevices;
  final String podCapacity;
  final List<String> availablePodCapacities;
  final List<String> selectedPodCapacities;
  final List<String> availablePodFillTypes;
  final List<String> selectedPodFillTypes;
  final List<String> availablePodResistances;
  final List<String> selectedPodResistances;
  final Map<String, String> podResistanceWattages;
  final List<String> availablePodPackSizes;
  final List<String> selectedPodPackSizes;
  final bool isPrefilledPod;


  // 4. Legacy Coil Specs (mapped to Coils & Cartridges)
  final String coilCompatibleTanks;
  final List<String> availableCoilResistances;
  final List<String> selectedCoilResistances;
  final String wireMaterial;
  final String recommendedWattage;
  final List<String> availableCoilPackSizes;
  final List<String> selectedCoilPackSizes;

  // 5. Accessory Specs
  final String accessoryCategory;
  final String accessoryCompatibility;
  final String accessoryMaterial;

  // Variations Matrix
  final List<ProductVariationModel> variations;

  const ProductFormState({
    this.currentStep = 0,
    this.categoryType = ProductCategoryType.liquid,
    this.isEditMode = false,
    this.initialProductId,
    this.title = '',
    this.description = '',
    this.brandName = '',
    this.basePrice = 0.0,
    this.salePrice = 0.0,
    this.baseStock = 0,
    this.baseSku = '',
    this.thumbnail = '',
    this.images = const [],
    this.isFeatured = false,
    this.isBadgeEnabled = false,
    this.badgeId = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,

    // Liquid Specs
    this.liquidOrigin = 'Local',
    this.availableFlavors = const [],
    this.selectedFlavors = const [],
    this.activeFlavor = '',
    this.vapeStyle = 'MTL',
    this.availableNicotines = const [
      '3mg',
      '6mg',
      '9mg',
      '12mg',
      '18mg',
      '20mg',
      '25mg',
      '30mg',
      '50mg',
    ],
    this.selectedNicotines = const [],
    this.availableSizes = const ['15ml', '30ml', '60ml', '100ml', '120ml'],
    this.selectedSizes = const [],
    this.vgPgRatio = '50/50',

    // Device Specs
    this.maxWattage = '',
    this.batteryType = 'Built-in Battery',
    this.batteryCapacity = '',
    this.chargingPort = '',
    this.screenType = '',
    this.airflowType = '',
    this.availableColors = const [],
    this.selectedColors = const [],

    // Pod & Coil Specs
    this.podCompatibleDevices = '',
    this.podCapacity = '',
    this.availablePodCapacities = const [
      '2.0ml',
      '3.0ml',
      '4.0ml',
      '4.5ml',
      '5.0ml',
    ],
    this.selectedPodCapacities = const [],
    this.availablePodFillTypes = const [
      'Top Fill',
      'Side Fill',
      'Bottom Fill',
    ],
    this.selectedPodFillTypes = const [],
    this.availablePodResistances = const [
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
    this.selectedPodResistances = const [],
    this.podResistanceWattages = const {},
    this.availablePodPackSizes = const [
      'Pack of 4',
      'Pack of 3',
      'Pack of 2',
      'Single Pod (1pc)',
    ],
    this.selectedPodPackSizes = const [],
    this.isPrefilledPod = false,

    // Coil Specs
    this.coilCompatibleTanks = '',
    this.availableCoilResistances = const [
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
    this.selectedCoilResistances = const [],
    this.wireMaterial = '',
    this.recommendedWattage = '',
    this.availableCoilPackSizes = const [
      'Pack of 5',
      'Pack of 3',
      'Single Coil (1pc)',
    ],
    this.selectedCoilPackSizes = const [],

    // Accessory Specs
    this.accessoryCategory = '',
    this.accessoryCompatibility = '',
    this.accessoryMaterial = '',

    this.variations = const [],
  });

  ProductFormState copyWith({
    int? currentStep,
    ProductCategoryType? categoryType,
    bool? isEditMode,
    String? initialProductId,
    String? title,
    String? description,
    String? brandName,
    double? basePrice,
    double? salePrice,
    int? baseStock,
    String? baseSku,
    String? thumbnail,
    List<String>? images,
    bool? isFeatured,
    bool? isBadgeEnabled,
    String? badgeId,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    String? liquidOrigin,
    List<String>? availableFlavors,
    List<String>? selectedFlavors,
    String? activeFlavor,
    String? vapeStyle,
    List<String>? availableNicotines,
    List<String>? selectedNicotines,
    List<String>? availableSizes,
    List<String>? selectedSizes,
    String? vgPgRatio,
    String? maxWattage,
    String? batteryType,
    String? batteryCapacity,
    String? chargingPort,
    String? screenType,
    String? airflowType,
    List<String>? availableColors,
    List<String>? selectedColors,
    String? podCompatibleDevices,
    String? podCapacity,
    List<String>? availablePodCapacities,
    List<String>? selectedPodCapacities,
    List<String>? availablePodFillTypes,
    List<String>? selectedPodFillTypes,
    List<String>? availablePodResistances,
    List<String>? selectedPodResistances,
    Map<String, String>? podResistanceWattages,
    List<String>? availablePodPackSizes,
    List<String>? selectedPodPackSizes,
    bool? isPrefilledPod,
    String? coilCompatibleTanks,
    List<String>? availableCoilResistances,
    List<String>? selectedCoilResistances,
    String? wireMaterial,
    String? recommendedWattage,
    List<String>? availableCoilPackSizes,
    List<String>? selectedCoilPackSizes,
    String? accessoryCategory,
    String? accessoryCompatibility,
    String? accessoryMaterial,
    List<ProductVariationModel>? variations,
  }) {
    return ProductFormState(
      currentStep: currentStep ?? this.currentStep,
      categoryType: categoryType ?? this.categoryType,
      isEditMode: isEditMode ?? this.isEditMode,
      initialProductId: initialProductId ?? this.initialProductId,
      title: title ?? this.title,
      description: description ?? this.description,
      brandName: brandName ?? this.brandName,
      basePrice: basePrice ?? this.basePrice,
      salePrice: salePrice ?? this.salePrice,
      baseStock: baseStock ?? this.baseStock,
      baseSku: baseSku ?? this.baseSku,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isBadgeEnabled: isBadgeEnabled ?? this.isBadgeEnabled,
      badgeId: badgeId ?? this.badgeId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      liquidOrigin: liquidOrigin ?? this.liquidOrigin,
      availableFlavors: availableFlavors ?? this.availableFlavors,
      selectedFlavors: selectedFlavors ?? this.selectedFlavors,
      activeFlavor: activeFlavor ?? this.activeFlavor,
      vapeStyle: vapeStyle ?? this.vapeStyle,
      availableNicotines: availableNicotines ?? this.availableNicotines,
      selectedNicotines: selectedNicotines ?? this.selectedNicotines,
      availableSizes: availableSizes ?? this.availableSizes,
      selectedSizes: selectedSizes ?? this.selectedSizes,
      vgPgRatio: vgPgRatio ?? this.vgPgRatio,
      maxWattage: maxWattage ?? this.maxWattage,
      batteryType: batteryType ?? this.batteryType,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      chargingPort: chargingPort ?? this.chargingPort,
      screenType: screenType ?? this.screenType,
      airflowType: airflowType ?? this.airflowType,
      availableColors: availableColors ?? this.availableColors,
      selectedColors: selectedColors ?? this.selectedColors,
      podCompatibleDevices: podCompatibleDevices ?? this.podCompatibleDevices,
      podCapacity: podCapacity ?? this.podCapacity,
      availablePodCapacities:
          availablePodCapacities ?? this.availablePodCapacities,
      selectedPodCapacities:
          selectedPodCapacities ?? this.selectedPodCapacities,
      availablePodFillTypes:
          availablePodFillTypes ?? this.availablePodFillTypes,
      selectedPodFillTypes:
          selectedPodFillTypes ?? this.selectedPodFillTypes,
      availablePodResistances:
          availablePodResistances ?? this.availablePodResistances,
      selectedPodResistances:
          selectedPodResistances ?? this.selectedPodResistances,
      podResistanceWattages:
          podResistanceWattages ?? this.podResistanceWattages,
      availablePodPackSizes:
          availablePodPackSizes ?? this.availablePodPackSizes,
      selectedPodPackSizes: selectedPodPackSizes ?? this.selectedPodPackSizes,
      isPrefilledPod: isPrefilledPod ?? this.isPrefilledPod,
      coilCompatibleTanks: coilCompatibleTanks ?? this.coilCompatibleTanks,
      availableCoilResistances:
          availableCoilResistances ?? this.availableCoilResistances,
      selectedCoilResistances:
          selectedCoilResistances ?? this.selectedCoilResistances,
      wireMaterial: wireMaterial ?? this.wireMaterial,
      recommendedWattage: recommendedWattage ?? this.recommendedWattage,
      availableCoilPackSizes:
          availableCoilPackSizes ?? this.availableCoilPackSizes,
      selectedCoilPackSizes:
          selectedCoilPackSizes ?? this.selectedCoilPackSizes,
      accessoryCategory: accessoryCategory ?? this.accessoryCategory,
      accessoryCompatibility:
          accessoryCompatibility ?? this.accessoryCompatibility,
      accessoryMaterial: accessoryMaterial ?? this.accessoryMaterial,
      variations: variations ?? this.variations,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    categoryType,
    isEditMode,
    initialProductId,
    title,
    description,
    brandName,
    basePrice,
    salePrice,
    baseStock,
    baseSku,
    thumbnail,
    images,
    isFeatured,
    isBadgeEnabled,
    badgeId,
    isSubmitting,
    errorMessage,
    isSuccess,
    liquidOrigin,
    availableFlavors,
    selectedFlavors,
    activeFlavor,
    vapeStyle,
    availableNicotines,
    selectedNicotines,
    availableSizes,
    selectedSizes,
    vgPgRatio,
    maxWattage,
    batteryType,
    batteryCapacity,
    chargingPort,
    screenType,
    airflowType,
    availableColors,
    selectedColors,
    podCompatibleDevices,
    podCapacity,
    availablePodCapacities,
    selectedPodCapacities,
    availablePodFillTypes,
    selectedPodFillTypes,
    availablePodResistances,
    selectedPodResistances,
    podResistanceWattages,
    availablePodPackSizes,
    selectedPodPackSizes,
    isPrefilledPod,
    coilCompatibleTanks,
    availableCoilResistances,
    selectedCoilResistances,
    wireMaterial,
    recommendedWattage,
    availableCoilPackSizes,
    selectedCoilPackSizes,
    accessoryCategory,
    accessoryCompatibility,
    accessoryMaterial,
    variations,
  ];
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
      ),
    );
  }

  void initForEditProduct(ProductModel product) {
    final specs = product.specifications;
    final flavs = product.flavors.isNotEmpty
        ? product.flavors
        : (specs['flavors'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

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
    final allNics = {...nicsFromAttrs, ...nicsFromSpecs}.toList();

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

    emit(
      ProductFormState(
        currentStep: 1, // Jump directly to Specs form
        isEditMode: true,
        initialProductId: product.id,
        categoryType: product.categoryType,
        title: product.title,
        description: product.description,
        brandName: product.brand.name,
        basePrice: product.price,
        salePrice: product.salePrice,
        baseStock: product.stock,
        baseSku: product.productVariations.isNotEmpty
            ? product.productVariations.first.sku.split('-').first
            : '',
        thumbnail: product.thumbnail,
        images: product.images,
        isFeatured: product.isFeatured,
        isBadgeEnabled: product.isBadgeEnabled,
        badgeId: product.badgeId,
        variations: product.productVariations,
        liquidOrigin: specs['liquidOrigin']?.toString() ??
            specs['liquidType']?.toString() ??
            (specs['isLocal'] == true ? 'Local' : 'Local'),
        availableFlavors: flavs,
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
      ),
    );

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

  void selectCategoryType(ProductCategoryType type) {
    emit(
      state.copyWith(
        categoryType: type,
        currentStep: 1, // Advance to step 2 (Specs)
        selectedFlavors: type == ProductCategoryType.liquid
            ? state.selectedFlavors
            : const [],
        availableFlavors: type == ProductCategoryType.liquid
            ? state.availableFlavors
            : const [],
        selectedNicotines: type == ProductCategoryType.liquid
            ? state.selectedNicotines
            : const [],
        selectedSizes: type == ProductCategoryType.liquid
            ? state.selectedSizes
            : const [],
        selectedColors: type == ProductCategoryType.device
            ? state.selectedColors
            : const [],
        selectedPodResistances: type == ProductCategoryType.pod
            ? state.selectedPodResistances
            : const [],
        selectedCoilResistances: type == ProductCategoryType.coil
            ? state.selectedCoilResistances
            : const [],
      ),
    );
  }

  // Basic Info setters
  void updateBasicInfo({
    String? title,
    String? description,
    String? brandName,
    double? basePrice,
    double? salePrice,
    int? baseStock,
    String? baseSku,
    String? thumbnail,
    List<String>? images,
    bool? isFeatured,
    bool? isBadgeEnabled,
    String? badgeId,
  }) {
    emit(
      state.copyWith(
        title: title,
        description: description,
        brandName: brandName,
        basePrice: basePrice,
        salePrice: salePrice,
        baseStock: baseStock,
        baseSku: baseSku,
        thumbnail: thumbnail,
        images: images,
        isFeatured: isFeatured,
        isBadgeEnabled: isBadgeEnabled,
        badgeId: badgeId,
      ),
    );
  }

  void setThumbnail(String url) {
    emit(state.copyWith(thumbnail: url.trim()));
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
      final list = List<String>.from(state.images)..removeAt(index);
      emit(state.copyWith(images: list));
    }
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
    emit(state.copyWith(badgeId: id));
  }

  // 1. LIQUID HANDLERS
  void addCustomFlavor(String flavor) {
    final clean = flavor.trim();
    if (clean.isEmpty) return;

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
  }) {
    emit(
      state.copyWith(
        accessoryCategory: category,
        accessoryCompatibility: compatibility,
        accessoryMaterial: material,
      ),
    );
  }

  // DYNAMIC VARIATIONS MATRIX GENERATOR
  void generateDynamicVariations() {
    final prefix = state.baseSku.trim().isNotEmpty
        ? state.baseSku.trim().toUpperCase()
        : 'SKU';
    final price = state.salePrice > 0 ? state.salePrice : state.basePrice;
    final stock = state.baseStock;
    final List<ProductVariationModel> newVars = [];

    switch (state.categoryType) {
      case ProductCategoryType.liquid:
        final originType = state.liquidOrigin == 'Local' ? 'Local' : 'Premium';
        final styles = state.vapeStyle == 'BOTH'
            ? ['MTL', 'DL']
            : [state.vapeStyle];
        final flavorsToGen = state.selectedFlavors.isNotEmpty
            ? state.selectedFlavors
            : (state.activeFlavor.isNotEmpty
                  ? [state.activeFlavor]
                  : <String>[]);
        final sizesToGen = state.selectedSizes.isNotEmpty
            ? state.selectedSizes
            : ['30ml'];

        if (flavorsToGen.isEmpty) {
          // If no flavors specified yet, create base style variations
          for (final style in styles) {
            final nicsForStyle = getNicotinesForStyle(
              style,
              state.selectedNicotines,
            );
            for (final sz in sizesToGen) {
              for (final nic in nicsForStyle) {
                final sku = '$prefix-$style-$sz-$nic'.toUpperCase();
                newVars.add(
                  ProductVariationModel(
                    id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${newVars.length}',
                    sku: sku,
                    price: state.basePrice,
                    salePrice: price,
                    stock: stock,
                    attributeValues: {
                      'Type': originType,
                      'Style': style,
                      'Size': sz,
                      'Nicotine': nic,
                    },
                  ),
                );
              }
            }
          }
        } else {
          for (final flav in flavorsToGen) {
            final flavCode = flav.replaceAll(' ', '').toUpperCase();
            for (final style in styles) {
              final nicsForStyle = getNicotinesForStyle(
                style,
                state.selectedNicotines,
              );
              for (final sz in sizesToGen) {
                for (final nic in nicsForStyle) {
                  final sku = '$prefix-$flavCode-$style-$sz-$nic'.toUpperCase();
                  newVars.add(
                    ProductVariationModel(
                      id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${newVars.length}',
                      sku: sku,
                      price: state.basePrice,
                      salePrice: price,
                      stock: stock,
                      attributeValues: {
                        'Type': originType,
                        'Flavour': flav,
                        'Style': style,
                        'Size': sz,
                        'Nicotine': nic,
                      },
                    ),
                  );
                }
              }
            }
          }
        }
        break;

      case ProductCategoryType.device:
        final colorsToGen = state.selectedColors.isNotEmpty
            ? state.selectedColors
            : ['Standard'];
        for (final color in colorsToGen) {
          final colorCode = color
              .replaceAll('#', '')
              .replaceAll('/', '-')
              .replaceAll(' ', '')
              .toUpperCase();
          final sku = '$prefix-$colorCode'.toUpperCase();
          newVars.add(
            ProductVariationModel(
              id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${newVars.length}',
              sku: sku,
              price: state.basePrice,
              salePrice: price,
              stock: stock,
              attributeValues: {'Color': color},
            ),
          );
        }
        break;

      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        final resList = state.selectedPodResistances.isNotEmpty
            ? state.selectedPodResistances
            : (state.selectedCoilResistances.isNotEmpty
                ? state.selectedCoilResistances
                : ['0.6Ω', '0.8Ω']);

        List<Map<String, String>> combinations = [];
        for (final res in resList) {
          combinations.add({'Resistance': res});
        }

        if (state.selectedPodCapacities.isNotEmpty) {
          final expanded = <Map<String, String>>[];
          for (final comb in combinations) {
            for (final cap in state.selectedPodCapacities) {
              expanded.add({...comb, 'Capacity': cap});
            }
          }
          combinations = expanded;
        }

        if (state.selectedPodFillTypes.isNotEmpty) {
          final expanded = <Map<String, String>>[];
          for (final comb in combinations) {
            for (final fill in state.selectedPodFillTypes) {
              expanded.add({...comb, 'FillType': fill});
            }
          }
          combinations = expanded;
        }

        for (final comb in combinations) {
          final parts = <String>[prefix];
          if (comb.containsKey('Resistance')) {
            final resCode = comb['Resistance']!
                .split(' ')
                .first
                .replaceAll('Ω', '')
                .replaceAll('ohm', '')
                .replaceAll('.', '');
            parts.add('R$resCode');
          }
          if (comb.containsKey('Capacity')) {
            final capCode = comb['Capacity']!
                .replaceAll(' ', '')
                .replaceAll('.', '')
                .toUpperCase();
            parts.add(capCode);
          }
          if (comb.containsKey('FillType')) {
            final fillVal = comb['FillType']!.toLowerCase();
            if (fillVal.contains('top')) {
              parts.add('TOP');
            } else if (fillVal.contains('side')) {
              parts.add('SIDE');
            } else if (fillVal.contains('bottom')) {
              parts.add('BOT');
            } else {
              parts.add(fillVal.replaceAll(' ', '').toUpperCase());
            }
          }
          final sku = parts.join('-').toUpperCase();
          newVars.add(
            ProductVariationModel(
              id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${newVars.length}',
              sku: sku,
              price: state.basePrice,
              salePrice: price,
              stock: stock,
              attributeValues: comb,
            ),
          );
        }
        break;


      case ProductCategoryType.accessory:
        newVars.add(
          ProductVariationModel(
            id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_0',
            sku: '$prefix-STD'.toUpperCase(),
            price: state.basePrice,
            salePrice: price,
            stock: stock,
            attributeValues: {
              if (state.accessoryCategory.isNotEmpty)
                'Category': state.accessoryCategory,
              if (state.accessoryMaterial.isNotEmpty)
                'Spec': state.accessoryMaterial,
            },
          ),
        );
        break;
    }

    emit(state.copyWith(variations: newVars));
  }

  void updateVariation(int index, ProductVariationModel updated) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list[index] = updated;
      emit(state.copyWith(variations: list));
    }
  }

  void updateVariationRow(int index, ProductVariationModel updated) {
    updateVariation(index, updated);
  }

  void removeVariation(int index) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list.removeAt(index);
      emit(state.copyWith(variations: list));
    }
  }

  void removeVariationRow(int index) {
    removeVariation(index);
  }

  void clearVariations() {
    emit(state.copyWith(variations: const []));
  }

  void applyBulkPriceAndStock(double basePrice, double salePrice, int stock) {
    final list = state.variations
        .map(
          (v) => v.copyWith(
            price: basePrice > 0 ? basePrice : v.price,
            salePrice: salePrice > 0 ? salePrice : v.salePrice,
            stock: stock >= 0 ? stock : v.stock,
          ),
        )
        .toList();
    emit(state.copyWith(variations: list));
  }

  void bulkUpdatePrice(double price) {
    final list = state.variations
        .map((v) => v.copyWith(salePrice: price, price: price))
        .toList();
    emit(state.copyWith(variations: list));
  }

  void bulkUpdateStock(int stock) {
    final list = state.variations.map((v) => v.copyWith(stock: stock)).toList();
    emit(state.copyWith(variations: list));
  }

  void setVariationImage(int index, String imageUrl) {
    if (index >= 0 && index < state.variations.length) {
      final list = List<ProductVariationModel>.from(state.variations);
      list[index] = list[index].copyWith(image: imageUrl);
      emit(state.copyWith(variations: list));
    }
  }

  void applyImageToAllVariations(String imageUrl) {
    final list = state.variations
        .map((v) => v.copyWith(image: imageUrl))
        .toList();
    emit(state.copyWith(variations: list));
  }

  void applyImageToColorVariations(String colorValue, String imageUrl) {
    final list = state.variations.map((v) {
      final color = v.attributeValues['Color'] ?? v.attributeValues['color'];
      if (color == colorValue) {
        return v.copyWith(image: imageUrl);
      }
      return v;
    }).toList();
    emit(state.copyWith(variations: list));
  }

  void applyImageToFlavorVariations(String flavorValue, String imageUrl) {
    final list = state.variations.map((v) {
      final flv =
          v.attributeValues['Flavour'] ??
          v.attributeValues['Flavor'] ??
          v.attributeValues['flavor'];
      if (flv == flavorValue) {
        return v.copyWith(image: imageUrl);
      }
      return v;
    }).toList();
    emit(state.copyWith(variations: list));
  }

  // BUILD & SAVE PRODUCT TO FIRESTORE
  ProductModel buildProductModel() {
    final now = DateTime.now();
    final id = state.initialProductId ?? 'PROD_${now.millisecondsSinceEpoch}';

    String categoryId = 'CAT_HARDWARE';
    switch (state.categoryType) {
      case ProductCategoryType.liquid:
        categoryId = state.liquidOrigin == 'Local'
            ? 'Local Liquid'
            : 'Premium Liquid';
        break;
      case ProductCategoryType.device:
        categoryId = 'CAT_HARDWARE';
        break;
      case ProductCategoryType.pod:
        categoryId = 'CAT_POD_SYSTEMS';
        break;
      case ProductCategoryType.coil:
        categoryId = 'CAT_COILS_PODS';
        break;
      case ProductCategoryType.accessory:
        categoryId = 'CAT_ACCESSORIES';
        break;
    }

    // Specifications map
    final Map<String, dynamic> specs = {
      'categoryType': state.categoryType.name,
      'vapeStyle': state.vapeStyle,
    };

    if (state.categoryType == ProductCategoryType.liquid) {
      specs['liquidOrigin'] = state.liquidOrigin;
      specs['liquidType'] = state.liquidOrigin;
      specs['isLocal'] = state.liquidOrigin == 'Local';
      specs['flavors'] = state.selectedFlavors;
      specs['nicotines'] = state.selectedNicotines;
      specs['sizes'] = state.selectedSizes;
      specs['vgPgRatio'] = state.vgPgRatio;
    } else if (state.categoryType == ProductCategoryType.device) {
      specs['maxWattage'] = state.maxWattage;
      specs['batteryType'] = state.batteryType;
      specs['batteryCapacity'] = state.batteryCapacity;
      specs['chargingPort'] = state.chargingPort;
      specs['screenType'] = state.screenType;
      specs['airflowType'] = state.airflowType;
      specs['colors'] = state.selectedColors;
    } else if (state.categoryType == ProductCategoryType.pod ||
        state.categoryType == ProductCategoryType.coil) {
      specs['compatibleDevices'] = state.podCompatibleDevices.isNotEmpty
          ? state.podCompatibleDevices
          : state.coilCompatibleTanks;
      specs['capacity'] = state.podCapacity;
      specs['isPrefilled'] = state.isPrefilledPod;
      if (state.selectedPodCapacities.isNotEmpty) {
        specs['capacities'] = state.selectedPodCapacities;
      }
      if (state.selectedPodFillTypes.isNotEmpty) {
        specs['fillTypes'] = state.selectedPodFillTypes;
      }
      final resList = state.selectedPodResistances.isNotEmpty
          ? state.selectedPodResistances
          : state.selectedCoilResistances;
      specs['resistances'] = resList;
      for (final res in resList) {
        final watt =
            state.podResistanceWattages[res] ?? getSuggestedWattage(res);
        specs['$res Wattage'] = watt;
      }
    } else if (state.categoryType == ProductCategoryType.accessory) {
      specs['accessoryCategory'] = state.accessoryCategory;
      specs['accessoryCompatibility'] = state.accessoryCompatibility;
      specs['accessoryMaterial'] = state.accessoryMaterial;
    }

    // Build Product Attributes strictly based on categoryType
    final List<ProductAttribute> attributes = [];

    if (state.categoryType == ProductCategoryType.liquid) {
      attributes.add(
        ProductAttribute(
          name: 'Type',
          values: [
            state.liquidOrigin == 'Local' ? 'Local Liquid' : 'Premium Liquid',
          ],
        ),
      );
      if (state.selectedFlavors.isNotEmpty) {
        attributes.add(
          ProductAttribute(name: 'Flavour', values: state.selectedFlavors),
        );
      }
      if (state.selectedNicotines.isNotEmpty) {
        attributes.add(
          ProductAttribute(name: 'Nicotine', values: state.selectedNicotines),
        );
      }
      if (state.selectedSizes.isNotEmpty) {
        attributes.add(
          ProductAttribute(name: 'Size', values: state.selectedSizes),
        );
      }
    } else if (state.categoryType == ProductCategoryType.device) {
      // Devices ONLY have Color attributes (NO Flavor/Wattage/Resistance)
      if (state.selectedColors.isNotEmpty) {
        final List<String> hexColors = state.selectedColors
            .map((c) {
              final text = c.trim();
              if (text.startsWith('#')) return text;
              final parsed = ColorUtils.parseColorsFromText(text);
              return parsed.isNotEmpty ? ColorUtils.toHex(parsed.first) : text;
            })
            .cast<String>()
            .toList();
        attributes.add(ProductAttribute(name: 'Color', values: hexColors));
      }
    } else if (state.categoryType == ProductCategoryType.pod ||
        state.categoryType == ProductCategoryType.coil) {
      final resList = state.selectedPodResistances.isNotEmpty
          ? state.selectedPodResistances
          : state.selectedCoilResistances;
      if (resList.isNotEmpty) {
        attributes.add(
          ProductAttribute(
            name: 'Resistance',
            values: resList,
          ),
        );
      }
      if (state.selectedPodCapacities.isNotEmpty) {
        attributes.add(
          ProductAttribute(
            name: 'Capacity',
            values: state.selectedPodCapacities,
          ),
        );
      }
      if (state.selectedPodFillTypes.isNotEmpty) {
        attributes.add(
          ProductAttribute(
            name: 'FillType',
            values: state.selectedPodFillTypes,
          ),
        );
      }
    } else if (state.categoryType == ProductCategoryType.accessory) {
      if (state.accessoryCategory.isNotEmpty) {
        attributes.add(
          ProductAttribute(name: 'Category', values: [state.accessoryCategory]),
        );
      }
    }


    // Resolve main thumbnail
    String resolvedThumbnail = state.thumbnail.trim();
    if (resolvedThumbnail.isEmpty) {
      if (state.images.isNotEmpty) {
        resolvedThumbnail = state.images.first.trim();
      } else if (state.variations.any((v) => v.image.trim().isNotEmpty)) {
        resolvedThumbnail = state.variations
            .firstWhere((v) => v.image.trim().isNotEmpty)
            .image
            .trim();
      }
    }

    // Collect all distinct images for gallery
    final Set<String> distinctImages = {};
    if (resolvedThumbnail.isNotEmpty) {
      distinctImages.add(resolvedThumbnail);
    }
    for (final img in state.images) {
      if (img.trim().isNotEmpty) distinctImages.add(img.trim());
    }
    for (final v in state.variations) {
      if (v.image.trim().isNotEmpty) distinctImages.add(v.image.trim());
    }
    final List<String> resolvedImages = distinctImages.toList();

    // Preserve each variation's own specific image without overwriting
    // AND normalize color attribute to exact hex so it matches productAttributes!
    final List<ProductVariationModel>
    finalizedVariations = state.variations.map((v) {
      final Map<String, String> cleanedAttrs = Map<String, String>.from(
        v.attributeValues,
      );
      if (cleanedAttrs.containsKey('Color') ||
          cleanedAttrs.containsKey('color')) {
        final colorKey = cleanedAttrs.containsKey('Color') ? 'Color' : 'color';
        final rawColor = cleanedAttrs[colorKey] ?? '';
        if (rawColor.isNotEmpty && !rawColor.startsWith('#')) {
          final parsed = ColorUtils.parseColorsFromText(rawColor);
          if (parsed.isNotEmpty) {
            cleanedAttrs[colorKey] = ColorUtils.toHex(parsed.first);
          }
        }
      }
      return v.copyWith(image: v.image.trim(), attributeValues: cleanedAttrs);
    }).toList();

    final String resolvedTitle;
    if (state.categoryType == ProductCategoryType.liquid) {
      resolvedTitle = '';
    } else {
      resolvedTitle = state.title.trim().isNotEmpty
          ? state.title.trim()
          : 'New ${state.categoryType.displayName} Product';
    }

    return ProductModel(
      id: id,
      title: resolvedTitle,
      description: state.description,
      price: state.basePrice,
      salePrice: state.salePrice > 0 ? state.salePrice : state.basePrice,
      stock: finalizedVariations.isNotEmpty
          ? finalizedVariations.fold(0, (acc, v) => acc + v.stock)
          : state.baseStock,
      thumbnail: resolvedThumbnail,
      images: resolvedImages,
      brand: ProductBrand(
        id: 'BRAND_${state.brandName.replaceAll(' ', '_').toUpperCase()}',
        name: state.brandName,
      ),
      categoryId: categoryId,
      categoryType: state.categoryType,
      isFeatured: state.isFeatured,
      isBadgeEnabled: state.isBadgeEnabled,
      badgeId: state.isBadgeEnabled ? state.badgeId : '',
      productType: finalizedVariations.isNotEmpty ? 'variable' : 'simple',
      productAttributes: attributes,
      productVariations: finalizedVariations,
      flavors: state.categoryType == ProductCategoryType.liquid
          ? state.selectedFlavors
          : const [],
      specifications: specs,
    );
  }

  Future<bool> saveProduct() async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final product = buildProductModel();
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
