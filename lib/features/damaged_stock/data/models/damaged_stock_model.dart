import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Supported classifications/reasons for inventory damage & waste.
enum DamagedReason {
  expired(
    'expired',
    'damage_reason_expired',
    Icons.history_toggle_off_rounded,
    Color(0xFFEF4444), // Red
  ),
  brokenShipping(
    'broken_shipping',
    'damage_reason_shipping',
    Icons.local_shipping_outlined,
    Color(0xFFF97316), // Orange
  ),
  storageDamage(
    'storage_damage',
    'damage_reason_storage',
    Icons.water_damage_outlined,
    Color(0xFF3B82F6), // Blue
  ),
  factoryDefect(
    'factory_defect',
    'damage_reason_factory',
    Icons.build_circle_outlined,
    Color(0xFF8B5CF6), // Purple
  ),
  customerReturnDamaged(
    'customer_return_damaged',
    'damage_reason_customer',
    Icons.assignment_return_outlined,
    Color(0xFFEAB308), // Yellow
  ),
  theftLoss(
    'theft_loss',
    'damage_reason_theft',
    Icons.inventory_2_outlined,
    Color(0xFF6B7280), // Gray
  ),
  other(
    'other',
    'damage_reason_other',
    Icons.more_horiz_rounded,
    Color(0xFF64748B), // Slate
  );

  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  const DamagedReason(this.id, this.labelKey, this.icon, this.color);

  static DamagedReason fromString(String? val) {
    if (val == null) return DamagedReason.other;
    final clean = val.trim().toLowerCase();
    for (final reason in DamagedReason.values) {
      if (reason.id == clean || reason.name.toLowerCase() == clean) {
        return reason;
      }
    }
    return DamagedReason.other;
  }
}

/// Damaged Stock & Waste Entity tracking write-offs and inventory losses.
class DamagedStockModel extends Equatable {
  final String id;
  final String productId;
  final String productTitle;
  final String productCategory;
  final String variationSku;
  final Map<String, String> variationAttributes;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double totalLoss; // quantity * costPrice
  final DamagedReason reason;
  final String notes;
  final String recordedBy;
  final DateTime createdAt;
  final List<String> images;

  const DamagedStockModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productCategory = '',
    this.variationSku = '',
    this.variationAttributes = const {},
    required this.quantity,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    double? totalLoss,
    this.reason = DamagedReason.other,
    this.notes = '',
    this.recordedBy = 'Admin',
    required this.createdAt,
    this.images = const [],
  }) : totalLoss = totalLoss ?? (quantity * costPrice);

  factory DamagedStockModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final rawAttrs = json['variationAttributes'] ?? json['attributes'] ?? {};
    final Map<String, String> attrs = {};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) => attrs[k.toString()] = v.toString());
    }

    final createdAtRaw = json['createdAt'] ?? json['date'];
    DateTime parsedDate;
    if (createdAtRaw is Timestamp) {
      parsedDate = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawImages = json['images'] ?? json['photos'];
    final List<String> imgList = [];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img != null && img.toString().isNotEmpty) {
          imgList.add(img.toString());
        }
      }
    }

    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    final cost = (json['costPrice'] as num?)?.toDouble() ?? 0.0;
    final selling = (json['sellingPrice'] as num?)?.toDouble() ?? 0.0;
    final loss = (json['totalLoss'] as num?)?.toDouble() ?? (qty * cost);

    return DamagedStockModel(
      id: docId ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? json['productName']?.toString() ?? '',
      productCategory: json['productCategory']?.toString() ?? '',
      variationSku: json['variationSku']?.toString() ?? json['sku']?.toString() ?? '',
      variationAttributes: attrs,
      quantity: qty,
      costPrice: cost,
      sellingPrice: selling,
      totalLoss: loss,
      reason: DamagedReason.fromString(json['reason']?.toString()),
      notes: json['notes']?.toString() ?? '',
      recordedBy: json['recordedBy']?.toString() ?? 'Admin',
      createdAt: parsedDate,
      images: imgList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productTitle': productTitle,
        'productCategory': productCategory,
        'variationSku': variationSku,
        'variationAttributes': variationAttributes,
        'quantity': quantity,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'totalLoss': totalLoss,
        'reason': reason.id,
        'notes': notes,
        'recordedBy': recordedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'images': images,
      };

  DamagedStockModel copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? productCategory,
    String? variationSku,
    Map<String, String>? variationAttributes,
    int? quantity,
    double? costPrice,
    double? sellingPrice,
    double? totalLoss,
    DamagedReason? reason,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
    List<String>? images,
  }) {
    return DamagedStockModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productCategory: productCategory ?? this.productCategory,
      variationSku: variationSku ?? this.variationSku,
      variationAttributes: variationAttributes ?? this.variationAttributes,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalLoss: totalLoss ?? this.totalLoss,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productTitle,
        productCategory,
        variationSku,
        variationAttributes,
        quantity,
        costPrice,
        sellingPrice,
        totalLoss,
        reason,
        notes,
        recordedBy,
        createdAt,
        images,
      ];
}
