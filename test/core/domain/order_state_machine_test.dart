import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/core/domain/state_machine/order_state_machine.dart';

void main() {
  group('OrderStatus and OrderStatusStateMachine Tests', () {
    test('Parses OrderStatus from loose strings', () {
      expect(OrderStatus.fromString('PENDING'), equals(OrderStatus.pending));
      expect(OrderStatus.fromString('processing'), equals(OrderStatus.processing));
      expect(OrderStatus.fromString('shipped'), equals(OrderStatus.shipped));
      expect(OrderStatus.fromString('delivered'), equals(OrderStatus.delivered));
      expect(OrderStatus.fromString('cancelled'), equals(OrderStatus.cancelled));
      expect(OrderStatus.fromString('canceled'), equals(OrderStatus.cancelled));
      expect(OrderStatus.fromString('unknown_status'), equals(OrderStatus.pending));
    });

    test('Validates transitions according to lifecycle rules', () {
      // Pending -> Processing (valid)
      expect(
        OrderStatusStateMachine.canTransition(OrderStatus.pending, OrderStatus.processing),
        isTrue,
      );

      // Pending -> Cancelled (valid)
      expect(
        OrderStatusStateMachine.canTransition(OrderStatus.pending, OrderStatus.cancelled),
        isTrue,
      );

      // Pending -> Delivered (invalid - must be processed & shipped first)
      expect(
        OrderStatusStateMachine.canTransition(OrderStatus.pending, OrderStatus.delivered),
        isFalse,
      );

      // Processing -> Shipped (valid)
      expect(
        OrderStatusStateMachine.canTransition(OrderStatus.processing, OrderStatus.shipped),
        isTrue,
      );

      // Same status transition returns false
      expect(
        OrderStatusStateMachine.canTransition(OrderStatus.shipped, OrderStatus.shipped),
        isFalse,
      );
    });

    test('Returns correct available transitions list', () {
      final fromPending = OrderStatusStateMachine.getAvailableTransitions(OrderStatus.pending);
      expect(fromPending, contains(OrderStatus.processing));
      expect(fromPending, contains(OrderStatus.cancelled));
      expect(fromPending, isNot(contains(OrderStatus.delivered)));
    });
  });
}
