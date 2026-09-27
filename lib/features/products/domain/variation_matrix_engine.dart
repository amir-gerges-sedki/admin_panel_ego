import '../data/models/product_model.dart';
import '../presentation/cubit/product_form_cubit.dart';
import 'strategies/product_type_strategy.dart';

/// Domain engine orchestrating product variations generation and bulk matrix updates.
class VariationMatrixEngine {
  VariationMatrixEngine._();

  /// Generates dynamic variations for the given [state] by delegating to the appropriate [ProductTypeStrategy],
  /// while preserving custom prices, sale prices, stock, and images for existing matching variations.
  static List<ProductVariationModel> generateVariations(ProductFormState state) {
    final strategy = ProductTypeStrategy.forType(state.categoryType);
    final newVars = strategy.generateVariations(state);

    if (state.variations.isEmpty) {
      return newVars;
    }

    return newVars.map((newVar) {
      final matches = state.variations.where(
        (oldVar) => _areAttributeValuesEqual(oldVar.attributeValues, newVar.attributeValues),
      );

      if (matches.isNotEmpty) {
        final existing = matches.first;
        final color = newVar.attributeValues['Color'] ?? newVar.attributeValues['color'];
        final fallbackImage = newVar.image.isNotEmpty
            ? newVar.image
            : (color != null ? (state.colorImages[color] ?? '') : '');
        return newVar.copyWith(
          id: existing.id.isNotEmpty ? existing.id : newVar.id,
          sku: existing.sku.isNotEmpty ? existing.sku : newVar.sku,
          price: existing.price > 0 ? existing.price : newVar.price,
          salePrice: existing.salePrice > 0 ? existing.salePrice : newVar.salePrice,
          costPrice: existing.costPrice > 0
              ? existing.costPrice
              : (newVar.costPrice > 0 ? newVar.costPrice : state.baseCostPrice),
          stock: existing.stock >= 0 ? existing.stock : newVar.stock,
          image: existing.image.isNotEmpty ? existing.image : fallbackImage,
        );
      }
      final color = newVar.attributeValues['Color'] ?? newVar.attributeValues['color'];
      final withCost = state.baseCostPrice > 0 && newVar.costPrice == 0
          ? newVar.copyWith(costPrice: state.baseCostPrice)
          : newVar;
      if (withCost.image.isEmpty && color != null && state.colorImages.containsKey(color)) {
        return withCost.copyWith(image: state.colorImages[color]);
      }
      return withCost;
    }).toList();
  }

