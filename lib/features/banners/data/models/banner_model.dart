import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String targetScreen;
  final bool active;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetScreen,
    this.active = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['Title']?.toString() ?? json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ??
          json['ImageUrl']?.toString() ??
          json['image']?.toString() ??
          json['Image']?.toString() ??
          '',
      targetScreen: json['targetScreen']?.toString() ?? json['TargetScreen']?.toString() ?? '/shop',
      active: json['active'] == true || json['Active'] == true || json['isActive'] == true || json['active'] == null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'targetScreen': targetScreen,
        'active': active,
      };

  @override
  List<Object?> get props => [id, title, imageUrl, targetScreen, active];
}
