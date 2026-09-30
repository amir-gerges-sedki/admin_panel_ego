import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

abstract class CustomerRemoteDataSource {
  Future<List<Map<String, dynamic>>> getRawUsers();
  Future<List<Map<String, dynamic>>> getRawOrders();
  Stream<Map<String, dynamic>?> watchRawUser(String userId);
  Stream<List<Map<String, dynamic>>> watchRawUsers();
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore _firestore;

  CustomerRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('Users');

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('Orders');

  @override
  Future<List<Map<String, dynamic>>> getRawUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Firestore Users fetch note: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRawOrders() async {
    try {
      final snapshot = await _ordersCollection.get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Firestore Orders aggregation note: $e');
      return [];
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchRawUser(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      data['id'] = snapshot.id;
      return data;
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRawUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
