import 'package:flutter/foundation.dart';
import '../datasources/banner_remote_data_source.dart';
import '../models/banner_model.dart';

abstract class BannerRepository {
  Future<List<BannerModel>> getBanners();
  Future<void> addBanner(BannerModel banner);
  Future<void> updateBanner(BannerModel banner);
  Future<void> deleteBanner(String id);
}

class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;

  BannerRepositoryImpl({BannerRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? BannerRemoteDataSourceImpl();

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      return await remoteDataSource.getBanners();
    } catch (e) {
      debugPrint('Firestore Banners fetch note: $e');
      return [];
    }
  }

  @override
  Future<void> addBanner(BannerModel banner) =>
      remoteDataSource.addBanner(banner);

  @override
  Future<void> updateBanner(BannerModel banner) =>
      remoteDataSource.updateBanner(banner);

  @override
  Future<void> deleteBanner(String id) =>
      remoteDataSource.deleteBanner(id);
}
