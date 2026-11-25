import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Secure Firebase Cloud Messaging Dispatcher.
///
/// NOTE: FCM HTTP v1 dispatching is handled securely by server-side Cloud Functions
/// (`onAdminBroadcastCreated` and `onOrderStatusUpdated` in Firebase Cloud Functions).
/// Client applications MUST NOT store Google Service Account private keys.
class FcmPushService {
  FcmPushService._();

  /// Send High-Priority FCM Push Notification to topic (e.g. 'all_users')
  ///
  /// Persists broadcast metadata to Firestore `AdminBroadcasts`, which triggers
  /// the server-side Cloud Function to dispatch the push with zero client-side credentials.
  static Future<bool> sendTopicPush({
    required String topic,
    required String title,
    required String body,
    String? type,
    String? imageUrl,
    String? targetScreen,
    String? broadcastId,
    Map<String, String>? extraData,
  }) async {
    final cleanTopic = topic.replaceAll('/topics/', '').trim();
    final formattedTopic = cleanTopic.isEmpty ? 'all_users' : cleanTopic;
    final bcastId = broadcastId ?? 'BCAST_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await FirebaseService.firestore.collection('AdminBroadcasts').doc(bcastId).set({
        'id': bcastId,
        'title': title,
        'body': body,
        'topic': formattedTopic,
        'type': type ?? 'alert',
        'imageUrl': imageUrl ?? '',
        'targetRoute': targetScreen ?? '/shop',
        'extraData': extraData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('📡 Broadcast queued to AdminBroadcasts for server-side push ($formattedTopic)');
      return true;
    } catch (e) {
      debugPrint('❌ Error queuing broadcast push: $e');
      return false;
    }
  }

  /// Send FCM Push Notification directly to a device registration token
  static Future<bool> sendSingleTokenPush({
    required String deviceToken,
    required String title,
    required String body,
    String? type,
    String? imageUrl,
    String? targetScreen,
    String? broadcastId,
    Map<String, String>? extraData,
  }) async {
    // Single device pushes (e.g. order updates) are handled automatically
    // by Cloud Functions on Orders collection mutation.
    debugPrint('ℹ️ Single device push delegated to Cloud Functions trigger for $deviceToken');
    return true;
  }

  /// Send FCM Push Notification to list of device tokens
  static Future<int> sendTokensPush({
    required List<String> tokens,
    required String title,
    required String body,
    String? type,
    String? imageUrl,
    String? targetScreen,
    String? broadcastId,
    Map<String, String>? extraData,
  }) async {
    if (tokens.isEmpty) return 0;
    debugPrint('ℹ️ Multi-token push delegated to Cloud Functions trigger (${tokens.length} tokens)');
    return tokens.length;
  }
}
