import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/localization/app_localizations.dart';

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) {
    final cleaned = val.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
  return 0;
}

DateTime _parseFirestoreDateTime(dynamic date) {
  if (date == null) return DateTime.now();
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString()) ?? DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic date) {
  if (date == null) return null;
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString());
}

class OrderItemModel extends Equatable {
  final String productId;
  final String title;
  final double price;
  final double? originalPrice;
  final int quantity;
  final Map<String, String> selectedVariation;
  final String image;
  final String brand;
  final String sku;
  final String notes;

  const OrderItemModel({
    required this.productId,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.quantity,
    this.selectedVariation = const {},
    this.image = '',
    this.brand = '',
    this.sku = '',
    this.notes = '',
  });

  double get totalItemPrice => price * quantity;

  factory OrderItemModel.fromJson(dynamic rawJson) {
    if (rawJson == null) {
      return const OrderItemModel(productId: '', title: 'Item', price: 0.0, quantity: 1);
    }

    Map<String, dynamic> json;
    if (rawJson is String) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map) {
          json = Map<String, dynamic>.from(decoded);
        } else {
          return OrderItemModel(productId: '', title: rawJson, price: 0.0, quantity: 1);
        }
      } catch (_) {
        return OrderItemModel(productId: '', title: rawJson, price: 0.0, quantity: 1);
      }
    } else if (rawJson is Map) {
      json = Map<String, dynamic>.from(rawJson);
    } else {
      return const OrderItemModel(productId: '', title: 'Item', price: 0.0, quantity: 1);
    }

    // Support nested product, productDetails, or item map
    final prodMap = (json['product'] is Map)
        ? Map<String, dynamic>.from(json['product'] as Map)
        : (json['productDetails'] is Map)
            ? Map<String, dynamic>.from(json['productDetails'] as Map)
            : (json['productData'] is Map)
                ? Map<String, dynamic>.from(json['productData'] as Map)
                : (json['item'] is Map)
                    ? Map<String, dynamic>.from(json['item'] as Map)
                    : null;

    // Parse variations (could be Map, String, List, or individual fields)
    final rawVar = json['selectedVariation'] ??
        json['SelectedVariation'] ??
        json['variation'] ??
        json['variations'] ??
        json['attributes'] ??
        json['selectedAttributes'] ??
        json['variationMap'] ??
        json['options'] ??
        json['selectedOptions'] ??
        prodMap?['selectedVariation'] ??
        prodMap?['variation'] ??
        prodMap?['attributes'];

    final Map<String, String> rawExtracted = {};
    if (rawVar is Map) {
      rawVar.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          rawExtracted[k.toString().trim()] = v.toString().trim();
        }
      });
    } else if (rawVar is String && rawVar.isNotEmpty) {
      if (rawVar.contains(':') || rawVar.contains(',') || rawVar.contains('/')) {
        final parts = rawVar.split(RegExp(r'[,/|]'));
        for (var part in parts) {
          final trimmed = part.trim();
          if (trimmed.contains(':')) {
            final kv = trimmed.split(':');
            rawExtracted[kv[0].trim()] = kv.sublist(1).join(':').trim();
          } else if (trimmed.isNotEmpty) {
            rawExtracted['Option'] = trimmed;
          }
        }
      } else {
        rawExtracted['Option'] = rawVar;
      }
    } else if (rawVar is List && rawVar.isNotEmpty) {
      for (int i = 0; i < rawVar.length; i++) {
        final item = rawVar[i];
        if (item is Map) {
          final k = item['name'] ?? item['key'] ?? item['title'] ?? item['attribute'] ?? 'Option ${i + 1}';
          final v = item['value'] ?? item['val'] ?? item['selected'] ?? '';
          if (v.toString().trim().isNotEmpty) {
            rawExtracted[k.toString().trim()] = v.toString().trim();
          }
        } else if (item != null && item.toString().trim().isNotEmpty) {
          rawExtracted['Option ${i + 1}'] = item.toString().trim();
        }
      }
    }

    // Auto-detect standalone vape variation fields from item / product map
    void checkCandidate(String targetCanonicalKey, List<dynamic> candidateValues) {
      for (final val in candidateValues) {
        if (val != null && val.toString().trim().isNotEmpty) {
          rawExtracted[targetCanonicalKey] ??= val.toString().trim();
          break;
        }
      }
    }

    checkCandidate('Flavor', [
      json['flavor'],
      json['Flavor'],
      json['flavour'],
      json['Flavour'],
      prodMap?['flavor'],
      prodMap?['flavour'],
    ]);

    checkCandidate('Style', [
      json['style'],
      json['Style'],
      json['type'],
      json['Type'],
      json['vapeStyle'],
      prodMap?['style'],
      prodMap?['type'],
    ]);

    checkCandidate('Size', [
      json['size'],
      json['Size'],
      json['bottleSize'],
      prodMap?['size'],
      prodMap?['bottleSize'],
    ]);

    checkCandidate('Nicotine', [
      json['nicotine'],
      json['Nicotine'],
      json['nicotineLevel'],
      json['nicotineStrength'],
      prodMap?['nicotine'],
    ]);

    checkCandidate('Color', [
      json['color'],
      json['Color'],
      json['colour'],
      json['finish'],
      prodMap?['color'],
    ]);

    checkCandidate('Resistance', [
      json['resistance'],
      json['Resistance'],
      json['ohm'],
      json['coilResistance'],
      prodMap?['resistance'],
    ]);

    checkCandidate('Wattage', [
      json['wattage'],
      json['Wattage'],
      prodMap?['wattage'],
    ]);

    // Normalize into canonical keys and ensure strict ordering:
    // 1. Flavor -> 2. Style -> 3. Size -> 4. Nicotine -> 5. Color -> 6. Resistance -> 7. Wattage
    final Map<String, String> variationMap = {};

    String? findAndRemove(List<String> synonyms) {
      for (final entry in rawExtracted.entries) {
        final lower = entry.key.toLowerCase().trim();
        if (synonyms.any((s) => s.toLowerCase() == lower)) {
          return entry.value;
        }
      }
      return null;
    }

    final flavorVal = findAndRemove(['flavor', 'flavour', 'نكهة', 'النكهة', 'flavors']);
    final styleVal = findAndRemove(['style', 'type', 'vapestyle', 'نمط', 'النمط']);
    final sizeVal = findAndRemove(['size', 'bottlesize', 'حجم', 'الحجم']);
    final nicotineVal = findAndRemove(['nicotine', 'nicotinelevel', 'nicotinestrength', 'nic', 'نيكوتين', 'النيكوتين']);
    final colorVal = findAndRemove(['color', 'colour', 'لون', 'اللون']);
    final resistanceVal = findAndRemove(['resistance', 'ohm', 'coilresistance', 'مقاومة', 'المقاومة']);
    final wattageVal = findAndRemove(['wattage', 'واط']);

    if (flavorVal != null && flavorVal.isNotEmpty) variationMap['Flavor'] = flavorVal;
    if (styleVal != null && styleVal.isNotEmpty) variationMap['Style'] = styleVal;
    if (sizeVal != null && sizeVal.isNotEmpty) variationMap['Size'] = sizeVal;
    if (nicotineVal != null && nicotineVal.isNotEmpty) variationMap['Nicotine'] = nicotineVal;
    if (colorVal != null && colorVal.isNotEmpty) variationMap['Color'] = colorVal;
    if (resistanceVal != null && resistanceVal.isNotEmpty) variationMap['Resistance'] = resistanceVal;
    if (wattageVal != null && wattageVal.isNotEmpty) variationMap['Wattage'] = wattageVal;

    // Add any remaining custom attributes
    rawExtracted.forEach((k, v) {
      final lower = k.toLowerCase().trim();
      final isAlreadyHandled = [
        'flavor', 'flavour', 'نكهة', 'النكهة', 'flavors',
        'style', 'type', 'vapestyle', 'نمط', 'النمط',
        'size', 'bottlesize', 'حجم', 'الحجم',
        'nicotine', 'nicotinelevel', 'nicotinestrength', 'nic', 'نيكوتين', 'النيكوتين',
        'color', 'colour', 'لون', 'اللون',
        'resistance', 'ohm', 'coilresistance', 'مقاومة', 'المقاومة',
        'wattage', 'واط',
      ].contains(lower);

      if (!isAlreadyHandled && v.isNotEmpty) {
        variationMap[k] = v;
      }
    });

    final price = _parseDouble(
      json['price'] ??
          json['Price'] ??
          json['unitPrice'] ??
          json['UnitPrice'] ??
          json['itemPrice'] ??
          json['cost'] ??
          json['Cost'] ??
          json['amount'] ??
          json['Amount'] ??
          json['salePrice'] ??
          prodMap?['price'] ??
          prodMap?['salePrice'] ??
          prodMap?['unitPrice'],
    );

    final originalPrice = json['originalPrice'] != null || json['oldPrice'] != null || prodMap?['basePrice'] != null
        ? _parseDouble(json['originalPrice'] ?? json['oldPrice'] ?? prodMap?['basePrice'])
        : null;

    final qty = _parseInt(
      json['quantity'] ??
          json['Quantity'] ??
          json['count'] ??
          json['Count'] ??
          json['qty'] ??
          json['Qty'] ??
          json['itemQuantity'] ??
          1,
    );

    String brand = '';
    final rawBrand = json['brand'] ??
        json['Brand'] ??
        json['brandName'] ??
        json['BrandName'] ??
        json['brand_name'] ??
        json['productBrand'] ??
        prodMap?['brand'] ??
        prodMap?['Brand'] ??
        prodMap?['brandName'] ??
        prodMap?['BrandName'] ??
        prodMap?['brand_name'] ??
        prodMap?['productBrand'];

    if (rawBrand is Map) {
      brand = rawBrand['name']?.toString() ??
          rawBrand['Name']?.toString() ??
          rawBrand['title']?.toString() ??
          rawBrand['Title']?.toString() ??
          rawBrand['brandName']?.toString() ??
          '';
    } else if (rawBrand != null) {
      final str = rawBrand.toString().trim();
      if (str.startsWith('{') && str.contains('name:')) {
        final match = RegExp(r'name:\s*([^,}]+)').firstMatch(str);
        brand = match?.group(1)?.trim() ?? str;
      } else {
        brand = str;
      }
    }

    final rawTitle = json['title']?.toString() ??
        json['Title']?.toString() ??
        json['name']?.toString() ??
        json['Name']?.toString() ??
        json['productName']?.toString() ??
        json['ProductName']?.toString() ??
        json['productTitle']?.toString() ??
        json['itemTitle']?.toString() ??
        json['itemName']?.toString() ??
        prodMap?['title']?.toString() ??
        prodMap?['name']?.toString() ??
        prodMap?['productName']?.toString() ??
        '';

    final String title = (rawTitle.trim().isNotEmpty && !rawTitle.toLowerCase().contains('untitled'))
        ? rawTitle.trim()
        : (flavorVal ?? (brand.isNotEmpty ? brand : 'Item'));

    final productId = json['productId']?.toString() ??
        json['ProductId']?.toString() ??
        json['product_id']?.toString() ??
        json['id']?.toString() ??
        json['Id']?.toString() ??
        json['prodId']?.toString() ??
        json['itemId']?.toString() ??
        prodMap?['id']?.toString() ??
        prodMap?['productId']?.toString() ??
        '';

    final sku = json['sku']?.toString() ??
        json['Sku']?.toString() ??
        json['SKU']?.toString() ??
        prodMap?['sku']?.toString() ??
        '';

    final notes = json['notes']?.toString() ??
        json['itemNotes']?.toString() ??
        json['comment']?.toString() ??
        '';

    String image = json['image']?.toString() ??
        json['Image']?.toString() ??
        json['thumbnail']?.toString() ??
        json['Thumbnail']?.toString() ??
        json['imageUrl']?.toString() ??
        json['ImageUrl']?.toString() ??
        json['img']?.toString() ??
        json['photo']?.toString() ??
        prodMap?['image']?.toString() ??
        prodMap?['thumbnail']?.toString() ??
        prodMap?['imageUrl']?.toString() ??
        '';

    if (image.isEmpty) {
      final rawImages = json['images'] ?? prodMap?['images'];
      if (rawImages is List && rawImages.isNotEmpty) {
        image = rawImages.first.toString();
      }
    }

    return OrderItemModel(
      productId: productId,
      title: title,
      price: price,
      originalPrice: (originalPrice != null && originalPrice > price) ? originalPrice : null,
      quantity: qty > 0 ? qty : 1,
      selectedVariation: variationMap,
      image: image,
      brand: brand,
      sku: sku,
      notes: notes,
    );
  }

  /// Formatted item title including brand name if available and not already in the title
  String get formattedTitleWithBrand {
    final cleanBrand = brand.trim();
    final cleanTitle = title.trim();
    if (cleanBrand.isNotEmpty && !cleanTitle.toLowerCase().contains(cleanBrand.toLowerCase())) {
      return '$cleanBrand - $cleanTitle';
    }
    return cleanTitle;
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'price': price,
        if (originalPrice != null) 'originalPrice': originalPrice,
        'quantity': quantity,
        'selectedVariation': selectedVariation,
        'image': image,
        if (brand.isNotEmpty) 'brand': brand,
        if (sku.isNotEmpty) 'sku': sku,
        if (notes.isNotEmpty) 'notes': notes,
      };

  @override
  List<Object?> get props => [productId, title, price, originalPrice, quantity, selectedVariation, image, brand, sku, notes];
}


