import 'package:equatable/equatable.dart';

/// Supported types of stock movements in the ERP/Inventory system.
enum StockMovementType {
  restock,
  sale,
  damage,
  adjustment,
  returnItem;

  String get displayName {
    switch (this) {
      case StockMovementType.restock:
        return 'Restock / Inflow';
      case StockMovementType.sale:
        return 'Sale / Order';
      case StockMovementType.damage:
        return 'Damaged / Write-off';
      case StockMovementType.adjustment:
        return 'Inventory Adjustment';
      case StockMovementType.returnItem:
        return 'Customer Return';
    }
  }

  String get arabicName {
    switch (this) {
      case StockMovementType.restock:
        return 'توريد وارد جديد';
      case StockMovementType.sale:
        return 'صرف مبيعات طلبية';
      case StockMovementType.damage:
        return 'تسجيل تالف / هالك';
      case StockMovementType.adjustment:
        return 'تسوية جردية';
      case StockMovementType.returnItem:
        return 'مرتجع من عميل';
    }
  }

  static StockMovementType fromString(String? val) {
    if (val == null) return StockMovementType.adjustment;
    final clean = val.toLowerCase().trim();
    switch (clean) {
      case 'restock':
      case 'inflow':
      case 'purchase':
        return StockMovementType.restock;
      case 'sale':
      case 'order':
        return StockMovementType.sale;
      case 'damage':
      case 'damaged':
      case 'waste':
        return StockMovementType.damage;
      case 'return':
      case 'returnitem':
      case 'returned':
        return StockMovementType.returnItem;
      case 'adjustment':
      default:
        return StockMovementType.adjustment;
    }
  }
}

/// Comprehensive audit log model for tracking inventory variations, restocks, sales, and adjustments.
class StockMovementModel extends Equatable {
  final String id;
  final String productId;
  final String productTitle;
  final String productCategory;
  final String variationSku;
  final Map<String, String> variationAttributes;
  final StockMovementType type;
  final int quantity; // Added or deducted quantity
  final int previousStock;
  final int newStock;
  final double costPricePerUnit;
  final double totalCost;
  final String supplierName;
  final String invoiceNumber;
  final String notes;
  final String performedBy;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productCategory = '',
    this.variationSku = '',
    this.variationAttributes = const {},
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.costPricePerUnit = 0.0,
    this.totalCost = 0.0,
    this.supplierName = '',
    this.invoiceNumber = '',
    this.notes = '',
    this.performedBy = 'Admin',
    required this.createdAt,
  });

  bool get isInflow =>
      type == StockMovementType.restock || type == StockMovementType.returnItem;
  bool get isOutflow =>
      type == StockMovementType.sale || type == StockMovementType.damage;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['variationAttributes'] ?? {};
    final Map<String, String> attrs = {};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) => attrs[k.toString()] = v.toString());
    }

    final createdAtRaw = json['createdAt'];
    DateTime parsedDate;
    if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw != null && createdAtRaw.toString().isNotEmpty) {
      try {
        // Handle Firestore Timestamp
        parsedDate = (createdAtRaw as dynamic).toDate();
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    final cost = (json['costPricePerUnit'] as num?)?.toDouble() ?? 0.0;
    final total = (json['totalCost'] as num?)?.toDouble() ?? (qty.abs() * cost);

    return StockMovementModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? '',
      productCategory: json['productCategory']?.toString() ?? '',
      variationSku: json['variationSku']?.toString() ?? '',
      variationAttributes: attrs,
      type: StockMovementType.fromString(json['type']?.toString()),
      quantity: qty,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      costPricePerUnit: cost,
      totalCost: total,
      supplierName: json['supplierName']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      performedBy: json['performedBy']?.toString() ?? 'Admin',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productTitle': productTitle,
        'productCategory': productCategory,
        'variationSku': variationSku,
        'variationAttributes': variationAttributes,
        'type': type.name,
        'quantity': quantity,
        'previousStock': previousStock,
        'newStock': newStock,
        'costPricePerUnit': costPricePerUnit,
        'totalCost': totalCost,
        'supplierName': supplierName,
        'invoiceNumber': invoiceNumber,
        'notes': notes,
        'performedBy': performedBy,
        'createdAt': createdAt.toIso8601String(),
      };

  StockMovementModel copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? productCategory,
    String? variationSku,
    Map<String, String>? variationAttributes,
    StockMovementType? type,
    int? quantity,
    int? previousStock,
    int? newStock,
    double? costPricePerUnit,
    double? totalCost,
    String? supplierName,
    String? invoiceNumber,
    String? notes,
    String? performedBy,
    DateTime? createdAt,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productCategory: productCategory ?? this.productCategory,
      variationSku: variationSku ?? this.variationSku,
      variationAttributes: variationAttributes ?? this.variationAttributes,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      costPricePerUnit: costPricePerUnit ?? this.costPricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      performedBy: performedBy ?? this.performedBy,
      createdAt: createdAt ?? this.createdAt,
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
        type,
        quantity,
        previousStock,
        newStock,
        costPricePerUnit,
        totalCost,
        supplierName,
        invoiceNumber,
        notes,
        performedBy,
        createdAt,
      ];
}
