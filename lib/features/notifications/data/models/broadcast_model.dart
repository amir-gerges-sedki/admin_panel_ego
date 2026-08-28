import 'package:equatable/equatable.dart';

class BroadcastModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String targetAudience; // 'All Users', 'SaltNic Vapers', 'Hardware Deals Seekers'
  final String imageUrl;
  final String targetScreen;
  final String topic; // 'all_users'
  final DateTime sentAt;
  final int successCount;

  const BroadcastModel({
    this.id = '',
    this.title = '',
    this.body = '',
    this.targetAudience = 'All Users',
    this.imageUrl = '',
    this.targetScreen = '/shop',
    this.topic = 'all_users',
    required this.sentAt,
    this.successCount = 1890,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['sentAt'] is DateTime) {
      parsedDate = json['sentAt'];
    } else {
      final str = json['sentAt']?.toString() ?? json['createdAt']?.toString() ?? '';
      parsedDate = DateTime.tryParse(str) ?? DateTime.now();
    }

    return BroadcastModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['notification']?['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['notification']?['body']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? 'All Users',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? json['notification']?['image']?.toString() ?? '',
      targetScreen: json['targetScreen']?.toString() ?? json['route']?.toString() ?? json['data']?['screen']?.toString() ?? '/shop',
      topic: json['topic']?.toString() ?? 'all_users',
      sentAt: parsedDate,
      successCount: (json['successCount'] as num?)?.toInt() ?? 1890,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'targetAudience': targetAudience,
        'imageUrl': imageUrl,
        'targetScreen': targetScreen,
        'topic': topic,
        'sentAt': sentAt.toIso8601String(),
        'successCount': successCount,
        'isBroadcast': true,
        'createdAt': sentAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        targetAudience,
        imageUrl,
        targetScreen,
        topic,
        sentAt,
        successCount,
      ];
}