class ShippingAddressModel extends Equatable {
  final String name;
  final String phoneNumber;
  final String alternatePhone;
  final String email;
  final String street;
  final String city;
  final String governorate;
  final String building;
  final String floor;
  final String apartment;
  final String landmark;
  final String postalCode;
  final String country;
  final String notes;

  const ShippingAddressModel({
    required this.name,
    required this.phoneNumber,
    this.alternatePhone = '',
    this.email = '',
    required this.street,
    required this.city,
    this.governorate = '',
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
    this.postalCode = '',
    this.country = 'Egypt',
    this.notes = '',
  });

  String get formattedFullAddress {
    final parts = <String>[];
    if (governorate.isNotEmpty) parts.add(governorate);
    if (city.isNotEmpty && city.toLowerCase() != governorate.toLowerCase()) parts.add(city);
    if (street.isNotEmpty) parts.add(street);
    if (building.isNotEmpty) parts.add('عمارة/مبنى: $building');
    if (floor.isNotEmpty) parts.add('طابق: $floor');
    if (apartment.isNotEmpty) parts.add('شقة: $apartment');
    if (landmark.isNotEmpty) parts.add('علامة مميزة: $landmark');
    return parts.isNotEmpty ? parts.join(' - ') : (street.isNotEmpty ? street : city);
  }

