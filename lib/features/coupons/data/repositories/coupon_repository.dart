import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/coupon_model.dart';

abstract class CouponRepository {
  Future<List<CouponModel>> getCoupons();
  Future<void> addCoupon(CouponModel coupon);
  Future<void> updateCoupon(CouponModel coupon);
  Future<void> deleteCoupon(String id);
}

class CouponRepositoryImpl implements CouponRepository {
  @override
  Future<List<CouponModel>> getCoupons() async {
    try {
      final snapshot = await FirebaseService.getDocsSafely('Coupons', secondaryName: 'coupons');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CouponModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore Coupons fetch note: $e');
      return [];
    }
  }

  @override
  Future<void> addCoupon(CouponModel coupon) async {
    await FirebaseService.couponsCollection.doc(coupon.id).set(coupon.toJson());
  }

  @override
  Future<void> updateCoupon(CouponModel coupon) async {
    await FirebaseService.couponsCollection.doc(coupon.id).set(coupon.toJson());
  }

  @override
  Future<void> deleteCoupon(String id) async {
    await FirebaseService.couponsCollection.doc(id).delete();
  }
}
