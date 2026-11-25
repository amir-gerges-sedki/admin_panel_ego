import 'package:equatable/equatable.dart';

/// Represents a distinct business tenant (Company / Legal Entity) in the EGO SaaS platform.
class TenantModel extends Equatable {
  final String tenantId;
  final String companyName;
  final String taxNumber;
  final String commercialRegister;
  final String ownerEmail;
  final String ownerPhone;
  final String subscriptionPlan; // 'starter', 'pro', 'enterprise'
  final String subscriptionStatus; // 'active', 'trialing', 'past_due', 'suspended'
  final DateTime? subscriptionExpiresAt;
  final int maxStores;
  final int maxBranches;
  final int maxEmployees;
  final Map<String, dynamic> featureFlags;
  final DateTime createdAt;
  final bool isActive;

  const TenantModel({
    required this.tenantId,
    required this.companyName,
    this.taxNumber = '',
    this.commercialRegister = '',
    required this.ownerEmail,
    this.ownerPhone = '',
    this.subscriptionPlan = 'pro',
    this.subscriptionStatus = 'active',
    this.subscriptionExpiresAt,
    this.maxStores = 5,
    this.maxBranches = 20,
    this.maxEmployees = 50,
    this.featureFlags = const {},
    required this.createdAt,
    this.isActive = true,
  });

  /// Default baseline tenant for backward-compatibility with existing legacy data
  static TenantModel get defaultTenant => TenantModel(
        tenantId: 'ego_master',
        companyName: 'EGO Vape Store Group',
        ownerEmail: 'admin@egovape.com',
        ownerPhone: '01000000000',
        subscriptionPlan: 'enterprise',
        subscriptionStatus: 'active',
        maxStores: 999,
        maxBranches: 999,
        maxEmployees: 999,
        createdAt: DateTime(2025, 1, 1),
      );

  TenantModel copyWith({
    String? tenantId,
    String? companyName,
    String? taxNumber,
    String? commercialRegister,
    String? ownerEmail,
    String? ownerPhone,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    int? maxStores,
    int? maxBranches,
    int? maxEmployees,
    Map<String, dynamic>? featureFlags,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TenantModel(
      tenantId: tenantId ?? this.tenantId,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      maxStores: maxStores ?? this.maxStores,
      maxBranches: maxBranches ?? this.maxBranches,
      maxEmployees: maxEmployees ?? this.maxEmployees,
      featureFlags: featureFlags ?? this.featureFlags,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'companyName': companyName,
        'taxNumber': taxNumber,
        'commercialRegister': commercialRegister,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'subscriptionPlan': subscriptionPlan,
        'subscriptionStatus': subscriptionStatus,
        if (subscriptionExpiresAt != null)
          'subscriptionExpiresAt': subscriptionExpiresAt!.toIso8601String(),
        'maxStores': maxStores,
        'maxBranches': maxBranches,
        'maxEmployees': maxEmployees,
        'featureFlags': featureFlags,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      tenantId: json['tenantId']?.toString() ?? 'ego_master',
      companyName: json['companyName']?.toString() ?? 'EGO Store',
      taxNumber: json['taxNumber']?.toString() ?? '',
      commercialRegister: json['commercialRegister']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      ownerPhone: json['ownerPhone']?.toString() ?? '',
      subscriptionPlan: json['subscriptionPlan']?.toString() ?? 'pro',
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? 'active',
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
      maxStores: (json['maxStores'] as num?)?.toInt() ?? 5,
      maxBranches: (json['maxBranches'] as num?)?.toInt() ?? 20,
      maxEmployees: (json['maxEmployees'] as num?)?.toInt() ?? 50,
      featureFlags: json['featureFlags'] is Map
          ? Map<String, dynamic>.from(json['featureFlags'] as Map)
          : const {},
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        tenantId,
        companyName,
        taxNumber,
        commercialRegister,
        ownerEmail,
        ownerPhone,
        subscriptionPlan,
        subscriptionStatus,
        subscriptionExpiresAt,
        maxStores,
        maxBranches,
        maxEmployees,
        featureFlags,
        createdAt,
        isActive,
      ];
}