  factory ShippingAddressModel.fromJson(dynamic json, [Map<String, dynamic>? parentOrderDoc]) {
    String name = '';
    String phone = '';
    String altPhone = '';
    String email = '';
    String street = '';
    String city = '';
    String governorate = '';
    String building = '';
    String floor = '';
    String apartment = '';
    String landmark = '';
    String postalCode = '';
    String country = 'Egypt';
    String notes = '';

    if (json is Map) {
      name = json['name']?.toString() ??
          json['Name']?.toString() ??
          json['userName']?.toString() ??
          json['UserName']?.toString() ??
          json['customerName']?.toString() ??
          json['CustomerName']?.toString() ??
          json['recipientName']?.toString() ??
          json['fullName']?.toString() ??
          json['FullName']?.toString() ??
          '';

      phone = json['phoneNumber']?.toString() ??
          json['PhoneNumber']?.toString() ??
          json['phone']?.toString() ??
          json['Phone']?.toString() ??
          json['mobile']?.toString() ??
          json['Mobile']?.toString() ??
          json['userPhone']?.toString() ??
          json['contactNumber']?.toString() ??
          '';

      altPhone = json['alternatePhone']?.toString() ??
          json['secondaryPhone']?.toString() ??
          json['backupPhone']?.toString() ??
          '';

      email = json['email']?.toString() ??
          json['Email']?.toString() ??
          json['userEmail']?.toString() ??
          '';

      street = json['street']?.toString() ??
          json['Street']?.toString() ??
          json['address']?.toString() ??
          json['Address']?.toString() ??
          json['fullAddress']?.toString() ??
          json['addressLine1']?.toString() ??
          json['line1']?.toString() ??
          json['streetAddress']?.toString() ??
          '';

      city = json['city']?.toString() ??
          json['City']?.toString() ??
          json['governorate']?.toString() ??
          json['Governorate']?.toString() ??
          json['state']?.toString() ??
          json['region']?.toString() ??
          json['area']?.toString() ??
          '';

      governorate = json['governorate']?.toString() ??
          json['Governorate']?.toString() ??
          json['state']?.toString() ??
          json['region']?.toString() ??
          '';

      building = json['building']?.toString() ??
          json['buildingNumber']?.toString() ??
          json['buildingName']?.toString() ??
          json['house']?.toString() ??
          '';

      floor = json['floor']?.toString() ??
          json['floorNumber']?.toString() ??
          '';

      apartment = json['apartment']?.toString() ??
          json['apartmentNumber']?.toString() ??
          json['flat']?.toString() ??
          '';

      landmark = json['landmark']?.toString() ??
          json['nearBy']?.toString() ??
          json['specialMark']?.toString() ??
          '';

      postalCode = json['postalCode']?.toString() ??
          json['zipCode']?.toString() ??
          json['zip']?.toString() ??
          '';

      country = json['country']?.toString() ??
          json['countryName']?.toString() ??
          'Egypt';

      notes = json['notes']?.toString() ??
          json['addressNotes']?.toString() ??
          json['deliveryInstructions']?.toString() ??
          '';
    } else if (json is String && json.isNotEmpty) {
      street = json;
    }

    if (parentOrderDoc != null) {
      if (name.isEmpty) {
        name = parentOrderDoc['userName']?.toString() ??
            parentOrderDoc['UserName']?.toString() ??
            parentOrderDoc['customerName']?.toString() ??
            parentOrderDoc['CustomerName']?.toString() ??
            parentOrderDoc['name']?.toString() ??
            parentOrderDoc['Name']?.toString() ??
            parentOrderDoc['recipientName']?.toString() ??
            parentOrderDoc['fullName']?.toString() ??
            '';
      }
      if (phone.isEmpty) {
        phone = parentOrderDoc['phoneNumber']?.toString() ??
            parentOrderDoc['PhoneNumber']?.toString() ??
            parentOrderDoc['phone']?.toString() ??
            parentOrderDoc['Phone']?.toString() ??
            parentOrderDoc['mobile']?.toString() ??
            parentOrderDoc['Mobile']?.toString() ??
            parentOrderDoc['userPhone']?.toString() ??
            parentOrderDoc['customerPhone']?.toString() ??
            '';
      }
      if (email.isEmpty) {
        email = parentOrderDoc['userEmail']?.toString() ??
            parentOrderDoc['email']?.toString() ??
            parentOrderDoc['customerEmail']?.toString() ??
            '';
      }
      if (street.isEmpty) {
        street = parentOrderDoc['street']?.toString() ??
            parentOrderDoc['Street']?.toString() ??
            parentOrderDoc['address']?.toString() ??
            parentOrderDoc['Address']?.toString() ??
            parentOrderDoc['fullAddress']?.toString() ??
            '';
      }
      if (city.isEmpty) {
        city = parentOrderDoc['city']?.toString() ??
            parentOrderDoc['City']?.toString() ??
            parentOrderDoc['governorate']?.toString() ??
            parentOrderDoc['Governorate']?.toString() ??
            parentOrderDoc['state']?.toString() ??
            parentOrderDoc['region']?.toString() ??
            '';
      }
      if (notes.isEmpty) {
        notes = parentOrderDoc['notes']?.toString() ??
            parentOrderDoc['orderNotes']?.toString() ??
            parentOrderDoc['customerNote']?.toString() ??
            '';
      }
    }

    return ShippingAddressModel(
      name: name.isNotEmpty ? name : 'Guest Customer',
      phoneNumber: phone,
      alternatePhone: altPhone,
      email: email,
      street: street,
      city: city.isNotEmpty ? city : 'Cairo',
      governorate: governorate.isNotEmpty ? governorate : (city.isNotEmpty ? city : 'Cairo'),
      building: building,
      floor: floor,
      apartment: apartment,
      landmark: landmark,
      postalCode: postalCode,
      country: country,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        if (alternatePhone.isNotEmpty) 'alternatePhone': alternatePhone,
        if (email.isNotEmpty) 'email': email,
        'street': street,
        'city': city,
        if (governorate.isNotEmpty) 'governorate': governorate,
        if (building.isNotEmpty) 'building': building,
        if (floor.isNotEmpty) 'floor': floor,
        if (apartment.isNotEmpty) 'apartment': apartment,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (postalCode.isNotEmpty) 'postalCode': postalCode,
        'country': country,
        if (notes.isNotEmpty) 'notes': notes,
      };

  @override
  List<Object?> get props => [
        name,
        phoneNumber,
        alternatePhone,
        email,
        street,
        city,
        governorate,
        building,
        floor,
        apartment,
        landmark,
        postalCode,
        country,
        notes,
      ];
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String customerEmail;
  final String status; // 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final List<OrderItemModel> items;
  final String paymentMethod;
  final String paymentStatus; // 'paid', 'unpaid', 'pending', 'cod'
  final ShippingAddressModel shippingAddress;
  final double subTotal;
  final double shippingCost;
  final double taxFee;
  final double discount;
  final String couponCode;
  final double totalAmount;
  final String orderNotes;
  final String trackingNumber;
  final String shippingCarrier;
  final List<Map<String, dynamic>> returnHistory;
  final double refundedAmount;
  final String returnReason;
  final Map<String, dynamic> rawDocData;

  const OrderModel({
    required this.id,
    required this.userId,
    this.customerEmail = '',
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.items,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.shippingAddress,
    required this.subTotal,
    required this.shippingCost,
    this.taxFee = 0.0,
    this.discount = 0.0,
    this.couponCode = '',
    required this.totalAmount,
    this.orderNotes = '',
    this.trackingNumber = '',
    this.shippingCarrier = '',
    this.returnHistory = const [],
    this.refundedAmount = 0.0,
    this.returnReason = '',
    this.rawDocData = const {},
  });

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerEmail,
    String? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    List<OrderItemModel>? items,
    String? paymentMethod,
    String? paymentStatus,
    ShippingAddressModel? shippingAddress,
    double? subTotal,
    double? shippingCost,
    double? taxFee,
    double? discount,
    String? couponCode,
    double? totalAmount,
    String? orderNotes,
    String? trackingNumber,
    String? shippingCarrier,
    List<Map<String, dynamic>>? returnHistory,
    double? refundedAmount,
    String? returnReason,
    Map<String, dynamic>? rawDocData,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerEmail: customerEmail ?? this.customerEmail,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      subTotal: subTotal ?? this.subTotal,
      shippingCost: shippingCost ?? this.shippingCost,
      taxFee: taxFee ?? this.taxFee,
      discount: discount ?? this.discount,
      couponCode: couponCode ?? this.couponCode,
      totalAmount: totalAmount ?? this.totalAmount,
      orderNotes: orderNotes ?? this.orderNotes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingCarrier: shippingCarrier ?? this.shippingCarrier,
      returnHistory: returnHistory ?? this.returnHistory,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      returnReason: returnReason ?? this.returnReason,
      rawDocData: rawDocData ?? this.rawDocData,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract raw items from all possible field names
    dynamic rawItems = json['items'] ??
        json['Items'] ??
        json['orderItems'] ??
        json['OrderItems'] ??
        json['products'] ??
        json['Products'] ??
        json['cartItems'] ??
        json['CartItems'] ??
        json['cartList'] ??
        json['CartList'] ??
        json['cart'] ??
        json['Cart'] ??
        json['order_items'] ??
        json['lineItems'] ??
        json['line_items'] ??
        json['orderProducts'] ??
        json['productsList'] ??
        json['itemsList'] ??
        json['lines'] ??
        json['Lines'] ??
        json['orderedItems'] ??
        json['orderDetails'] ??
        json['details'];

    if (rawItems is String && rawItems.trim().startsWith('[')) {
      try {
        rawItems = jsonDecode(rawItems);
      } catch (_) {}
    } else if (rawItems is String && rawItems.trim().startsWith('{')) {
      try {
        rawItems = jsonDecode(rawItems);
      } catch (_) {}
    }

    final List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      for (final itm in rawItems) {
        if (itm != null) {
          parsedItems.add(OrderItemModel.fromJson(itm));
        }
      }
    } else if (rawItems is Map) {
      rawItems.forEach((k, v) {
        if (v != null) {
          parsedItems.add(OrderItemModel.fromJson(v));
        }
      });
    }

