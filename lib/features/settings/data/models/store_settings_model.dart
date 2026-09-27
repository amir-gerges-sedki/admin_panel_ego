import 'package:equatable/equatable.dart';
import 'governorate_delivery_model.dart';
import 'store_branch_model.dart';

class StoreSettingsModel extends Equatable {
  final String phoneNumber;
  final String whatsNumber;
  final String email;
  final String address;
  final bool enforceAgeVerification;
  final bool showNicotineWarningBanner;
  final double flatDeliveryFee;
  final double freeShippingThreshold;
  final String estimatedDeliveryTime;
  final int lowStockThreshold;
  final List<StoreBranchModel> branches;
  final List<GovernorateDeliveryModel> governorates;

  const StoreSettingsModel({
    required this.phoneNumber,
    required this.whatsNumber,
    required this.email,
    required this.address,
    this.enforceAgeVerification = true,
    this.showNicotineWarningBanner = true,
    this.flatDeliveryFee = 0.0,
    this.freeShippingThreshold = 0.0,
    this.estimatedDeliveryTime = '24-48 Hours',
    this.lowStockThreshold = 10,
    List<StoreBranchModel>? branches,
    List<GovernorateDeliveryModel>? governorates,
  })  : branches = branches ?? const [],
        governorates = governorates ?? const [];

  StoreSettingsModel copyWith({
    String? phoneNumber,
    String? whatsNumber,
    String? email,
    String? address,
    bool? enforceAgeVerification,
    bool? showNicotineWarningBanner,
    double? flatDeliveryFee,
    double? freeShippingThreshold,
    String? estimatedDeliveryTime,
    int? lowStockThreshold,
    List<StoreBranchModel>? branches,
    List<GovernorateDeliveryModel>? governorates,
  }) {
    return StoreSettingsModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsNumber: whatsNumber ?? this.whatsNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      enforceAgeVerification:
          enforceAgeVerification ?? this.enforceAgeVerification,
      showNicotineWarningBanner:
          showNicotineWarningBanner ?? this.showNicotineWarningBanner,
      flatDeliveryFee: flatDeliveryFee ?? this.flatDeliveryFee,
      freeShippingThreshold:
          freeShippingThreshold ?? this.freeShippingThreshold,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      branches: branches ?? this.branches,
      governorates: governorates ?? this.governorates,
    );
  }

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    var rawBranches = json['branches'];
    List<StoreBranchModel> parsedBranches = [];
    if (rawBranches is List) {
      for (final item in rawBranches) {
        if (item is Map) {
          try {
            parsedBranches.add(
              StoreBranchModel.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        } else if (item is StoreBranchModel) {
          parsedBranches.add(item);
        }
      }
    }

    var rawGovs = json['governorates'];
    List<GovernorateDeliveryModel> parsedGovs = [];
    if (rawGovs is List && rawGovs.isNotEmpty) {
      final defaultList = GovernorateDeliveryModel.defaultGovernorates();
      final Map<String, GovernorateDeliveryModel> map = {};
      for (final def in defaultList) {
        map[def.id] = def;
      }

      for (final item in rawGovs) {
        if (item is Map) {
          try {
            final parsed = GovernorateDeliveryModel.fromJson(
                Map<String, dynamic>.from(item));
            if (parsed.id.isNotEmpty) {
              map[parsed.id] = parsed;
            }
          } catch (_) {}
        }
      }
      parsedGovs = defaultList.map((d) => map[d.id] ?? d).toList();
    } else {
      parsedGovs = GovernorateDeliveryModel.defaultGovernorates();
    }

    return StoreSettingsModel(
      phoneNumber: (json['phoneNumber'] ?? '01012345678').toString(),
      whatsNumber: (json['whatsNumber'] ?? '01012345678').toString(),
      email: (json['email'] ?? 'support@egostore.com').toString(),
      address: (json['address'] ?? 'Cairo, Egypt').toString(),
      enforceAgeVerification: json['enforceAgeVerification'] ?? true,
      showNicotineWarningBanner: json['showNicotineWarningBanner'] ?? true,
      flatDeliveryFee: (json['flatDeliveryFee'] as num?)?.toDouble() ?? 0.0,
      freeShippingThreshold:
          (json['freeShippingThreshold'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryTime:
          (json['estimatedDeliveryTime'] ?? '24-48 Hours').toString(),
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
      branches: parsedBranches,
      governorates: parsedGovs,
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
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'lowStockThreshold': lowStockThreshold,
        'branches': branches.map((b) => b.toJson()).toList(),
        'governorates': governorates.map((g) => g.toJson()).toList(),
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
        estimatedDeliveryTime,
        lowStockThreshold,
        branches,
        governorates,
      ];
}
