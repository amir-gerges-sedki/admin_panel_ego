import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Clean Architecture Data Model for Supplier Payments (سندات الصرف والدفع للموردين).
class SupplierPaymentModel extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final String? invoiceId;
  final String? invoiceNumber;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String notes;
  final DateTime createdAt;

  const SupplierPaymentModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.invoiceId,
    this.invoiceNumber,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'Cash',
    this.referenceNumber = '',
    this.notes = '',
    required this.createdAt,
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

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SupplierPaymentModel(
      id: docId ?? json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: _parseDateTime(json['paymentDate']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'supplierId': supplierId,
        'supplierName': supplierName,
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'amount': amount,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  SupplierPaymentModel copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    String? invoiceId,
    String? invoiceNumber,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplierPaymentModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
