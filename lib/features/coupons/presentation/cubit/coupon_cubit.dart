import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/coupon_model.dart';
import '../../data/repositories/coupon_repository.dart';

abstract class CouponState extends Equatable {
  const CouponState();
  @override
  List<Object?> get props => [];
}

class CouponInitial extends CouponState {}
class CouponLoading extends CouponState {}
class CouponLoaded extends CouponState {
  final List<CouponModel> coupons;
  final List<CouponModel>? _filteredCoupons;
  final String? _searchQuery;

  List<CouponModel> get filteredCoupons => _filteredCoupons ?? coupons;
  String get searchQuery => _searchQuery ?? '';

  const CouponLoaded({
    this.coupons = const [],
    List<CouponModel>? filteredCoupons,
    String? searchQuery,
  })  : _filteredCoupons = filteredCoupons ?? coupons,
        _searchQuery = searchQuery ?? '';

  CouponLoaded copyWith({
    List<CouponModel>? coupons,
    List<CouponModel>? filteredCoupons,
    String? searchQuery,
  }) {
    final c = coupons ?? this.coupons;
    return CouponLoaded(
      coupons: c,
      filteredCoupons: filteredCoupons ?? _filteredCoupons ?? c,
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [coupons, filteredCoupons, searchQuery];
}

class CouponError extends CouponState {
  final String message;
  const CouponError(this.message);
  @override
  List<Object?> get props => [message];
}

class CouponCubit extends Cubit<CouponState> {
  final CouponRepository couponRepository;

  CouponCubit(this.couponRepository) : super(CouponInitial());

  Future<void> loadCoupons() async {
    emit(CouponLoading());
    try {
      final coupons = await couponRepository.getCoupons();
      emit(CouponLoaded(coupons: coupons, filteredCoupons: coupons));
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
