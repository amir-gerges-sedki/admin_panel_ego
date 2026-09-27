import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Production Firebase Cloud Messaging HTTP v1 Dispatcher using Google Service Account
class FcmPushService {
  static const String projectId = 'mastervape-163a7';
  static const String _fcmV1Endpoint =
      'https://fcm.googleapis.com/v1/projects/mastervape-163a7/messages:send';

  static final Map<String, dynamic> _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "mastervape-163a7",
    "private_key_id": "eb542356c3349decd4e16e5fe9ddb8e3082fa2b1",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCef8s2DTD9yaPZ\nxU8nWv9McGv2y5WatnpCUN9fXue/qqVtjKkKoPGt9pReTwER626qo/QnM5IgKgLU\nI89s0VtkI/6EMNZ43VLNHEvcsGhrQsJmuNpamTtdKXqLth3XyF93st6xIZcUyzbB\niT+92DKev8e4uI9jUVIJqeTe04iHLawFdM+11tRgq/uLHYPJXNFi6Srx+jJSOOCP\nXpTC8U7W7S/WMzczAHDVYTdv0+wLBu9Rgn1wSbNhDhBtSjBJ9N69ax2dLESPhDi+\noeg2/HL83IuqEEF6/szl6pNQJl2Z54ODimeJ8ru4H0RLgE/LI/n2uBt9nYTO+AgC\nsVuGSPvvAgMBAAECggEAB0ETFGi7JsptSODKdCMqjx2QG24K7VdPtixMZOmLks6l\nHqPy8q0WEp+3/67+/gp3+LBjUs398KHrmjj/W9wjIiyxj+xKTKLYkNGsOTALv2kB\nS8FHISFlQajN1oohyIf/spNJtPK0HvwECAyXkcFM484kPnSX/3Qv3IhdlMM6uvEO\nPFGQNJwwS3e+bc6yDtW4QvLF3n2kHLrZmjXo6ysh0c9DICXIcPCy4sHuS0OTFghK\n69FFD90TekUL7k3ZvFhrT8PxCCfjtNPeVmRcoSa30CxI8MOVpSKmpBNSbz45wy7t\nKBgFVk5Ck0QE3dBd8dLSmtZ4NA0/QX3cNPBsTahwRQKBgQDRJhznz78dB8KccSSz\n1obJDsubb8q86SLTCquEXeERAi91AGe7GDiOVD0XWxCa0Pm3EPcbSPYF4n5OYaVn\nBrTNBFh0tzoVcV3y8YVpKmDCbnSDdzr067xcc7O+nTZuEs7FrSGdwFmRsN8Yceib\nJfnK71l8Pvh9zW7aqpiz4HFSawKBgQDCAR2RmP163X7owz+IxCCTTX+DMivSlA/W\nNT1mwoPCrfGVgNbUFDJ0wFBfpf44S9B0y/xvwVMi8h69nsJFNpsJTOp6dfoMPBmg\ni82tDOt+IAsqCOH7HohmkbXpmoOhDvQvDKHvLz0rbzIpuwSsIweU1bDkwithfyhV\nWLmvXWeFjQKBgAfUCl7u2rNmd/VNEtecXv0ljZ9qxsbdXw1RJ+xTazosv8P8WOWa\n2XsSUhsOsIdq7P3aJ7WgvHyp5ppec0dw69GEqR7tQMJOtPqD6b9u86Izai8FhnJm\nZG19cyveTIxALfceLNTvvyqB2Ufb853jBP+Ah/Prk3d5+f07R23sJ7GzAoGAONJQ\n0cMoguL697uwESO4ksxBC7EXKr8ZAFlpmX5hTxTZTDuHMGiV+qIVKF6a3ew+qubQ\nEf9ilTqrDEjCh7kdoZS4nJOPYCP+MYqg/A1rr+48ttwRLBbeRoRo7nnGEdcqZ9lg\nWIjSdrVD0PsovC4qW0pXXDkOsainrI+nGxjVaEUCgYEAo4vewRnlwat48hDmZdCk\nJ9s/KoSCWrv66rZIzkOqfh9tzMDUf62DsMZTH9kaSlxqcsycvqoyh+ftesNHkA66\nXaX79kNED/AZGYfXHyyUCOJKYHDYvI7a8cYFO23f+ad9d0OHPQJzvF4Xhk90AHng\n3CuVjti160IqfQrqfaFJqZk=\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-cf0qn@mastervape-163a7.iam.gserviceaccount.com",
    "client_id": "110326739676054847032",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-cf0qn%40mastervape-163a7.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// Retrieve valid Google OAuth2 Bearer Access Token
  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(
        _serviceAccountCredentials,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;
      return _cachedAccessToken;
    } catch (e) {
      debugPrint('Google OAuth2 Service Account Token error: $e');
      return null;
    }
  }

  /// Send High-Priority FCM Push Notification to topic (e.g. 'all_users')
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

    try {
      final token = await getAccessToken();
      if (token == null) {
        debugPrint('⚠️ Cannot obtain OAuth2 token for FCM v1');
        return false;
      }

      final Map<String, String> dataMap = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'screen': targetScreen ?? '/shop',
        'targetScreen': targetScreen ?? '/shop',
        'id': broadcastId ?? 'BCAST_${DateTime.now().millisecondsSinceEpoch}',
        'broadcastId':
            broadcastId ?? 'BCAST_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'body': body,
        'message': body,
        'type': type ?? 'alert',
        if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      if (extraData != null) {
        extraData.forEach((k, v) => dataMap[k] = v);
      }

      final payload = {
        'message': {
          'topic': formattedTopic,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
          },
          'data': dataMap,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1, 'content-available': 1},
            },
          },
        },
      };

      debugPrint('📡 Sending FCM v1 Push to topic ($formattedTopic)...');

      final response = await http.post(
        Uri.parse(_fcmV1Endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint(
          '✅ FCM v1 Push successfully delivered to $formattedTopic! Response: ${response.body}',
        );
        return true;
      } else {
        debugPrint(
          '⚠️ FCM v1 Response (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM v1 Push: $e');
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
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final Map<String, String> dataMap = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'screen': targetScreen ?? '/shop',
        'targetScreen': targetScreen ?? '/shop',
        'id': broadcastId ?? 'BCAST_${DateTime.now().millisecondsSinceEpoch}',
        'broadcastId':
            broadcastId ?? 'BCAST_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'body': body,
        'message': body,
        'type': type ?? 'alert',
        if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      if (extraData != null) {
        extraData.forEach((k, v) => dataMap[k] = v);
      }

      final payload = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
          },
          'data': dataMap,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1, 'content-available': 1},
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmV1Endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM single token push sent to ${deviceToken.substring(0, 10)}...');
        return true;
      } else {
        debugPrint('⚠️ FCM single token push failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending token push: $e');
      return false;
    }
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
    int count = 0;
    for (final token in tokens) {
      final ok = await sendSingleTokenPush(
        deviceToken: token,
        title: title,
        body: body,
        type: type,
        imageUrl: imageUrl,
        targetScreen: targetScreen,
        broadcastId: broadcastId,
        extraData: extraData,
      );
      if (ok) count++;
    }
    return count;
  }
}
