import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';

abstract class BadgeRemoteDataSource {
  Future<List<BadgeModel>> getBadges();
  Future<void> addBadge(BadgeModel badge);
  Future<void> updateBadge(BadgeModel badge);
  Future<void> deleteBadge(String badgeId);
}

class BadgeRemoteDataSourceImpl implements BadgeRemoteDataSource {
  final FirebaseFirestore _firestore;

  BadgeRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _badgesCollection =>
      _firestore.collection('Badges');

  @override
  Future<List<BadgeModel>> getBadges() async {
    final query = await _badgesCollection.get();

    final list = query.docs.map((doc) {
      final data = doc.data();
      return BadgeModel.fromJson({...data, 'id': doc.id});
    }).toList();

    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  @override
  Future<void> addBadge(BadgeModel badge) async {
    final id = badge.id.isNotEmpty
        ? badge.id
        : 'BADGE_${DateTime.now().millisecondsSinceEpoch}';
    await _badgesCollection
        .doc(id)
        .set(badge.copyWith(id: id).toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateBadge(BadgeModel badge) async {
    await _badgesCollection.doc(badge.id).update(badge.toJson());
  }

  @override
  Future<void> deleteBadge(String badgeId) async {
    await _badgesCollection.doc(badgeId).delete();
  }
}
