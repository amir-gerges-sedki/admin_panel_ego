import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

abstract class CustomerRemoteDataSource {
  Future<List<Map<String, dynamic>>> getRawUsers();
  Future<List<Map<String, dynamic>>> getRawOrders();
  Stream<Map<String, dynamic>?> watchRawUser(String userId);
  Stream<List<Map<String, dynamic>>> watchRawUsers();
  Future<Map<String, dynamic>?> findUserByPhone(String phone);
  Future<void> updateCustomerPoints({
    required String userId,
    required int pointsDelta,
    String? reason,
  });
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

  List<String> _buildPhoneVariants(String rawPhone) {
    final clean = rawPhone.trim().replaceAll(RegExp(r'\s+|-'), '');
    if (clean.isEmpty) return [];

    final set = <String>{clean};

    String base = clean;
    if (base.startsWith('+20')) {
      base = base.substring(3);
    } else if (base.startsWith('+2')) {
      base = base.substring(2);
    } else if (base.startsWith('0020')) {
      base = base.substring(4);
    } else if (base.startsWith('20') && base.length >= 12) {
      base = base.substring(2);
    }

    if (base.startsWith('0')) {
      base = base.substring(1);
    }

    if (base.isNotEmpty) {
      set.add(base);
      set.add('0$base');
      set.add('20$base');
      set.add('+20$base');
    }

    return set.toList();
  }

  @override
  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final variants = _buildPhoneVariants(phone);
    if (variants.isEmpty) return null;
    try {
      final queryList = variants.take(10).toList();

      var snap = await _usersCollection.where('phoneNumber', whereIn: queryList).limit(1).get();
      if (snap.docs.isEmpty) {
        snap = await _usersCollection.where('phone', whereIn: queryList).limit(1).get();
      }
      if (snap.docs.isEmpty) {
        snap = await _usersCollection.where('PhoneNumber', whereIn: queryList).limit(1).get();
      }

      if (snap.docs.isNotEmpty) {
        final data = Map<String, dynamic>.from(snap.docs.first.data());
        data['id'] = snap.docs.first.id;
        return data;
      }

      // Memory fallback for partial phone numbers / edge cases
      final allSnap = await _usersCollection.limit(150).get();
      for (final doc in allSnap.docs) {
        final d = doc.data();
        final p = (d['phone'] ?? d['phoneNumber'] ?? d['PhoneNumber'] ?? '').toString().replaceAll(RegExp(r'\s+|-'), '');
        if (p.isNotEmpty) {
          for (final v in variants) {
            if (p == v || (v.length >= 9 && p.endsWith(v.substring(v.length - 9)))) {
              final data = Map<String, dynamic>.from(d);
              data['id'] = doc.id;
              return data;
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding user by phone: $e');
      return null;
    }
  }

  @override
  Future<void> updateCustomerPoints({
    required String userId,
    required int pointsDelta,
    String? reason,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _usersCollection.doc(userId).set({
        'loyaltyPoints': FieldValue.increment(pointsDelta),
      }, SetOptions(merge: true));

      await _usersCollection.doc(userId).collection('loyalty_history').add({
        'pointsDelta': pointsDelta,
        'reason': reason ?? 'Admin adjustment',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating customer points: $e');
      rethrow;
    }
  }
}
