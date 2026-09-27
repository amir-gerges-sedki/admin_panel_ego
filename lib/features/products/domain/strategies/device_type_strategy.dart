import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'product_type_strategy.dart';

/// Device Category Strategy handling vape mods, pod kits, battery specs, and color variations.
class DeviceTypeStrategy implements ProductTypeStrategy {
  const DeviceTypeStrategy();

  @override
  ProductCategoryType get categoryType => ProductCategoryType.device;

  @override
  String resolveCategoryId(ProductFormState state) => 'CAT_HARDWARE';

  @override
  List<ProductAttribute> buildProductAttributes(ProductFormState state) {
    final List<ProductAttribute> attributes = [];

    // Devices ONLY have Color attributes (NO Flavor/Wattage/Resistance)
    if (state.selectedColors.isNotEmpty) {
      attributes.add(ProductAttribute(name: 'Color', values: state.selectedColors));
    }

    return attributes;
  }

  @override
  Map<String, dynamic> buildSpecifications(ProductFormState state) {
    final Map<String, dynamic> specs = {
      'categoryType': categoryType.name,
    };
    if (state.maxWattage.trim().isNotEmpty) {
      specs['maxWattage'] = state.maxWattage.trim();
    }
    if (state.batteryType.trim().isNotEmpty) {
      specs['batteryType'] = state.batteryType.trim();
    }
    if (state.batteryCapacity.trim().isNotEmpty) {
      specs['batteryCapacity'] = state.batteryCapacity.trim();
    }
    if (state.chargingPort.trim().isNotEmpty) {
      specs['chargingPort'] = state.chargingPort.trim();
    }
    if (state.screenType.trim().isNotEmpty) {
      specs['screenType'] = state.screenType.trim();
    }
    if (state.airflowType.trim().isNotEmpty) {
      specs['airflowType'] = state.airflowType.trim();
    }
    if (state.selectedColors.isNotEmpty) {
      specs['colors'] = state.selectedColors;
    }
    return specs;
  }

  @override
  String resolveTitle(ProductFormState state) {
    return state.title.trim().isNotEmpty
        ? state.title.trim()
        : 'New ${categoryType.displayName} Product';
  }

  @override
  List<ProductVariationModel> generateVariations(ProductFormState state) {
    final brandClean = state.brandName.trim().isNotEmpty
        ? state.brandName.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : '';
    final prefix = state.baseSku.trim().isNotEmpty
        ? state.baseSku.trim().toUpperCase()
        : (brandClean.isNotEmpty ? brandClean : 'DEV');
    final price = state.salePrice > 0 ? state.salePrice : state.basePrice;
    final stock = state.baseStock;

    final colorsToGen = state.selectedColors.isNotEmpty
        ? state.selectedColors
        : ['Standard'];

    final List<ProductVariationModel> variations = [];

    for (final color in colorsToGen) {
      final colorCode = color
          .replaceAll('#', '')
          .replaceAll('/', '-')
          .replaceAll(' ', '')
          .toUpperCase();
      final sku = '$prefix-$colorCode'.toUpperCase();

      variations.add(
        ProductVariationModel(
          id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
          sku: sku,
          price: state.basePrice,
          salePrice: price,
          stock: stock,
          attributeValues: {'Color': color},
        ),
      );
    }

    return variations;
  }
}
