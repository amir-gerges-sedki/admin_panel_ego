import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

DateTime _parseCouponDate(dynamic date) {
  if (date == null) return DateTime.now().add(const Duration(days: 30));
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString()) ?? DateTime.now().add(const Duration(days: 30));
}

class CouponModel extends Equatable {
  final String id;
  final String code;
  final double discountPercentage;
  final bool isActive;
  final DateTime expiryDate;
  final double minOrderAmount;
  final int usageCount;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    required this.isActive,
    required this.expiryDate,
    this.minOrderAmount = 0.0,
    this.usageCount = 0,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      code: json['code']?.toString() ?? json['Code']?.toString() ?? '',
      discountPercentage: (json['discountPercentage'] ?? json['DiscountPercentage'] ?? json['discount'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == true || json['IsActive'] == true || json['active'] == true || json['isActive'] == null,
      expiryDate: _parseCouponDate(json['expiryDate'] ?? json['ExpiryDate'] ?? json['expiresAt']),
      minOrderAmount: (json['minOrderAmount'] ?? json['MinOrderAmount'] ?? json['minOrder'] as num?)?.toDouble() ?? 0.0,
      usageCount: (json['usageCount'] ?? json['UsageCount'] ?? json['usage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'discountPercentage': discountPercentage,
        'isActive': isActive,
        'expiryDate': expiryDate.toIso8601String(),
        'minOrderAmount': minOrderAmount,
        'usageCount': usageCount,
      };

  @override
  List<Object?> get props => [id, code, discountPercentage, isActive, expiryDate, minOrderAmount, usageCount];
}
