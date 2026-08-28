import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/helper/color_utils.dart';

enum ProductCategoryType {
  liquid,
  device,
  pod,
  coil,
  accessory;

  static List<ProductCategoryType> get visibleTypes => const [
    ProductCategoryType.liquid,
    ProductCategoryType.device,
    ProductCategoryType.pod,
    ProductCategoryType.accessory,
  ];

  String get id {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'CAT_LIQUIDS';
      case ProductCategoryType.device:
        return 'CAT_HARDWARE';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'CAT_COILS_PODS';
      case ProductCategoryType.accessory:
        return 'CAT_ACCESSORIES';
    }
  }

  String get displayName {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'E-Liquids';
      case ProductCategoryType.device:
        return 'Devices & Mods';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'Coils & Cartridges';
      case ProductCategoryType.accessory:
        return 'Accessories';
    }
  }

  String get arabicName {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'سوائل إلكترونية (Liquid)';
      case ProductCategoryType.device:
        return 'أجهزة ومودات (Device)';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'كويلات وكارتردج (Coils & Cartridges)';
      case ProductCategoryType.accessory:
        return 'إكسسوارات ومستلزمات';
    }
  }

  String get description {
    switch (this) {
      case ProductCategoryType.liquid:
        return 'سولت نيكوتين وفري بيز مع النكهات وسحب MTL/DL';
      case ProductCategoryType.device:
        return 'أجهزة فيب وبود كيت مع خيارات الألوان والبطارية';
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return 'كويلات مقاومة وبودات وكارتردج مع قيم المقاومة ونطاق الواط (Wattage)';
      case ProductCategoryType.accessory:
        return 'بطاريات وشواحن وقطن وزجاج وأدوات الصيانة';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategoryType.liquid:
        return Icons.water_drop_rounded;
      case ProductCategoryType.device:
        return Icons.vape_free_rounded;
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return Icons.flash_on_rounded;
      case ProductCategoryType.accessory:
        return Icons.handyman_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case ProductCategoryType.liquid:
        return const Color(0xFF0EA5E9); // Ocean Cyan
      case ProductCategoryType.device:
        return const Color(0xFF6366F1); // Indigo
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return const Color(0xFF10B981); // Emerald Green
      case ProductCategoryType.accessory:
        return const Color(0xFFEC4899); // Rose Pink
    }
  }

  static ProductCategoryType fromString(String? raw) {
    if (raw == null) return ProductCategoryType.liquid;
    final r = raw.toLowerCase();
    if (r.contains('liquid') ||
        r.contains('salt') ||
        r.contains('freebase') ||
        r.contains('juice') ||
        r.contains('flavor') ||
        r.contains('local') ||
        r.contains('prem') ||
        r.contains('prim')) {
      return ProductCategoryType.liquid;
    }
    if (r.contains('pod') ||
        r.contains('cartridge') ||
        r.contains('coil') ||
        r.contains('mesh') ||
        r.contains('resistance')) {
      return ProductCategoryType.pod;
    }
    if (r.contains('accessory') ||
        r.contains('battery') ||
        r.contains('charger') ||
        r.contains('cotton') ||
        r.contains('glass') ||
        r.contains('tool')) {
      return ProductCategoryType.accessory;
    }
    if (r.contains('device') ||
        r.contains('kit') ||
        r.contains('mod') ||
        r.contains('hardware')) {
      return ProductCategoryType.device;
    }
    return ProductCategoryType.liquid;
  }
}

class ProductBrand extends Equatable {
  final String id;
  final String name;
  final String image;
  final int productsCount;

  const ProductBrand({
    required this.id,
    required this.name,
    this.image = '',
    this.productsCount = 0,
  });

