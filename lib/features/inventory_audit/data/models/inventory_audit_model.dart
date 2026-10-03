import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Single item within a Physical Stock Count Audit
class InventoryAuditItemModel extends Equatable {
  final String productId;
  final String productTitle;
  final String variationSku;
  final Map<String, String> variationAttributes;
  final int systemQuantity;
  final int physicalQuantity;
  final double unitCost;
  final String notes;

  const InventoryAuditItemModel({
    required this.productId,
    required this.productTitle,
    this.variationSku = '',
    this.variationAttributes = const {},
    required this.systemQuantity,
    required this.physicalQuantity,
    this.unitCost = 0.0,
    this.notes = '',
  });

  int get variance => physicalQuantity - systemQuantity;
  double get varianceCost => variance * unitCost;

  factory InventoryAuditItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> attrs = {};
    if (json['variationAttributes'] is Map) {
      attrs = Map<String, String>.from(
        (json['variationAttributes'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }

    return InventoryAuditItemModel(
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? '',
      variationSku: json['variationSku']?.toString() ?? '',
      variationAttributes: attrs,
      systemQuantity: (json['systemQuantity'] as num?)?.toInt() ?? 0,
      physicalQuantity: (json['physicalQuantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        'variationSku': variationSku,
        'variationAttributes': variationAttributes,
        'systemQuantity': systemQuantity,
        'physicalQuantity': physicalQuantity,
        'variance': variance,
        'unitCost': unitCost,
        'varianceCost': varianceCost,
        'notes': notes,
      };

  InventoryAuditItemModel copyWith({
    String? productId,
    String? productTitle,
    String? variationSku,
    Map<String, String>? variationAttributes,
    int? systemQuantity,
    int? physicalQuantity,
    double? unitCost,
    String? notes,
  }) {
    return InventoryAuditItemModel(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      variationSku: variationSku ?? this.variationSku,
      variationAttributes: variationAttributes ?? this.variationAttributes,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      physicalQuantity: physicalQuantity ?? this.physicalQuantity,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        variationSku,
        systemQuantity,
        physicalQuantity,
      ];
}

/// Comprehensive Physical Stock Count & Reconciliation Audit Document
class InventoryAuditModel extends Equatable {
  final String id;
  final String auditNumber;
  final String branchId;
  final String branchName;
  final DateTime auditDate;
  final String auditedBy;
  final String status; // 'draft' or 'completed'
  final List<InventoryAuditItemModel> items;
  final String notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  const InventoryAuditModel({
    required this.id,
    required this.auditNumber,
    required this.branchId,
    required this.branchName,
    required this.auditDate,
    required this.auditedBy,
    this.status = 'draft',
    this.items = const [],
    this.notes = '',
    this.completedAt,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  int get totalSystemUnits => items.fold<int>(0, (prev, i) => prev + i.systemQuantity);
  int get totalCountedUnits => items.fold<int>(0, (prev, i) => prev + i.physicalQuantity);
  int get totalVarianceUnits => items.fold<int>(0, (prev, i) => prev + i.variance);
  int get deficitUnitsCount => items.where((i) => i.variance < 0).fold<int>(0, (prev, i) => prev + i.variance.abs());
  int get surplusUnitsCount => items.where((i) => i.variance > 0).fold<int>(0, (prev, i) => prev + i.variance);
  double get totalVarianceCost => items.fold<double>(0.0, (prev, i) => prev + i.varianceCost);

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  factory InventoryAuditModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final parsedItems = <InventoryAuditItemModel>[];
    if (json['items'] is List) {
      for (final raw in json['items'] as List) {
        if (raw is Map) {
          parsedItems.add(InventoryAuditItemModel.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return InventoryAuditModel(
      id: docId ?? json['id']?.toString() ?? '',
      auditNumber: json['auditNumber']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? 'main_branch',
      branchName: json['branchName']?.toString() ?? 'Main Branch',
      auditDate: _parseDate(json['auditDate']),
      auditedBy: json['auditedBy']?.toString() ?? 'Staff',
      status: json['status']?.toString() ?? 'draft',
      items: parsedItems,
      notes: json['notes']?.toString() ?? '',
      completedAt: json['completedAt'] != null ? _parseDate(json['completedAt']) : null,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'auditNumber': auditNumber,
        'branchId': branchId,
        'branchName': branchName,
        'auditDate': Timestamp.fromDate(auditDate),
        'auditedBy': auditedBy,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
        'totalSystemUnits': totalSystemUnits,
        'totalCountedUnits': totalCountedUnits,
        'totalVarianceUnits': totalVarianceUnits,
        'totalVarianceCost': totalVarianceCost,
        'notes': notes,
        if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  InventoryAuditModel copyWith({
    String? id,
    String? auditNumber,
    String? branchId,
    String? branchName,
    DateTime? auditDate,
    String? auditedBy,
    String? status,
    List<InventoryAuditItemModel>? items,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return InventoryAuditModel(
      id: id ?? this.id,
      auditNumber: auditNumber ?? this.auditNumber,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      auditDate: auditDate ?? this.auditDate,
      auditedBy: auditedBy ?? this.auditedBy,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, auditNumber, branchId, status, items.length];
}
