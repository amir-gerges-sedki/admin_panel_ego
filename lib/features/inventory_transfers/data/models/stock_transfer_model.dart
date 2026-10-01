import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Lifecycle status for Inter-Branch Inventory Transfers.
enum StockTransferStatus {
  pending(
    'pending',
    'transfer_status_pending',
    Icons.schedule_rounded,
    Color(0xFFEAB308), // Yellow
  ),
  approved(
    'approved',
    'transfer_status_approved',
    Icons.check_circle_outline_rounded,
    Color(0xFF3B82F6), // Blue
  ),
  inTransit(
    'in_transit',
    'transfer_status_in_transit',
    Icons.local_shipping_outlined,
    Color(0xFF8B5CF6), // Purple
  ),
  received(
    'received',
    'transfer_status_received',
    Icons.task_alt_rounded,
    Color(0xFF10B981), // Emerald Green
  ),
  rejected(
    'rejected',
    'transfer_status_rejected',
    Icons.cancel_outlined,
    Color(0xFFEF4444), // Red
  ),
  cancelled(
    'cancelled',
    'transfer_status_cancelled',
    Icons.remove_circle_outline_rounded,
    Color(0xFF6B7280), // Slate / Gray
  );

  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  const StockTransferStatus(this.id, this.labelKey, this.icon, this.color);

  static StockTransferStatus fromString(String? val) {
    if (val == null) return StockTransferStatus.pending;
    final clean = val.trim().toLowerCase();
    for (final s in StockTransferStatus.values) {
      if (s.id == clean || s.name.toLowerCase() == clean) {
        return s;
      }
    }
    return StockTransferStatus.pending;
  }
}

/// Priority of the branch merchandise request.
enum StockTransferPriority {
  normal(
    'normal',
    'transfer_priority_normal',
    Color(0xFF3B82F6), // Blue
  ),
  urgent(
    'urgent',
    'transfer_priority_urgent',
    Color(0xFFEF4444), // Red
  ),
  nextShipment(
    'next_shipment',
    'transfer_priority_next_shipment',
    Color(0xFFF59E0B), // Amber
  );

  final String id;
  final String labelKey;
  final Color color;

  const StockTransferPriority(this.id, this.labelKey, this.color);

  static StockTransferPriority fromString(String? val) {
    if (val == null) return StockTransferPriority.normal;
    final clean = val.trim().toLowerCase();
    for (final p in StockTransferPriority.values) {
      if (p.id == clean || p.name.toLowerCase() == clean) {
        return p;
      }
    }
    return StockTransferPriority.normal;
  }
}

/// Single item requested within an Inter-Branch Stock Transfer.
class StockTransferItemModel extends Equatable {
  final String productId;
  final String productTitle;
  final String productCategory;
  final String variationSku;
  final Map<String, String> variationAttributes;
  final int requestedQuantity;
  final int approvedQuantity;
  final int receivedQuantity;
  final double costPrice;
  final double sellingPrice;
  final String image;

  const StockTransferItemModel({
    required this.productId,
    required this.productTitle,
    this.productCategory = '',
    this.variationSku = '',
    this.variationAttributes = const {},
    required this.requestedQuantity,
    int? approvedQuantity,
    int? receivedQuantity,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.image = '',
  })  : approvedQuantity = approvedQuantity ?? requestedQuantity,
        receivedQuantity = receivedQuantity ?? 0;

  factory StockTransferItemModel.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['variationAttributes'] ?? json['attributes'] ?? {};
    final Map<String, String> attrs = {};
    if (rawAttrs is Map) {
      rawAttrs.forEach((k, v) => attrs[k.toString()] = v.toString());
    }

    final reqQty = (json['requestedQuantity'] as num?)?.toInt() ?? 1;
    final appQty = (json['approvedQuantity'] as num?)?.toInt() ?? reqQty;
    final recQty = (json['receivedQuantity'] as num?)?.toInt() ?? 0;

