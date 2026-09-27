import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String targetScreen;
  final String? productId;
  final String? productTitle;
  final String? targetType;
  final bool active;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetScreen,
    this.productId,
    this.productTitle,
    this.targetType,
    this.active = true,
  });

  bool get isProductTarget =>
      targetType == 'product' ||
      (productId != null && productId!.isNotEmpty) ||
      targetScreen.contains('product');

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productTitle: json['productTitle']?.toString(),
      targetScreen: json['targetScreen']?.toString() ?? '',
      targetType: json['targetType']?.toString(),
      active: json['active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'productId': productId,
    'productTitle': productTitle,
    'targetScreen': targetScreen,
    'targetType': targetType ?? (isProductTarget ? 'product' : 'custom'),
    'active': active,
  };

  BannerModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? targetScreen,
    String? productId,
    String? productTitle,
    String? targetType,
    bool? active,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      targetScreen: targetScreen ?? this.targetScreen,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      targetType: targetType ?? this.targetType,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [id, title];
}
