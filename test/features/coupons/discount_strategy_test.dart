import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/coupons/domain/discount_strategy.dart';

void main() {
  group('DiscountStrategy Polymorphic Evaluation Tests', () {
    test('PercentageDiscountStrategy calculates correct discount percentage', () {
      final strategy = PercentageDiscountStrategy(
        couponCode: 'SAVE20',
        discountPercentage: 20.0,
        minOrderAmount: 200.0,
        expiryDate: DateTime(2026, 12, 31),
        isActive: true,
      );

      // Below minOrderAmount: Not eligible, 0 discount
      expect(strategy.isEligible(orderSubtotal: 150.0), isFalse);
      expect(strategy.calculateDiscount(orderSubtotal: 150.0), equals(0.0));

      // Above minOrderAmount: 20% of 500 = 100
      expect(strategy.isEligible(orderSubtotal: 500.0), isTrue);
      expect(strategy.calculateDiscount(orderSubtotal: 500.0), equals(100.0));
    });

    test('PercentageDiscountStrategy respects max discount cap and active status', () {
      final cappedStrategy = PercentageDiscountStrategy(
        couponCode: 'SUPER50',
        discountPercentage: 50.0,
        minOrderAmount: 100.0,
        expiryDate: DateTime(2026, 12, 31),
        isActive: true,
        maxDiscountCap: 150.0,
      );

      // 50% of 1000 = 500, capped at 150
      expect(cappedStrategy.calculateDiscount(orderSubtotal: 1000.0), equals(150.0));

      final inactiveStrategy = PercentageDiscountStrategy(
        couponCode: 'INACTIVE',
        discountPercentage: 20.0,
        minOrderAmount: 100.0,
        expiryDate: DateTime(2026, 12, 31),
        isActive: false,
      );
      expect(inactiveStrategy.calculateDiscount(orderSubtotal: 500.0), equals(0.0));
    });

    test('FixedAmountDiscountStrategy deducts fixed amount with bounds checking', () {
      final fixedStrategy = FixedAmountDiscountStrategy(
        couponCode: 'FLAT50',
        fixedAmount: 50.0,
        minOrderAmount: 100.0,
        expiryDate: DateTime(2026, 12, 31),
        isActive: true,
      );

      expect(fixedStrategy.calculateDiscount(orderSubtotal: 200.0), equals(50.0));

      // Cannot discount more than subtotal
      final smallSubtotalStrategy = FixedAmountDiscountStrategy(
        couponCode: 'FLAT50',
        fixedAmount: 50.0,
        minOrderAmount: 0.0,
        expiryDate: DateTime(2026, 12, 31),
        isActive: true,
      );
      expect(smallSubtotalStrategy.calculateDiscount(orderSubtotal: 30.0), equals(30.0));
    });
  });
}
