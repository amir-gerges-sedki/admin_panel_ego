import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'product_type_strategy.dart';

/// Disposable Vape Category Strategy handling Flavors, MTL/DL Vaping Style, Puffs Count, and Battery specs.
class DisposableTypeStrategy implements ProductTypeStrategy {
  const DisposableTypeStrategy();

  @override
  ProductCategoryType get categoryType => ProductCategoryType.disposable;

  @override
  String resolveCategoryId(ProductFormState state) => 'CAT_DISPOSABLES';

  @override
  List<ProductAttribute> buildProductAttributes(ProductFormState state) {
    final List<ProductAttribute> attributes = [];

    final styles = state.vapeStyle == 'BOTH'
        ? ['MTL', 'DL']
        : [state.vapeStyle];
    attributes.add(
      ProductAttribute(name: 'Style', values: styles),
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

    if (state.puffsCount.trim().isNotEmpty) {
      attributes.add(
        ProductAttribute(name: 'Puffs', values: [state.puffsCount.trim()]),
      );
    }

    return attributes;
  }

  @override
  Map<String, dynamic> buildSpecifications(ProductFormState state) {
    return {
      'categoryType': categoryType.name,
      'vapeStyle': state.vapeStyle,
      'puffs': state.puffsCount.trim(),
      'puffsCount': state.puffsCount.trim(),
      'numberOfPuffs': state.puffsCount.trim(),
      'batteryCapacity': state.disposableBatteryCapacity.trim(),
      'flavors': state.selectedFlavors,
      if (state.selectedNicotines.isNotEmpty) 'nicotines': state.selectedNicotines,
    };
  }

  @override
  String resolveTitle(ProductFormState state) {
    if (state.title.trim().isNotEmpty) {
      return state.title.trim();
    }
    final flavors = state.selectedFlavors;
    if (flavors.length == 1) {
      return flavors.first.trim();
    } else if (flavors.length > 1) {
      return state.brandName.trim();
    }
    return '';
  }

  @override
  List<ProductVariationModel> generateVariations(ProductFormState state) {
    final brandClean = state.brandName.trim().isNotEmpty
        ? state.brandName.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : '';
    final prefix = state.baseSku.trim().isNotEmpty
        ? state.baseSku.trim().toUpperCase()
        : (brandClean.isNotEmpty ? brandClean : 'DISP');
    final stock = state.baseStock;
    final price = state.basePrice;
    final salePrice = state.salePrice > 0 ? state.salePrice : price;

    final styles = state.vapeStyle == 'BOTH'
        ? ['MTL', 'DL']
        : [state.vapeStyle];

    final flavorsToGen = state.selectedFlavors.isNotEmpty
        ? state.selectedFlavors
        : <String>[];

    final nicsToGen = state.selectedNicotines.isNotEmpty
        ? state.selectedNicotines
        : <String>[];

    final List<ProductVariationModel> variations = [];

    final flavors = flavorsToGen.isNotEmpty ? flavorsToGen : [null];
    final nics = nicsToGen.isNotEmpty ? nicsToGen : [null];

    for (final flav in flavors) {
      final flavCode = flav != null ? flav.replaceAll(' ', '').toUpperCase() : '';
      for (final nic in nics) {
        final nicCode = nic != null ? nic.replaceAll(' ', '').toUpperCase() : '';
        for (final style in styles) {
          final skuParts = [prefix];
          if (flavCode.isNotEmpty) skuParts.add(flavCode);
          if (nicCode.isNotEmpty) skuParts.add(nicCode);
          skuParts.add(style);
          final sku = skuParts.join('-').toUpperCase();

          final attrValues = <String, String>{};
          if (flav != null) attrValues['Flavour'] = flav;
          if (nic != null) attrValues['Nicotine'] = nic;
          attrValues['Style'] = style;

          variations.add(
            ProductVariationModel(
              id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
              sku: sku,
              price: price,
              salePrice: salePrice,
              stock: stock,
              attributeValues: attrValues,
            ),
          );
        }
      }
    }

    return variations;
  }
}
