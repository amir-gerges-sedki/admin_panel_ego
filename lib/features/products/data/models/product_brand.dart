import 'package:equatable/equatable.dart';

/// Clean Architecture Data Model representing the nested brand object inside a Product.
class ProductBrand extends Equatable {
  final String id;
  final String name;

  const ProductBrand({
    required this.id,
    required this.name,
  });

  factory ProductBrand.fromJson(dynamic json) {
    if (json is Map) {
      return ProductBrand(
        id: json['id']?.toString().trim() ?? '',
        name: json['name']?.toString().trim() ?? '',
      );
    } else if (json is String && json.trim().isNotEmpty) {
      return ProductBrand(
        id: '',
        name: json.trim(),
      );
    }
    return const ProductBrand(id: '', name: '');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  @override
  List<Object?> get props => [id, name];
}

