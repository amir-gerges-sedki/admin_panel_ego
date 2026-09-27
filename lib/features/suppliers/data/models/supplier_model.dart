import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Clean Architecture Data Model for Suppliers (الموردين) in EGO Store ERP.
class SupplierModel extends Equatable {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String taxNumber;
  final String paymentTerms;
  final double totalPurchases;
  final double totalPaid;
  final double balanceDue;
  final int invoicesCount;
  final List<String> suppliedCategories;
  final String notes;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxNumber = '',
    this.paymentTerms = 'Cash',
    this.totalPurchases = 0.0,
    this.totalPaid = 0.0,
    this.balanceDue = 0.0,
    this.invoicesCount = 0,
    this.suppliedCategories = const [],
    this.notes = '',
    this.rating = 5.0,
    this.isActive = true,
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

  factory SupplierModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final purchases = (json['totalPurchases'] as num?)?.toDouble() ?? 0.0;
    final paid = (json['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final computedBalance = (json['balanceDue'] as num?)?.toDouble() ?? (purchases - paid);

    return SupplierModel(
      id: docId ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      taxNumber: json['taxNumber']?.toString() ?? '',
      paymentTerms: json['paymentTerms']?.toString() ?? 'Cash',
      totalPurchases: purchases,
      totalPaid: paid,
      balanceDue: computedBalance,
      invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
      suppliedCategories: json['suppliedCategories'] != null
          ? List<String>.from(json['suppliedCategories'])
          : const [],
      notes: json['notes']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      isActive: json['isActive'] == true || json['isActive'] == null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'taxNumber': taxNumber,
        'paymentTerms': paymentTerms,
        'totalPurchases': totalPurchases,
        'totalPaid': totalPaid,
        'balanceDue': balanceDue,
        'invoicesCount': invoicesCount,
        'suppliedCategories': suppliedCategories,
        'notes': notes,
        'rating': rating,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  SupplierModel copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
    String? paymentTerms,
    double? totalPurchases,
    double? totalPaid,
    double? balanceDue,
    int? invoicesCount,
    List<String>? suppliedCategories,
    String? notes,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPaid: totalPaid ?? this.totalPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      invoicesCount: invoicesCount ?? this.invoicesCount,
      suppliedCategories: suppliedCategories ?? this.suppliedCategories,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
