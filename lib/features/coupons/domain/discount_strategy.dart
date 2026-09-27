import '../data/models/coupon_model.dart';

/// Strategy interface for calculating coupon discounts and evaluating eligibility rules (OCP).
abstract class DiscountStrategy {
  String get name;

  /// Returns true if the order satisfies eligibility criteria for this discount
  bool isEligible({
    required double orderSubtotal,
    DateTime? currentDate,
  });

  /// Calculates the discount amount deducted from the subtotal
  double calculateDiscount({
    required double orderSubtotal,
    DateTime? currentDate,
  });

  /// Factory creating strategy from CouponModel
  static DiscountStrategy fromCoupon(CouponModel coupon) {
    return PercentageDiscountStrategy(
      couponCode: coupon.code,
      discountPercentage: coupon.discountPercentage,
      minOrderAmount: coupon.minOrderAmount,
      startDate: coupon.startDate,
      expiryDate: coupon.expiryDate,
      isActive: coupon.isActive,
    );
  }
}

/// Standard Percentage-based discount calculation strategy.
class PercentageDiscountStrategy implements DiscountStrategy {
  final String couponCode;
  final double discountPercentage;
  final double minOrderAmount;
  final DateTime? startDate;
  final DateTime expiryDate;
  final bool isActive;
  final double maxDiscountCap;

  const PercentageDiscountStrategy({
    required this.couponCode,
    required this.discountPercentage,
    required this.minOrderAmount,
    this.startDate,
    required this.expiryDate,
    required this.isActive,
    this.maxDiscountCap = double.infinity,
  });

  @override
  String get name => 'Percentage Discount ($discountPercentage%)';

  @override
  bool isEligible({
    required double orderSubtotal,
    DateTime? currentDate,
  }) {
    if (!isActive) return false;
    final now = currentDate ?? DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (now.isAfter(expiryDate)) return false;
    if (orderSubtotal < minOrderAmount) return false;
    return true;
  }

  @override
  double calculateDiscount({
    required double orderSubtotal,
    DateTime? currentDate,
  }) {
    if (!isEligible(orderSubtotal: orderSubtotal, currentDate: currentDate)) {
      return 0.0;
    }

    final rawDiscount = (orderSubtotal * discountPercentage) / 100.0;
    if (rawDiscount > maxDiscountCap) {
      return maxDiscountCap;
    }
    return rawDiscount > orderSubtotal ? orderSubtotal : rawDiscount;
  }
}

/// Fixed flat amount discount strategy.
class FixedAmountDiscountStrategy implements DiscountStrategy {
  final String couponCode;
  final double fixedAmount;
  final double minOrderAmount;
  final DateTime? startDate;
  final DateTime expiryDate;
  final bool isActive;

  const FixedAmountDiscountStrategy({
    required this.couponCode,
    required this.fixedAmount,
    required this.minOrderAmount,
    this.startDate,
    required this.expiryDate,
    required this.isActive,
  });

  @override
  String get name => 'Fixed Amount Discount ($fixedAmount EGP)';

  @override
  bool isEligible({
    required double orderSubtotal,
    DateTime? currentDate,
  }) {
    if (!isActive) return false;
    final now = currentDate ?? DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (now.isAfter(expiryDate)) return false;
    if (orderSubtotal < minOrderAmount) return false;
    return true;
  }

  @override
  double calculateDiscount({
    required double orderSubtotal,
    DateTime? currentDate,
  }) {
    if (!isEligible(orderSubtotal: orderSubtotal, currentDate: currentDate)) {
      return 0.0;
    }
    return fixedAmount > orderSubtotal ? orderSubtotal : fixedAmount;
  }
}
