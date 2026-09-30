import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/brand_model.dart';

abstract class BrandRemoteDataSource {
  Future<List<BrandModel>> getBrands();
  Future<BrandModel?> getBrandById(String id);
  Future<BrandModel?> getBrandByName(String name);
  Future<Map<String, int>> getProductCountsPerBrand();
  Future<void> addBrand(BrandModel brand);
  Future<void> updateBrand(BrandModel brand);
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders);
  Future<void> deleteBrand(String id);
}

class BrandRemoteDataSourceImpl implements BrandRemoteDataSource {
  final FirebaseFirestore _firestore;

  BrandRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> get _brandsCollection =>
      FirebaseService.brandsCollection;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      FirebaseService.productsCollection;

  @override
  Future<List<BrandModel>> getBrands() async {
    final snapshot = await _brandsCollection.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BrandModel.fromJson(data);
    }).toList();
  }

  @override
  Future<Map<String, int>> getProductCountsPerBrand() async {
    try {
      final snapshot = await _productsCollection.get();
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final brandMap = data['brand'];
        String? bId;
        String? bName;

        if (brandMap is Map) {
          bId = brandMap['id']?.toString().trim().toLowerCase();
          bName = brandMap['name']?.toString().trim().toLowerCase();
        }

        if (bId != null && bId.isNotEmpty) {
          counts[bId] = (counts[bId] ?? 0) + 1;
        }
        if (bName != null && bName.isNotEmpty) {
          counts[bName] = (counts[bName] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('Error getting product counts per brand: $e');
      return {};
    }
  }

  @override
  Future<BrandModel?> getBrandById(String id) async {
    final doc = await _brandsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    final data = doc.data()!;
    data['id'] = doc.id;
    return BrandModel.fromJson(data);
  }

  @override
  Future<BrandModel?> getBrandByName(String name) async {
    final snapshot = await _brandsCollection
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return BrandModel.fromJson(data);
  }

  @override
  Future<void> addBrand(BrandModel brand) async {
    await _brandsCollection.doc(brand.id).set(brand.toJson());
  }

  @override
  Future<void> updateBrand(BrandModel brand) async {
    await _brandsCollection
        .doc(brand.id)
        .set(brand.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateBrandOrdersBatch(Map<String, int> brandOrders) async {
    final batch = _firestore.batch();
    for (final entry in brandOrders.entries) {
      batch.set(_brandsCollection.doc(entry.key), {
        'sortOrder': entry.value,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteBrand(String id) async {
    await _brandsCollection.doc(id).delete();
  }
}
