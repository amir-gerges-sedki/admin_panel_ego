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

  @override
  Future<List<Map<String, dynamic>>> getRawUsers() async {
    try {
      var snapshot = await _firestore.collection('Users').get();
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore.collection('users').get();
      }
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
      var snapshot = await _firestore.collection('Orders').get();
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore.collection('orders').get();
      }
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
    return _firestore.collection('Users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      data['id'] = snapshot.id;
      return data;
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRawUsers() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
