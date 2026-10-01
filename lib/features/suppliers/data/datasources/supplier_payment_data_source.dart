import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/purchase_invoice_model.dart';
import '../models/supplier_payment_model.dart';

/// Handles all Supplier Payment Firestore operations:
/// - CRUD for supplier_payments collection
/// - Updating supplier financials (totalPaid, balanceDue)
/// - Updating linked invoice payment status
abstract class SupplierPaymentDataSource {
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  });

  Future<SupplierPaymentModel> recordSupplierPayment(
      SupplierPaymentModel payment);
}

class SupplierPaymentDataSourceImpl implements SupplierPaymentDataSource {
  final FirebaseFirestore _firestore;

  SupplierPaymentDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _firestore.collection('supplier_payments');

  // -------------------------------------------------------------
  // Supplier Payments CRUD
  // -------------------------------------------------------------

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _paymentsCollection
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
        final snapshot = await _paymentsCollection.limit(limit).get();
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
  Future<SupplierPaymentModel> recordSupplierPayment(
      SupplierPaymentModel payment) async {
    try {
      final batch = _firestore.batch();

      final paymentDocRef = payment.id.isNotEmpty
          ? _paymentsCollection.doc(payment.id)
          : _paymentsCollection.doc();

      final paymentJson = payment.toJson();
      paymentJson['id'] = paymentDocRef.id;
      paymentJson['createdAt'] = FieldValue.serverTimestamp();

      batch.set(paymentDocRef, paymentJson);

      // 1. Update Supplier Paid and Balance
      if (payment.supplierId.isNotEmpty) {
        final supplierRef =
            _firestore.collection('suppliers').doc(payment.supplierId);
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
        final invoiceRef = _firestore
            .collection('purchase_invoices')
            .doc(payment.invoiceId);
        final invoiceDoc = await invoiceRef.get();
        if (invoiceDoc.exists && invoiceDoc.data() != null) {
          final invData = invoiceDoc.data()!;
          invData['id'] = invoiceDoc.id;
          final currentInvoice =
              PurchaseInvoiceModel.fromJson(invData, invoiceDoc.id);

          final newPaid = currentInvoice.paidAmount + payment.amount;
          final newRemaining =
              (currentInvoice.totalAmount - newPaid).clamp(0.0, 999999999.0);
          final newStatus = newPaid >= currentInvoice.totalAmount
              ? InvoicePaymentStatus.paid
              : (newPaid > 0
                  ? InvoicePaymentStatus.partial
                  : InvoicePaymentStatus.unpaid);

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
