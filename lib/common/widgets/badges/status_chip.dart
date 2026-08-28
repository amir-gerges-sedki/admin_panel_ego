import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';

enum StatusType {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  inStock,
  lowStock,
  outOfStock,
  active,
  inactive,
}

/// Status badge adhering to UI_DESIGN_SYSTEM.md semantic status colors
class StatusChip extends StatelessWidget {
  final String label;
  final StatusType status;

  const StatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  factory StatusChip.fromOrderStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return StatusChip(label: statusStr, status: StatusType.pending);
      case 'processing':
        return StatusChip(label: statusStr, status: StatusType.processing);
      case 'shipped':
        return StatusChip(label: statusStr, status: StatusType.shipped);
      case 'delivered':
        return StatusChip(label: statusStr, status: StatusType.delivered);
      case 'cancelled':
        return StatusChip(label: statusStr, status: StatusType.cancelled);
      default:
        return StatusChip(label: statusStr, status: StatusType.processing);
    }
  }

  factory StatusChip.fromStock(int stock) {
    if (stock <= 0) {
      return const StatusChip(label: 'Out of Stock', status: StatusType.outOfStock);
    } else if (stock < 10) {
      return StatusChip(label: 'Low Stock ($stock)', status: StatusType.lowStock);
    } else {
      return StatusChip(label: 'In Stock ($stock)', status: StatusType.inStock);
    }
  }

  factory StatusChip.fromActive(bool isActive) {
    return StatusChip(
      label: isActive ? 'Active' : 'Inactive',
      status: isActive ? StatusType.active : StatusType.inactive,
    );
  }

  Color _getColor() {
    switch (status) {
      case StatusType.pending:
        return AppColor.statusPending;
      case StatusType.processing:
        return AppColor.statusProcessing;
      case StatusType.shipped:
        return AppColor.statusShipped;
      case StatusType.delivered:
      case StatusType.inStock:
      case StatusType.active:
        return AppColor.statusDelivered;
      case StatusType.lowStock:
        return AppColor.warning;
      case StatusType.cancelled:
      case StatusType.outOfStock:
      case StatusType.inactive:
        return AppColor.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm + 2, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.xs + 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
