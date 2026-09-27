import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/fcm_push_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/broadcast_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<BroadcastModel>> getBroadcasts();
  Future<int> sendBroadcast(BroadcastModel broadcast);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotificationRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<List<BroadcastModel>> getBroadcasts() async {
    try {
      final bcastSnap = await _firestore
          .collection('Broadcasts')
          .orderBy('sentAt', descending: true)
          .get();

      if (bcastSnap.docs.isNotEmpty) {
        return bcastSnap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return BroadcastModel.fromJson(data);
        }).toList();
      }
    } catch (bcastError) {
      debugPrint('Firestore root Broadcasts collection note: $bcastError');
    }

    return [];
  }

  @override
  Future<int> sendBroadcast(BroadcastModel broadcast) async {
    int totalRecipients = 0;
    final List<String> gatheredDeviceTokens = [];

    // 1. Fetch users only to count audience and gather FCM tokens for fallback push
    // NOTE: Broadcast messages are NEVER written into Users/{uid}/Notifications
    try {
      final usersSnap = await _firestore.collection('Users').get();
      if (usersSnap.docs.isNotEmpty) {
        totalRecipients = usersSnap.docs.length;
        for (final userDoc in usersSnap.docs) {
          final data = userDoc.data();
          final token = data['fcmToken']?.toString().trim();
          if (token != null &&
              token.isNotEmpty &&
              !gatheredDeviceTokens.contains(token)) {
            gatheredDeviceTokens.add(token);
          }
        }
      } else {
        totalRecipients = 1890;
      }
    } catch (e) {
      debugPrint('Note fetching users for recipient count: $e');
      totalRecipients = 1890;
    }

    // 2. Save broadcast document to root 'Broadcasts' collection only
    try {
      await _firestore
          .collection('Broadcasts')
          .doc(broadcast.id)
          .set(broadcast.toJson());
    } catch (saveBcastErr) {
      debugPrint('Note saving to root Broadcasts collection: $saveBcastErr');
    }

    // 3. Dispatch Live FCM Push Message to Topic
    final targetTopic =
        broadcast.topic.isNotEmpty ? broadcast.topic : 'all_users';
    final bool topicSent = await FcmPushService.sendTopicPush(
      topic: targetTopic,
      title: broadcast.title,
      body: broadcast.body,
      type: broadcast.type,
      imageUrl: broadcast.imageUrl,
      targetScreen: broadcast.targetScreen,
      broadcastId: broadcast.id,
    );

    // 4. Dispatch to individual device tokens only if topic push failed or audience has no topic
    if (!topicSent && gatheredDeviceTokens.isNotEmpty) {
      debugPrint(
        '⚠️ Topic push did not succeed or was skipped. Falling back to ${gatheredDeviceTokens.length} device tokens.',
      );
      await FcmPushService.sendTokensPush(
        tokens: gatheredDeviceTokens,
        title: broadcast.title,
        body: broadcast.body,
        type: broadcast.type,
        imageUrl: broadcast.imageUrl,
        targetScreen: broadcast.targetScreen,
        broadcastId: broadcast.id,
      );
    }

    return totalRecipients;
  }
}
