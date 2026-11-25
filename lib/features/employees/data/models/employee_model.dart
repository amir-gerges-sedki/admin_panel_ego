import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/pin_hasher.dart';

/// Employee Model for HR, Salaries, Advances, Staff Management, and PIN Authentication.
class EmployeeModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String nationalId;
  final String jobTitle;
  final double baseSalary;
  final DateTime hireDate;
  final bool isActive;
  final String notes;
  final String address;
  final String emergencyContact;
  final DateTime createdAt;

  /// Personal PIN code for Admin Panel & POS access (stored securely as SHA-256 hash or legacy string)
  final String pinCode;

  /// Assigned administrative role ('super_admin', 'admin', 'staff')
  final String role;

  /// Assigned branch ID (e.g. 'main_branch')
  final String branchId;

  /// Sales commission percentage for bonus calculations (e.g. 2.5 for 2.5%)
  final double commissionRate;

  /// Optional staff avatar / profile image URL
  final String avatarUrl;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    this.nationalId = '',
    required this.jobTitle,
    required this.baseSalary,
    required this.hireDate,
    this.isActive = true,
    this.notes = '',
    this.address = '',
    this.emergencyContact = '',
    required this.createdAt,
    this.pinCode = '',
    this.role = 'staff',
    this.branchId = 'main_branch',
    this.commissionRate = 0.0,
    this.avatarUrl = '',
  });

  /// Verifies a candidate plain PIN against this employee's stored hash or legacy PIN
  bool verifyPin(String candidate) {
    return PinHasher.verifyPin(candidatePin: candidate, storedHashOrPlain: pinCode);
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final hireRaw = json['hireDate'];
    DateTime parsedHireDate;
    if (hireRaw is Timestamp) {
      parsedHireDate = hireRaw.toDate();
    } else if (hireRaw is String) {
      parsedHireDate = DateTime.tryParse(hireRaw) ?? DateTime.now();
    } else {
      parsedHireDate = DateTime.now();
    }

    final createdRaw = json['createdAt'];
    DateTime parsedCreatedAt;
    if (createdRaw is Timestamp) {
      parsedCreatedAt = createdRaw.toDate();
    } else if (createdRaw is String) {
      parsedCreatedAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return EmployeeModel(
      id: docId ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      nationalId: json['nationalId']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString() ?? json['position']?.toString() ?? 'Staff',
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
      hireDate: parsedHireDate,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      pinCode: json['pinCode']?.toString() ?? json['pin']?.toString() ?? '',
      role: json['role']?.toString() ?? 'staff',
      branchId: json['branchId']?.toString() ?? 'main_branch',
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: json['avatarUrl']?.toString() ?? json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'nationalId': nationalId,
        'jobTitle': jobTitle,
        'baseSalary': baseSalary,
        'hireDate': Timestamp.fromDate(hireDate),
        'isActive': isActive,
        'notes': notes,
        'address': address,
        'emergencyContact': emergencyContact,
        'createdAt': Timestamp.fromDate(createdAt),
        'pinCode': pinCode,
        'role': role,
        'branchId': branchId,
        'commissionRate': commissionRate,
        'avatarUrl': avatarUrl,
      };

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? nationalId,
    String? jobTitle,
    double? baseSalary,
    DateTime? hireDate,
    bool? isActive,
    String? notes,
    String? address,
    String? emergencyContact,
    DateTime? createdAt,
    String? pinCode,
    String? role,
    String? branchId,
    double? commissionRate,
    String? avatarUrl,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      jobTitle: jobTitle ?? this.jobTitle,
      baseSalary: baseSalary ?? this.baseSalary,
      hireDate: hireDate ?? this.hireDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      commissionRate: commissionRate ?? this.commissionRate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        nationalId,
        jobTitle,
        baseSalary,
        hireDate,
        isActive,
        notes,
        address,
        emergencyContact,
        createdAt,
        pinCode,
        role,
        branchId,
        commissionRate,
        avatarUrl,
      ];
}
