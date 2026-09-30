import 'package:equatable/equatable.dart';
import 'product_attribute.dart';
import 'product_brand.dart';
import 'product_category_type.dart';
import 'product_variation_model.dart';

// Re-export domain sub-models so existing imports throughout the app remain seamless.
export 'product_attribute.dart';
export 'product_brand.dart';
export 'product_category_type.dart';
export 'product_variation_model.dart';
export 'stock_movement_model.dart';

/// Comprehensive Product Model representing all vaping catalog items.
class ProductModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final double salePrice;
  final double costPrice;
  final int stock;
  final int? lowStockThreshold;
  final List<String> images;
  final ProductBrand brand;
  final String categoryId;
  final ProductCategoryType categoryType;
  final bool isBadgeEnabled;
  final String badgeId;
  final bool isOnline; // If true, visible in E-Commerce Mobile App. If false, POS/Store only.
  final String productType; // 'simple' or 'variable'
  final List<ProductAttribute> productAttributes;
  final List<ProductVariationModel> productVariations;
  final Map<String, dynamic> specifications;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.salePrice,
    this.costPrice = 0.0,
    required this.stock,
    this.lowStockThreshold,
    this.images = const [],
    required this.brand,
    required this.categoryId,
    this.categoryType = ProductCategoryType.liquid,
    this.isBadgeEnabled = false,
    this.badgeId = '',
    this.isOnline = true,
    this.productType = 'simple',
    this.productAttributes = const [],
    this.productVariations = const [],
    this.specifications = const {},
  });

  double get effectivePrice => salePrice > 0 ? salePrice : price;
  double get profitPerUnit => (effectivePrice - costPrice).clamp(0.0, double.infinity);
  double get profitMarginPercent => effectivePrice > 0 ? ((effectivePrice - costPrice) / effectivePrice) * 100 : 0.0;


  bool get isVariable =>
      productType == 'variable' || productVariations.isNotEmpty;

  /// Dynamic primary thumbnail resolved from the first image in [images].
  String get thumbnail => images.isNotEmpty ? images.first : '';

  /// Dynamic flavor list resolved directly from [productAttributes] or [productVariations].
  List<String> get flavors {
    for (final attr in productAttributes) {
      if (attr.name.toLowerCase().contains('flav')) {
        return attr.values;
      }
    }
    final Set<String> flavsFromVars = {};
    for (final v in productVariations) {
      v.attributeValues.forEach((key, val) {
        if (key.toLowerCase().contains('flav') && val.trim().isNotEmpty) {
          flavsFromVars.add(val.trim());
        }
      });
    }
    if (flavsFromVars.isNotEmpty) return flavsFromVars.toList();

    final specFlavors = specifications['flavors'];
    if (specFlavors is List && specFlavors.isNotEmpty) {
      return specFlavors
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return const [];
  }

  /// Dynamic Display Title resolving cleanly for all product categories:
  /// - If title is explicitly set (and not 'Untitled Product' / 'Untitled'): use it.
  /// - For Liquids & Disposables:
  ///   - 1 Flavor: Flavor Name
  ///   - >1 Flavors: Brand Name
  ///   - No Flavors: Brand Name
  /// - Fallback: Brand Name or Category Type
  String get displayTitle {
    final cleanTitle = title.trim();
    if (cleanTitle.isNotEmpty &&
        !cleanTitle.toLowerCase().contains('untitled')) {
      return cleanTitle;
    }

    final flavs = flavors;
    if (categoryType == ProductCategoryType.liquid ||
        categoryType == ProductCategoryType.disposable) {
      if (flavs.length == 1) {
        return flavs.first;
      } else if (brand.name.trim().isNotEmpty) {
        return brand.name.trim();
      } else if (flavs.isNotEmpty) {
        return flavs.join(', ');
      }
    }

    if (brand.name.trim().isNotEmpty) {
      return brand.name.trim();
    }

    if (flavs.isNotEmpty) {
      return flavs.first;
    }

    return categoryType.displayName;
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? salePrice,
    double? costPrice,
    int? stock,
    int? lowStockThreshold,
    List<String>? images,
    ProductBrand? brand,
    String? categoryId,
    ProductCategoryType? categoryType,
    bool? isBadgeEnabled,
    String? badgeId,
    bool? isOnline,
    String? productType,
    List<ProductAttribute>? productAttributes,
    List<ProductVariationModel>? productVariations,
    Map<String, dynamic>? specifications,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryType: categoryType ?? this.categoryType,
      isBadgeEnabled: isBadgeEnabled ?? this.isBadgeEnabled,
      badgeId: badgeId ?? this.badgeId,
      isOnline: isOnline ?? this.isOnline,
      productType: productType ?? this.productType,
      productAttributes: productAttributes ?? this.productAttributes,
      productVariations: productVariations ?? this.productVariations,
      specifications: specifications ?? this.specifications,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imagesList = _parseImages(json);
    final brand = _parseBrand(json);

    final catId =
        json['categoryId']?.toString() ??
        json['CategoryId']?.toString() ??
        json['category']?.toString() ??
        json['Category']?.toString() ??
        json['lineId']?.toString() ??
        json['LineId']?.toString() ??
        'general';

    final rawType =
        json['categoryType']?.toString() ??
        json['productCategoryType']?.toString() ??
        json['productType']?.toString() ??
        catId;

    final determinedType = ProductCategoryType.fromString(rawType);
    final specsMap = _parseSpecifications(json);
    final sanitizedAttrs = _parseAttributes(json, determinedType);
    final sanitizedVars = _parseVariations(json, determinedType);
    final resolvedTitle = _parseTitle(json, determinedType);

    final rawBadgeId =
        json['badgeId']?.toString() ??
        json['BadgeId']?.toString() ??
        json['badgeRef']?.toString() ??
        json['badge']?.toString() ??
        '';

    final hasBadge =
        json['isBadgeEnabled'] == true ||
        json['IsBadgeEnabled'] == true ||
        json['hasBadge'] == true ||
        rawBadgeId.isNotEmpty;

    final isOnlineVal = json['isOnline'] is bool
        ? json['isOnline'] as bool
        : (json['isOnline']?.toString().toLowerCase() != 'false');

    return ProductModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      title: resolvedTitle,
      description:
          json['description']?.toString() ??
          json['Description']?.toString() ??
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
      images: imagesList,
      brand: brand,
      categoryId: catId,
      categoryType: determinedType,
      isBadgeEnabled: hasBadge,
      badgeId: rawBadgeId,
      isOnline: isOnlineVal,
      productType:
          (json['productType'] ??
                  json['ProductType'] ??
                  json['type'] ??
                  'simple')
              .toString()
              .toLowerCase(),
      productAttributes: sanitizedAttrs,
      productVariations: sanitizedVars,
      specifications: specsMap,
    );
  }

  Map<String, dynamic> toJson({bool forFirestore = false}) {
    final bool isLiquid = categoryType == ProductCategoryType.liquid;
    final String liquidOriginVal =
        (specifications['liquidOrigin'] ??
                (specifications['isLocal'] == true ? 'Local' : 'Premium'))
            .toString();
    final String liquidCategoryLabel =
        liquidOriginVal.toLowerCase().contains('local')
        ? 'Local Liquid'
        : 'Premium Liquid';

    return {
      'id': id,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'costPrice': costPrice,
      'stock': stock,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      'images': images,
      'brand': brand.toJson(),
      'categoryId': categoryId,
      'categoryType': isLiquid ? liquidCategoryLabel : categoryType.name,
      if (!isLiquid) ...{'title': title, 'name': title},
      'isBadgeEnabled': isBadgeEnabled,
      'badgeId': isBadgeEnabled ? badgeId : '',
      'isOnline': isOnline,
      'productType': productVariations.isNotEmpty ? 'variable' : productType,
      'productAttributes': productAttributes.map((e) => e.toJson()).toList(),
      'productVariations': productVariations.map((e) => e.toJson()).toList(),
      'specifications': specifications,
    };
  }

  // --- PRIVATE CLEAN ARCHITECTURE PARSER HELPERS ---

  static List<String> _parseImages(Map<String, dynamic> json) {
    final rawImages =
        json['images'] ?? json['Images'] ?? json['imageUrls'] ?? [];
    final List<String> imagesList = [];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img != null && img.toString().isNotEmpty) {
          imagesList.add(img.toString());
        }
      }
    }

    final fallbackThumb =
        json['thumbnail']?.toString() ??
        json['Thumbnail']?.toString() ??
        json['image']?.toString() ??
        json['Image']?.toString();

    if (fallbackThumb != null &&
        fallbackThumb.trim().isNotEmpty &&
        !imagesList.contains(fallbackThumb.trim())) {
      imagesList.insert(0, fallbackThumb.trim());
    }

    return imagesList;
  }

  static ProductBrand _parseBrand(Map<String, dynamic> json) {
    final rawBrand = json['brand'] ??
        json['Brand'] ??
        json['brandName'] ??
        json['BrandName'] ??
        json['line'] ??
        json['lineName'];
    return ProductBrand.fromJson(rawBrand);
  }

  static Map<String, dynamic> _parseSpecifications(Map<String, dynamic> json) {
    final rawSpecs = json['specifications'] ?? json['specs'] ?? {};
    final Map<String, dynamic> specsMap = {};
    if (rawSpecs is Map) {
      rawSpecs.forEach((k, v) {
        final kLower = k.toString().toLowerCase();
        if (kLower != 'type' && kLower != 'liquidtype') {
          specsMap[k.toString()] = v;
        }
      });
    }
    final rootStyle = json['vapeStyle'] ?? json['style'] ?? json['Style'];
    if (rootStyle != null && !specsMap.containsKey('vapeStyle')) {
      specsMap['vapeStyle'] = rootStyle.toString();
    }
    final rootFlavors = json['flavors'] ?? json['Flavors'];
    if (rootFlavors != null && !specsMap.containsKey('flavors')) {
      specsMap['flavors'] = rootFlavors;
    }
    final rootOrigin = json['liquidOrigin'] ?? json['origin'];
    if (rootOrigin != null && !specsMap.containsKey('liquidOrigin')) {
      specsMap['liquidOrigin'] = rootOrigin.toString();
    } else if (!specsMap.containsKey('liquidOrigin')) {
      final catType = json['categoryType']?.toString() ?? '';
      if (catType.toLowerCase().contains('local')) {
        specsMap['liquidOrigin'] = 'Local';
      } else if (catType.toLowerCase().contains('prem')) {
        specsMap['liquidOrigin'] = 'Premium';
      }
    }
    return specsMap;
  }

  static List<ProductAttribute> _parseAttributes(
    Map<String, dynamic> json,
    ProductCategoryType determinedType,
  ) {
    final rawAttrs = json['productAttributes'] ?? json['ProductAttributes'];
    final List<ProductAttribute> attrsList = [];
    if (rawAttrs is List) {
      for (final item in rawAttrs) {
        if (item is ProductAttribute) {
          final n = item.name.toLowerCase();
          if (n != 'wattage' && n != 'watt' && n != 'type' && n != 'liquidtype') {
            attrsList.add(item);
          }
        } else if (item is Map) {
          final attr = ProductAttribute.fromJson(
            Map<String, dynamic>.from(item),
          );
          final n = attr.name.toLowerCase();
          if (n != 'wattage' && n != 'watt' && n != 'type' && n != 'liquidtype') {
            attrsList.add(attr);
          }
        }
      }
    }

    final List<ProductAttribute> sanitizedAttrs = [];
    for (final attr in attrsList) {
      final nameLower = attr.name.toLowerCase();
      if (nameLower == 'wattage' ||
          nameLower == 'watt' ||
          nameLower == 'type' ||
          nameLower == 'liquidtype') {
        continue;
      }

      if (determinedType == ProductCategoryType.device ||
          determinedType == ProductCategoryType.accessory) {
        if (nameLower.contains('color')) {
          sanitizedAttrs.add(
            ProductAttribute(name: 'Color', values: attr.values.map((v) => v.trim()).toList()),
          );
        }
      } else if (determinedType == ProductCategoryType.pod ||
          determinedType == ProductCategoryType.coil) {
        if (nameLower.contains('res') ||
            nameLower.contains('ohm') ||
            nameLower.contains('pack') ||
            nameLower.contains('cap') ||
            nameLower.contains('fill')) {
          sanitizedAttrs.add(attr);
        }
      } else if (determinedType == ProductCategoryType.liquid) {
        if (nameLower.contains('flav') ||
            nameLower.contains('nic') ||
            nameLower.contains('size') ||
            nameLower.contains('style')) {
          sanitizedAttrs.add(attr);
        }
      } else {
        sanitizedAttrs.add(attr);
      }
    }
    return sanitizedAttrs;
  }

  static List<ProductVariationModel> _parseVariations(
    Map<String, dynamic> json,
    ProductCategoryType determinedType,
  ) {
    final rawVars = json['productVariations'] ?? json['ProductVariations'];
    final List<ProductVariationModel> varsList = [];
    if (rawVars is List) {
      for (final item in rawVars) {
        if (item is ProductVariationModel) {
          varsList.add(item);
        } else if (item is Map) {
          varsList.add(
            ProductVariationModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final List<ProductVariationModel> sanitizedVars = [];
    for (final v in varsList) {
      final Map<String, String> cleanedMap = {};
      v.attributeValues.forEach((key, val) {
        final kLower = key.toLowerCase();
        if (kLower == 'wattage' ||
            kLower == 'watt' ||
            kLower == 'type' ||
            kLower == 'liquidtype') {
          return;
        }

        if (determinedType == ProductCategoryType.device ||
            determinedType == ProductCategoryType.accessory) {
          if (kLower.contains('color')) {
            cleanedMap['Color'] = val.trim();
          } else {
            cleanedMap[key] = val;
          }
        } else if (determinedType == ProductCategoryType.pod ||
            determinedType == ProductCategoryType.coil) {
          if (kLower.contains('res') || kLower.contains('ohm')) {
            cleanedMap['Resistance'] = val;
          } else if (kLower.contains('cap') || kLower.contains('سعة')) {
            cleanedMap['Capacity'] = val;
          } else if (kLower.contains('fill') || kLower.contains('ملء')) {
            cleanedMap['FillType'] = val;
          } else if (kLower.contains('pack')) {
            cleanedMap['Pack'] = val;
          } else {
            cleanedMap[key] = val;
          }
        } else {
          cleanedMap[key] = val;
        }
      });
      sanitizedVars.add(v.copyWith(attributeValues: cleanedMap));
    }
    return sanitizedVars;
  }

  static String _parseTitle(
    Map<String, dynamic> json,
    ProductCategoryType determinedType,
  ) {
    final rawTitle =
        json['title'] ??
        json['Title'] ??
        json['name'] ??
        json['Name'] ??
        json['liquidName'] ??
        json['LiquidName'];
    if (rawTitle != null &&
        rawTitle.toString().trim().isNotEmpty &&
        !rawTitle.toString().trim().toLowerCase().contains('untitled')) {
      return rawTitle.toString().trim();
    } else {
      return '';
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    salePrice,
    costPrice,
    stock,
    lowStockThreshold,
    images,
    brand,
    categoryId,
    categoryType,
    isBadgeEnabled,
    badgeId,
    isOnline,
    productType,
    productAttributes,
    productVariations,
    specifications,
  ];
}
