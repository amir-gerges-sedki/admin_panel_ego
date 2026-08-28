import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';

abstract class BadgeRepository {
  Future<List<BadgeModel>> getBadges();
  Future<void> addBadge(BadgeModel badge);
  Future<void> updateBadge(BadgeModel badge);
  Future<void> deleteBadge(String badgeId);
}

class BadgeRepositoryImpl implements BadgeRepository {
  final FirebaseFirestore _firestore;

  BadgeRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<BadgeModel>> getBadges() async {
    try {
      final List<String> collectionNames = [
        'Badges',
        'badges',
        'ProductBadges',
        'product_badges',
      ];
      QuerySnapshot<Map<String, dynamic>>? snap;

      for (final col in collectionNames) {
        try {
          final query = await _firestore.collection(col).get();
          if (query.docs.isNotEmpty) {
            snap = query;
            break;
          }
        } catch (_) {}
      }

      if (snap == null || snap.docs.isEmpty) {
        return [];
      }

      final list = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BadgeModel.fromJson(data);
      }).toList();

      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return list;
    } catch (e) {
      debugPrint('Firestore fetch error for Badges: $e');
      return [];
    }
  }

  @override
  Future<void> addBadge(BadgeModel badge) async {
    try {
      final id = badge.id.isNotEmpty
          ? badge.id
          : 'BADGE_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore
          .collection('Badges')
          .doc(id)
          .set(badge.copyWith(id: id).toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore add error for Badges: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBadge(BadgeModel badge) async {
    try {
      await _firestore
          .collection('Badges')
          .doc(badge.id)
          .set(badge.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore update error for Badges: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBadge(String badgeId) async {
    try {
      await _firestore.collection('Badges').doc(badgeId).delete();
    } catch (e) {
      debugPrint('Firestore delete error for Badges: $e');
      rethrow;
    }
  }
}
