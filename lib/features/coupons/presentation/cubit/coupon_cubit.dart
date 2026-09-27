import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/coupon_model.dart';
import '../../data/repositories/coupon_repository.dart';
import 'coupon_state.dart';

export 'coupon_state.dart';

class CouponCubit extends Cubit<CouponState> {
  final CouponRepository couponRepository;

  CouponCubit(this.couponRepository) : super(const CouponInitial());

  Future<void> loadCoupons() async {
    emit(const CouponLoading());
    try {
      final coupons = await couponRepository.getCoupons();
      final updatedCoupons = <CouponModel>[];

      for (final c in coupons) {
        if (c.isActive && c.isExpired) {
          final deactivated = c.copyWith(isActive: false);
          // Persist the inactive status to Firestore asynchronously
          couponRepository.updateCoupon(deactivated).ignore();
          updatedCoupons.add(deactivated);
        } else {
          updatedCoupons.add(c);
        }
      }

      emit(CouponLoaded(coupons: updatedCoupons, filteredCoupons: updatedCoupons));
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  void filterCoupons(String query) {
    if (state is! CouponLoaded) return;
    final currentState = state as CouponLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.coupons.where((c) {
      return q.isEmpty ||
          c.code.toLowerCase().contains(q) ||
          c.discountPercentage.toString().contains(q) ||
          c.minOrderAmount.toString().contains(q) ||
          c.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredCoupons: filtered,
      searchQuery: query.trim(),
    ));
  }

  Future<void> addCoupon(CouponModel coupon) async {
    try {
      await couponRepository.addCoupon(coupon);
      await loadCoupons();
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    try {
      await couponRepository.updateCoupon(coupon);
      await loadCoupons();
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }

  Future<void> deleteCoupon(String couponId) async {
    try {
      await couponRepository.deleteCoupon(couponId);
      await loadCoupons();
    } catch (e) {
      emit(CouponError(e.toString()));
    }
  }
}
