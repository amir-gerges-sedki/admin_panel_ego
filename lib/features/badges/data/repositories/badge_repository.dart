import 'package:flutter/foundation.dart';
import '../datasources/badge_remote_data_source.dart';
import '../models/badge_model.dart';

abstract class BadgeRepository {
  Future<List<BadgeModel>> getBadges();
  Future<void> addBadge(BadgeModel badge);
  Future<void> updateBadge(BadgeModel badge);
  Future<void> deleteBadge(String badgeId);
}

class BadgeRepositoryImpl implements BadgeRepository {
  final BadgeRemoteDataSource remoteDataSource;

  BadgeRepositoryImpl({BadgeRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? BadgeRemoteDataSourceImpl();

  @override
  Future<List<BadgeModel>> getBadges() async {
    try {
      return await remoteDataSource.getBadges();
    } catch (e) {
      debugPrint('Firestore fetch error for Badges: $e');
      return [];
    }
  }

  @override
  Future<void> addBadge(BadgeModel badge) async {
    try {
      await remoteDataSource.addBadge(badge);
    } catch (e) {
      debugPrint('Firestore add error for Badges: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBadge(BadgeModel badge) async {
    try {
      await remoteDataSource.updateBadge(badge);
    } catch (e) {
      debugPrint('Firestore update error for Badges: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBadge(String badgeId) async {
    try {
      await remoteDataSource.deleteBadge(badgeId);
    } catch (e) {
      debugPrint('Firestore delete error for Badges: $e');
      rethrow;
    }
  }
}
