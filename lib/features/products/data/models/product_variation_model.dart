import 'package:equatable/equatable.dart';

/// Single product variation with unique SKU, price, stock, and attribute values.
class ProductVariationModel extends Equatable {
  final String id;
  final String sku;
  final double price;
  final double salePrice;
  final double costPrice;
  final int stock;
  final int? lowStockThreshold;
  final String image;
  final Map<String, String> attributeValues;
  final Map<String, int> branchStock;

  const ProductVariationModel({
    required this.id,
    required this.sku,
    required this.price,
    required this.salePrice,
    this.costPrice = 0.0,
    required this.stock,
    this.lowStockThreshold,
    this.image = '',
    required this.attributeValues,
    this.branchStock = const {},
  });

  double get effectivePrice => salePrice > 0 ? salePrice : price;
  double get profitPerUnit => (effectivePrice - costPrice).clamp(0.0, double.infinity);
  double get profitMarginPercent => effectivePrice > 0 ? ((effectivePrice - costPrice) / effectivePrice) * 100 : 0.0;

  /// Returns stock for a specific branch or sum of all branches
  int getStockForBranch(String? branchId) {
    final bStock = branchStock;
    if (branchId == null || branchId == 'all' || branchId.isEmpty) {
      if (bStock.isNotEmpty) {
        return bStock.values.fold<int>(0, (sum, val) => sum + val);
      }
      return stock;
    }
    if (bStock.containsKey(branchId)) {
      return bStock[branchId] ?? 0;
    }
    if (bStock.isEmpty && (branchId == 'main_branch' || branchId == 'primary')) {
      return stock;
    }
    return 0;
  }

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    final rawAttrs =
        json['attributeValues'] ??
        json['AttributeValues'] ??
        json['attributes'] ??
        {};
    final Map<String, String> attrs = {};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) {
        final keyStr = k.toString();
        if (keyStr.toLowerCase() != 'wattage' &&
            keyStr.toLowerCase() != 'watt') {
          attrs[keyStr] = v.toString();
        }
      });
    }

    final rawBranchStock = json['branchStock'] ?? json['BranchStock'] ?? {};
    final Map<String, int> parsedBranchStock = {};
    if (rawBranchStock is Map) {
      rawBranchStock.forEach((k, v) {
        if (v is num) {
          parsedBranchStock[k.toString()] = v.toInt();
        }
      });
    }

    return ProductVariationModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      sku:
          json['sku']?.toString() ??
          json['Sku']?.toString() ??
          json['SKU']?.toString() ??
          '',
      price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 0.0,
      salePrice:
          (json['salePrice'] ?? json['SalePrice'] ?? json['price'] as num?)
              ?.toDouble() ??
          0.0,
      costPrice:
          (json['costPrice'] ?? json['CostPrice'] ?? json['cost'] as num?)
              ?.toDouble() ??
          0.0,
      stock:
          (json['stock'] ??
                  json['Stock'] ??
                  json['quantity'] ??
                  json['Quantity'] as num?)
              ?.toInt() ??
          0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
      image: json['image']?.toString() ?? json['Image']?.toString() ?? '',
      attributeValues: attrs,
      branchStock: parsedBranchStock,
    );
  }

  ProductVariationModel copyWith({
    String? id,
    String? sku,
    double? price,
    double? salePrice,
    double? costPrice,
    int? stock,
    int? lowStockThreshold,
    String? image,
    Map<String, String>? attributeValues,
    Map<String, int>? branchStock,
  }) {
    return ProductVariationModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      image: image ?? this.image,
      attributeValues: attributeValues ?? this.attributeValues,
      branchStock: branchStock ?? this.branchStock,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'price': price,
    'salePrice': salePrice,
    'costPrice': costPrice,
    'stock': stock,
    if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
    'image': image,
    'attributeValues': attributeValues,
    if (branchStock.isNotEmpty) 'branchStock': branchStock,
  };

  @override
  List<Object?> get props => [
    id,
    sku,
    price,
    salePrice,
    costPrice,
    stock,
    lowStockThreshold,
    image,
    attributeValues,
    branchStock,
  ];
}
