import 'package:equatable/equatable.dart';

class BroadcastModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type; // 'alert', 'promo', 'offer', 'new_arrival'
  final String
  targetAudience; // 'All Users', 'SaltNic Vapers', 'Hardware Deals Seekers'
  final String imageUrl;
  final String targetScreen;
  final String topic; // 'all_users'
  final DateTime sentAt;
  final int successCount;

  const BroadcastModel({
    this.id = '',
    this.title = '',
    this.body = '',
    this.type = 'alert',
    this.targetAudience = '',
    this.imageUrl = '',
    this.targetScreen = '',
    this.topic = '',
    required this.sentAt,
    this.successCount = 1890,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['sentAt'] is DateTime) {
      parsedDate = json['sentAt'];
    } else {
      final str =
          json['sentAt']?.toString() ?? json['createdAt']?.toString() ?? '';
      parsedDate = DateTime.tryParse(str) ?? DateTime.now();
    }

    return BroadcastModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      targetScreen: json['targetScreen']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      sentAt: parsedDate,
      successCount: (json['successCount'] as num?)?.toInt() ?? 1890,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type,
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
    type,
    targetAudience,
    imageUrl,
    targetScreen,
    topic,
    sentAt,
    successCount,
  ];
}
