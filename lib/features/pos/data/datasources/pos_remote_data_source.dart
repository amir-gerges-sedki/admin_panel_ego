import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/inventory_stock_manager.dart';
import '../../../products/data/models/product_model.dart';
import '../models/pos_sale_model.dart';

abstract class PosRemoteDataSource {
  Stream<List<ProductModel>> getProductsStream();
  Future<List<ProductModel>> getProducts();
  Future<PosSaleModel> submitPosSale(PosSaleModel sale);
}

class PosRemoteDataSourceImpl implements PosRemoteDataSource {
  final FirebaseFirestore _firestore;

  PosRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore.collection('Products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('Products').get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading products for POS: $e');
      return [];
    }
  }

  List<String> _buildPhoneVariants(String rawPhone) {
    final clean = rawPhone.trim().replaceAll(RegExp(r'\s+|-'), '');
    if (clean.isEmpty) return [];

    final set = <String>{clean};

    String base = clean;
    if (base.startsWith('+20')) {
      base = base.substring(3);
    } else if (base.startsWith('+2')) {
      base = base.substring(2);
    } else if (base.startsWith('0020')) {
      base = base.substring(4);
    } else if (base.startsWith('20') && base.length >= 12) {
      base = base.substring(2);
    }

    if (base.startsWith('0')) {
      base = base.substring(1);
    }

    if (base.isNotEmpty) {
      set.add(base);
      set.add('0$base');
      set.add('20$base');
      set.add('+20$base');
    }

    return set.toList();
  }

  @override
  Future<PosSaleModel> submitPosSale(PosSaleModel sale) async {
    try {
      final docRef = _firestore.collection('Orders').doc();
      final saleId = docRef.id;

      final enrichedSale = sale.copyWith(
        id: saleId,
        orderNumber: sale.orderNumber.isNotEmpty
            ? sale.orderNumber
            : 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
        status: 'completed',
      );

      // 1. Prepare Order Document
      final orderData = <String, dynamic>{
        'id': saleId,
        'orderNumber': enrichedSale.orderNumber,
        'userId': 'pos_cashier',
        'customerEmail': 'pos_instore@egovapestore.com',
        'status': 'delivered',
        'orderDate': Timestamp.fromDate(enrichedSale.createdAt),
        'deliveryDate': Timestamp.fromDate(enrichedSale.createdAt),
        'paymentMethod': enrichedSale.paymentMethod,
        'paymentStatus': 'paid',
        'subTotal': enrichedSale.subTotal,
        'shippingCost': 0.0,
        'taxFee': enrichedSale.taxFee,
        'discount': enrichedSale.discount,
        'totalAmount': enrichedSale.totalAmount,
        'orderNotes': enrichedSale.notes,
        'source': 'pos',
        'orderType': 'in_store',
        'pointsEarned': enrichedSale.pointsEarned,
        'pointsRedeemed': enrichedSale.pointsRedeemed,
        'pointsDiscount': enrichedSale.pointsDiscount,
        'cashierName': enrichedSale.cashierName,
        'cashierId': enrichedSale.cashierId,
        'salesPersonId': enrichedSale.salesPersonId.isNotEmpty ? enrichedSale.salesPersonId : enrichedSale.cashierId,
        'salesPersonName': enrichedSale.salesPersonName.isNotEmpty ? enrichedSale.salesPersonName : enrichedSale.cashierName,
        'commissionRate': enrichedSale.commissionRate,
        'branchId': enrichedSale.branchId,
        'branchName': enrichedSale.branchName,
        'shiftId': enrichedSale.shiftId,
        'shippingAddress': {
          'name': enrichedSale.customerName,
          'phoneNumber': enrichedSale.customerPhone,
          'street': 'In-Store Purchase (مبيعات المتجر المباشرة)',
          'city': enrichedSale.branchName,
          'governorate': 'Store POS',
          'country': 'Egypt',
        },
        'items': enrichedSale.items.map((itm) => {
          'productId': itm.productId,
          'title': itm.title,
          'price': itm.effectiveUnitPrice,
          'costPrice': itm.costPrice,
          'quantity': itm.quantity,
          'selectedVariation': itm.selectedVariation,
          'sku': itm.sku,
          'brand': itm.brand,
          'image': itm.image,
          'totalItemPrice': itm.lineTotal,
          if (itm.serialNumbers.isNotEmpty) 'serialNumbers': itm.serialNumbers,
        }).toList(),
      };

      // 2. Prepare Stock Adjustment Items
      final stockItems = enrichedSale.items
          .where((i) => i.productId.isNotEmpty)
          .map((i) => StockAdjustmentItem(
                productId: i.productId,
                quantity: i.quantity,
                variationId: i.variationId,
                sku: i.sku,
                selectedAttributes: i.selectedVariation,
                title: i.title,
              ))
          .toList();

      // 3. Execute Atomic POS Transaction (Stock Deduction + Order Creation + POS Mirror)
      await _firestore.runTransaction((transaction) async {
        // A. Atomic Stock Deduction with strict stock validation
        await InventoryStockManager.adjustStockBatchInTransaction(
          transaction: transaction,
          items: stockItems,
          isRestock: false,
          branchId: enrichedSale.branchId,
          strictStockCheck: true,
          firestore: _firestore,
        );

        // B. Write Order Document atomically
        transaction.set(docRef, orderData);

        // C. Write POS Sales mirror atomically
        final posSaleRef = _firestore.collection('pos_sales').doc(saleId);
        transaction.set(posSaleRef, enrichedSale.toJson());
      });

      // 4. Customer Loyalty Points update / creation (Async post-checkout)
      final cleanPhone = enrichedSale.customerPhone.trim().replaceAll(RegExp(r'\s+|-'), '');
      if (cleanPhone.isNotEmpty) {
        try {
          final pointsDelta = enrichedSale.pointsEarned - enrichedSale.pointsRedeemed;
          final variants = _buildPhoneVariants(enrichedSale.customerPhone);

          QuerySnapshot<Map<String, dynamic>>? userSnap;
          final queryList = variants.take(10).toList();

          if (queryList.isNotEmpty) {
            userSnap = await _firestore.collection('Users').where('phoneNumber', whereIn: queryList).limit(1).get();
            if (userSnap.docs.isEmpty) {
              userSnap = await _firestore.collection('Users').where('phone', whereIn: queryList).limit(1).get();
            }
            if (userSnap.docs.isEmpty) {
              userSnap = await _firestore.collection('Users').where('PhoneNumber', whereIn: queryList).limit(1).get();
            }
          }

          String customerDocId = '';

          if (userSnap != null && userSnap.docs.isNotEmpty) {
            final userDoc = userSnap.docs.first;
            customerDocId = userDoc.id;

            await _firestore.collection('Users').doc(userDoc.id).set({
              'loyaltyPoints': FieldValue.increment(pointsDelta),
              'totalOrders': FieldValue.increment(1),
              'totalSpent': FieldValue.increment(enrichedSale.totalAmount),
            }, SetOptions(merge: true));

            await _firestore.collection('Users').doc(userDoc.id).collection('loyalty_history').add({
              'orderId': saleId,
              'orderNumber': enrichedSale.orderNumber,
              'pointsEarned': enrichedSale.pointsEarned,
              'pointsRedeemed': enrichedSale.pointsRedeemed,
              'pointsDelta': pointsDelta,
              'orderTotal': enrichedSale.totalAmount,
              'createdAt': Timestamp.now(),
            });
          } else {
            final newCustRef = _firestore.collection('Users').doc();
            customerDocId = newCustRef.id;

            await newCustRef.set({
              'id': newCustRef.id,
              'name': enrichedSale.customerName.trim().isNotEmpty &&
                      enrichedSale.customerName != 'Walk-in Customer (عميل مباشر)'
                  ? enrichedSale.customerName.trim()
                  : 'Customer ${cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : cleanPhone}',
              'userName': enrichedSale.customerName,
              'phoneNumber': cleanPhone,
              'phone': cleanPhone,
              'email': '$cleanPhone@walkin.customer',
              'role': 'user',
              'city': enrichedSale.branchName,
              'loyaltyPoints': enrichedSale.pointsEarned,
              'totalOrders': 1,
              'totalSpent': enrichedSale.totalAmount,
              'createdAt': Timestamp.now(),
            });
          }

          if (customerDocId.isNotEmpty) {
            await docRef.set({
              'userId': customerDocId,
              'customerId': customerDocId,
              'customerPhone': cleanPhone,
            }, SetOptions(merge: true));
          }
        } catch (loyaltyError) {
          debugPrint('Error updating customer loyalty points: $loyaltyError');
        }
      }

      return enrichedSale;
    } catch (e) {
      debugPrint('Error submitting POS sale: $e');
      rethrow;
    }
  }
}
