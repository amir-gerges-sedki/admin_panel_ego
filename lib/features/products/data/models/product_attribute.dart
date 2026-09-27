import 'package:equatable/equatable.dart';

/// Product Attribute representation (e.g. Flavor, Nicotine, Size, Style, Color).
class ProductAttribute extends Equatable {
  final String name;
  final List<String> values;

  const ProductAttribute({required this.name, required this.values});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] ?? json['Values'];
    final List<String> parsedValues = rawValues is List
        ? rawValues.map((e) => e.toString()).toList()
        : <String>[];

    return ProductAttribute(
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      values: parsedValues,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'values': values};

  @override
  List<Object?> get props => [name, values];
}
