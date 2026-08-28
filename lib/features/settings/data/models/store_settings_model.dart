import 'package:equatable/equatable.dart';

class StoreSettingsModel extends Equatable {
  final String phoneNumber;
  final String whatsNumber;
  final String email;
  final String address;
  final bool enforceAgeVerification;
  final bool showNicotineWarningBanner;
  final double flatDeliveryFee;
  final double freeShippingThreshold;

  const StoreSettingsModel({
    required this.phoneNumber,
    required this.whatsNumber,
    required this.email,
    required this.address,
    this.enforceAgeVerification = true,
    this.showNicotineWarningBanner = true,
    this.flatDeliveryFee = 60.0,
    this.freeShippingThreshold = 2000.0,
  });

  StoreSettingsModel copyWith({
    String? phoneNumber,
    String? whatsNumber,
    String? email,
    String? address,
    bool? enforceAgeVerification,
    bool? showNicotineWarningBanner,
    double? flatDeliveryFee,
    double? freeShippingThreshold,
  }) {
    return StoreSettingsModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsNumber: whatsNumber ?? this.whatsNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      enforceAgeVerification: enforceAgeVerification ?? this.enforceAgeVerification,
      showNicotineWarningBanner: showNicotineWarningBanner ?? this.showNicotineWarningBanner,
      flatDeliveryFee: flatDeliveryFee ?? this.flatDeliveryFee,
      freeShippingThreshold: freeShippingThreshold ?? this.freeShippingThreshold,
    );
  }

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      phoneNumber: json['phoneNumber'] ?? '01012345678',
      whatsNumber: json['whatsNumber'] ?? '01012345678',
      email: json['email'] ?? 'support@egostore.com',
      address: json['address'] ?? 'Cairo, Egypt',
      enforceAgeVerification: json['enforceAgeVerification'] ?? true,
      showNicotineWarningBanner: json['showNicotineWarningBanner'] ?? true,
      flatDeliveryFee: (json['flatDeliveryFee'] as num?)?.toDouble() ?? 60.0,
      freeShippingThreshold: (json['freeShippingThreshold'] as num?)?.toDouble() ?? 2000.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'whatsNumber': whatsNumber,
        'email': email,
        'address': address,
        'enforceAgeVerification': enforceAgeVerification,
        'showNicotineWarningBanner': showNicotineWarningBanner,
        'flatDeliveryFee': flatDeliveryFee,
        'freeShippingThreshold': freeShippingThreshold,
      };

  @override
  List<Object?> get props => [
        phoneNumber,
        whatsNumber,
        email,
        address,
        enforceAgeVerification,
        showNicotineWarningBanner,
        flatDeliveryFee,
        freeShippingThreshold,
      ];
}
