import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/stock_transfer_model.dart';

abstract class StockTransferRemoteDataSource {
  Future<String> createTransfer(StockTransferModel transfer);
  Future<List<StockTransferModel>> getTransfers({String? branchId, StockTransferStatus? status});
  Stream<List<StockTransferModel>> watchTransfers({String? branchId});
  Future<void> updateTransferStatus(
    String transferId,
    StockTransferStatus status, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
  });
  Future<void> deleteTransfer(String transferId);
}

class StockTransferRemoteDataSourceImpl implements StockTransferRemoteDataSource {
  final FirebaseFirestore _firestore;

  StockTransferRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('stock_transfers');

  @override
  Future<String> createTransfer(StockTransferModel transfer) async {
    try {
      final docRef = transfer.id.isNotEmpty
          ? _collection.doc(transfer.id)
          : _collection.doc();

      final modelToSave = transfer.id.isNotEmpty
          ? transfer
          : transfer.copyWith(id: docRef.id);

      await docRef.set(modelToSave.toJson(), SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint('! [StockTransfer] Error creating transfer: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockTransferModel>> getTransfers({
    String? branchId,
    StockTransferStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;

      // Filter by branch if specified
      if (branchId != null && branchId.trim().isNotEmpty && branchId != 'all') {
        // Query transfers where this branch is either sender or receiver
        // In Firestore, we query all or filter in-memory to prevent requiring composite indexes
      }

      final snapshot = await query.get();
      List<StockTransferModel> results = snapshot.docs.map((doc) {
        return StockTransferModel.fromJson(doc.data(), doc.id);
      }).toList();

      // In-memory filter for branch (either fromBranch or toBranch)
      if (branchId != null && branchId.trim().isNotEmpty && branchId != 'all') {
        results = results.where((t) {
          return t.fromBranchId == branchId || t.toBranchId == branchId;
        }).toList();
      }

      // In-memory filter for status
      if (status != null) {
        results = results.where((t) => t.status == status).toList();
      }

      // In-memory sort by createdAt descending
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return results;
    } catch (e) {
      debugPrint('! [StockTransfer] Error fetching transfers: $e');
      return [];
    }
  }

  @override
  Stream<List<StockTransferModel>> watchTransfers({String? branchId}) {
    return _collection.snapshots().map((snapshot) {
      List<StockTransferModel> results = snapshot.docs.map((doc) {
        return StockTransferModel.fromJson(doc.data(), doc.id);
      }).toList();

      if (branchId != null && branchId.trim().isNotEmpty && branchId != 'all') {
        results = results.where((t) {
          return t.fromBranchId == branchId || t.toBranchId == branchId;
        }).toList();
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    });
  }

  @override
  Future<void> updateTransferStatus(
    String transferId,
    StockTransferStatus status, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
  }) async {
    try {
      final docRef = _collection.doc(transferId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        throw Exception('Transfer document $transferId does not exist.');
      }

      final existing = StockTransferModel.fromJson(docSnap.data()!, docSnap.id);
      final now = DateTime.now();

      // Update items if receivedQuantities provided
      List<StockTransferItemModel> updatedItems = existing.items;
      if (receivedQuantities != null && receivedQuantities.isNotEmpty) {
        updatedItems = existing.items.map((item) {
          final skuOrId = item.variationSku.isNotEmpty ? item.variationSku : item.productId;
          if (receivedQuantities.containsKey(skuOrId)) {
            return item.copyWith(receivedQuantity: receivedQuantities[skuOrId]);
          }
          return item;
        }).toList();
      } else if (status == StockTransferStatus.received) {
        // Default received qty to requested qty if not explicitly set
        updatedItems = existing.items.map((item) {
          return item.copyWith(
            receivedQuantity: item.receivedQuantity > 0 ? item.receivedQuantity : item.requestedQuantity,
          );
        }).toList();
      }

      final Map<String, dynamic> updateData = {
        'status': status.id,
        'updatedAt': Timestamp.fromDate(now),
        'items': updatedItems.map((e) => e.toJson()).toList(),
      };

      if (status == StockTransferStatus.received) {
        updateData['receivedAt'] = Timestamp.fromDate(now);
        if (performedBy != null && performedBy.isNotEmpty) {
          updateData['receivedBy'] = performedBy;
        }
      }

      if (notes != null && notes.isNotEmpty) {
        updateData['notes'] = existing.notes.isNotEmpty
            ? '${existing.notes}\n[${status.id.toUpperCase()}]: $notes'
            : notes;
      }

      await docRef.update(updateData);
    } catch (e) {
      debugPrint('! [StockTransfer] Error updating status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTransfer(String transferId) async {
    try {
      await _collection.doc(transferId).delete();
    } catch (e) {
      debugPrint('! [StockTransfer] Error deleting transfer: $e');
      rethrow;
    }
  }
}
