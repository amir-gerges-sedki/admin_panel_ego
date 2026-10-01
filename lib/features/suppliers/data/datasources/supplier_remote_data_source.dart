import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/supplier_model.dart';

/// Handles only Supplier entity CRUD operations.
/// Invoice and Payment logic lives in dedicated data sources.
abstract class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel?> getSupplierById(String id);
  Future<SupplierModel> addSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final FirebaseFirestore _firestore;

  SupplierRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _suppliersCollection =>
      _firestore.collection('suppliers');

  // -------------------------------------------------------------
  // Suppliers CRUD
  // -------------------------------------------------------------

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final snapshot = await _suppliersCollection
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
        final snapshot = await _suppliersCollection.get();
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
      final doc = await _suppliersCollection.doc(id).get();
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
          ? _suppliersCollection.doc(supplier.id)
          : _suppliersCollection.doc();

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
      final docRef = _suppliersCollection.doc(supplier.id);
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
      await _suppliersCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteSupplier error: $e');
      rethrow;
    }
  }
}
