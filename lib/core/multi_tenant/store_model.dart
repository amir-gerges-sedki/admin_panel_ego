import 'package:equatable/equatable.dart';

/// Represents a distinct Store / Brand under a Tenant.
class StoreModel extends Equatable {
  final String storeId;
  final String tenantId;
  final String name;
  final String slug;
  final String logoUrl;
  final String currency; // Default: 'EGP'
  final String primaryColor;
  final bool isOnlineStoreEnabled;
  final bool isPosEnabled;
  final bool isActive;
  final DateTime createdAt;

  const StoreModel({
    required this.storeId,
    required this.tenantId,
    required this.name,
    this.slug = '',
    this.logoUrl = '',
    this.currency = 'EGP',
    this.primaryColor = '#3B82F6',
    this.isOnlineStoreEnabled = true,
    this.isPosEnabled = true,
    this.isActive = true,
    required this.createdAt,
  });

  /// Default baseline store for backward compatibility
  static StoreModel get defaultStore => StoreModel(
        storeId: 'store_main',
        tenantId: 'ego_master',
        name: 'EGO Main Store',
        slug: 'ego-main',
        currency: 'EGP',
        isOnlineStoreEnabled: true,
        isPosEnabled: true,
        createdAt: DateTime(2025, 1, 1),
      );

  StoreModel copyWith({
    String? storeId,
    String? tenantId,
    String? name,
    String? slug,
    String? logoUrl,
    String? currency,
    String? primaryColor,
    bool? isOnlineStoreEnabled,
    bool? isPosEnabled,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StoreModel(
      storeId: storeId ?? this.storeId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      primaryColor: primaryColor ?? this.primaryColor,
      isOnlineStoreEnabled: isOnlineStoreEnabled ?? this.isOnlineStoreEnabled,
      isPosEnabled: isPosEnabled ?? this.isPosEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'tenantId': tenantId,
        'name': name,
        'slug': slug,
        'logoUrl': logoUrl,
        'currency': currency,
        'primaryColor': primaryColor,
        'isOnlineStoreEnabled': isOnlineStoreEnabled,
        'isPosEnabled': isPosEnabled,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      storeId: json['storeId']?.toString() ?? 'store_main',
      tenantId: json['tenantId']?.toString() ?? 'ego_master',
      name: json['name']?.toString() ?? 'Main Store',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'EGP',
      primaryColor: json['primaryColor']?.toString() ?? '#3B82F6',
      isOnlineStoreEnabled: json['isOnlineStoreEnabled'] as bool? ?? true,
      isPosEnabled: json['isPosEnabled'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        storeId,
        tenantId,
        name,
        slug,
        logoUrl,
        currency,
        primaryColor,
        isOnlineStoreEnabled,
        isPosEnabled,
        isActive,
        createdAt,
      ];
}
