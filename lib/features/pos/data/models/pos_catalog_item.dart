import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';

/// Represents a single saleable catalog unit in the POS cashier interface.
/// If a product is variable, each variation is expanded into its own [PosCatalogItem].
/// If a product is simple, it represents the product itself.
class PosCatalogItem extends Equatable {
  final ProductModel product;
  final ProductVariationModel? variation;

  const PosCatalogItem({
    required this.product,
    this.variation,
  });

  /// Unique identifier for this unit (variation ID if variable, or product ID)
  String get id => variation?.id.isNotEmpty == true ? variation!.id : product.id;

  /// Stock Keeping Unit / Barcode
  String get sku {
    if (variation != null && variation!.sku.isNotEmpty) {
      return variation!.sku;
    }
    final barcodeSpec = product.specifications['barcode']?.toString();
    if (barcodeSpec != null && barcodeSpec.isNotEmpty) {
      return barcodeSpec;
    }
    return product.id;
  }

  /// Brand name
  String get brandName => product.brand.name.trim();

  /// Product main title
  String get productTitle => product.title.trim();

  /// Category type
  ProductCategoryType get categoryType => product.categoryType;

  /// Effective selling price
  double get price => variation != null ? variation!.effectivePrice : product.effectivePrice;

  /// Original standard price before sale/discount
  double get originalPrice => variation != null ? variation!.price : product.price;

  /// Whether unit has a discount
  bool get hasDiscount => originalPrice > price;

  /// Cost price for profit margins
  double get costPrice => variation != null && variation!.costPrice > 0
      ? variation!.costPrice
      : product.costPrice;

  /// Real-time available stock
  int get stock => variation != null ? variation!.stock : product.stock;

  /// Out of stock check
  bool get isOutOfStock => stock <= 0;

  /// Low stock check
  bool get isLowStock {
    final threshold = variation?.lowStockThreshold ?? product.lowStockThreshold ?? 3;
    return stock > 0 && stock <= threshold;
  }

  /// Thumbnail image (variation specific or product thumbnail)
  String get thumbnail {
    if (variation != null && variation!.image.isNotEmpty) {
      return variation!.image;
    }
    return product.thumbnail;
  }

  /// Attribute values dictionary
  Map<String, String> get attributeValues => variation?.attributeValues ?? const {};

  /// Whether this item is a variation of a variable product
  bool get isVariation => variation != null;

  /// Extracted Flavor if present
  String? get flavor {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('flav') || k.contains('نكهة') || k.contains('طعم')) {
        return entry.value.trim();
      }
    }
    if (product.flavors.length == 1) {
      return product.flavors.first.trim();
    }
    return null;
  }

  /// Extracted Nicotine level if present
  String? get nicotine {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('nic') || k.contains('نيكوتين')) {
        return entry.value.trim();
      }
    }
    return null;
  }

  /// Extracted Bottle Size / Volume if present
  String? get size {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('size') || k.contains('حجم') || k.contains('سعة') || k.contains('volume')) {
        return entry.value.trim();
      }
    }
    return null;
  }

  /// Extracted Color if present
  String? get color {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('color') || k.contains('لون') || k.contains('colour')) {
        return entry.value.trim();
      }
    }
    return null;
  }

  /// Extracted Resistance / Ohm if present
  String? get resistance {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('res') || k.contains('ohm') || k.contains('مقاومة') || k.contains('Ω')) {
        return entry.value.trim();
      }
    }
    return null;
  }

  /// Extracted Vape Style (Salt Nic / Freebase / DL / MTL) if present
  String? get style {
    for (final entry in attributeValues.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('style') || k.contains('ستايل') || k.contains('نوع') || k.contains('type')) {
        return entry.value.trim();
      }
    }
    final specStyle = product.specifications['vapeStyle']?.toString();
    if (specStyle != null && specStyle.trim().isNotEmpty) {
      return specStyle.trim();
    }
    return null;
  }

  /// Prominent main title for cashier display (e.g. Flavor name, Color & Ohm, or Title)
  String get displayHeadline {
    if (flavor != null && flavor!.isNotEmpty) {
      return flavor!;
    }
    if (color != null && resistance != null) {
      return '$color • $resistance';
    }
    if (color != null && color!.isNotEmpty) {
      return color!;
    }
    if (resistance != null && resistance!.isNotEmpty) {
      return resistance!;
    }
    if (attributeValues.isNotEmpty) {
      return attributeValues.values.join(' • ');
    }
    return productTitle.isNotEmpty ? productTitle : brandName;
  }

  /// Secondary subtitle (e.g., Brand and parent product model)
  String get displaySubtitle {
    final cleanBrand = brandName;
    final cleanProduct = productTitle;

    if (displayHeadline == flavor || displayHeadline == color || displayHeadline == resistance) {
      if (cleanProduct.isNotEmpty && cleanProduct.toLowerCase() != cleanBrand.toLowerCase()) {
        return cleanBrand.isNotEmpty ? '$cleanBrand • $cleanProduct' : cleanProduct;
      }
      return cleanBrand;
    }

    if (cleanBrand.isNotEmpty && !cleanProduct.toLowerCase().contains(cleanBrand.toLowerCase())) {
      return cleanBrand;
    }

    return categoryType.displayName;
  }

  /// Search keyword matching helper
  bool matchesSearch(List<String> queryWords) {
    if (queryWords.isEmpty) return true;

    final searchableParts = <String>[
      productTitle.toLowerCase(),
      brandName.toLowerCase(),
      sku.toLowerCase(),
      id.toLowerCase(),
      if (flavor != null) flavor!.toLowerCase(),
      if (nicotine != null) nicotine!.toLowerCase(),
      if (size != null) size!.toLowerCase(),
      if (color != null) color!.toLowerCase(),
      if (resistance != null) resistance!.toLowerCase(),
      ...attributeValues.entries.map((e) => '${e.key} ${e.value}'.toLowerCase()),
      ...attributeValues.values.map((v) => v.toLowerCase()),
      ...product.flavors.map((f) => f.toLowerCase()),
      product.description.toLowerCase(),
      categoryType.name.toLowerCase(),
      categoryType.displayName.toLowerCase(),
    ];

    final combined = searchableParts.join(' ');
    return queryWords.every((word) => combined.contains(word));
  }

  @override
  List<Object?> get props => [id, sku, price, stock, attributeValues, product.id];
}
