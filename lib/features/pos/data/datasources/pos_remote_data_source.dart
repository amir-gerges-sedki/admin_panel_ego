import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
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

      final enrichedSale = PosSaleModel(
        id: saleId,
        orderNumber: sale.orderNumber.isNotEmpty
            ? sale.orderNumber
            : 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
        cashierName: sale.cashierName,
        cashierId: sale.cashierId,
        branchId: sale.branchId,
        branchName: sale.branchName,
        shiftId: sale.shiftId,
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
        items: sale.items,
        subTotal: sale.subTotal,
        discount: sale.discount,
        taxFee: sale.taxFee,
        totalAmount: sale.totalAmount,
        paidAmount: sale.paidAmount,
        changeAmount: sale.changeAmount,
        paymentMethod: sale.paymentMethod,
        notes: sale.notes,
        status: 'completed',
        pointsEarned: sale.pointsEarned,
        pointsRedeemed: sale.pointsRedeemed,
        pointsDiscount: sale.pointsDiscount,
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
          'quantity': itm.quantity,
          'selectedVariation': itm.selectedVariation,
          'sku': itm.sku,
          'brand': itm.brand,
          'image': itm.image,
          'totalItemPrice': itm.lineTotal,
        }).toList(),
      };

      // 2. Save Order & Stock Deduction in Batch / Transaction
      await docRef.set(orderData);

      // 2b. Customer Loyalty Points update / creation
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

      // Save a mirror in pos_sales for reporting
      try {
        await _firestore.collection('pos_sales').doc(saleId).set(enrichedSale.toJson());
      } catch (_) {}

      // 3. Deduct stock for all purchased items (including branchStock)
      for (final itm in enrichedSale.items) {
        if (itm.productId.isNotEmpty) {
          await _deductStock(
            productId: itm.productId,
            quantity: itm.quantity,
            selectedVariation: itm.selectedVariation,
            variationId: itm.variationId,
            branchId: enrichedSale.branchId,
          );
        }
      }

      return enrichedSale;
    } catch (e) {
      debugPrint('Error submitting POS sale: $e');
      rethrow;
    }
  }

  Future<void> _deductStock({
    required String productId,
    required int quantity,
    required Map<String, String> selectedVariation,
    String? variationId,
    String branchId = 'main_branch',
  }) async {
    try {
      final prodRef = _firestore.collection('Products').doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(prodRef);
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;

        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
        final rawBranchStock = data['branchStock'] ?? data['BranchStock'] ?? {};
        final Map<String, int> updatedBranchStock = {};
        if (rawBranchStock is Map) {
          rawBranchStock.forEach((k, v) {
            if (v is num) updatedBranchStock[k.toString()] = v.toInt();
          });
        }

        final effectiveBranchId = branchId.isNotEmpty ? branchId : 'main_branch';
        final currentBranchQty = updatedBranchStock[effectiveBranchId] ?? currentStock;
        updatedBranchStock[effectiveBranchId] = (currentBranchQty - quantity).clamp(0, 999999).toInt();

        final rawVars = data['productVariations'] ?? data['variations'];
        final List<Map<String, dynamic>> updatedVars = [];
        bool variationUpdated = false;

        if (rawVars is List && rawVars.isNotEmpty) {
          for (final v in rawVars) {
            if (v is Map) {
              final vMap = Map<String, dynamic>.from(v);
              bool isMatch = false;

              if (variationId != null && variationId.isNotEmpty && vMap['id']?.toString() == variationId) {
                isMatch = true;
              } else if (selectedVariation.isNotEmpty) {
                final vAttrs = vMap['attributeValues'] ?? vMap['attributes'] ?? {};
                if (vAttrs is Map) {
                  bool allMatch = true;
                  selectedVariation.forEach((k, val) {
                    if (vAttrs[k]?.toString().toLowerCase().trim() != val.toLowerCase().trim()) {
                      allMatch = false;
                    }
                  });
                  if (allMatch) isMatch = true;
                }
              }

              if (isMatch && !variationUpdated) {
                final vStock = (vMap['stock'] as num?)?.toInt() ?? 0;
                vMap['stock'] = (vStock - quantity).clamp(0, 999999).toInt();

                final vBranchRaw = vMap['branchStock'] ?? vMap['BranchStock'] ?? {};
                final Map<String, int> vBranchStock = {};
                if (vBranchRaw is Map) {
                  vBranchRaw.forEach((k, val) {
                    if (val is num) vBranchStock[k.toString()] = val.toInt();
                  });
                }
                final currVBranchQty = vBranchStock[effectiveBranchId] ?? vStock;
                vBranchStock[effectiveBranchId] = (currVBranchQty - quantity).clamp(0, 999999).toInt();
                vMap['branchStock'] = vBranchStock;

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
          newTotalStock = (currentStock - quantity).clamp(0, 999999).toInt();
        }

        final updateData = <String, dynamic>{
          'stock': newTotalStock,
          'branchStock': updatedBranchStock,
        };
        if (updatedVars.isNotEmpty && variationUpdated) {
          updateData['productVariations'] = updatedVars;
        }

        transaction.update(prodRef, updateData);
      });
      debugPrint('📦 [POS Stock] Successfully deducted $quantity units for product $productId at branch $branchId');
    } catch (e) {
      debugPrint('⚠️ [POS Stock Error] $e');
    }
  }
}
