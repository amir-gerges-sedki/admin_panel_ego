import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';

/// Single item in POS Cart with pricing, variation attributes, quantity, and item-level discount.
class PosCartItemModel extends Equatable {
  final String productId;
  final String title;
  final String brand;
  final String sku;
  final String image;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final int availableStock;
  final Map<String, String> selectedVariation;
  final String? variationId;
  final double discount; // Per-unit discount in EGP
  final String notes;

  const PosCartItemModel({
    required this.productId,
    required this.title,
    this.brand = '',
    this.sku = '',
    this.image = '',
    required this.unitPrice,
    this.costPrice = 0.0,
    required this.quantity,
    this.availableStock = 999,
    this.selectedVariation = const {},
    this.variationId,
    this.discount = 0.0,
    this.notes = '',
  });

  /// Effective price after unit discount
  double get effectiveUnitPrice => (unitPrice - discount).clamp(0.0, double.infinity);

  /// Line item total
  double get lineTotal => effectiveUnitPrice * quantity;

  /// Original line item total before discount
  double get originalLineTotal => unitPrice * quantity;

  /// Total discount on this line
  double get totalLineDiscount => discount * quantity;

  /// Formatted variation display string
  String get variationSummary {
    if (selectedVariation.isEmpty) return '';
    return selectedVariation.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  /// Full display title including brand
  String get fullTitle {
    final cleanBrand = brand.trim();
    final cleanTitle = title.trim();
    if (cleanBrand.isNotEmpty && !cleanTitle.toLowerCase().contains(cleanBrand.toLowerCase())) {
      return '$cleanBrand - $cleanTitle';
    }
    return cleanTitle;
  }

  PosCartItemModel copyWith({
    String? productId,
    String? title,
    String? brand,
    String? sku,
    String? image,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    int? availableStock,
    Map<String, String>? selectedVariation,
    String? variationId,
    double? discount,
    String? notes,
  }) {
    return PosCartItemModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      image: image ?? this.image,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
      selectedVariation: selectedVariation ?? this.selectedVariation,
      variationId: variationId ?? this.variationId,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
    );
  }

  /// Factory helper from ProductModel & optional ProductVariationModel
  factory PosCartItemModel.fromProduct(
    ProductModel product, {
    ProductVariationModel? variation,
    int quantity = 1,
  }) {
    if (variation != null) {
      return PosCartItemModel(
        productId: product.id,
        title: product.title,
        brand: product.brand.name,
        sku: variation.sku.isNotEmpty ? variation.sku : product.id,
        image: variation.image.isNotEmpty ? variation.image : product.thumbnail,
        unitPrice: variation.effectivePrice,
        costPrice: variation.costPrice > 0 ? variation.costPrice : product.costPrice,
        quantity: quantity,
        availableStock: variation.stock,
        selectedVariation: variation.attributeValues,
        variationId: variation.id,
      );
    }

    return PosCartItemModel(
      productId: product.id,
      title: product.title,
      brand: product.brand.name,
      sku: product.id,
      image: product.thumbnail,
      unitPrice: product.effectivePrice,
      costPrice: product.costPrice,
      quantity: quantity,
      availableStock: product.stock,
      selectedVariation: const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'brand': brand,
        'sku': sku,
        'image': image,
        'unitPrice': unitPrice,
        'costPrice': costPrice,
        'quantity': quantity,
        'selectedVariation': selectedVariation,
        if (variationId != null) 'variationId': variationId,
        if (discount > 0) 'discount': discount,
        if (notes.isNotEmpty) 'notes': notes,
        'lineTotal': lineTotal,
      };

  factory PosCartItemModel.fromJson(Map<String, dynamic> json) {
    return PosCartItemModel(
      productId: json['productId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      availableStock: (json['availableStock'] as num?)?.toInt() ?? 999,
      selectedVariation: json['selectedVariation'] != null
          ? Map<String, String>.from(json['selectedVariation'] as Map)
          : const {},
      variationId: json['variationId']?.toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        productId,
        title,
        brand,
        sku,
        image,
        unitPrice,
        costPrice,
        quantity,
        availableStock,
        selectedVariation,
        variationId,
        discount,
        notes,
      ];
}
