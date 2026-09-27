import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'product_type_strategy.dart';

/// Accessory Category Strategy handling batteries, tools, cotton, glass, cases, and hardware accessories.
class AccessoryTypeStrategy implements ProductTypeStrategy {
  const AccessoryTypeStrategy();

  @override
  ProductCategoryType get categoryType => ProductCategoryType.accessory;

  @override
  String resolveCategoryId(ProductFormState state) => 'CAT_ACCESSORIES';

  @override
  List<ProductAttribute> buildProductAttributes(ProductFormState state) {
    final List<ProductAttribute> attributes = [];

    if (state.selectedColors.isNotEmpty) {
      attributes.add(ProductAttribute(name: 'Color', values: state.selectedColors));
    } else {
      final List<String> allImages = [];
      if (state.thumbnail.trim().isNotEmpty) {
        allImages.add(state.thumbnail.trim());
      }
      for (final img in state.images) {
        final clean = img.trim();
        if (clean.isNotEmpty && !allImages.contains(clean)) {
          allImages.add(clean);
        }
      }
      if (allImages.length > 1) {
        attributes.add(
          ProductAttribute(
            name: 'Option',
            values: List.generate(allImages.length, (i) => 'Option ${i + 1}'),
          ),
        );
      }
    }
    return attributes;
  }

  @override
  Map<String, dynamic> buildSpecifications(ProductFormState state) {
    final Map<String, dynamic> specs = {
      'categoryType': categoryType.name,
    };
    if (state.selectedColors.isNotEmpty) {
      specs['colors'] = state.selectedColors;
    }
    if (state.colorImages.isNotEmpty) {
      specs['colorImages'] = state.colorImages;
    }
    if (state.compatibleProductIds.isNotEmpty) {
      specs['compatibleProductIds'] = state.compatibleProductIds;
      specs['relatedProductIds'] = state.compatibleProductIds;
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
        : (brandClean.isNotEmpty ? brandClean : 'ACC');
    final price = state.salePrice > 0 ? state.salePrice : state.basePrice;
    final stock = state.baseStock;

    // 1. If colors are selected: generate variations per color
    if (state.selectedColors.isNotEmpty) {
      final List<ProductVariationModel> variations = [];
      for (final color in state.selectedColors) {
        final colorCode = color
            .replaceAll('#', '')
            .replaceAll('/', '-')
            .replaceAll(' ', '')
            .toUpperCase();
        final sku = '$prefix-$colorCode'.toUpperCase();
        final image = state.colorImages[color] ?? '';

        variations.add(
          ProductVariationModel(
            id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${variations.length}',
            sku: sku,
            price: state.basePrice,
            salePrice: price,
            stock: stock,
            image: image,
            attributeValues: {
              'Color': color,
            },
          ),
        );
      }
      return variations;
    }

    // 2. If NO colors, but multiple images are added: generate variations per image!
    final List<String> allImages = [];
    if (state.thumbnail.trim().isNotEmpty) {
      allImages.add(state.thumbnail.trim());
    }
    for (final img in state.images) {
      final clean = img.trim();
      if (clean.isNotEmpty && !allImages.contains(clean)) {
        allImages.add(clean);
      }
    }

    if (allImages.length > 1) {
      final List<ProductVariationModel> variations = [];
      for (int i = 0; i < allImages.length; i++) {
        final imgUrl = allImages[i];
        final optName = 'Option ${i + 1}';
        final sku = '$prefix-OPT-${i + 1}'.toUpperCase();

        variations.add(
          ProductVariationModel(
            id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_$i',
            sku: sku,
            price: state.basePrice,
            salePrice: price,
            stock: stock,
            image: imgUrl,
            attributeValues: {
              'Option': optName,
            },
          ),
        );
      }
      return variations;
    }

    // 3. Single standard variation
    return [
      ProductVariationModel(
        id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_0',
        sku: '$prefix-STD'.toUpperCase(),
        price: state.basePrice,
        salePrice: price,
        stock: stock,
        image: allImages.isNotEmpty ? allImages.first : '',
        attributeValues: const {},
      ),
    ];
  }
}