    // 2. Extract address
    final rawAddress = json['shippingAddress'] ??
        json['ShippingAddress'] ??
        json['address'] ??
        json['Address'] ??
        json['deliveryAddress'] ??
        json['DeliveryAddress'] ??
        json['userAddress'] ??
        json['UserAddress'] ??
        json['customerAddress'] ??
        json['shipping_address'] ??
        json['addressData'] ??
        json;

    final shippingAddress = ShippingAddressModel.fromJson(rawAddress, json);

    // 3. Extract financial figures
    final total = _parseDouble(
      json['totalAmount'] ??
          json['TotalAmount'] ??
          json['total'] ??
          json['Total'] ??
          json['totalPrice'] ??
          json['TotalPrice'] ??
          json['grandTotal'] ??
          json['GrandTotal'] ??
          json['orderTotal'] ??
          json['OrderTotal'] ??
          json['finalTotal'] ??
          json['FinalTotal'] ??
          json['price'] ??
          json['Price'] ??
          json['amount'] ??
          json['Amount'] ??
          json['netTotal'],
    );

    // Calculate items sum
    double itemsSum = 0.0;
    for (final itm in parsedItems) {
      itemsSum += itm.price * itm.quantity;
    }

    final sub = _parseDouble(
      json['subTotal'] ??
          json['SubTotal'] ??
          json['subtotal'] ??
          json['Subtotal'] ??
          json['itemsPrice'] ??
          json['productsTotal'],
    );

