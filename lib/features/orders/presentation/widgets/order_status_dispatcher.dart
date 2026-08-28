import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';

class OrderStatusDispatcher extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusSelected;

  const OrderStatusDispatcher({
    super.key,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  static const List<Map<String, dynamic>> _statuses = [
    {'name': 'Pending', 'color': AppColor.statusPending, 'icon': Icons.hourglass_top_rounded},
    {'name': 'Processing', 'color': AppColor.statusProcessing, 'icon': Icons.sync_rounded},
    {'name': 'Shipped', 'color': AppColor.statusShipped, 'icon': Icons.local_shipping_rounded},
    {'name': 'Delivered', 'color': AppColor.statusDelivered, 'icon': Icons.check_circle_rounded},
    {'name': 'Cancelled', 'color': AppColor.statusCancelled, 'icon': Icons.cancel_rounded},
  ];

  @override
  Widget build(BuildContext context) {
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
          children: _statuses.map((s) {
            final isCurrent = currentStatus.toLowerCase() == (s['name'] as String).toLowerCase();
            final color = s['color'] as Color;

            return OutlinedButton.icon(
              onPressed: isCurrent
                  ? null
                  : () {
                      onStatusSelected(s['name'] as String);
                      HelperFun.successSnackbar(
                        'Order Updated',
                        'Status shifted to ${s['name']}. FCM notification dispatched to user phone.',
                      );
                    },
              icon: Icon(s['icon'] as IconData, size: 16, color: isCurrent ? color : null),
              label: Text(s['name'] as String),
              style: OutlinedButton.styleFrom(
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
