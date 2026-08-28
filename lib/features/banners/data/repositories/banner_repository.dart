import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/banner_model.dart';

abstract class BannerRepository {
  Future<List<BannerModel>> getBanners();
  Future<void> addBanner(BannerModel banner);
  Future<void> updateBanner(BannerModel banner);
  Future<void> deleteBanner(String id);
}

class BannerRepositoryImpl implements BannerRepository {
  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final snapshot = await FirebaseService.getDocsSafely(
        'Banners',
        secondaryName: 'banners',
      );
      if (snapshot.docs.isEmpty) {
        return _mockBanners();
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BannerModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore Banners fetch note: $e');
      return _mockBanners();
    }
  }

  @override
  Future<void> addBanner(BannerModel banner) async {
    await FirebaseService.bannersCollection.doc(banner.id).set(banner.toJson());
  }

  @override
  Future<void> updateBanner(BannerModel banner) async {
    await FirebaseService.bannersCollection.doc(banner.id).set(banner.toJson());
  }

  @override
  Future<void> deleteBanner(String id) async {
    await FirebaseService.bannersCollection.doc(id).delete();
  }

  static List<BannerModel> _mockBanners() {
    return [
      const BannerModel(
        id: 'BANNER_01',
        title: 'Premium Salt Nicotine Flavors Sale',
        imageUrl:
            'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=1200&q=80',
        targetScreen: '/category/CAT_SALT_NIC',
        active: true,
      ),
      const BannerModel(
        id: 'BANNER_02',
        title: 'New Hardware Mods & Pod Systems',
        imageUrl:
            'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1200&q=80',
        targetScreen: '/category/CAT_DEVICES',
        active: true,
      ),
      const BannerModel(
        id: 'BANNER_03',
        title: 'Vaporesso & GeekVape Official Collection',
        imageUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&q=80',
        targetScreen: '/brand/BRAND_VAPORESSO',
        active: true,
      ),
    ];
  }
}