    final double finalSubTotal = sub > 0 ? sub : (itemsSum > 0 ? itemsSum : total);

    final rawShipping = json['shippingCost'] ??
        json['ShippingCost'] ??
        json['shippingFee'] ??
        json['ShippingFee'] ??
        json['deliveryFee'] ??
        json['DeliveryFee'] ??
        json['delivery_fee'] ??
        json['shipping_fee'] ??
        json['shippingPrice'] ??
        json['ShippingPrice'] ??
        json['deliveryPrice'] ??
        json['DeliveryPrice'] ??
        json['deliveryCost'] ??
        json['DeliveryCost'] ??
        json['delivery_cost'] ??
        json['shipping_cost'] ??
        json['shippingAmount'] ??
        json['ShippingAmount'] ??
        json['shipping_amount'] ??
        json['deliveryAmount'] ??
        json['DeliveryAmount'] ??
        json['delivery_amount'] ??
        json['shippingCharge'] ??
        json['ShippingCharge'] ??
        json['shipping_charge'] ??
        json['deliveryCharge'] ??
        json['DeliveryCharge'] ??
        json['delivery_charge'] ??
        json['shipping'] ??
        json['Shipping'] ??
        json['delivery'] ??
        json['Delivery'] ??
        json['freight'] ??
        json['Freight'];

