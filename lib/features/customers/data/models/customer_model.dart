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
  final String userName;
  final String email;
  final String phone;
  final String image;
  final String role;
  final String city;
  final int totalOrders;
  final double totalSpent;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.email,
    required this.phone,
    this.image = '',
    this.role = 'user',
    this.city = 'Cairo',
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['Name']?.toString() ??
          json['fullName']?.toString() ??
          json['FullName']?.toString() ??
          json['userName']?.toString() ??
          'Customer',
      userName: json['userName']?.toString() ??
          json['UserName']?.toString() ??
          json['username']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? json['Email']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['Phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['PhoneNumber']?.toString() ??
          '',
      image: json['image']?.toString() ??
          json['Image']?.toString() ??
          json['profilePicture']?.toString() ??
          json['photoUrl']?.toString() ??
          '',
      role: (json['role'] ?? json['Role'] ?? 'user').toString().toLowerCase(),
      city: json['city']?.toString() ?? json['City']?.toString() ?? 'Cairo',
      totalOrders: (json['totalOrders'] ?? json['TotalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] ?? json['TotalSpent'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseCustomerDate(json['createdAt'] ?? json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'userName': userName,
        'email': email,
        'phone': phone,
        'image': image,
        'role': role,
        'city': city,
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        userName,
        email,
        phone,
        image,
        role,
        city,
        totalOrders,
        totalSpent,
        createdAt,
      ];
}
