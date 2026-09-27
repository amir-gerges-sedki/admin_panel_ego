import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> getBanners();
  Future<void> addBanner(BannerModel banner);
  Future<void> updateBanner(BannerModel banner);
  Future<void> deleteBanner(String id);
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final FirebaseFirestore _firestore;

  BannerRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bannersCollection =>
      _firestore.collection('Banners');

  @override
  Future<List<BannerModel>> getBanners() async {
    final snapshot = await _bannersCollection.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BannerModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> addBanner(BannerModel banner) async {
    await _bannersCollection.doc(banner.id).set(banner.toJson());
  }

  @override
  Future<void> updateBanner(BannerModel banner) async {
    await _bannersCollection
        .doc(banner.id)
        .set(banner.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteBanner(String id) async {
    await _bannersCollection.doc(id).delete();
  }
}
