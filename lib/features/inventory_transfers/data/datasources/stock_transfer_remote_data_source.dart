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

      // Apply Inter-Branch Stock Adjustments when transfer is marked as Received
      if (status == StockTransferStatus.received && existing.status != StockTransferStatus.received) {
        final fromBranch = existing.fromBranchId.isNotEmpty ? existing.fromBranchId : 'main_branch';
        final toBranch = existing.toBranchId.isNotEmpty ? existing.toBranchId : 'main_branch';

        if (fromBranch != toBranch) {
          for (final item in updatedItems) {
            final qty = item.receivedQuantity > 0 ? item.receivedQuantity : item.requestedQuantity;
            if (item.productId.isEmpty || qty <= 0) continue;

            await _transferItemStock(
              productId: item.productId,
              variationSku: item.variationSku,
              quantity: qty,
              fromBranchId: fromBranch,
              fromBranchName: existing.fromBranchName,
              toBranchId: toBranch,
              toBranchName: existing.toBranchName,
              transferId: transferId,
              performedBy: performedBy ?? 'Store Staff',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('! [StockTransfer] Error updating status: $e');
      rethrow;
    }
  }

  Future<void> _transferItemStock({
    required String productId,
    required String variationSku,
    required int quantity,
    required String fromBranchId,
    required String fromBranchName,
    required String toBranchId,
    required String toBranchName,
    required String transferId,
    required String performedBy,
  }) async {
    try {
      final prodRef = _firestore.collection('Products').doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(prodRef);
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;

        final productTitle = data['title']?.toString() ?? 'Product';
        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;

        // 1. Update product branchStock
        final rawBranchStock = data['branchStock'] ?? data['BranchStock'] ?? {};
        final Map<String, int> updatedBranchStock = {};
        if (rawBranchStock is Map) {
          rawBranchStock.forEach((k, v) {
            if (v is num) updatedBranchStock[k.toString()] = v.toInt();
          });
        }

        final fromQty = updatedBranchStock[fromBranchId] ?? currentStock;
        final toQty = updatedBranchStock[toBranchId] ?? 0;

        updatedBranchStock[fromBranchId] = (fromQty - quantity).clamp(0, 999999).toInt();
        updatedBranchStock[toBranchId] = (toQty + quantity).clamp(0, 999999).toInt();

        // 2. Update variations branchStock if variationSku provided
        final rawVars = data['productVariations'] ?? data['variations'];
        final List<Map<String, dynamic>> updatedVars = [];
        bool variationUpdated = false;

        if (rawVars is List && rawVars.isNotEmpty) {
          for (final v in rawVars) {
            if (v is Map) {
              final vMap = Map<String, dynamic>.from(v);
              final sku = vMap['sku']?.toString().trim().toLowerCase() ?? '';

              if (variationSku.isNotEmpty && sku == variationSku.trim().toLowerCase()) {
                final vStock = (vMap['stock'] as num?)?.toInt() ?? 0;
                final vBranchRaw = vMap['branchStock'] ?? vMap['BranchStock'] ?? {};
                final Map<String, int> vBranchStock = {};
                if (vBranchRaw is Map) {
                  vBranchRaw.forEach((k, val) {
                    if (val is num) vBranchStock[k.toString()] = val.toInt();
                  });
                }

                final vFromQty = vBranchStock[fromBranchId] ?? vStock;
                final vToQty = vBranchStock[toBranchId] ?? 0;

                vBranchStock[fromBranchId] = (vFromQty - quantity).clamp(0, 999999).toInt();
                vBranchStock[toBranchId] = (vToQty + quantity).clamp(0, 999999).toInt();
                vMap['branchStock'] = vBranchStock;
                variationUpdated = true;
              }
              updatedVars.add(vMap);
            }
          }
        }

        final updateData = <String, dynamic>{
          'branchStock': updatedBranchStock,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (updatedVars.isNotEmpty && variationUpdated) {
          updateData['productVariations'] = updatedVars;
        }

        transaction.update(prodRef, updateData);

        // 3. Log Stock Movement audit for the transfer
        final movRef = _firestore.collection('stock_movements').doc();
        transaction.set(movRef, {
          'id': movRef.id,
          'productId': productId,
          'productTitle': productTitle,
          'variationSku': variationSku,
          'type': 'transfer',
          'quantity': quantity,
          'fromBranchId': fromBranchId,
          'fromBranchName': fromBranchName,
          'toBranchId': toBranchId,
          'toBranchName': toBranchName,
          'transferId': transferId,
          'notes': 'تحويل بضاعة من $fromBranchName إلى $toBranchName (طلب #$transferId)',
          'performedBy': performedBy,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('📦 [Transfer Stock] Transferred $quantity units of $productId from $fromBranchName to $toBranchName');
    } catch (e) {
      debugPrint('⚠️ [Transfer Stock Error] $e');
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
