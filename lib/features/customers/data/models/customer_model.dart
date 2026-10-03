import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

DateTime _parseCustomerDate(dynamic date) {
  if (date == null) return DateTime.now();
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString()) ?? DateTime.now();
}

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String image;
  final String role;
  final String city;
  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.image = '',
    this.role = 'user',
    this.city = 'Cairo',
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    String parsedName = (json['name'] ?? json['userName'])?.toString().trim() ?? '';
    if (parsedName.isEmpty) {
      final fName = (json['FirstName'] ?? json['firstName'])?.toString().trim() ?? '';
      final lName = (json['LastName'] ?? json['lastName'])?.toString().trim() ?? '';
      parsedName = '$fName $lName'.trim();
    }
    if (parsedName.isEmpty) {
      parsedName = 'Customer';
    }

    final parsedPhone = (json['phone'] ??
            json['phoneNumber'] ??
            json['PhoneNumber'] ??
            json['mobile'])
        ?.toString()
        .trim() ??
        '';

    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: parsedName,
      email: json['email']?.toString() ?? '',
      phone: parsedPhone,
      image: json['image']?.toString() ?? '',
      role: (json['role'] ?? 'user').toString().toLowerCase(),
      city: json['city']?.toString() ?? 'Cairo',
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      createdAt: _parseCustomerDate(json['createdAt']),
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? image,
    String? role,
    String? city,
    int? totalOrders,
    double? totalSpent,
    int? loyaltyPoints,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      role: role ?? this.role,
      city: city ?? this.city,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'image': image,
    'role': role,
    'city': city,
    'totalOrders': totalOrders,
    'totalSpent': totalSpent,
    'loyaltyPoints': loyaltyPoints,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    image,
    role,
    city,
    totalOrders,
    totalSpent,
    loyaltyPoints,
    createdAt,
  ];
}
