import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/stock_movement_model.dart';

abstract class StockMovementRemoteDataSource {
  Future<List<StockMovementModel>> getStockMovements({
    int limit = 100,
    String? productId,
    StockMovementType? type,
  });
  Future<void> recordStockMovement(StockMovementModel movement);
  Future<void> recordBatchStockMovements(List<StockMovementModel> movements);
}

class StockMovementRemoteDataSourceImpl implements StockMovementRemoteDataSource {
  final FirebaseFirestore _firestore;

  StockMovementRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<List<StockMovementModel>> getStockMovements({
    int limit = 100,
    String? productId,
    StockMovementType? type,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('stock_movements')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (productId != null && productId.isNotEmpty) {
        query = query.where('productId', isEqualTo: productId);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return StockMovementModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getStockMovements error: $e');
      // Fallback query without orderBy if index is building
      try {
        final snapshot = await _firestore
            .collection('stock_movements')
            .limit(limit)
            .get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return StockMovementModel.fromJson(data);
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (fallbackError) {
        debugPrint('Firestore fallback error: $fallbackError');
        return [];
      }
    }
  }

  @override
  Future<void> recordStockMovement(StockMovementModel movement) async {
    try {
      final docRef = movement.id.isNotEmpty
          ? _firestore.collection('stock_movements').doc(movement.id)
          : _firestore.collection('stock_movements').doc();

      final json = movement.toJson();
      json['id'] = docRef.id;
      json['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(json);
    } catch (e) {
      debugPrint('Firestore recordStockMovement error: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordBatchStockMovements(List<StockMovementModel> movements) async {
    if (movements.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final m in movements) {
        final docRef = m.id.isNotEmpty
            ? _firestore.collection('stock_movements').doc(m.id)
            : _firestore.collection('stock_movements').doc();

        final json = m.toJson();
        json['id'] = docRef.id;
        json['createdAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, json);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore recordBatchStockMovements error: $e');
      rethrow;
    }
  }
}
