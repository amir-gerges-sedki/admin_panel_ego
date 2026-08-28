import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/fcm_push_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders();
  Stream<List<OrderModel>> getOrdersStream();
  Future<void> updateOrderStatus(String orderId, String newStatus);
}

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final List<OrderModel> allOrders = [];
      final Set<String> seenIds = {};

      // 1. Fetch from canonical 'Orders' collection (PascalCase)
      try {
        final snap = await FirebaseService.firestore
            .collection('Orders')
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => FirebaseService.firestore
                  .collection('Orders')
                  .get(const GetOptions(source: Source.cache)),
            );

        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['_docId'] = doc.id;
          var model = OrderModel.fromJson(data);

          // If items array is empty in main doc, inspect subcollections
          if (model.items.isEmpty) {
            final subItems = await _fetchSubcollectionItems(doc.reference);
            if (subItems.isNotEmpty) {
              model = model.copyWith(items: subItems);
            }
          }

          if (seenIds.add(model.id)) {
            allOrders.add(model);
          }
        }
      } catch (e) {
        debugPrint('Firestore Orders fetch note: $e');
      }

      // 2. Fallback check on 'orders' if root Orders was empty
      if (allOrders.isEmpty) {
        try {
          final snap = await FirebaseService.firestore
              .collection('orders')
              .get()
              .timeout(const Duration(seconds: 3));

          for (final doc in snap.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            data['_docId'] = doc.id;
            var model = OrderModel.fromJson(data);

            if (model.items.isEmpty) {
              final subItems = await _fetchSubcollectionItems(doc.reference);
              if (subItems.isNotEmpty) {
                model = model.copyWith(items: subItems);
              }
            }

            if (seenIds.add(model.id)) {
              allOrders.add(model);
            }
          }
        } catch (_) {}
      }

      // 3. Sort by date descending
      allOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return allOrders;
    } catch (e) {
      debugPrint('Firestore Orders fetch error: $e');
      return [];
    }
  }

  @override
  Stream<List<OrderModel>> getOrdersStream() {
    return FirebaseService.ordersCollection
        .snapshots()
        .map((snapshot) {
          final List<OrderModel> orders = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            data['_docId'] = doc.id;
            orders.add(OrderModel.fromJson(data));
          }
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        })
        .handleError((error) {
          debugPrint('Orders Stream error: $error');
          return <OrderModel>[];
        });
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final cleanId = orderId.replaceAll('#', '').trim();
      final idVariants = [orderId, cleanId, '#$cleanId'];
      final notifTitle = 'تحديث حالة الطلب #$cleanId';
      final notifBody = _getStatusNotificationBody(newStatus, cleanId);
      final notifId = 'NOTIF_ORDER_$cleanId';
      final nowIso = DateTime.now().toIso8601String();

      DocumentSnapshot<Map<String, dynamic>>? matchedDoc;
      String? targetUserId;

      // 1. Try finding the document in 'Orders' collection by direct ID variants
      for (final idVar in idVariants) {
        try {
          final docSnap = await FirebaseService.firestore
              .collection('Orders')
              .doc(idVar)
              .get();
          if (docSnap.exists) {
            matchedDoc = docSnap;
            break;
          }
        } catch (_) {}
      }

      // 2. If not found by direct doc ID, scan 'Orders' collection by fields (id, orderId, orderNumber, etc.)
      if (matchedDoc == null) {
        try {
          final allOrdersSnap = await FirebaseService.firestore
              .collection('Orders')
              .get();
          for (final doc in allOrdersSnap.docs) {
            if (_docMatchesId(doc, idVariants)) {
              matchedDoc = doc;
              break;
            }
          }
        } catch (_) {}
      }

      // 3. Fallback: Search in collectionGroup('Orders')
      if (matchedDoc == null) {
        try {
          final cgSnap = await FirebaseService.firestore
              .collectionGroup('Orders')
              .get();
          for (final doc in cgSnap.docs) {
            if (_docMatchesId(doc, idVariants)) {
              matchedDoc = doc;
              break;
            }
          }
        } catch (_) {}
      }

      // 4. Update the matched order document in Firestore
      if (matchedDoc != null && matchedDoc.exists) {
        final orderData = matchedDoc.data() ?? {};
        targetUserId =
            orderData['userId']?.toString() ??
            orderData['uid']?.toString() ??
            orderData['customerId']?.toString() ??
            orderData['user_id']?.toString() ??
            orderData['customer_id']?.toString() ??
            orderData['customer']?['id']?.toString() ??
            orderData['customer']?['uid']?.toString() ??
            orderData['user']?['id']?.toString() ??
            orderData['user']?['uid']?.toString() ??
            orderData['shippingAddress']?['userId']?.toString();

        if (targetUserId == null || targetUserId.isEmpty) {
          final segments = matchedDoc.reference.path.split('/');
          if (segments.length >= 2 && segments[0].toLowerCase() == 'users') {
            targetUserId = segments[1];
          }
        }

        debugPrint(
          '✅ Updating Order doc ${matchedDoc.id} with status: $newStatus',
        );
        await matchedDoc.reference.update({
          'status': newStatus.toLowerCase(),
          'orderStatus': newStatus.toLowerCase(),
          'Status': newStatus,
          'OrderStatus': newStatus,
          'isRead': false,
          'read': false,
          'is_read': false,
          'updatedAt': nowIso,
          'updated_at': nowIso,
        });
      } else {
        debugPrint(
          '⚠️ Warning: Order $orderId was not found in Firestore to update',
        );
      }

      // 5. Save in-app notification in canonical Users/{userId}/Notifications
      if (targetUserId != null && targetUserId.isNotEmpty) {
        try {
          final notifPayload = {
            'id': notifId,
            'orderId': cleanId,
            'order_id': cleanId,
            'title': notifTitle,
            'body': notifBody,
            'message': notifBody,
            'targetScreen': '/orders/$cleanId',
            'screen': '/orders/$cleanId',
            'status': newStatus.toLowerCase(),
            'orderStatus': newStatus.toLowerCase(),
            'isRead': false,
            'read': false,
            'sentAt': nowIso,
            'createdAt': nowIso,
            'timestamp': nowIso,
            'updatedAt': nowIso,
            'type': 'order_status_update',
            'category': 'order',
            'userId': targetUserId,
          };

          await FirebaseService.firestore
              .collection('Users')
              .doc(targetUserId)
              .collection('Notifications')
              .doc(notifId)
              .set(notifPayload, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error writing Users/{userId}/Notifications: $e');
        }
      }

      // 6. Send Push Notification ONLY to the customer (Device Token & User Topic)
      _dispatchCustomerPush(
        targetUserId: targetUserId,
        title: notifTitle,
        body: notifBody,
        orderId: cleanId,
        newStatus: newStatus,
        notifId: notifId,
      );
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  bool _docMatchesId(
    DocumentSnapshot<Map<String, dynamic>> doc,
    List<String> idVariants,
  ) {
    for (final v in idVariants) {
      final lowerV = v.toLowerCase().trim();
      if (doc.id.toLowerCase().trim() == lowerV) return true;
    }
    final data = doc.data() ?? {};
    final candidateFields = [
      data['id'],
      data['orderId'],
      data['OrderId'],
      data['order_id'],
      data['orderNumber'],
      data['OrderNumber'],
      data['order_number'],
      data['number'],
      data['_docId'],
    ];
    for (final fieldVal in candidateFields) {
      if (fieldVal != null) {
        final str = fieldVal.toString().toLowerCase().trim();
        for (final v in idVariants) {
          if (str == v.toLowerCase().trim()) return true;
        }
      }
    }
    return false;
  }

  void _dispatchCustomerPush({
    String? targetUserId,
    required String title,
    required String body,
    required String orderId,
    required String newStatus,
    required String notifId,
  }) async {
    try {
      if (targetUserId == null || targetUserId.isEmpty) {
        debugPrint('⚠️ Target customer userId is missing for order #$orderId');
        return;
      }

      final List<String> customerTokens = [];
      final extraData = {
        'orderId': orderId,
        'order_id': orderId,
        'status': newStatus.toLowerCase(),
        'type': 'order_status_update',
        'targetScreen': '/orders/$orderId',
        'screen': '/orders/$orderId',
      };

      // Retrieve customer's device tokens from canonical 'Users' collection
      try {
        final userDoc = await FirebaseService.firestore
            .collection('Users')
            .doc(targetUserId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() ?? {};

          void addToken(dynamic t) {
            if (t != null && t.toString().trim().isNotEmpty) {
              final tokenStr = t.toString().trim();
              if (!customerTokens.contains(tokenStr)) {
                customerTokens.add(tokenStr);
              }
            }
          }

          addToken(data['fcmToken']);
          addToken(data['pushToken']);
          addToken(data['deviceToken']);
          addToken(data['token']);
          addToken(data['fcm_token']);
          addToken(data['notificationToken']);

          final tokensList =
              data['fcmTokens'] ?? data['tokens'] ?? data['deviceTokens'];
          if (tokensList is List) {
            for (final t in tokensList) {
              addToken(t);
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching customer FCM token from Users: $e');
      }

      // Send EXACTLY ONE targeted push notification to avoid duplicate spam
      if (customerTokens.isNotEmpty) {
        final uniqueTokens = customerTokens.toSet().toList();
        debugPrint(
          '📱 Sending single push to customer device for user $targetUserId...',
        );
        await FcmPushService.sendSingleTokenPush(
          deviceToken: uniqueTokens.first,
          title: title,
          body: body,
          targetScreen: '/orders/$orderId',
          broadcastId: notifId,
          extraData: extraData,
        );
      } else {
        // Fallback to customer's personal topic if token is missing
        debugPrint('📡 Sending push to customer topic user_$targetUserId...');
        await FcmPushService.sendTopicPush(
          topic: 'user_$targetUserId',
          title: title,
          body: body,
          targetScreen: '/orders/$orderId',
          broadcastId: notifId,
          extraData: extraData,
        );
      }
    } catch (e) {
      debugPrint('FCM customer push dispatch error: $e');
    }
  }

  String _getStatusNotificationBody(String status, String orderId) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'طلبك قيد التجهيز والتعبئة الآن من متجر EGO Store.';
      case 'shipped':
        return 'تم شحن طلبك بنجاح وهو في طريقه إليك مع مندوب الشحن!';
      case 'delivered':
        return 'تم تسليم طلبك بنجاح. نتمنى لك تجربة ممتعة مع EGO Store!';
      case 'cancelled':
        return 'تم إلغاء الطلب. يرجى التواصل مع خدمة العملاء لأي استفسار.';
      case 'pending':
        return 'طلبك قيد المراجعة والانتظار في متجر EGO Store.';
      default:
        return 'تم تحديث حالة طلبك #$orderId إلى: $status.';
    }
  }

  Future<List<OrderItemModel>> _fetchSubcollectionItems(
    DocumentReference docRef,
  ) async {
    try {
      final possibleSubcollections = [
        'Items',
        'items',
        'OrderItems',
        'orderItems',
        'order_items',
        'products',
        'Products',
        'CartItems',
        'cartItems',
        'details',
      ];

      for (final col in possibleSubcollections) {
        final snap = await docRef
            .collection(col)
            .get()
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () => docRef
                  .collection(col)
                  .get(const GetOptions(source: Source.cache)),
            );

        if (snap.docs.isNotEmpty) {
          final List<OrderItemModel> items = [];
          for (final d in snap.docs) {
            final data = d.data();
            data['id'] ??= d.id;
            items.add(OrderItemModel.fromJson(data));
          }
          if (items.isNotEmpty) return items;
        }
      }
    } catch (_) {}
    return [];
  }
}
