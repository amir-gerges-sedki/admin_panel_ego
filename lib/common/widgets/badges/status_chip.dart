import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/localization/app_localizations.dart';

enum StatusType {
  pending,
  processing,
  shipped,
  delivered,
  returned,
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
    switch (statusStr.toLowerCase().trim()) {
      case 'pending':
        return StatusChip(label: statusStr, status: StatusType.pending);
      case 'processing':
      case 'in_progress':
        return StatusChip(label: statusStr, status: StatusType.processing);
      case 'shipped':
      case 'dispatched':
      case 'out_for_delivery':
        return StatusChip(label: statusStr, status: StatusType.shipped);
      case 'delivered':
      case 'completed':
        return StatusChip(label: statusStr, status: StatusType.delivered);
      case 'returned':
      case 'refunded':
      case 'return':
      case 'partially_returned':
      case 'مرتجع':
      case 'إرجاع':
        return StatusChip(label: statusStr.isEmpty ? 'Returned' : statusStr, status: StatusType.returned);
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'ملغي':
        return StatusChip(label: statusStr, status: StatusType.cancelled);
      default:
        return StatusChip(label: statusStr, status: StatusType.processing);
    }
  }

  factory StatusChip.fromStock(int stock) {
    if (stock <= 0) {
      return StatusChip(label: 'out_of_stock'.tr, status: StatusType.outOfStock);
    } else if (stock < 10) {
      return StatusChip(label: '${'low_stock'.tr} ($stock)', status: StatusType.lowStock);
    } else {
      return StatusChip(label: '${'in_stock'.tr} ($stock)', status: StatusType.inStock);
    }
  }

  factory StatusChip.fromActive(bool isActive) {
    return StatusChip(
      label: isActive ? 'active'.tr : 'inactive'.tr,
      status: isActive ? StatusType.active : StatusType.inactive,
    );
  }

  factory StatusChip.fromCoupon({
    required bool isActive,
    required bool isExpired,
    bool isStarted = true,
  }) {
    if (!isActive) {
      return StatusChip(label: 'inactive'.tr, status: StatusType.inactive);
    }
    if (isExpired) {
      return StatusChip(label: 'expired'.tr, status: StatusType.cancelled);
    }
    if (!isStarted) {
      return StatusChip(label: 'scheduled'.tr, status: StatusType.pending);
    }
    return StatusChip(label: 'active'.tr, status: StatusType.active);
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
      case StatusType.returned:
        return const Color(0xFFF97316); // Vibrant orange/amber for returns
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
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
