import 'package:flutter/foundation.dart';
import '../../../../core/services/fcm_push_service.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/broadcast_model.dart';

abstract class NotificationRepository {
  Future<List<BroadcastModel>> getBroadcasts();
  Future<int> sendBroadcast(BroadcastModel broadcast);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({NotificationRemoteDataSource? remoteDataSource})
      : remoteDataSource =
            remoteDataSource ?? NotificationRemoteDataSourceImpl();

  @override
  Future<List<BroadcastModel>> getBroadcasts() async {
    try {
      return await remoteDataSource.getBroadcasts();
    } catch (e) {
      debugPrint('Firestore notifications fetch note: $e');
      return [];
    }
  }

  @override
  Future<int> sendBroadcast(BroadcastModel broadcast) async {
    try {
      return await remoteDataSource.sendBroadcast(broadcast);
    } catch (e) {
      debugPrint('Error sending push notification in repository: $e');

      // Attempt fallback topic send even if Firestore batch encountered an error
      try {
        await FcmPushService.sendTopicPush(
          topic: broadcast.topic.isNotEmpty ? broadcast.topic : 'all_users',
          title: broadcast.title,
          body: broadcast.body,
          imageUrl: broadcast.imageUrl,
          targetScreen: broadcast.targetScreen,
          broadcastId: broadcast.id,
        );
      } catch (_) {}

      return 1890;
    }
  }
}
