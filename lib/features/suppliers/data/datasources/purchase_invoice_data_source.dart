import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../products/data/models/product_model.dart';
import '../models/purchase_invoice_model.dart';
import '../models/supplier_payment_model.dart';

/// Handles all Purchase Invoice Firestore operations:
/// - CRUD for purchase_invoices collection
/// - Auto-restocking inventory on invoice creation
/// - Stock movement logging
abstract class PurchaseInvoiceDataSource {
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  });

  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  });

  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice);
  Future<void> deletePurchaseInvoice(String invoiceId);
}

class PurchaseInvoiceDataSourceImpl implements PurchaseInvoiceDataSource {
  final FirebaseFirestore _firestore;

  PurchaseInvoiceDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _firestore.collection('purchase_invoices');

  // -------------------------------------------------------------
  // Purchase Invoices CRUD
  // -------------------------------------------------------------

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _invoicesCollection
          .orderBy('invoiceDate', descending: true)
          .limit(limit);

      if (supplierId != null && supplierId.isNotEmpty) {
        query = query.where('supplierId', isEqualTo: supplierId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PurchaseInvoiceModel.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getPurchaseInvoices error: $e');
      try {
        final snapshot = await _invoicesCollection.limit(limit).get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return PurchaseInvoiceModel.fromJson(data, doc.id);
        }).toList();
        list.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        return list;
      } catch (err) {
        debugPrint('Firestore fallback getPurchaseInvoices error: $err');
        return [];
      }
    }
  }

  @override
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  }) async {
    try {
      final batch = _firestore.batch();

      final invoiceDocRef = invoice.id.isNotEmpty
          ? _invoicesCollection.doc(invoice.id)
          : _invoicesCollection.doc();

      final invoiceJson = invoice.toJson();
      invoiceJson['id'] = invoiceDocRef.id;
      invoiceJson['createdAt'] = FieldValue.serverTimestamp();
      invoiceJson['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(invoiceDocRef, invoiceJson);

      // 1. Update Supplier Financial Totals
      if (invoice.supplierId.isNotEmpty) {
        final supplierRef =
            _firestore.collection('suppliers').doc(invoice.supplierId);
        batch.set(
          supplierRef,
          {
            'totalPurchases': FieldValue.increment(invoice.totalAmount),
            'totalPaid': FieldValue.increment(invoice.paidAmount),
            'balanceDue': FieldValue.increment(invoice.remainingAmount),
            'invoicesCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 2. If upfront payment was made, record in supplier_payments
      if (invoice.paidAmount > 0) {
        final paymentDocRef =
            _firestore.collection('supplier_payments').doc();
        final payment = SupplierPaymentModel(
          id: paymentDocRef.id,
          supplierId: invoice.supplierId,
          supplierName: invoice.supplierName,
          invoiceId: invoiceDocRef.id,
          invoiceNumber: invoice.invoiceNumber,
          amount: invoice.paidAmount,
          paymentDate: invoice.invoiceDate,
          paymentMethod: invoice.paymentMethod,
          referenceNumber: 'Initial-Payment-${invoice.invoiceNumber}',
          notes:
              'Automatic payment entry for purchase invoice ${invoice.invoiceNumber}',
          createdAt: DateTime.now(),
        );
        final paymentJson = payment.toJson();
        paymentJson['id'] = paymentDocRef.id;
        paymentJson['createdAt'] = FieldValue.serverTimestamp();
        batch.set(paymentDocRef, paymentJson);
      }

      await batch.commit();

      // 3. Auto-Replenish Inventory & Log Stock Movements
      if (autoUpdateStock && invoice.stockReceived && invoice.items.isNotEmpty) {
        for (final item in invoice.items) {
          if (item.productId.isEmpty || item.quantity <= 0) continue;
          await _applyItemRestock(
            productId: item.productId,
            variationSku: item.variationSku,
            quantity: item.quantity,
            unitCost: item.unitCost,
            supplierName: invoice.supplierName,
            invoiceNumber: invoice.invoiceNumber,
            invoiceNotes: invoice.notes,
          );
        }
      }

      return invoice.copyWith(id: invoiceDocRef.id);
    } catch (e) {
      debugPrint('Firestore createPurchaseInvoice error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice) async {
    try {
      final docRef = _invoicesCollection.doc(invoice.id);
      final json = invoice.toJson();
      json['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.update(json);
    } catch (e) {
      debugPrint('Firestore updatePurchaseInvoice error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePurchaseInvoice(String invoiceId) async {
    try {
      await _invoicesCollection.doc(invoiceId).delete();
    } catch (e) {
      debugPrint('Firestore deletePurchaseInvoice error: $e');
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // Private: Stock Restocking from Invoice Items
  // -------------------------------------------------------------

  Future<void> _applyItemRestock({
    required String productId,
    String? variationSku,
    required int quantity,
    required double unitCost,
    required String supplierName,
    required String invoiceNumber,
    String? invoiceNotes,
  }) async {
    try {
      final prodDocRef = _firestore.collection('Products').doc(productId);
      final prodDoc = await prodDocRef.get();
      if (!prodDoc.exists || prodDoc.data() == null) return;

      final data = prodDoc.data()!;
      data['id'] = prodDoc.id;
      final product = ProductModel.fromJson(data);

      int previousStock = product.stock;
      int newStock = product.stock + quantity;
      List<ProductVariationModel> updatedVariations = [];

      if (product.productVariations.isNotEmpty &&
          variationSku != null &&
          variationSku.isNotEmpty) {
        updatedVariations = product.productVariations.map((v) {
          if (v.sku == variationSku) {
            previousStock = v.stock;
            final updatedVStock = v.stock + quantity;
            return v.copyWith(stock: updatedVStock);
          }
          return v;
        }).toList();

        newStock = updatedVariations.fold<int>(0, (acc, v) => acc + v.stock);
      }

      // Update Product in Firestore
      final updateMap = <String, dynamic>{
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (updatedVariations.isNotEmpty) {
        updateMap['productVariations'] =
            updatedVariations.map((v) => v.toJson()).toList();
      }

      await prodDocRef.update(updateMap);

      // Log Stock Movement
      final movRef = _firestore.collection('stock_movements').doc();
      final movement = StockMovementModel(
        id: movRef.id,
        productId: product.id,
        productTitle: product.displayTitle,
        variationSku: variationSku ?? '',
        variationAttributes:
            variationSku != null && updatedVariations.isNotEmpty
                ? (updatedVariations
                        .where((v) => v.sku == variationSku)
                        .firstOrNull
                        ?.attributeValues ??
                    {})
                : {},
        type: StockMovementType.restock,
        quantity: quantity,
        previousStock: previousStock,
        newStock: (variationSku != null && updatedVariations.isNotEmpty)
            ? (previousStock + quantity)
            : newStock,
        costPricePerUnit: unitCost,
        totalCost: quantity * unitCost,
        supplierName: supplierName,
        invoiceNumber: invoiceNumber,
        notes: invoiceNotes?.isNotEmpty == true
            ? invoiceNotes!
            : 'Purchase Invoice Restock #$invoiceNumber',
        performedBy: 'Admin / Purchase Engine',
        createdAt: DateTime.now(),
      );

      final movJson = movement.toJson();
      movJson['id'] = movRef.id;
      movJson['createdAt'] = FieldValue.serverTimestamp();
      await movRef.set(movJson);
    } catch (e) {
      debugPrint('Error applying item restock from invoice: $e');
    }
  }
}
