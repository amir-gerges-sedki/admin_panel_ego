import 'package:equatable/equatable.dart';

class StoreBranchModel extends Equatable {
  final String id;
  final String name; // e.g. "فرع المعادي" / "Main Branch"
  final String phone;
  final String address;
  final String mapsUrl;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final bool isWarehouse;

  const StoreBranchModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.mapsUrl = '',
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.isWarehouse = false,
  });

  StoreBranchModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? mapsUrl,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    bool? isWarehouse,
  }) {
    return StoreBranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      isWarehouse: isWarehouse ?? this.isWarehouse,
    );
  }

  factory StoreBranchModel.fromJson(Map<String, dynamic> json) {
    final nameStr = json['name']?.toString() ?? '';
    final isWarehouseAuto = nameStr.toLowerCase().contains('مخزن') || nameStr.toLowerCase().contains('warehouse');
    return StoreBranchModel(
      id: json['id']?.toString() ?? '',
      name: nameStr,
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      mapsUrl: json['mapsUrl']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPrimary: json['isPrimary'] as bool? ?? false,
      isWarehouse: json['isWarehouse'] as bool? ?? isWarehouseAuto,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'mapsUrl': mapsUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isPrimary': isPrimary,
        'isWarehouse': isWarehouse,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        mapsUrl,
        latitude,
        longitude,
        isPrimary,
        isWarehouse,
      ];
}

