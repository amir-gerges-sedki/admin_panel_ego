import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../products/data/models/product_model.dart';
import '../models/inventory_audit_model.dart';

abstract class InventoryAuditRemoteDataSource {
  Future<List<InventoryAuditModel>> getAudits({String? branchId});
  Future<String> saveAuditDraft(InventoryAuditModel audit);
  Future<void> reconcileAndCompleteAudit(InventoryAuditModel audit, {required String performedBy});
  Future<void> deleteAudit(String auditId);
}

class InventoryAuditRemoteDataSourceImpl implements InventoryAuditRemoteDataSource {
  final FirebaseFirestore _firestore;

  InventoryAuditRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inventory_audits');

  @override
  Future<List<InventoryAuditModel>> getAudits({String? branchId}) async {
    try {
      Query<Map<String, dynamic>> query = _collection.orderBy('createdAt', descending: true);
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        query = query.where('branchId', isEqualTo: branchId);
      }
      final snapshot = await query.limit(50).get();
      return snapshot.docs.map((doc) => InventoryAuditModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error loading inventory audits: $e');
      return [];
    }
  }

  @override
  Future<String> saveAuditDraft(InventoryAuditModel audit) async {
    try {
      final docRef = audit.id.isNotEmpty ? _collection.doc(audit.id) : _collection.doc();
      final data = audit.copyWith(id: docRef.id).toJson();
      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving audit draft: $e');
      rethrow;
    }
  }

  @override
  Future<void> reconcileAndCompleteAudit(
    InventoryAuditModel audit, {
    required String performedBy,
  }) async {
    try {
      final auditDocRef = audit.id.isNotEmpty ? _collection.doc(audit.id) : _collection.doc();
      final branchId = audit.branchId.isNotEmpty ? audit.branchId : 'main_branch';
      final now = DateTime.now();

      // 1. Reconcile Stock in Products collection
      for (final item in audit.items) {
        if (item.productId.isEmpty) continue;
        if (item.variance == 0) continue; // No stock difference -> no adjustment needed

        try {
          final prodRef = _firestore.collection('Products').doc(item.productId);
          await _firestore.runTransaction((transaction) async {
            final snap = await transaction.get(prodRef);
            if (!snap.exists) return;

            final data = snap.data() ?? {};
            final product = ProductModel.fromJson(data);

            // Update product branchStock
            final Map<String, int> updatedBranchStock = Map<String, int>.from(product.branchStock);
            updatedBranchStock[branchId] = item.physicalQuantity;

            int newTotalStock = product.stock;
            List<ProductVariationModel> updatedVariations = [];

            if (product.productVariations.isNotEmpty && item.variationSku.isNotEmpty) {
              updatedVariations = product.productVariations.map((v) {
                if (v.sku.toLowerCase() == item.variationSku.toLowerCase()) {
                  final Map<String, int> vBranchStock = Map<String, int>.from(v.branchStock);
                  vBranchStock[branchId] = item.physicalQuantity;
                  final totalVStock = vBranchStock.values.fold<int>(0, (prev, val) => prev + val);

                  return v.copyWith(
                    stock: totalVStock,
                    branchStock: vBranchStock,
                  );
                }
                return v;
              }).toList();

              newTotalStock = updatedVariations.fold<int>(0, (prev, v) => prev + v.stock);
            } else {
              if (updatedBranchStock.isNotEmpty) {
                newTotalStock = updatedBranchStock.values.fold<int>(0, (prev, val) => prev + val);
              } else {
                newTotalStock = item.physicalQuantity;
              }
            }

            final updateData = <String, dynamic>{
              'stock': newTotalStock,
              'branchStock': updatedBranchStock,
              'updatedAt': FieldValue.serverTimestamp(),
            };
            if (updatedVariations.isNotEmpty) {
              updateData['productVariations'] = updatedVariations.map((v) => v.toJson()).toList();
            }

            transaction.update(prodRef, updateData);

            // Log Stock Movement
            final movRef = _firestore.collection('stock_movements').doc();
            transaction.set(movRef, {
              'id': movRef.id,
              'productId': product.id,
              'productTitle': product.displayTitle,
              'variationSku': item.variationSku,
              'variationAttributes': item.variationAttributes,
              'type': 'adjustment',
              'quantity': item.variance,
              'previousStock': item.systemQuantity,
              'newStock': item.physicalQuantity,
              'costPricePerUnit': item.unitCost,
              'totalCost': item.varianceCost,
              'invoiceNumber': audit.auditNumber,
              'notes': 'تسوية جرد فعلي #${audit.auditNumber} (فرع: ${audit.branchName}) - الفارق: ${item.variance > 0 ? "+" : ""}${item.variance}',
              'performedBy': performedBy,
              'createdAt': FieldValue.serverTimestamp(),
            });
          });
        } catch (itemErr) {
          debugPrint('⚠️ Error reconciling audit item ${item.productTitle}: $itemErr');
        }
      }

      // 2. Save completed audit document
      final completedAudit = audit.copyWith(
        id: auditDocRef.id,
        status: 'completed',
        completedAt: now,
      );

      await auditDocRef.set(completedAudit.toJson(), SetOptions(merge: true));
      debugPrint('✅ Audit #${audit.auditNumber} reconciled and completed successfully.');
    } catch (e) {
      debugPrint('Error reconciling audit: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAudit(String auditId) async {
    try {
      await _collection.doc(auditId).delete();
    } catch (e) {
      debugPrint('Error deleting audit: $e');
      rethrow;
    }
  }
}
