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

      // Save a mirror in pos_sales for reporting
      try {
        await _firestore.collection('pos_sales').doc(saleId).set(enrichedSale.toJson());
      } catch (_) {}

      // 3. Deduct stock for all purchased items
      for (final itm in enrichedSale.items) {
        if (itm.productId.isNotEmpty) {
          await _deductStock(
            productId: itm.productId,
            quantity: itm.quantity,
            selectedVariation: itm.selectedVariation,
            variationId: itm.variationId,
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
  }) async {
    try {
      final prodRef = _firestore.collection('Products').doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(prodRef);
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;

        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
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
        };
        if (updatedVars.isNotEmpty && variationUpdated) {
          updateData['productVariations'] = updatedVars;
        }

        transaction.update(prodRef, updateData);
      });
      debugPrint('📦 [POS Stock] Successfully deducted $quantity units for product $productId');
    } catch (e) {
      debugPrint('⚠️ [POS Stock Error] $e');
    }
  }
}
