import 'package:flutter/material.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/domain/state_machine/order_state_machine.dart';

class OrderStatusDispatcher extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusSelected;

  const OrderStatusDispatcher({
    super.key,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final current = OrderStatus.fromString(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispatcher Workflow Action (Updates Status & Pushes FCM Alert):',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrderStatus.values.map((status) {
            final isCurrent = current == status;
            final color = status.color;
            final canTransition = OrderStatusStateMachine.canTransition(current, status);

            return OutlinedButton.icon(
              onPressed: (isCurrent || !canTransition)
                  ? null
                  : () => onStatusSelected(status.displayName),
              icon: Icon(status.icon, size: 14, color: isCurrent ? color : null),
              label: Text(status.displayName, style: const TextStyle(fontSize: 11.5)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: isCurrent ? color : null,
                side: BorderSide(
                  color: isCurrent ? color : color.withValues(alpha: 0.35),
                  width: isCurrent ? 2 : 1,
                ),
                backgroundColor: isCurrent ? color.withValues(alpha: 0.12) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