    double parsedShippingCost = 0.0;
    if (rawShipping is Map) {
      parsedShippingCost = _parseDouble(
        rawShipping['cost'] ??
            rawShipping['Cost'] ??
            rawShipping['fee'] ??
            rawShipping['Fee'] ??
            rawShipping['price'] ??
            rawShipping['Price'] ??
            rawShipping['amount'] ??
            rawShipping['Amount'] ??
            rawShipping['deliveryFee'] ??
            rawShipping['shippingFee'],
      );
    } else if (rawShipping != null) {
      parsedShippingCost = _parseDouble(rawShipping);
    }

    final taxFee = _parseDouble(
      json['taxFee'] ?? json['TaxFee'] ?? json['tax'] ?? json['Tax'] ?? json['vat'] ?? json['VAT'],
    );

    final discount = _parseDouble(
      json['discount'] ??
          json['Discount'] ??
          json['discountAmount'] ??
          json['DiscountAmount'] ??
          json['couponDiscount'] ??
          json['promoDiscount'],
    );

    // Auto-infer delivery fee if it wasn't explicitly saved as a field but total exceeds subtotal
    if (parsedShippingCost == 0.0 && total > 0.0) {
      final baseSub = finalSubTotal > 0.0 ? finalSubTotal : itemsSum;
      if (baseSub > 0.0) {
        final expectedWithoutShipping = baseSub + taxFee - discount;
        final diff = total - expectedWithoutShipping;
        if (diff > 0.01) {
          parsedShippingCost = diff;
        }
      }
    }

