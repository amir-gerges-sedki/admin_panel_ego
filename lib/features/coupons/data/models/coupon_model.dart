import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

DateTime? _parseNullableDate(dynamic date) {
  if (date == null) return null;
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString());
}

DateTime _parseCouponDate(dynamic date) {
  if (date == null) return DateTime.now().add(const Duration(days: 30));
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString()) ??
      DateTime.now().add(const Duration(days: 30));
}

class CouponModel extends Equatable {
  final String id;
  final String code;
  final double discountPercentage;
  final bool isActive;
  final DateTime? startDate;
  final DateTime expiryDate;
  final double minOrderAmount;
  final int usageCount;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    required this.isActive,
    this.startDate,
    required this.expiryDate,
    this.minOrderAmount = 0.0,
    this.usageCount = 0,
  });

  /// Returns true if current time is past the expiry date
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Returns true if current time has reached or passed the start date
  bool get isStarted =>
      startDate == null ||
      DateTime.now().isAfter(startDate!) ||
      DateTime.now().isAtSameMomentAs(startDate!);

  /// A coupon is effectively active only if admin enabled it, start date reached, and not expired
  bool get isEffectiveActive => isActive && isStarted && !isExpired;

  CouponModel copyWith({
    String? id,
    String? code,
    double? discountPercentage,
    bool? isActive,
    DateTime? startDate,
    DateTime? expiryDate,
    double? minOrderAmount,
    int? usageCount,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      code: json['code']?.toString() ?? json['Code']?.toString() ?? '',
      discountPercentage:
          (json['discountPercentage'] ??
                  json['DiscountPercentage'] ??
                  json['discount'] as num?)
              ?.toDouble() ??
          0.0,
      isActive:
          json['isActive'] == true ||
          json['IsActive'] == true ||
          json['active'] == true ||
          json['isActive'] == null,
      startDate: _parseNullableDate(
        json['startDate'] ?? json['StartDate'] ?? json['startsAt'],
      ),
      expiryDate: _parseCouponDate(
        json['expiryDate'] ??
            json['ExpiryDate'] ??
            json['expiresAt'] ??
            json['validUntil'],
      ),
      minOrderAmount:
          (json['minOrderAmount'] ??
                  json['MinOrderAmount'] ??
                  json['minOrder'] as num?)
              ?.toDouble() ??
          0.0,
      usageCount:
          (json['usageCount'] ?? json['UsageCount'] ?? json['usage'] as num?)
              ?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountPercentage': discountPercentage,
    'isActive': isActive,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'minOrderAmount': minOrderAmount,
    'usageCount': usageCount,
  };

  @override
  List<Object?> get props => [
    id,
    code,
    discountPercentage,
    isActive,
    startDate,
    expiryDate,
    minOrderAmount,
    usageCount,
  ];
}
