import 'package:flutter/foundation.dart';
import '../datasources/coupon_remote_data_source.dart';
import '../models/coupon_model.dart';

abstract class CouponRepository {
  Future<List<CouponModel>> getCoupons();
  Future<void> addCoupon(CouponModel coupon);
  Future<void> updateCoupon(CouponModel coupon);
  Future<void> deleteCoupon(String id);
}

class CouponRepositoryImpl implements CouponRepository {
  final CouponRemoteDataSource remoteDataSource;

  CouponRepositoryImpl({CouponRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? CouponRemoteDataSourceImpl();

  @override
  Future<List<CouponModel>> getCoupons() async {
    try {
      return await remoteDataSource.getCoupons();
    } catch (e) {
      debugPrint('Firestore Coupons fetch note: $e');
      return [];
    }
  }

  @override
  Future<void> addCoupon(CouponModel coupon) =>
      remoteDataSource.addCoupon(coupon);

  @override
  Future<void> updateCoupon(CouponModel coupon) =>
      remoteDataSource.updateCoupon(coupon);

  @override
  Future<void> deleteCoupon(String id) =>
      remoteDataSource.deleteCoupon(id);
}
