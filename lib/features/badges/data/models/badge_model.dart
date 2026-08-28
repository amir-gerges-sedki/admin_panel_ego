import 'package:equatable/equatable.dart';

/// Clean Architecture Data Model for Product / Homepage Badges loaded from Firebase
class BadgeModel extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String colorHex;
  final String textColorHex;
  final String icon;
  final bool isActive;
  final int displayOrder;

  const BadgeModel({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.colorHex = '#4B68FF',
    this.textColorHex = '#FFFFFF',
    this.icon = '',
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory BadgeModel.empty() {
    return const BadgeModel(
      id: '',
      name: '',
      nameAr: '',
      colorHex: '#4B68FF',
      textColorHex: '#FFFFFF',
      icon: '',
      isActive: true,
      displayOrder: 0,
    );
  }

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['Name']?.toString() ?? json['title']?.toString() ?? 'Badge',
      nameAr: json['nameAr']?.toString() ?? json['NameAr']?.toString() ?? json['titleAr']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? json['ColorHex']?.toString() ?? json['color']?.toString() ?? '#4B68FF',
      textColorHex: json['textColorHex']?.toString() ?? json['TextColorHex']?.toString() ?? '#FFFFFF',
      icon: json['icon']?.toString() ?? json['Icon']?.toString() ?? '',
      isActive: json['isActive'] != false && json['IsActive'] != false,
      displayOrder: (json['displayOrder'] ?? json['DisplayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameAr': nameAr,
        'colorHex': colorHex,
        'textColorHex': textColorHex,
        'icon': icon,
        'isActive': isActive,
        'displayOrder': displayOrder,
      };

  BadgeModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? colorHex,
    String? textColorHex,
    String? icon,
    bool? isActive,
    int? displayOrder,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      colorHex: colorHex ?? this.colorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        colorHex,
        textColorHex,
        icon,
        isActive,
        displayOrder,
      ];
}