  static bool _areAttributeValuesEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.isEmpty && b.isEmpty) return true;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      final keyClean = entry.key.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
      final matchingKey = b.keys.firstWhere(
        (k) => k.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '') == keyClean,
        orElse: () => '',
      );
      if (matchingKey.isEmpty) return false;
      final valA = entry.value?.toString().trim().toLowerCase() ?? '';
      final valB = b[matchingKey]?.toString().trim().toLowerCase() ?? '';
      if (valA != valB) return false;
    }
    return true;
  }

  /// Bulk updates price and stock across all variations in [variations].
  static List<ProductVariationModel> applyBulkPriceAndStock({
    required List<ProductVariationModel> variations,
    required double basePrice,
    required double salePrice,
    required int stock,
    double? costPrice,
  }) {
    return variations
        .map(
          (v) => v.copyWith(
            price: basePrice > 0 ? basePrice : v.price,
            salePrice: salePrice > 0 ? salePrice : v.salePrice,
            costPrice: (costPrice != null && costPrice >= 0) ? costPrice : v.costPrice,
            stock: stock >= 0 ? stock : v.stock,
          ),
        )
        .toList();
  }

  /// Applies tiered pricing for Liquid products based on vape style, nicotine strength, and bottle size.
  ///
  /// - [mtlStandardPrice] & [mtlStandardSalePrice]: Applied to MTL with standard Freebase nicotines (3mg, 6mg, 9mg, 12mg).
  /// - [mtl18mgPrice] & [mtl18mgSalePrice]: Applied to MTL with 18mg nicotine.
  /// - [dl3mgPrice] & [dl3mgSalePrice]: Applied to DL with 3mg nicotine.
  /// - [dl6mgPrice] & [dl6mgSalePrice]: Applied to DL with 6mg nicotine.
  /// - [salt30mgPrice] & [salt30mgSalePrice]: Applied to Salt Nic with 30mg (and 20mg/25mg).
  /// - [salt50mgPrice] & [salt50mgSalePrice]: Applied to Salt Nic with 50mg.
  /// - [targetSize]: If specified and not 'ALL', limits updates to variations matching that size.
  static List<ProductVariationModel> applyLiquidTierPrices({
    required List<ProductVariationModel> variations,
    String? targetSize,
    double? mtlStandardPrice,
    double? mtlStandardSalePrice,
    double? dl3mgPrice,
    double? dl3mgSalePrice,
    double? dl6mgPrice,
    double? dl6mgSalePrice,
    double? mtl18mgPrice,
    double? mtl18mgSalePrice,
    double? salt30mgPrice,
    double? salt30mgSalePrice,
    double? salt50mgPrice,
    double? salt50mgSalePrice,
  }) {
    final cleanTargetSize = targetSize?.replaceAll(' ', '').toUpperCase();
    final applyToAllSizes = cleanTargetSize == null ||
        cleanTargetSize.isEmpty ||
        cleanTargetSize == 'ALL';

    return variations.map((v) {
      // 1. Filter by bottle size if targetSize is specified
      if (!applyToAllSizes) {
        final varSize = (v.attributeValues['Size'] ?? '').replaceAll(' ', '').toUpperCase();
        if (varSize != cleanTargetSize) {
          return v;
        }
      }

      // 2. Resolve Style and Nicotine
      final style = (v.attributeValues['Style'] ?? '').trim().toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').trim().toLowerCase();

      double? resolvedPrice;
      double? resolvedSalePrice;

      if (style == 'MTL') {
        if (nic.contains('18')) {
          if (mtl18mgPrice != null && mtl18mgPrice >= 0) resolvedPrice = mtl18mgPrice;
          if (mtl18mgSalePrice != null && mtl18mgSalePrice >= 0) resolvedSalePrice = mtl18mgSalePrice;
        } else if (nic.contains('30') || nic.contains('20') || nic.contains('25')) {
          if (salt30mgPrice != null && salt30mgPrice >= 0) resolvedPrice = salt30mgPrice;
          if (salt30mgSalePrice != null && salt30mgSalePrice >= 0) resolvedSalePrice = salt30mgSalePrice;
        } else if (nic.contains('50')) {
          if (salt50mgPrice != null && salt50mgPrice >= 0) resolvedPrice = salt50mgPrice;
          if (salt50mgSalePrice != null && salt50mgSalePrice >= 0) resolvedSalePrice = salt50mgSalePrice;
        } else if (nic.contains('3') || nic.contains('6') || nic.contains('9') || nic.contains('12')) {
          // Standard MTL Freebase group (6mg, 9mg, 12mg, and 3mg if MTL)
          if (mtlStandardPrice != null && mtlStandardPrice >= 0) resolvedPrice = mtlStandardPrice;
          if (mtlStandardSalePrice != null && mtlStandardSalePrice >= 0) resolvedSalePrice = mtlStandardSalePrice;
        }
      } else if (style == 'DL') {
        if (nic.contains('3')) {
          if (dl3mgPrice != null && dl3mgPrice >= 0) resolvedPrice = dl3mgPrice;
          if (dl3mgSalePrice != null && dl3mgSalePrice >= 0) resolvedSalePrice = dl3mgSalePrice;
        } else if (nic.contains('6')) {
          if (dl6mgPrice != null && dl6mgPrice >= 0) resolvedPrice = dl6mgPrice;
          if (dl6mgSalePrice != null && dl6mgSalePrice >= 0) resolvedSalePrice = dl6mgSalePrice;
        }
      } else {
        // Fallback when style is omitted
        if (nic.contains('30') || nic.contains('20') || nic.contains('25')) {
          if (salt30mgPrice != null && salt30mgPrice >= 0) resolvedPrice = salt30mgPrice;
          if (salt30mgSalePrice != null && salt30mgSalePrice >= 0) resolvedSalePrice = salt30mgSalePrice;
        } else if (nic.contains('50')) {
          if (salt50mgPrice != null && salt50mgPrice >= 0) resolvedPrice = salt50mgPrice;
          if (salt50mgSalePrice != null && salt50mgSalePrice >= 0) resolvedSalePrice = salt50mgSalePrice;
        } else if (nic.contains('3')) {
          if (dl3mgPrice != null && dl3mgPrice >= 0) {
            resolvedPrice = dl3mgPrice;
          } else if (mtlStandardPrice != null && mtlStandardPrice >= 0) {
            resolvedPrice = mtlStandardPrice;
          }
          if (dl3mgSalePrice != null && dl3mgSalePrice >= 0) {
            resolvedSalePrice = dl3mgSalePrice;
          } else if (mtlStandardSalePrice != null && mtlStandardSalePrice >= 0) {
            resolvedSalePrice = mtlStandardSalePrice;
          }
        } else if (nic.contains('6')) {
          if (dl6mgPrice != null && dl6mgPrice >= 0) {
            resolvedPrice = dl6mgPrice;
          } else if (mtlStandardPrice != null && mtlStandardPrice >= 0) {
            resolvedPrice = mtlStandardPrice;
          }
          if (dl6mgSalePrice != null && dl6mgSalePrice >= 0) {
            resolvedSalePrice = dl6mgSalePrice;
          } else if (mtlStandardSalePrice != null && mtlStandardSalePrice >= 0) {
            resolvedSalePrice = mtlStandardSalePrice;
          }
        } else if (nic.contains('9') || nic.contains('12')) {
          if (mtlStandardPrice != null && mtlStandardPrice >= 0) resolvedPrice = mtlStandardPrice;
          if (mtlStandardSalePrice != null && mtlStandardSalePrice >= 0) resolvedSalePrice = mtlStandardSalePrice;
        }
      }

      if (resolvedPrice != null || resolvedSalePrice != null) {
        final newPrice = resolvedPrice ?? v.price;
        final newSalePrice = (resolvedSalePrice != null && resolvedSalePrice > 0)
            ? resolvedSalePrice
            : (resolvedPrice ?? v.salePrice);
        return v.copyWith(
          price: newPrice,
          salePrice: newSalePrice,
        );
      }

      return v;
    }).toList();
  }

  /// Removes variations matching a specific bottle size and nicotine tier.
  /// Used when certain variations (e.g. 100ml with 6mg, 9mg, 12mg MTL) do not exist in inventory.
  static List<ProductVariationModel> removeLiquidTierVariations({
    required List<ProductVariationModel> variations,
    required String targetSize,
    required String tierKey,
  }) {
    final cleanTargetSize = targetSize.replaceAll(' ', '').toUpperCase();
    if (cleanTargetSize.isEmpty || cleanTargetSize == 'ALL') {
      return variations;
    }

    return variations.where((v) {
      final varSize = (v.attributeValues['Size'] ?? '').replaceAll(' ', '').toUpperCase();
      if (varSize != cleanTargetSize) {
        return true; // Keep other bottle sizes intact!
      }

      final style = (v.attributeValues['Style'] ?? '').trim().toUpperCase();
      final nic = (v.attributeValues['Nicotine'] ?? '').trim().toLowerCase();

      switch (tierKey.toLowerCase()) {
        case 'mtl_standard':
          final isMtlStandard = (style == 'MTL' || style.isEmpty) &&
              (nic.contains('6') || nic.contains('9') || nic.contains('12') || nic.contains('3')) &&
              !nic.contains('18') &&
              !nic.contains('30') &&
              !nic.contains('50');
          return !isMtlStandard;

        case 'dl3':
          final isDl3 = (style == 'DL' || style.isEmpty) && nic.contains('3');
          return !isDl3;

        case 'dl6':
          final isDl6 = (style == 'DL' || style.isEmpty) && nic.contains('6');
          return !isDl6;

        case 'salt30':
          final isSalt30 = nic.contains('30') || nic.contains('20') || nic.contains('25');
          return !isSalt30;

        case 'salt50':
          final isSalt50 = nic.contains('50');
          return !isSalt50;

        case 'mtl18':
          final isMtl18 = (style == 'MTL' || style.isEmpty) && nic.contains('18');
          return !isMtl18;

        default:
          return true;
      }
    }).toList();
  }

  /// Applies a single image to all variations matching a specific attribute key and value.
  static List<ProductVariationModel> applyImageByAttribute({
    required List<ProductVariationModel> variations,
    required String attributeKey,
    required String targetValue,
    required String imageUrl,
  }) {
    final cleanKey = attributeKey.toLowerCase().trim();
    final cleanTarget = targetValue.trim();

    return variations.map((v) {
      bool matches = false;
      for (final entry in v.attributeValues.entries) {
        if (entry.key.toLowerCase().trim() == cleanKey && entry.value.trim() == cleanTarget) {
          matches = true;
          break;
        }
      }
      if (matches) {
        return v.copyWith(image: imageUrl.trim());
      }
      return v;
    }).toList();
  }

  /// Computes the effective selling price of a variation.
  static double effectivePrice(ProductVariationModel v) {
    if (v.salePrice > 0 && v.salePrice < v.price) {
      return v.salePrice;
    }
    if (v.price > 0) return v.price;
    if (v.salePrice > 0) return v.salePrice;
    return 0.0;
  }

  /// Builds the complete [ProductModel] from the current [state] using the appropriate [ProductTypeStrategy].
  /// When variations exist, the root [price] and [salePrice] automatically reflect the lowest available price
  /// across variations so customer-facing storefront product cards display the lowest price (e.g. "From 350 EGP").
  static ProductModel buildProductModel(ProductFormState state) {
    final strategy = ProductTypeStrategy.forType(state.categoryType);
    final now = DateTime.now();
    final id = state.initialProductId ?? 'PROD_${now.millisecondsSinceEpoch}';

    final categoryId = strategy.resolveCategoryId(state);
    final specifications = strategy.buildSpecifications(state);
    final attributes = strategy.buildProductAttributes(state);
    final resolvedTitle = strategy.resolveTitle(state);

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

    // Automatically compute root price, salePrice, and costPrice from variations (lowest price)
    double resolvedPrice = state.basePrice;
    double resolvedSalePrice = state.salePrice;
    double resolvedCostPrice = state.baseCostPrice;
    int resolvedStock = state.baseStock;

    if (state.variations.isNotEmpty) {
      final pricedVars = state.variations
          .where((v) => v.price > 0 || v.salePrice > 0)
          .toList();
      final pool = pricedVars.isNotEmpty ? pricedVars : state.variations;

      // Find the variation with the minimum effective price
      ProductVariationModel lowestVar = pool.first;
      double lowestEffective = effectivePrice(lowestVar);

      for (final v in pool) {
        final eff = effectivePrice(v);
        if (eff > 0 && (lowestEffective == 0 || eff < lowestEffective)) {
          lowestEffective = eff;
          lowestVar = v;
        }
      }

      if (lowestVar.salePrice > 0 && lowestVar.salePrice < lowestVar.price) {
        resolvedPrice = lowestVar.price;
        resolvedSalePrice = lowestVar.salePrice;
      } else {
        resolvedPrice = lowestVar.price > 0 ? lowestVar.price : lowestVar.salePrice;
        resolvedSalePrice = 0.0;
      }

      resolvedCostPrice = lowestVar.costPrice > 0 ? lowestVar.costPrice : state.baseCostPrice;
      resolvedStock = state.variations.fold(0, (acc, v) => acc + v.stock);
    }

    return ProductModel(
      id: id,
      title: resolvedTitle,
      description: state.description,
      price: resolvedPrice,
      salePrice: resolvedSalePrice,
      costPrice: resolvedCostPrice,
      stock: resolvedStock,
      images: distinctImages.toList(),
      brand: ProductBrand(
        id: state.brandId.isNotEmpty
            ? state.brandId
            : 'BRAND_${state.brandName.replaceAll(' ', '_').toUpperCase()}',
        name: state.brandName,
      ),
      categoryId: categoryId,
      categoryType: state.categoryType,
      isBadgeEnabled: state.isBadgeEnabled,
      badgeId: state.isBadgeEnabled ? state.badgeId : '',
      productType: state.variations.isNotEmpty ? 'variable' : 'simple',
      productAttributes: attributes,
      productVariations: state.variations,
      specifications: specifications,
    );
  }
}
