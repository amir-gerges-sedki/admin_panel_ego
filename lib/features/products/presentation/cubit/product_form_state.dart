import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

class ProductFormState extends Equatable {
  final int currentStep; // 0: Type, 1: Specs, 2: Matrix, 3: Review
  final ProductCategoryType categoryType;
  final bool isEditMode;
  final String? initialProductId;

  // Basic Info
  final String title;
  final String description;
  final String brandId;
  final String brandName;
  final double basePrice;
  final double salePrice;
  final double baseCostPrice;
  final int baseStock;
  final String baseSku;
  final String thumbnail;
  final List<String> images;
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
  final Map<String, String> colorImages; // Maps color name to variation image URL

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
  final String accessoryQuantityPerPack; // e.g. 'Pack of 5', 'Single', '10-Pack'
  final List<String> selectedAccessoryTags; // quick compatibility/material tags

  // 6. Disposable Specs
  final String puffsCount;
  final String disposableBatteryCapacity;

  // Compatible / Related Products (for Pods, Coils, Accessories, Devices)
  final List<String> compatibleProductIds;
  final List<ProductModel> compatibleProducts;

  // Variations Matrix
  final List<ProductVariationModel> variations;

  const ProductFormState({
    this.currentStep = 0,
    this.categoryType = ProductCategoryType.liquid,
    this.isEditMode = false,
    this.initialProductId,
    this.title = '',
    this.description = '',
    this.brandId = '',
    this.brandName = '',
    this.basePrice = 0.0,
    this.salePrice = 0.0,
    this.baseCostPrice = 0.0,
    this.baseStock = 0,
    this.baseSku = '',
    this.thumbnail = '',
    this.images = const [],
    this.isBadgeEnabled = false,
    this.badgeId = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,

    // Disposable Specs
    this.puffsCount = '',
    this.disposableBatteryCapacity = '',

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
    this.colorImages = const {},

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
    this.accessoryQuantityPerPack = '',
    this.selectedAccessoryTags = const [],

    this.compatibleProductIds = const [],
    this.compatibleProducts = const [],

    this.variations = const [],
  });

  ProductFormState copyWith({
    int? currentStep,
    ProductCategoryType? categoryType,
    bool? isEditMode,
    String? initialProductId,
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
    Map<String, String>? colorImages,
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
    String? accessoryQuantityPerPack,
    List<String>? selectedAccessoryTags,
    List<String>? compatibleProductIds,
    List<ProductModel>? compatibleProducts,
    String? puffsCount,
    String? disposableBatteryCapacity,
    List<ProductVariationModel>? variations,
  }) {
    return ProductFormState(
      currentStep: currentStep ?? this.currentStep,
      categoryType: categoryType ?? this.categoryType,
      isEditMode: isEditMode ?? this.isEditMode,
      initialProductId: initialProductId ?? this.initialProductId,
      title: title ?? this.title,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      basePrice: basePrice ?? this.basePrice,
      salePrice: salePrice ?? this.salePrice,
      baseCostPrice: baseCostPrice ?? this.baseCostPrice,
      baseStock: baseStock ?? this.baseStock,
      baseSku: baseSku ?? this.baseSku,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      isBadgeEnabled: isBadgeEnabled ?? this.isBadgeEnabled,
      badgeId: badgeId ?? this.badgeId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      puffsCount: puffsCount ?? this.puffsCount,
      disposableBatteryCapacity:
          disposableBatteryCapacity ?? this.disposableBatteryCapacity,
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
      colorImages: colorImages ?? this.colorImages,
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
      accessoryQuantityPerPack:
          accessoryQuantityPerPack ?? this.accessoryQuantityPerPack,
      selectedAccessoryTags:
          selectedAccessoryTags ?? this.selectedAccessoryTags,
      compatibleProductIds:
          compatibleProductIds ?? this.compatibleProductIds,
      compatibleProducts:
          compatibleProducts ?? this.compatibleProducts,
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
    brandId,
    brandName,
    basePrice,
    salePrice,
    baseCostPrice,
    baseStock,
    baseSku,
    thumbnail,
    images,
    isBadgeEnabled,
    badgeId,
    isSubmitting,
    errorMessage,
    isSuccess,
    puffsCount,
    disposableBatteryCapacity,
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
    colorImages,
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
    accessoryQuantityPerPack,
    selectedAccessoryTags,
    compatibleProductIds,
    compatibleProducts,
    variations,
  ];
}
