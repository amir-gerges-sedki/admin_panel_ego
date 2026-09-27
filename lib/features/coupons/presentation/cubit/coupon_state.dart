import 'package:equatable/equatable.dart';
import '../../data/models/coupon_model.dart';

abstract class CouponState extends Equatable {
  const CouponState();

  @override
  List<Object?> get props => [];
}

class CouponInitial extends CouponState {
  const CouponInitial();
}

class CouponLoading extends CouponState {
  const CouponLoading();
}

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
