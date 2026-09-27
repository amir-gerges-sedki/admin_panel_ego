import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/fcm_push_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders();
  Stream<List<OrderModel>> getOrdersStream();
  Future<void> updateOrderStatus(String orderId, String newStatus);
  Future<void> processOrderReturn({
    required String orderId,
    required List<Map<String, dynamic>> itemsToReturn,
    required double refundAmount,
    required String reason,
    required bool restockInventory,
    required bool isFullReturn,
    String? performedBy,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final List<OrderModel> allOrders = [];
      final Set<String> seenIds = {};

      // 1. Fetch from canonical 'Orders' collection (PascalCase)
      try {
        final snap = await _firestore
            .collection('Orders')
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => _firestore
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
          final snap = await _firestore
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
    return _firestore
        .collection('Orders')
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
          final docSnap = await _firestore
              .collection('Orders')
              .doc(idVar)
              .get();
          if (docSnap.exists) {
            matchedDoc = docSnap;
            break;
          }
        } catch (_) {}
      }

      // 2. If not found by direct doc ID, query 'Orders' collection by 'orderId' field
      if (matchedDoc == null) {
        try {
          final querySnap = await _firestore
              .collection('Orders')
              .where('orderId', whereIn: idVariants)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            matchedDoc = querySnap.docs.first;
          }
        } catch (_) {}
      }

      // 3. Fallback: Query 'Orders' collection by 'id' field
      if (matchedDoc == null) {
        try {
          final querySnap = await _firestore
              .collection('Orders')
              .where('id', whereIn: idVariants)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            matchedDoc = querySnap.docs.first;
          }
        } catch (_) {}
      }

      // 4. Update the matched order document in Firestore & adjust stock dynamically
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

        final rawItems = (orderData['items'] is List && (orderData['items'] as List).isNotEmpty)
            ? (orderData['items'] as List)
            : (orderData['orderItems'] is List ? orderData['orderItems'] as List : []);

        final prevStatus = (orderData['status'] ?? orderData['orderStatus'] ?? 'pending').toString().toLowerCase().trim();
        final targetStatus = newStatus.toLowerCase().trim();
        final isCancelledTarget = targetStatus == 'cancelled' || targetStatus == 'canceled' || targetStatus == 'rejected' || targetStatus == 'returned';
        final isCancelledPrev = prevStatus == 'cancelled' || prevStatus == 'canceled' || prevStatus == 'rejected' || prevStatus == 'returned';
        final bool currentlyDeducted = orderData['stockDeducted'] != false; // default true if not set

        bool newStockDeducted = currentlyDeducted;

        // If transitioning TO cancelled -> Restock
        if (isCancelledTarget && currentlyDeducted) {
          if (rawItems.isNotEmpty) {
            await _adjustStockForItems(rawItems, isRestock: true);
          } else {
            final subItems = await _fetchSubcollectionItems(matchedDoc.reference);
            if (subItems.isNotEmpty) {
              await _adjustStockForItems(
                subItems.map((e) => {
                  'productId': e.productId,
                  'quantity': e.quantity,
                  'sku': e.sku,
                  'selectedVariation': e.selectedVariation,
                }).toList(),
                isRestock: true,
              );
            }
          }
          newStockDeducted = false;
        }
        // If transitioning FROM cancelled back to active -> Deduct stock again
        else if (isCancelledPrev && !isCancelledTarget && !currentlyDeducted) {
          if (rawItems.isNotEmpty) {
            await _adjustStockForItems(rawItems, isRestock: false);
          } else {
            final subItems = await _fetchSubcollectionItems(matchedDoc.reference);
            if (subItems.isNotEmpty) {
              await _adjustStockForItems(
                subItems.map((e) => {
                  'productId': e.productId,
                  'quantity': e.quantity,
                  'sku': e.sku,
                  'selectedVariation': e.selectedVariation,
                }).toList(),
                isRestock: false,
              );
            }
          }
          newStockDeducted = true;
        }

        debugPrint(
          '✅ Updating Order doc ${matchedDoc.id} with status: $newStatus (stockDeducted: $newStockDeducted)',
        );
        await matchedDoc.reference.update({
          'status': targetStatus,
          'orderStatus': targetStatus,
          'Status': newStatus,
          'OrderStatus': newStatus,
          'stockDeducted': newStockDeducted,
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

      // 5. Send Push Notification ONLY to the customer (Device Token & User Topic)
      _dispatchCustomerPush(
        targetUserId: targetUserId,
        title: notifTitle,
        body: notifBody,
        orderId: cleanId,
        newStatus: newStatus,
        notifId: notifId,
      );
    } catch (e) {
      debugPrint('Update Order Status Error: $e');
      rethrow;
    }
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
        'targetRoute': '/orders',
        'targetScreen': '/orders/$orderId',
        'screen': '/orders/$orderId',
      };

      // Retrieve customer's device tokens from canonical 'Users' collection
      try {
        final userDoc = await _firestore
            .collection('Users')
            .doc(targetUserId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() ?? {};
          final token = data['fcmToken']?.toString().trim();
          if (token != null && token.isNotEmpty) {
            customerTokens.add(token);
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
          type: 'order_status_update',
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
          type: 'order_status_update',
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

  Future<void> _adjustStockForItems(List<dynamic> rawItems, {required bool isRestock}) async {
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final productId = (item['productId'] ?? item['id'] ?? item['product_id'])?.toString().trim();
      final quantity = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
      final variationId = (item['variationId'] ?? item['variation_id'])?.toString().trim();
      final sku = item['sku']?.toString().trim();
      final selectedVar = (item['selectedVariation'] is Map)
          ? Map<String, dynamic>.from(item['selectedVariation'] as Map)
          : null;

      if (productId == null || productId.isEmpty) continue;

      try {
        await _firestore.runTransaction((transaction) async {
          final prodRef = _firestore.collection('Products').doc(productId);
          final prodSnap = await transaction.get(prodRef);
          if (!prodSnap.exists) return;

          final prodData = prodSnap.data() ?? {};
          final currentStock = (prodData['stock'] as num?)?.toInt() ?? 0;
          final rawVars = prodData['productVariations'];
          final List<Map<String, dynamic>> updatedVars = [];
          bool variationUpdated = false;

          if (rawVars is List && rawVars.isNotEmpty) {
            for (final v in rawVars) {
              if (v is Map) {
                final vMap = Map<String, dynamic>.from(v);
                final vId = vMap['id']?.toString().trim();
                final vSku = vMap['sku']?.toString().trim();
                final vAttrs = vMap['attributeValues'] is Map
                    ? Map<String, dynamic>.from(vMap['attributeValues'] as Map)
                    : {};

                // Match variation by ID, SKU, or attributeValues map
                bool isMatch = false;
                if (variationId != null && variationId.isNotEmpty && (vId == variationId || vSku == variationId)) {
                  isMatch = true;
                } else if (sku != null && sku.isNotEmpty && vSku == sku) {
                  isMatch = true;
                } else if (selectedVar != null && selectedVar.isNotEmpty) {
                  bool allAttrsMatch = true;
                  for (final entry in selectedVar.entries) {
                    final k = entry.key.toString().trim().toLowerCase();
                    final vStr = entry.value.toString().trim().toLowerCase();
                    final attrVal = vAttrs.entries
                        .firstWhere(
                          (e) => e.key.toString().trim().toLowerCase() == k,
                          orElse: () => const MapEntry('', ''),
                        )
                        .value
                        .toString()
                        .trim()
                        .toLowerCase();
                    if (attrVal != vStr) {
                      allAttrsMatch = false;
                      break;
                    }
                  }
                  if (allAttrsMatch) isMatch = true;
                }

                if (isMatch && !variationUpdated) {
                  final vStock = (vMap['stock'] as num?)?.toInt() ?? 0;
                  final newVStock = isRestock ? (vStock + quantity) : (vStock - quantity).clamp(0, 999999).toInt();
                  vMap['stock'] = newVStock;
                  variationUpdated = true;
                }
                updatedVars.add(vMap);
              }
            }
          }

          int newTotalStock;
          if (updatedVars.isNotEmpty && variationUpdated) {
            newTotalStock = updatedVars.fold<int>(
              0,
              (acc, v) => acc + ((v['stock'] as num?)?.toInt() ?? 0),
            );
          } else {
            final calculated = isRestock
                ? (currentStock + quantity)
                : (currentStock - quantity);
            newTotalStock = calculated.clamp(0, 999999).toInt();
          }

          final updateData = <String, dynamic>{
            'stock': newTotalStock,
          };
          if (updatedVars.isNotEmpty && variationUpdated) {
            updateData['productVariations'] = updatedVars;
          }

          transaction.update(prodRef, updateData);
        });
        debugPrint('📦 [Admin Dynamic Stock] ${isRestock ? "Restocked" : "Deducted"} $quantity units for product $productId');
      } catch (e) {
        debugPrint('⚠️ [Admin Dynamic Stock] Error updating stock for product $productId: $e');
      }
    }
  }

  @override
  Future<void> processOrderReturn({
    required String orderId,
    required List<Map<String, dynamic>> itemsToReturn,
    required double refundAmount,
    required String reason,
    required bool restockInventory,
    required bool isFullReturn,
    String? performedBy,
  }) async {
    try {
      final cleanId = orderId.replaceAll('#', '').trim();
      final idVariants = [orderId, cleanId, '#$cleanId'];
      final nowIso = DateTime.now().toIso8601String();

      DocumentSnapshot<Map<String, dynamic>>? matchedDoc;
      String? targetUserId;

      // 1. Locate the order document
      for (final idVar in idVariants) {
        try {
          final docSnap = await _firestore.collection('Orders').doc(idVar).get();
          if (docSnap.exists) {
            matchedDoc = docSnap;
            break;
          }
        } catch (_) {}
      }

      if (matchedDoc == null) {
        try {
          final querySnap = await _firestore
              .collection('Orders')
              .where('orderId', whereIn: idVariants)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            matchedDoc = querySnap.docs.first;
          }
        } catch (_) {}
      }

      if (matchedDoc == null) {
        try {
          final querySnap = await _firestore
              .collection('Orders')
              .where('id', whereIn: idVariants)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            matchedDoc = querySnap.docs.first;
          }
        } catch (_) {}
      }

      if (matchedDoc != null && matchedDoc.exists) {
        final orderData = matchedDoc.data() ?? {};
        targetUserId = orderData['userId']?.toString() ??
            orderData['uid']?.toString() ??
            orderData['customerId']?.toString() ??
            orderData['user_id']?.toString() ??
            orderData['customer_id']?.toString() ??
            orderData['shippingAddress']?['userId']?.toString();

        final returnRecord = {
          'id': 'RET_${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': nowIso,
          'items': itemsToReturn,
          'refundAmount': refundAmount,
          'reason': reason,
          'restockInventory': restockInventory,
          'isFullReturn': isFullReturn,
          'performedBy': performedBy ?? 'Admin/Cashier',
        };

        // 2. Restock inventory if requested & log stock movement audit
        if (restockInventory && itemsToReturn.isNotEmpty) {
          await _adjustStockForItems(itemsToReturn, isRestock: true);

          for (final item in itemsToReturn) {
            try {
              final prodId = (item['productId'] ?? item['id'])?.toString() ?? '';
              final title = item['title']?.toString() ?? 'Item';
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final sku = item['sku']?.toString() ?? '';
              final selectedVar = item['selectedVariation'] is Map
                  ? Map<String, String>.from(item['selectedVariation'] as Map)
                  : <String, String>{};

              await _firestore.collection('StockMovements').add({
                'productId': prodId,
                'productTitle': title,
                'variationSku': sku,
                'variationAttributes': selectedVar,
                'type': 'return',
                'quantity': qty,
                'previousStock': 0,
                'newStock': 0,
                'costPricePerUnit': (item['price'] as num?)?.toDouble() ?? 0.0,
                'totalCost': ((item['price'] as num?)?.toDouble() ?? 0.0) * qty,
                'invoiceNumber': cleanId,
                'notes': 'مرتجع طلبية #$cleanId - $reason',
                'performedBy': performedBy ?? 'Admin',
                'createdAt': nowIso,
              });
            } catch (e) {
              debugPrint('StockMovement return log note: $e');
            }
          }
        }

        // 3. Update order document with return history and optional status change
        final updatePayload = <String, dynamic>{
          'returnHistory': FieldValue.arrayUnion([returnRecord]),
          'refundedAmount': FieldValue.increment(refundAmount),
          'returnReason': reason,
          'updatedAt': nowIso,
        };

        if (isFullReturn) {
          updatePayload['status'] = 'returned';
          updatePayload['orderStatus'] = 'returned';
          updatePayload['Status'] = 'Returned';
          updatePayload['OrderStatus'] = 'Returned';
        }

        await matchedDoc.reference.update(updatePayload);

        // 4. Send notification to customer
        _dispatchCustomerPush(
          targetUserId: targetUserId,
          title: 'إرجاع طلب #$cleanId',
          body: 'تم استرجاع الأصناف بنجاح وإيداع المبلغ المسترد (${refundAmount.toStringAsFixed(2)} ج.م).',
          orderId: cleanId,
          newStatus: isFullReturn ? 'returned' : 'partially_returned',
          notifId: 'NOTIF_RET_$cleanId',
        );
      }
    } catch (e) {
      debugPrint('Process Order Return Error: $e');
      rethrow;
    }
  }
}
