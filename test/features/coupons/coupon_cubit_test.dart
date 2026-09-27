import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/coupons/data/models/coupon_model.dart';
import 'package:admin_panel_ego/features/coupons/data/repositories/coupon_repository.dart';
import 'package:admin_panel_ego/features/coupons/presentation/cubit/coupon_cubit.dart';

class FakeCouponRepository implements CouponRepository {
  final List<CouponModel> coupons;
  final List<CouponModel> updatedCoupons = [];

  FakeCouponRepository([List<CouponModel>? initial])
      : coupons = initial ?? [];

  @override
  Future<List<CouponModel>> getCoupons() async => List.from(coupons);

  @override
  Future<void> addCoupon(CouponModel coupon) async {
    coupons.add(coupon);
  }

  @override
  Future<void> updateCoupon(CouponModel coupon) async {
    updatedCoupons.add(coupon);
    final idx = coupons.indexWhere((c) => c.id == coupon.id);
    if (idx != -1) {
      coupons[idx] = coupon;
    }
  }

  @override
  Future<void> deleteCoupon(String id) async {
    coupons.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('CouponModel Dates & Lifecycle Tests', () {
    test('isEffectiveActive returns true only within valid date range when active', () {
      final now = DateTime.now();
      final activeCoupon = CouponModel(
        id: 'c1',
        code: 'VALID20',
        discountPercentage: 20,
        isActive: true,
        startDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
      );

      expect(activeCoupon.isStarted, isTrue);
      expect(activeCoupon.isExpired, isFalse);
      expect(activeCoupon.isEffectiveActive, isTrue);
    });

    test('isEffectiveActive returns false if expiryDate has passed', () {
      final now = DateTime.now();
      final expiredCoupon = CouponModel(
        id: 'c2',
        code: 'EXPIRED10',
        discountPercentage: 10,
        isActive: true,
        startDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.subtract(const Duration(days: 1)),
      );

      expect(expiredCoupon.isStarted, isTrue);
      expect(expiredCoupon.isExpired, isTrue);
      expect(expiredCoupon.isEffectiveActive, isFalse);
    });

    test('isEffectiveActive returns false if startDate is in the future (scheduled)', () {
      final now = DateTime.now();
      final futureCoupon = CouponModel(
        id: 'c3',
        code: 'FUTURE50',
        discountPercentage: 50,
        isActive: true,
        startDate: now.add(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 10)),
      );

      expect(futureCoupon.isStarted, isFalse);
      expect(futureCoupon.isExpired, isFalse);
      expect(futureCoupon.isEffectiveActive, isFalse);
    });

    test('fromJson and toJson correctly serialize startDate and expiryDate', () {
      final start = DateTime(2026, 9, 1, 10, 0, 0);
      final expiry = DateTime(2026, 10, 1, 23, 59, 59);

      final model = CouponModel(
        id: 'c_test',
        code: 'TEST2026',
        discountPercentage: 15,
        isActive: true,
        startDate: start,
        expiryDate: expiry,
      );

      final json = model.toJson();
      expect(json['code'], 'TEST2026');
      expect(json['startDate'], start.toIso8601String());
      expect(json['expiryDate'], expiry.toIso8601String());

      final fromJson = CouponModel.fromJson(json);
      expect(fromJson.code, 'TEST2026');
      expect(fromJson.startDate?.year, 2026);
      expect(fromJson.startDate?.month, 9);
      expect(fromJson.expiryDate.year, 2026);
      expect(fromJson.expiryDate.month, 10);
    });
  });

  group('CouponCubit Auto-Deactivation Tests', () {
    late FakeCouponRepository fakeRepo;
    late CouponCubit cubit;

    setUp(() {
      final now = DateTime.now();
      fakeRepo = FakeCouponRepository([
        CouponModel(
          id: 'c_active',
          code: 'ACTIVE',
          discountPercentage: 10,
          isActive: true,
          startDate: now.subtract(const Duration(days: 2)),
          expiryDate: now.add(const Duration(days: 10)),
        ),
        CouponModel(
          id: 'c_expired_but_marked_active',
          code: 'PAST_DUE',
          discountPercentage: 20,
          isActive: true, // currently marked active in DB
          startDate: now.subtract(const Duration(days: 20)),
          expiryDate: now.subtract(const Duration(days: 1)), // but expired!
        ),
      ]);
      cubit = CouponCubit(fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('loadCoupons automatically deactivates expired coupons in state and DB', () async {
      await cubit.loadCoupons();

      expect(cubit.state, isA<CouponLoaded>());
      final state = cubit.state as CouponLoaded;

      // Active coupon remains active
      final active = state.coupons.firstWhere((c) => c.id == 'c_active');
      expect(active.isActive, isTrue);

      // Expired coupon is automatically deactivated (isActive = false)
      final pastDue = state.coupons.firstWhere((c) => c.id == 'c_expired_but_marked_active');
      expect(pastDue.isActive, isFalse);

      // Persisted to repository
      expect(fakeRepo.updatedCoupons.any((c) => c.id == 'c_expired_but_marked_active' && !c.isActive), isTrue);
    });
  });
}