  factory ProductBrand.fromJson(dynamic json) {
    if (json == null) return const ProductBrand(id: '', name: 'General');
    if (json is String) {
      return ProductBrand(id: json, name: json);
    }
    if (json is Map) {
      return ProductBrand(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        name:
            json['name']?.toString() ??
            json['Name']?.toString() ??
            json['lineName']?.toString() ??
            json['LineName']?.toString() ??
            json['title']?.toString() ??
            '',
        image:
            json['image']?.toString() ??
            json['Image']?.toString() ??
            json['logo']?.toString() ??
            '',
        productsCount:
            (json['productsCount'] ?? json['ProductsCount'] as num?)?.toInt() ??
            0,
      );
    }
    return ProductBrand(id: '', name: json.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'productsCount': productsCount,
  };

  @override
  List<Object?> get props => [id, name, image, productsCount];
}

class ProductAttribute extends Equatable {
  final String name;
  final List<String> values;

  const ProductAttribute({required this.name, required this.values});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] ?? json['Values'];
    final List<String> parsedValues = rawValues is List
        ? rawValues.map((e) => e.toString()).toList()
        : <String>[];

    return ProductAttribute(
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      values: parsedValues,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'values': values};

  @override
  List<Object?> get props => [name, values];
}

class ProductVariationModel extends Equatable {
  final String id;
  final String sku;
  final double price;
  final double salePrice;
  final int stock;
  final String image;
  final Map<String, String> attributeValues;

  const ProductVariationModel({
    required this.id,
    required this.sku,
    required this.price,
    required this.salePrice,
    required this.stock,
    this.image = '',
    required this.attributeValues,
  });

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
      stock:
          (json['stock'] ??
                  json['Stock'] ??
                  json['quantity'] ??
                  json['Quantity'] as num?)
              ?.toInt() ??
          0,
      image: json['image']?.toString() ?? json['Image']?.toString() ?? '',
      attributeValues: attrs,
    );
  }

  ProductVariationModel copyWith({
    String? id,
    String? sku,
    double? price,
    double? salePrice,
    int? stock,
    String? image,
    Map<String, String>? attributeValues,
  }) {
    return ProductVariationModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      image: image ?? this.image,
      attributeValues: attributeValues ?? this.attributeValues,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'price': price,
    'salePrice': salePrice,
    'stock': stock,
    'image': image,
    'Image': image,
    'attributeValues': attributeValues,
    'attributes': attributeValues,
  };

  @override
  List<Object?> get props => [
    id,
    sku,
    price,
    salePrice,
    stock,
    image,
    attributeValues,
  ];
}

class ProductModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final double salePrice;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final ProductBrand brand;
  final String categoryId;
  final ProductCategoryType categoryType;
  final bool isFeatured;
  final bool isBadgeEnabled;
  final String badgeId;
  final String productType; // 'simple' or 'variable'
  final List<ProductAttribute> productAttributes;
  final List<ProductVariationModel> productVariations;
  final List<String> flavors;
  final Map<String, dynamic> specifications;
  final double rating;
  final int totalReviews;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.thumbnail,
    this.images = const [],
    required this.brand,
    required this.categoryId,
    this.categoryType = ProductCategoryType.liquid,
    this.isFeatured = false,
    this.isBadgeEnabled = false,
    this.badgeId = '',
    this.productType = 'simple',
    this.productAttributes = const [],
    this.productVariations = const [],
    this.flavors = const [],
    this.specifications = const {},
    this.rating = 5.0,
    this.totalReviews = 0,
  });

  bool get isVariable =>
      productType == 'variable' || productVariations.isNotEmpty;

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? salePrice,
    int? stock,
    String? thumbnail,
    List<String>? images,
    ProductBrand? brand,
    String? categoryId,
    ProductCategoryType? categoryType,
    bool? isFeatured,
    bool? isBadgeEnabled,
    String? badgeId,
    String? productType,
    List<ProductAttribute>? productAttributes,
    List<ProductVariationModel>? productVariations,
    List<String>? flavors,
    Map<String, dynamic>? specifications,
    double? rating,
    int? totalReviews,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryType: categoryType ?? this.categoryType,
      isFeatured: isFeatured ?? this.isFeatured,
      isBadgeEnabled: isBadgeEnabled ?? this.isBadgeEnabled,
      badgeId: badgeId ?? this.badgeId,
      productType: productType ?? this.productType,
      productAttributes: productAttributes ?? this.productAttributes,
      productVariations: productVariations ?? this.productVariations,
      flavors: flavors ?? this.flavors,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Images list
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

    final thumb =
        json['thumbnail']?.toString() ??
        json['Thumbnail']?.toString() ??
        json['image']?.toString() ??
        json['Image']?.toString() ??
        (imagesList.isNotEmpty ? imagesList.first : '');

    // Brand / Line detection
    final rawBrand =
        json['brandName'] ??
        json['BrandName'] ??
        json['brand'] ??
        json['Brand'] ??
        json['line'] ??
        json['Line'] ??
        json['lineName'] ??
        json['LineName'];

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

    // Flavors list
    final rawFlavors = json['flavors'] ?? json['Flavors'] ?? [];
    final List<String> flavorsList = [];
    if (rawFlavors is List) {
      for (final f in rawFlavors) {
        if (f != null && f.toString().isNotEmpty) {
          flavorsList.add(f.toString());
        }
      }
    }

    // Specifications
    final rawSpecs = json['specifications'] ?? json['specs'] ?? {};
    final Map<String, dynamic> specsMap = {};
    if (rawSpecs is Map) {
      rawSpecs.forEach((k, v) => specsMap[k.toString()] = v);
    }

    // Attributes list
    final rawAttrs = json['productAttributes'] ?? json['ProductAttributes'];
    final List<ProductAttribute> attrsList = [];
    if (rawAttrs is List) {
      for (final item in rawAttrs) {
        if (item is ProductAttribute) {
          if (item.name.toLowerCase() != 'wattage' &&
              item.name.toLowerCase() != 'watt') {
            attrsList.add(item);
          }
        } else if (item is Map) {
          final attr = ProductAttribute.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (attr.name.toLowerCase() != 'wattage' &&
              attr.name.toLowerCase() != 'watt') {
            attrsList.add(attr);
          }
        }
      }
    }

    // Variations list
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

    // Sanitize attributes list strictly by category type
    final List<ProductAttribute> sanitizedAttrs = [];
    for (final attr in attrsList) {
      final nameLower = attr.name.toLowerCase();
      if (nameLower == 'wattage' || nameLower == 'watt') continue;

      if (determinedType == ProductCategoryType.device) {
        // Device ONLY has Color - normalize each color value to hex!
        if (nameLower.contains('color')) {
          final List<String> normalizedValues = attr.values
              .map((val) {
                final text = val.trim();
                if (text.startsWith('#')) return text;
                final parsed = ColorUtils.parseColorsFromText(text);
                if (parsed.isNotEmpty) {
                  return ColorUtils.toHex(parsed.first);
                }
                return text;
              })
              .cast<String>()
              .toList();
          sanitizedAttrs.add(
            ProductAttribute(name: 'Color', values: normalizedValues),
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

    // Sanitize variation attributes strictly by category type
    final List<ProductVariationModel> sanitizedVars = [];
    for (final v in varsList) {
      final Map<String, String> cleanedMap = {};
      v.attributeValues.forEach((key, val) {
        final kLower = key.toLowerCase();
        if (kLower == 'wattage' || kLower == 'watt') return;

        if (determinedType == ProductCategoryType.device) {
          if (kLower.contains('color')) {
            // NORMALIZE TO HEX SO IT MATCHES PRODUCT ATTRIBUTES 100%!
            final text = val.trim();
            if (text.startsWith('#')) {
              cleanedMap['Color'] = text;
            } else {
              final parsed = ColorUtils.parseColorsFromText(text);
              if (parsed.isNotEmpty) {
                cleanedMap['Color'] = ColorUtils.toHex(parsed.first);
              } else {
                cleanedMap['Color'] = text;
              }
            }
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

    final rawTitle =
        json['title'] ??
        json['Title'] ??
        json['name'] ??
        json['Name'] ??
        json['liquidName'] ??
        json['LiquidName'];
    final String resolvedTitle;
    if (rawTitle != null && rawTitle.toString().trim().isNotEmpty) {
      resolvedTitle = rawTitle.toString().trim();
    } else if (determinedType == ProductCategoryType.liquid) {
      resolvedTitle = '';
    } else {
      resolvedTitle = 'Untitled Product';
    }

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
      stock:
          (json['stock'] ??
                  json['Stock'] ??
                  json['quantity'] ??
                  json['Quantity'] as num?)
              ?.toInt() ??
          0,
      thumbnail: thumb,
      images: imagesList,
      brand: ProductBrand.fromJson(rawBrand),
      categoryId: catId,
      categoryType: determinedType,
      isFeatured: json['isFeatured'] == true || json['IsFeatured'] == true,
      isBadgeEnabled: hasBadge,
      badgeId: rawBadgeId,
      productType:
          (json['productType'] ??
                  json['ProductType'] ??
                  json['type'] ??
                  'simple')
              .toString()
              .toLowerCase(),
      productAttributes: sanitizedAttrs,
      productVariations: sanitizedVars,
      flavors: determinedType == ProductCategoryType.liquid
          ? flavorsList
          : const [],
      specifications: specsMap,
      rating: (json['rating'] ?? json['Rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews:
          (json['totalReviews'] ?? json['TotalReviews'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson({bool forFirestore = false}) {
    final bool isLiquid = categoryType == ProductCategoryType.liquid;
    final String liquidOriginVal =
        (specifications['liquidOrigin'] ??
                specifications['liquidType'] ??
                (specifications['isLocal'] == true ? 'Local' : 'Premium'))
            .toString();
    final String liquidCategoryLabel =
        liquidOriginVal.toLowerCase().contains('local')
        ? 'Local Liquid'
        : 'Premium Liquid';

    final Map<String, dynamic> data = {
      'id': id,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'thumbnail': thumbnail,
      'Thumbnail': thumbnail,
      'image': thumbnail,
      'Image': thumbnail,
      'images': images,
      'Images': images,
      'imageUrls': images,
      'brand': brand.toJson(),
      'brandName': brand.name,
      'line': brand.name,
      'lineName': brand.name,
      'categoryId': isLiquid ? liquidCategoryLabel : categoryId,
      'category': isLiquid ? liquidCategoryLabel : categoryId,
      'subCategory': isLiquid ? liquidCategoryLabel : '',
      'subCategoryName': isLiquid ? liquidCategoryLabel : '',
      'categoryType': isLiquid ? liquidCategoryLabel : categoryType.name,
      'liquidOrigin': isLiquid ? liquidOriginVal : '',
      'liquidType': isLiquid ? liquidCategoryLabel : '',
      'origin': isLiquid ? liquidOriginVal : '',
      'isFeatured': isFeatured,
      'isBadgeEnabled': isBadgeEnabled,
      'badgeId': isBadgeEnabled ? badgeId : '',
      'productType': productVariations.isNotEmpty ? 'variable' : productType,
      'productAttributes': productAttributes.map((e) => e.toJson()).toList(),
      'ProductAttributes': productAttributes.map((e) => e.toJson()).toList(),
      'productVariations': productVariations.map((e) => e.toJson()).toList(),
      'ProductVariations': productVariations.map((e) => e.toJson()).toList(),
      'flavors': categoryType == ProductCategoryType.liquid
          ? flavors
          : <String>[],
      'specifications': specifications,
      'rating': rating,
      'totalReviews': totalReviews,
    };

    if (isLiquid) {
      if (forFirestore) {
        data['title'] = FieldValue.delete();
        data['name'] = FieldValue.delete();
        data['Title'] = FieldValue.delete();
        data['Name'] = FieldValue.delete();
      }
    } else {
      data['title'] = title;
      data['name'] = title;
    }

    return data;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    salePrice,
    stock,
    thumbnail,
    images,
    brand,
    categoryId,
    categoryType,
    isFeatured,
    isBadgeEnabled,
    badgeId,
    productType,
    productAttributes,
    productVariations,
    flavors,
    specifications,
    rating,
    totalReviews,
  ];
}
