import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../products/data/models/product_model.dart';
import '../models/purchase_invoice_model.dart';
import '../models/supplier_model.dart';
import '../models/supplier_payment_model.dart';

abstract class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel?> getSupplierById(String id);
  Future<SupplierModel> addSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);

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

  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  });
  Future<SupplierPaymentModel> recordSupplierPayment(SupplierPaymentModel payment);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final FirebaseFirestore _firestore;

  SupplierRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  // -------------------------------------------------------------
  // Suppliers CRUD
  // -------------------------------------------------------------

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final snapshot = await _firestore
          .collection('suppliers')
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SupplierModel.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getSuppliers error: $e');
      try {
        final snapshot = await _firestore.collection('suppliers').get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return SupplierModel.fromJson(data, doc.id);
        }).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      } catch (err) {
        debugPrint('Firestore fallback getSuppliers error: $err');
        return [];
      }
    }
  }

  @override
  Future<SupplierModel?> getSupplierById(String id) async {
    try {
      final doc = await _firestore.collection('suppliers').doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return SupplierModel.fromJson(data, doc.id);
    } catch (e) {
      debugPrint('Firestore getSupplierById error: $e');
      return null;
    }
  }

  @override
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    try {
      final docRef = supplier.id.isNotEmpty
          ? _firestore.collection('suppliers').doc(supplier.id)
          : _firestore.collection('suppliers').doc();

      final json = supplier.toJson();
      json['id'] = docRef.id;
      json['createdAt'] = FieldValue.serverTimestamp();
      json['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(json);
      return supplier.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Firestore addSupplier error: $e');
      rethrow;
    }
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    try {
      final docRef = _firestore.collection('suppliers').doc(supplier.id);
      final json = supplier.toJson();
      json['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(json);
      return supplier;
    } catch (e) {
      debugPrint('Firestore updateSupplier error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      await _firestore.collection('suppliers').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteSupplier error: $e');
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // Purchase Invoices & Stock Inflow
  // -------------------------------------------------------------

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('purchase_invoices')
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
        final snapshot = await _firestore
            .collection('purchase_invoices')
            .limit(limit)
            .get();
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
          ? _firestore.collection('purchase_invoices').doc(invoice.id)
          : _firestore.collection('purchase_invoices').doc();

      final invoiceJson = invoice.toJson();
      invoiceJson['id'] = invoiceDocRef.id;
      invoiceJson['createdAt'] = FieldValue.serverTimestamp();
      invoiceJson['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(invoiceDocRef, invoiceJson);

      // 1. Update Supplier Financial Totals
      if (invoice.supplierId.isNotEmpty) {
        final supplierRef = _firestore.collection('suppliers').doc(invoice.supplierId);
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
        final paymentDocRef = _firestore.collection('supplier_payments').doc();
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
          notes: 'Automatic payment entry for purchase invoice ${invoice.invoiceNumber}',
          createdAt: DateTime.now(),
        );
        final paymentJson = payment.toJson();
        paymentJson['id'] = paymentDocRef.id;
        paymentJson['createdAt'] = FieldValue.serverTimestamp();
        batch.set(paymentDocRef, paymentJson);
      }

      await batch.commit();

      // 3. Auto-Replenish Inventory & Log Stock Movements if stockReceived is true
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
        variationAttributes: variationSku != null && updatedVariations.isNotEmpty
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

  @override
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice) async {
    try {
      final docRef = _firestore.collection('purchase_invoices').doc(invoice.id);
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
      await _firestore.collection('purchase_invoices').doc(invoiceId).delete();
    } catch (e) {
      debugPrint('Firestore deletePurchaseInvoice error: $e');
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // Supplier Payments
  // -------------------------------------------------------------

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('supplier_payments')
          .orderBy('paymentDate', descending: true)
          .limit(limit);

      if (supplierId != null && supplierId.isNotEmpty) {
        query = query.where('supplierId', isEqualTo: supplierId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SupplierPaymentModel.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getSupplierPayments error: $e');
      try {
        final snapshot = await _firestore
            .collection('supplier_payments')
            .limit(limit)
            .get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return SupplierPaymentModel.fromJson(data, doc.id);
        }).toList();
        list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        return list;
      } catch (err) {
        debugPrint('Firestore fallback getSupplierPayments error: $err');
        return [];
      }
    }
  }

  @override
  Future<SupplierPaymentModel> recordSupplierPayment(SupplierPaymentModel payment) async {
    try {
      final batch = _firestore.batch();

      final paymentDocRef = payment.id.isNotEmpty
          ? _firestore.collection('supplier_payments').doc(payment.id)
          : _firestore.collection('supplier_payments').doc();

      final paymentJson = payment.toJson();
      paymentJson['id'] = paymentDocRef.id;
      paymentJson['createdAt'] = FieldValue.serverTimestamp();

      batch.set(paymentDocRef, paymentJson);

      // 1. Update Supplier Paid and Balance
      if (payment.supplierId.isNotEmpty) {
        final supplierRef = _firestore.collection('suppliers').doc(payment.supplierId);
        batch.set(
          supplierRef,
          {
            'totalPaid': FieldValue.increment(payment.amount),
            'balanceDue': FieldValue.increment(-payment.amount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 2. If bound to specific invoice, update invoice paid/remaining/status
      if (payment.invoiceId != null && payment.invoiceId!.isNotEmpty) {
        final invoiceRef = _firestore.collection('purchase_invoices').doc(payment.invoiceId);
        final invoiceDoc = await invoiceRef.get();
        if (invoiceDoc.exists && invoiceDoc.data() != null) {
          final invData = invoiceDoc.data()!;
          invData['id'] = invoiceDoc.id;
          final currentInvoice = PurchaseInvoiceModel.fromJson(invData, invoiceDoc.id);

          final newPaid = currentInvoice.paidAmount + payment.amount;
          final newRemaining = (currentInvoice.totalAmount - newPaid).clamp(0.0, 999999999.0);
          final newStatus = newPaid >= currentInvoice.totalAmount
              ? InvoicePaymentStatus.paid
              : (newPaid > 0 ? InvoicePaymentStatus.partial : InvoicePaymentStatus.unpaid);

          batch.update(invoiceRef, {
            'paidAmount': newPaid,
            'remainingAmount': newRemaining,
            'paymentStatus': newStatus.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      return payment.copyWith(id: paymentDocRef.id);
    } catch (e) {
      debugPrint('Firestore recordSupplierPayment error: $e');
      rethrow;
    }
  }
}
