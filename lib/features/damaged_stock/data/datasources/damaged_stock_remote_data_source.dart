import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/damaged_stock_model.dart';

abstract class DamagedStockRemoteDataSource {
  Stream<List<DamagedStockModel>> watchDamagedStock();
  Future<List<DamagedStockModel>> getDamagedStock();
  Future<void> addDamagedStock(DamagedStockModel record);
  Future<void> deleteDamagedStock(String id);
}

class DamagedStockRemoteDataSourceImpl implements DamagedStockRemoteDataSource {
  final FirebaseFirestore _firestore;

  DamagedStockRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('damaged_stock');

  @override
  Stream<List<DamagedStockModel>> watchDamagedStock() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DamagedStockModel.fromJson(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      debugPrint('Firestore DamagedStock stream error: $error');
      return <DamagedStockModel>[];
    });
  }

  @override
  Future<List<DamagedStockModel>> getDamagedStock() async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        return DamagedStockModel.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getDamagedStock error: $e');
      return [];
    }
  }

  @override
  Future<void> addDamagedStock(DamagedStockModel record) async {
    final docRef = record.id.isNotEmpty ? _collection.doc(record.id) : _collection.doc();
    final data = record.copyWith(id: docRef.id).toJson();
    await docRef.set(data);
  }

  @override
  Future<void> deleteDamagedStock(String id) async {
    await _collection.doc(id).delete();
  }
}