    return StockTransferItemModel(
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? json['productName']?.toString() ?? '',
      productCategory: json['productCategory']?.toString() ?? '',
      variationSku: json['variationSku']?.toString() ?? json['sku']?.toString() ?? '',
      variationAttributes: attrs,
      requestedQuantity: reqQty,
      approvedQuantity: appQty,
      receivedQuantity: recQty,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      image: json['image']?.toString() ?? json['productImage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        'productCategory': productCategory,
        'variationSku': variationSku,
        'variationAttributes': variationAttributes,
        'requestedQuantity': requestedQuantity,
        'approvedQuantity': approvedQuantity,
        'receivedQuantity': receivedQuantity,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'image': image,
      };

  StockTransferItemModel copyWith({
    String? productId,
    String? productTitle,
    String? productCategory,
    String? variationSku,
    Map<String, String>? variationAttributes,
    int? requestedQuantity,
    int? approvedQuantity,
    int? receivedQuantity,
    double? costPrice,
    double? sellingPrice,
    String? image,
  }) {
    return StockTransferItemModel(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productCategory: productCategory ?? this.productCategory,
      variationSku: variationSku ?? this.variationSku,
      variationAttributes: variationAttributes ?? this.variationAttributes,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      approvedQuantity: approvedQuantity ?? this.approvedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      image: image ?? this.image,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productTitle,
        productCategory,
        variationSku,
        variationAttributes,
        requestedQuantity,
        approvedQuantity,
        receivedQuantity,
        costPrice,
        sellingPrice,
        image,
      ];
}

/// Root Stock Transfer Document tracking merchandise requests between branches.
class StockTransferModel extends Equatable {
  final String id;
  final String transferNumber; // e.g. "TR-20261001-001"
  final String fromBranchId;
  final String fromBranchName;
  final String toBranchId;
  final String toBranchName;
  final StockTransferStatus status;
  final StockTransferPriority priority;
  final List<StockTransferItemModel> items;
  final String notes;
  final String requestedBy;
  final String shiftId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? receivedAt;
  final String receivedBy;

  const StockTransferModel({
    required this.id,
    required this.transferNumber,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    this.status = StockTransferStatus.pending,
    this.priority = StockTransferPriority.normal,
    this.items = const [],
    this.notes = '',
    this.requestedBy = 'Cashier',
    this.shiftId = '',
    required this.createdAt,
    this.updatedAt,
    this.receivedAt,
    this.receivedBy = '',
  });

  int get totalRequestedItems => items.fold(0, (prev, i) => prev + i.requestedQuantity);
  int get totalReceivedItems => items.fold(0, (prev, i) => prev + i.receivedQuantity);

  factory StockTransferModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final rawItems = json['items'];
    final List<StockTransferItemModel> parsedItems = [];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          parsedItems.add(StockTransferItemModel.fromJson(it));
        } else if (it is Map) {
          parsedItems.add(StockTransferItemModel.fromJson(Map<String, dynamic>.from(it)));
        }
      }
    }

    final createdAtRaw = json['createdAt'];
    DateTime parsedCreatedAt;
    if (createdAtRaw is Timestamp) {
      parsedCreatedAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      parsedCreatedAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final updatedAtRaw = json['updatedAt'];
    DateTime? parsedUpdatedAt;
    if (updatedAtRaw is Timestamp) {
      parsedUpdatedAt = updatedAtRaw.toDate();
    } else if (updatedAtRaw is String) {
      parsedUpdatedAt = DateTime.tryParse(updatedAtRaw);
    }

    final receivedAtRaw = json['receivedAt'];
    DateTime? parsedReceivedAt;
    if (receivedAtRaw is Timestamp) {
      parsedReceivedAt = receivedAtRaw.toDate();
    } else if (receivedAtRaw is String) {
      parsedReceivedAt = DateTime.tryParse(receivedAtRaw);
    }

    return StockTransferModel(
      id: docId ?? json['id']?.toString() ?? '',
      transferNumber: json['transferNumber']?.toString() ?? '',
      fromBranchId: json['fromBranchId']?.toString() ?? '',
      fromBranchName: json['fromBranchName']?.toString() ?? '',
      toBranchId: json['toBranchId']?.toString() ?? '',
      toBranchName: json['toBranchName']?.toString() ?? '',
      status: StockTransferStatus.fromString(json['status']?.toString()),
      priority: StockTransferPriority.fromString(json['priority']?.toString()),
      items: parsedItems,
      notes: json['notes']?.toString() ?? '',
      requestedBy: json['requestedBy']?.toString() ?? 'Cashier',
      shiftId: json['shiftId']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      receivedAt: parsedReceivedAt,
      receivedBy: json['receivedBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transferNumber': transferNumber,
        'fromBranchId': fromBranchId,
        'fromBranchName': fromBranchName,
        'toBranchId': toBranchId,
        'toBranchName': toBranchName,
        'status': status.id,
        'priority': priority.id,
        'items': items.map((e) => e.toJson()).toList(),
        'notes': notes,
        'requestedBy': requestedBy,
        'shiftId': shiftId,
        'createdAt': Timestamp.fromDate(createdAt),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
        if (receivedAt != null) 'receivedAt': Timestamp.fromDate(receivedAt!),
        'receivedBy': receivedBy,
      };

  StockTransferModel copyWith({
    String? id,
    String? transferNumber,
    String? fromBranchId,
    String? fromBranchName,
    String? toBranchId,
    String? toBranchName,
    StockTransferStatus? status,
    StockTransferPriority? priority,
    List<StockTransferItemModel>? items,
    String? notes,
    String? requestedBy,
    String? shiftId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? receivedAt,
    String? receivedBy,
  }) {
    return StockTransferModel(
      id: id ?? this.id,
      transferNumber: transferNumber ?? this.transferNumber,
      fromBranchId: fromBranchId ?? this.fromBranchId,
      fromBranchName: fromBranchName ?? this.fromBranchName,
      toBranchId: toBranchId ?? this.toBranchId,
      toBranchName: toBranchName ?? this.toBranchName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      requestedBy: requestedBy ?? this.requestedBy,
      shiftId: shiftId ?? this.shiftId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transferNumber,
        fromBranchId,
        fromBranchName,
        toBranchId,
        toBranchName,
        status,
        priority,
        items,
        notes,
        requestedBy,
        shiftId,
        createdAt,
        updatedAt,
        receivedAt,
        receivedBy,
      ];
}
