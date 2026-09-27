import 'package:equatable/equatable.dart';

/// Clean Architecture Data Model for Brands loaded from Firestore collection 'Brands'.
class BrandModel extends Equatable {
  final String id;
  final String name;
  final String image;
  final bool isFeatured;
  final int productsCount;
  final int sortOrder;

  const BrandModel({
    required this.id,
    required this.name,
    this.image = '',
    this.isFeatured = true,
    this.productsCount = 0,
    this.sortOrder = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      isFeatured: json['isFeatured'] == true || json['isFeatured'] == null,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      sortOrder:
          (json['sortOrder'] ?? json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? image,
    bool? isFeatured,
    int? productsCount,
    int? sortOrder,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isFeatured: isFeatured ?? this.isFeatured,
      productsCount: productsCount ?? this.productsCount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'isFeatured': isFeatured,
    'productsCount': productsCount,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    image,
    isFeatured,
    productsCount,
    sortOrder,
  ];
}