    final couponCode = json['couponCode']?.toString() ??
        json['coupon']?.toString() ??
        json['promoCode']?.toString() ??
        json['voucher']?.toString() ??
        '';

    // If no items in array, check for single product top-level fields
    if (parsedItems.isEmpty) {
      final singleTitle = json['title']?.toString() ??
          json['Title']?.toString() ??
          json['productName']?.toString() ??
          json['ProductName']?.toString() ??
          json['name']?.toString() ??
          json['Name']?.toString() ??
          json['itemTitle']?.toString();

      final singleProdId = json['productId']?.toString() ??
          json['ProductId']?.toString() ??
          json['prodId']?.toString() ??
          json['id']?.toString();

      if (singleTitle != null &&
          singleTitle.isNotEmpty &&
          singleTitle != 'Order' &&
          !singleTitle.startsWith('تحديث') &&
          !singleTitle.startsWith('طلب')) {
        parsedItems.add(OrderItemModel(
          productId: singleProdId ?? '',
          title: singleTitle,
          price: _parseDouble(json['price'] ?? json['Price'] ?? json['unitPrice'] ?? total),
          quantity: _parseInt(json['quantity'] ?? json['Quantity'] ?? json['qty'] ?? 1).clamp(1, 9999),
          image: json['image']?.toString() ?? json['thumbnail']?.toString() ?? json['imageUrl']?.toString() ?? '',
          brand: json['brand']?.toString() ?? '',
          sku: json['sku']?.toString() ?? '',
        ));
      }
    }

    // Calculate fallback total if total was 0 but items have prices
    double finalTotal = total;
    if (finalTotal == 0.0 && parsedItems.isNotEmpty) {
      double itemsSumRecalc = 0.0;
      for (final itm in parsedItems) {
        itemsSumRecalc += itm.price * itm.quantity;
      }
      if (itemsSumRecalc > 0) {
        finalTotal = itemsSumRecalc + parsedShippingCost + taxFee - discount;
      }
    }


    // 4. Extract ID and other metadata
    final id = json['orderId']?.toString() ??
        json['OrderId']?.toString() ??
        json['id']?.toString() ??
        json['Id']?.toString() ??
        json['orderNumber']?.toString() ??
        json['order_id']?.toString() ??
        '';

    final userId = json['userId']?.toString() ??
        json['UserId']?.toString() ??
        json['uid']?.toString() ??
        json['Uid']?.toString() ??
        json['customerId']?.toString() ??
        json['user_id']?.toString() ??
        '';

    final customerEmail = json['userEmail']?.toString() ??
        json['email']?.toString() ??
        json['customerEmail']?.toString() ??
        shippingAddress.email;

    final status = (json['status'] ?? json['Status'] ?? json['orderStatus'] ?? 'pending')
        .toString()
        .toLowerCase()
        .trim();

    final paymentMethod = json['paymentMethod']?.toString() ??
        json['PaymentMethod']?.toString() ??
        json['payment']?.toString() ??
        json['Payment']?.toString() ??
        json['paymentType']?.toString() ??
        json['payment_method']?.toString() ??
        'Cash on Delivery';

    final paymentStatus = json['paymentStatus']?.toString() ??
        json['PaymentStatus']?.toString() ??
        (json['isPaid'] == true ? 'paid' : 'pending');

    final orderNotes = json['notes']?.toString() ??
        json['orderNotes']?.toString() ??
        json['customerNotes']?.toString() ??
        json['customerNote']?.toString() ??
        shippingAddress.notes;

    final trackingNumber = json['trackingNumber']?.toString() ??
        json['trackingCode']?.toString() ??
        json['tracking_number']?.toString() ??
        '';

    final shippingCarrier = json['shippingCarrier']?.toString() ??
        json['carrier']?.toString() ??
        json['shippingCompany']?.toString() ??
        '';

    // Parse return history and metadata
    final List<Map<String, dynamic>> parsedReturnHistory = [];
    final rawReturns = json['returnHistory'] ?? json['returns'] ?? json['returnedItems'];
    if (rawReturns is List) {
      for (final r in rawReturns) {
        if (r is Map) {
          parsedReturnHistory.add(Map<String, dynamic>.from(r));
        }
      }
    }

    final double refundedAmount = _parseDouble(
      json['refundedAmount'] ?? json['refundAmount'] ?? json['totalRefunded'],
    );

    final String returnReason = json['returnReason']?.toString() ??
        json['refundReason']?.toString() ??
        json['cancelReason']?.toString() ??
        '';

