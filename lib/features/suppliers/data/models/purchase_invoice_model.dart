import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Payment status for purchase invoices
enum InvoicePaymentStatus {
  unpaid('unpaid'),
  partial('partial'),
  paid('paid'),
  overdue('overdue');

  final String value;
  const InvoicePaymentStatus(this.value);

  static InvoicePaymentStatus fromString(String? val) {
    if (val == null) return InvoicePaymentStatus.unpaid;
    final clean = val.trim().toLowerCase();
    for (final s in InvoicePaymentStatus.values) {
      if (s.value == clean) return s;
    }
    return InvoicePaymentStatus.unpaid;
  }
}

/// Line item within a Purchase Invoice
class PurchaseInvoiceItemModel extends Equatable {
  final String productId;
  final String productTitle;
  final String? variationSku;
  final Map<String, String> variationAttributes;
  final int quantity;
  final double unitCost;
  final double subtotal;
  final String notes;

  const PurchaseInvoiceItemModel({
    required this.productId,
    required this.productTitle,
    this.variationSku,
    this.variationAttributes = const {},
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.notes = '',
  });

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;
    final cost = (json['unitCost'] as num?)?.toDouble() ?? 0.0;
    final sub = (json['subtotal'] as num?)?.toDouble() ?? (qty * cost);

    Map<String, String> attrs = {};
    if (json['variationAttributes'] != null && json['variationAttributes'] is Map) {
      attrs = Map<String, String>.from(
        (json['variationAttributes'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }

    return PurchaseInvoiceItemModel(
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? '',
      variationSku: json['variationSku']?.toString(),
      variationAttributes: attrs,
      quantity: qty,
      unitCost: cost,
      subtotal: sub,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productTitle': productTitle,
        'variationSku': variationSku,
        'variationAttributes': variationAttributes,
        'quantity': quantity,
        'unitCost': unitCost,
        'subtotal': subtotal,
        'notes': notes,
      };

  PurchaseInvoiceItemModel copyWith({
    String? productId,
    String? productTitle,
    String? variationSku,
    Map<String, String>? variationAttributes,
    int? quantity,
    double? unitCost,
    double? subtotal,
    String? notes,
  }) {
    return PurchaseInvoiceItemModel(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      variationSku: variationSku ?? this.variationSku,
      variationAttributes: variationAttributes ?? this.variationAttributes,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productTitle,
        variationSku,
        variationAttributes,
        quantity,
        unitCost,
        subtotal,
        notes,
      ];
}

/// Clean Architecture Data Model for Purchase Invoices (فواتير الشراء والتوريد).
class PurchaseInvoiceModel extends Equatable {
  final String id;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final List<PurchaseInvoiceItemModel> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingCost;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final InvoicePaymentStatus paymentStatus;
  final String paymentMethod;
  final bool stockReceived;
  final String notes;
  final String attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceDate,
    this.dueDate,
    this.items = const [],
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.shippingCost = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentStatus = InvoicePaymentStatus.unpaid,
    this.paymentMethod = 'Cash',
    this.stockReceived = true,
    this.notes = '',
    this.attachmentUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final parsedItems = <PurchaseInvoiceItemModel>[];
    if (json['items'] != null && json['items'] is List) {
      for (final raw in json['items']) {
        if (raw is Map<String, dynamic>) {
          parsedItems.add(PurchaseInvoiceItemModel.fromJson(raw));
        }
      }
    }

    final total = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paid = (json['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remaining = (json['remainingAmount'] as num?)?.toDouble() ?? (total - paid);

    InvoicePaymentStatus status = InvoicePaymentStatus.fromString(json['paymentStatus']?.toString());
    if (paid >= total && total > 0) {
      status = InvoicePaymentStatus.paid;
    } else if (paid > 0 && paid < total) {
      status = InvoicePaymentStatus.partial;
    }

    DateTime? due;
    if (json['dueDate'] != null) {
      due = _parseDateTime(json['dueDate']);
    }

    return PurchaseInvoiceModel(
      id: docId ?? json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      invoiceDate: _parseDateTime(json['invoiceDate']),
      dueDate: due,
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: status,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      stockReceived: json['stockReceived'] == true || json['stockReceived'] == null,
      notes: json['notes']?.toString() ?? '',
      attachmentUrl: json['attachmentUrl']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'invoiceDate': Timestamp.fromDate(invoiceDate),
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'discountAmount': discountAmount,
        'shippingCost': shippingCost,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'paymentStatus': paymentStatus.value,
        'paymentMethod': paymentMethod,
        'stockReceived': stockReceived,
        'notes': notes,
        'attachmentUrl': attachmentUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  PurchaseInvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierId,
    String? supplierName,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<PurchaseInvoiceItemModel>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? shippingCost,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    InvoicePaymentStatus? paymentStatus,
    String? paymentMethod,
    bool? stockReceived,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseInvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stockReceived: stockReceived ?? this.stockReceived,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
