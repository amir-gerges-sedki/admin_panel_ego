import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

abstract class CouponRemoteDataSource {
  Future<List<CouponModel>> getCoupons();
  Future<void> addCoupon(CouponModel coupon);
  Future<void> updateCoupon(CouponModel coupon);
  Future<void> deleteCoupon(String id);
}

class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  final FirebaseFirestore _firestore;

  CouponRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _couponsCollection =>
      _firestore.collection('Coupons');

  @override
  Future<List<CouponModel>> getCoupons() async {
    final snapshot = await _couponsCollection.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CouponModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> addCoupon(CouponModel coupon) async {
    await _couponsCollection.doc(coupon.id).set(coupon.toJson());
  }

  @override
  Future<void> updateCoupon(CouponModel coupon) async {
    await _couponsCollection
        .doc(coupon.id)
        .set(coupon.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteCoupon(String id) async {
    await _couponsCollection.doc(id).delete();
  }
}