    return OrderModel(
      id: id.isNotEmpty ? id : 'ORD_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      customerEmail: customerEmail,
      status: status.isNotEmpty ? status : 'pending',
      orderDate: _parseFirestoreDateTime(
        json['orderDate'] ??
            json['OrderDate'] ??
            json['createdAt'] ??
            json['CreatedAt'] ??
            json['timestamp'] ??
            json['Timestamp'] ??
            json['date'] ??
            json['Date'] ??
            json['created_at'],
      ),
      deliveryDate: _parseNullableDateTime(
        json['deliveryDate'] ?? json['DeliveryDate'] ?? json['deliveredAt'],
      ),
      items: parsedItems,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      shippingAddress: shippingAddress,
      subTotal: finalSubTotal,
      shippingCost: parsedShippingCost,
      taxFee: taxFee,
      discount: discount,
      couponCode: couponCode,
      totalAmount: finalTotal,
      orderNotes: orderNotes,
      trackingNumber: trackingNumber,
      shippingCarrier: shippingCarrier,
      returnHistory: parsedReturnHistory,
      refundedAmount: refundedAmount,
      returnReason: returnReason,
      rawDocData: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        if (customerEmail.isNotEmpty) 'customerEmail': customerEmail,
        'status': status,
        'orderDate': orderDate.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'shippingAddress': shippingAddress.toJson(),
        'subTotal': subTotal,
        'shippingCost': shippingCost,
        'taxFee': taxFee,
        'discount': discount,
        if (couponCode.isNotEmpty) 'couponCode': couponCode,
        'totalAmount': totalAmount,
        if (orderNotes.isNotEmpty) 'orderNotes': orderNotes,
        if (trackingNumber.isNotEmpty) 'trackingNumber': trackingNumber,
        if (shippingCarrier.isNotEmpty) 'shippingCarrier': shippingCarrier,
        if (returnHistory.isNotEmpty) 'returnHistory': returnHistory,
        if (refundedAmount > 0) 'refundedAmount': refundedAmount,
        if (returnReason.isNotEmpty) 'returnReason': returnReason,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        customerEmail,
        status,
        orderDate,
        deliveryDate,
        items,
        paymentMethod,
        paymentStatus,
        shippingAddress,
        subTotal,
        shippingCost,
        taxFee,
        discount,
        couponCode,
        totalAmount,
        orderNotes,
        trackingNumber,
        shippingCarrier,
        returnHistory,
        refundedAmount,
        returnReason,
      ];

  /// Returns whether this record originated from in-store POS cashier register
  bool get isPosSale =>
      rawDocData['source'] == 'pos' ||
      rawDocData['orderType'] == 'in_store' ||
      rawDocData['isPosSale'] == true ||
      paymentMethod.toLowerCase().startsWith('pos_') ||
      id.toUpperCase().startsWith('POS-') ||
      (rawDocData['orderNumber']?.toString().toUpperCase().startsWith('POS-') ?? false) ||
      userId == 'pos_cashier';

  /// Returns whether this record is an online delivery order from mobile customer app
  bool get isOnlineOrder => !isPosSale;

  /// Returns whether this order is fully or partially returned
  bool get isReturned =>
      status.toLowerCase() == 'returned' ||
      status.toLowerCase() == 'refunded' ||
      status.toLowerCase() == 'partially_returned' ||
      returnHistory.isNotEmpty;

  /// Returns true if only a subset of items was returned
  bool get hasPartialReturn => returnHistory.isNotEmpty && status.toLowerCase() != 'returned';

  /// Human readable cashier name if this is an in-store transaction
  String get cashierName => rawDocData['cashierName']?.toString() ?? '';

  /// Human readable payment method formatted cleanly without underscores
  String get displayPaymentMethod {
    final clean = paymentMethod.trim();
    if (clean.isEmpty) return '—';
    final lower = clean.toLowerCase();
    if (lower == 'cod' || lower == 'cash_on_delivery' || lower == 'cash on delivery') {
      return 'cash_on_delivery'.tr;
    }
    if (lower == 'pos_cash' || lower == 'cash' || lower == 'كاش') {
      return 'payment_method_cash'.tr;
    }
    if (lower == 'pos_card' || lower == 'card' || lower == 'visa' || lower == 'credit_card' || lower == 'فيزا') {
      return 'payment_method_card'.tr;
    }
    if (lower == 'instapay' || lower == 'insta_pay') {
      return 'payment_method_instapay'.tr;
    }
    if (lower == 'vodafone_cash' || lower == 'vodafone') {
      return 'payment_method_vodafone_cash'.tr;
    }
    if (lower == 'bank_transfer') {
      return 'payment_method_bank_transfer'.tr;
    }
    return clean.replaceAll('_', ' ');
  }

  /// Source label formatted for Arabic/English display
  String get sourceDisplayLabel {
    final isAr = AppLocalizations.current.locale.languageCode == 'ar';
    return isPosSale
        ? (isAr ? 'كاشير الفرع (POS)' : 'Branch POS')
        : (isAr ? 'تطبيق أونلاين (App)' : 'Online App');
  }
}
