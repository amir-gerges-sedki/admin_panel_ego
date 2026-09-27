import '../../../../core/algorithms/cartesian_product.dart';
import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'product_type_strategy.dart';

/// Coils & Pod Cartridges Strategy handling multi-dimensional combinations (Resistance, Capacity, Fill Type).
class CoilsPodsTypeStrategy implements ProductTypeStrategy {
  const CoilsPodsTypeStrategy();

  @override
  ProductCategoryType get categoryType => ProductCategoryType.pod;

  @override
  String resolveCategoryId(ProductFormState state) {
    return state.categoryType == ProductCategoryType.coil
        ? 'CAT_COILS_PODS'
        : 'CAT_POD_SYSTEMS';
  }

  @override
  List<ProductAttribute> buildProductAttributes(ProductFormState state) {
    final List<ProductAttribute> attributes = [];

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

    return attributes;
  }

  @override
  Map<String, dynamic> buildSpecifications(ProductFormState state) {
    final resList = state.selectedPodResistances.isNotEmpty
        ? state.selectedPodResistances
        : state.selectedCoilResistances;

    final Map<String, dynamic> specs = {
      'categoryType': state.categoryType.name,
      if (state.podCompatibleDevices.trim().isNotEmpty)
        'compatibleDevices': state.podCompatibleDevices.trim()
      else if (state.coilCompatibleTanks.trim().isNotEmpty)
        'compatibleDevices': state.coilCompatibleTanks.trim(),
      if (state.podCapacity.trim().isNotEmpty)
        'capacity': state.podCapacity.trim(),
      'isPrefilled': state.isPrefilledPod,
      if (resList.isNotEmpty) 'resistances': resList,
      if (state.compatibleProductIds.isNotEmpty) ...{
        'compatibleProductIds': state.compatibleProductIds,
        'relatedProductIds': state.compatibleProductIds,
      },
    };

    if (state.selectedPodCapacities.isNotEmpty) {
      specs['capacities'] = state.selectedPodCapacities;
      if (!specs.containsKey('capacity') || (specs['capacity'] as String).isEmpty) {
        specs['capacity'] = state.selectedPodCapacities.join(', ');
      }
    }
    if (state.selectedPodFillTypes.isNotEmpty) {
      specs['fillTypes'] = state.selectedPodFillTypes;
      specs['fillSystem'] = state.selectedPodFillTypes.join(', ');
      specs['fillType'] = state.selectedPodFillTypes.join(', ');
    }

    final List<String> wattageSummary = [];
    for (final res in resList) {
      final watt = state.podResistanceWattages[res] ??
          ProductFormCubit.getSuggestedWattage(res);
      specs['$res Wattage'] = watt;
      if (watt.isNotEmpty) {
        if (resList.length == 1) {
          wattageSummary.add(watt);
        } else {
          wattageSummary.add('$res: $watt');
        }
      }
    }

    if (wattageSummary.isNotEmpty) {
      final summaryStr = wattageSummary.join(' | ');
      specs['wattage'] = summaryStr;
      specs['recommendedWattage'] = summaryStr;
    }

    return specs;
  }

  @override
  String resolveTitle(ProductFormState state) {
    return state.title.trim().isNotEmpty
        ? state.title.trim()
        : 'New ${state.categoryType.displayName} Product';
  }

  @override
  List<ProductVariationModel> generateVariations(ProductFormState state) {
    final brandClean = state.brandName.trim().isNotEmpty
        ? state.brandName.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase()
        : '';
    final prefix = state.baseSku.trim().isNotEmpty
        ? state.baseSku.trim().toUpperCase()
        : (brandClean.isNotEmpty ? brandClean : 'POD');
    final price = state.salePrice > 0 ? state.salePrice : state.basePrice;
    final stock = state.baseStock;

    final resList = state.selectedPodResistances.isNotEmpty
        ? state.selectedPodResistances
        : (state.selectedCoilResistances.isNotEmpty
            ? state.selectedCoilResistances
            : ['0.6Ω', '0.8Ω']);

    // Build dimensional maps for Cartesian product
    final Map<String, List<String>> dimensions = {
      'Resistance': resList,
    };

    if (state.selectedPodCapacities.isNotEmpty) {
      dimensions['Capacity'] = state.selectedPodCapacities;
    }
    if (state.selectedPodFillTypes.isNotEmpty) {
      dimensions['FillType'] = state.selectedPodFillTypes;
    }

    final combinations = CartesianProduct.computeNamed<String>(dimensions);
    final List<ProductVariationModel> variations = [];

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

      variations.add(
        ProductVariationModel(
          id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
          sku: sku,
          price: state.basePrice,
          salePrice: price,
          stock: stock,
          attributeValues: comb,
        ),
      );
    }

    return variations;
  }
}
