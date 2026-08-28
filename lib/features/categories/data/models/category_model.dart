import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String image;
  final String? parentId;
  final bool isFeatured;
  final int productsCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.image = '',
    this.parentId,
    this.isFeatured = true,
    this.productsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['Name']?.toString() ?? json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? json['Image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? json['ParentId']?.toString(),
      isFeatured: json['isFeatured'] == true || json['IsFeatured'] == true || json['isFeatured'] == null,
      productsCount: (json['productsCount'] ?? json['ProductsCount'] as num?)?.toInt() ?? 0,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? parentId,
    bool? isFeatured,
    int? productsCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      isFeatured: isFeatured ?? this.isFeatured,
      productsCount: productsCount ?? this.productsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'parentId': parentId,
        'isFeatured': isFeatured,
        'productsCount': productsCount,
      };

  @override
  List<Object?> get props => [id, name, image, parentId, isFeatured, productsCount];
}

class BrandModel extends Equatable {
  final String id;
  final String name;
  final String image;
  final bool isFeatured;
  final int productsCount;

  const BrandModel({
    required this.id,
    required this.name,
    this.image = '',
    this.isFeatured = true,
    this.productsCount = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['Name']?.toString() ??
          json['lineName']?.toString() ??
          json['LineName']?.toString() ??
          json['line']?.toString() ??
          json['Line']?.toString() ??
          json['title']?.toString() ??
          json['Title']?.toString() ??
          '',
      image: json['image']?.toString() ??
          json['Image']?.toString() ??
          json['logo']?.toString() ??
          json['Logo']?.toString() ??
          json['imageUrl']?.toString() ??
          json['ImageUrl']?.toString() ??
          '',
      isFeatured: json['isFeatured'] == true || json['IsFeatured'] == true || json['isFeatured'] == null,
      productsCount: (json['productsCount'] ?? json['ProductsCount'] ?? json['count'] ?? json['Count'] as num?)?.toInt() ?? 0,
    );
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? image,
    bool? isFeatured,
    int? productsCount,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isFeatured: isFeatured ?? this.isFeatured,
      productsCount: productsCount ?? this.productsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'isFeatured': isFeatured,
        'productsCount': productsCount,
      };

  @override
  List<Object?> get props => [id, name, image, isFeatured, productsCount];
}
