import '../../../../core/algorithms/cartesian_product.dart';
import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'product_type_strategy.dart';

/// E-Liquid Category Strategy handling Salt Nic, Freebase, Flavors, and Origin classifications.
class LiquidTypeStrategy implements ProductTypeStrategy {
  const LiquidTypeStrategy();

  @override
  ProductCategoryType get categoryType => ProductCategoryType.liquid;

  @override
  String resolveCategoryId(ProductFormState state) => 'CAT_LIQUIDS';

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
    if (state.selectedSizes.isNotEmpty) {
      attributes.add(
        ProductAttribute(name: 'Size', values: state.selectedSizes),
      );
    }

    return attributes;
  }

  @override
  Map<String, dynamic> buildSpecifications(ProductFormState state) {
    return {
      'categoryType': categoryType.name,
      'vapeStyle': state.vapeStyle,
      'liquidOrigin': state.liquidOrigin,
      'isLocal': state.liquidOrigin == 'Local',
      'flavors': state.selectedFlavors,
      'nicotines': state.selectedNicotines,
      'sizes': state.selectedSizes,
      'vgPgRatio': state.vgPgRatio,
    };
  }

  @override
  String resolveTitle(ProductFormState state) => '';

  /// Computes variation price for Liquid products according to market & business rules:
  /// - 6mg, 9mg, 12mg have strictly the SAME price tier.
  /// - 3mg is the lowest price tier.
  /// - 18mg is slightly higher than 12mg.
  /// - 30mg is higher (salt nic).
  /// - 50mg is higher.
  /// - Bottle size (15ml, 30ml, 60ml, 100ml, 120ml) scales proportionally.
  static double computeTieredLiquidPrice({
    required double basePrice,
    required String nicotine,
    required String size,
  }) {
    if (basePrice <= 0) return 0.0;

    final nicClean = nicotine.toLowerCase().trim();
    double nicMultiplier = 1.0;

    if (nicClean.contains('3mg') || nicClean == '3') {
      nicMultiplier = 0.92; // 3mg is lowest tier
    } else if (nicClean.contains('6mg') ||
        nicClean.contains('9mg') ||
        nicClean.contains('12mg')) {
      nicMultiplier = 1.0; // 6mg, 9mg, 12mg MUST be strictly equal
    } else if (nicClean.contains('18mg')) {
      nicMultiplier = 1.08; // 18mg is slightly higher than 12mg
    } else if (nicClean.contains('20mg') || nicClean.contains('25mg')) {
      nicMultiplier = 1.15;
    } else if (nicClean.contains('30mg')) {
      nicMultiplier = 1.25; // 30mg is higher
    } else if (nicClean.contains('50mg')) {
      nicMultiplier = 1.38; // 50mg is higher
    }

    final szClean = size.toLowerCase().trim();
    double sizeMultiplier = 1.0;
    if (szClean.contains('15ml')) {
      sizeMultiplier = 0.6;
    } else if (szClean.contains('30ml')) {
      final isSalt = nicClean.contains('20') ||
          nicClean.contains('25') ||
          nicClean.contains('30') ||
          nicClean.contains('50');
      sizeMultiplier = isSalt ? 1.0 : 0.75;
    } else if (szClean.contains('60ml')) {
      sizeMultiplier = 1.0;
    } else if (szClean.contains('100ml')) {
      sizeMultiplier = 1.45;
    } else if (szClean.contains('120ml')) {
      sizeMultiplier = 1.7;
    }

    final calculated = basePrice * nicMultiplier * sizeMultiplier;
    return (calculated / 5).round() * 5.0;
  }

  @override
  List<ProductVariationModel> generateVariations(ProductFormState state) {
    final brandClean = state.brandName.trim().isNotEmpty
        ? state.brandName.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : '';
    final prefix = state.baseSku.trim().isNotEmpty
        ? state.baseSku.trim().toUpperCase()
        : (brandClean.isNotEmpty ? brandClean : 'LIQ');
    final stock = state.baseStock;

    final styles = state.vapeStyle == 'BOTH'
        ? ['MTL', 'DL']
        : [state.vapeStyle];

    final flavorsToGen = state.selectedFlavors.isNotEmpty
        ? state.selectedFlavors
        : (state.activeFlavor.isNotEmpty ? [state.activeFlavor] : <String>[]);

    final sizesToGen = state.selectedSizes.isNotEmpty
        ? state.selectedSizes
        : ['30ml'];

    final List<ProductVariationModel> variations = [];

    if (flavorsToGen.isEmpty) {
      for (final style in styles) {
        final nicsForStyle = ProductFormCubit.getNicotinesForStyle(
          style,
          state.selectedNicotines,
        );

        final rawCombinations = CartesianProduct.computeNamed<String>({
          'Size': sizesToGen,
          'Nicotine': nicsForStyle,
        });

        for (final comb in rawCombinations) {
          final sz = comb['Size']!;
          final nic = comb['Nicotine']!;
          final sku = '$prefix-$style-$sz-$nic'.toUpperCase();

          final varBasePrice = computeTieredLiquidPrice(
            basePrice: state.basePrice,
            nicotine: nic,
            size: sz,
          );
          final varSalePrice = state.salePrice > 0
              ? computeTieredLiquidPrice(
                  basePrice: state.salePrice,
                  nicotine: nic,
                  size: sz,
                )
              : varBasePrice;

          variations.add(
            ProductVariationModel(
              id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
              sku: sku,
              price: varBasePrice,
              salePrice: varSalePrice,
              stock: stock,
              attributeValues: {
                'Style': style,
                'Size': sz,
                'Nicotine': nic,
              },
            ),
          );
        }
      }
    } else {
      for (final flav in flavorsToGen) {
        final flavCode = flav.replaceAll(' ', '').toUpperCase();
        for (final style in styles) {
          final nicsForStyle = ProductFormCubit.getNicotinesForStyle(
            style,
            state.selectedNicotines,
          );

          final rawCombinations = CartesianProduct.computeNamed<String>({
            'Size': sizesToGen,
            'Nicotine': nicsForStyle,
          });

          for (final comb in rawCombinations) {
            final sz = comb['Size']!;
            final nic = comb['Nicotine']!;
            final sku = '$prefix-$flavCode-$style-$sz-$nic'.toUpperCase();

            final varBasePrice = computeTieredLiquidPrice(
              basePrice: state.basePrice,
              nicotine: nic,
              size: sz,
            );
            final varSalePrice = state.salePrice > 0
                ? computeTieredLiquidPrice(
                    basePrice: state.salePrice,
                    nicotine: nic,
                    size: sz,
                  )
                : varBasePrice;

            variations.add(
              ProductVariationModel(
                id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
                sku: sku,
                price: varBasePrice,
                salePrice: varSalePrice,
                stock: stock,
                attributeValues: {
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

    return variations;
  }
}
