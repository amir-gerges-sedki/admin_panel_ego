import 'package:flutter/material.dart';
import '../../constant/app_colors.dart';

/// Supported canonical order statuses across EGO Admin Panel.
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  returned,
  cancelled;

  String get key => name;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get arabicName {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.processing:
        return 'قيد التجهيز';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.returned:
        return 'مرتجع';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColor.statusPending;
      case OrderStatus.processing:
        return AppColor.statusProcessing;
      case OrderStatus.shipped:
        return AppColor.statusShipped;
      case OrderStatus.delivered:
        return AppColor.statusDelivered;
      case OrderStatus.returned:
        return const Color(0xFFF97316); // Vibrant orange/amber for returns
      case OrderStatus.cancelled:
        return AppColor.statusCancelled;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.processing:
        return Icons.sync_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.returned:
        return Icons.assignment_return_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  static OrderStatus fromString(String raw) {
    final clean = raw.toLowerCase().trim();
    switch (clean) {
      case 'processing':
      case 'in_progress':
        return OrderStatus.processing;
      case 'shipped':
      case 'dispatched':
      case 'out_for_delivery':
        return OrderStatus.shipped;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'returned':
      case 'refunded':
      case 'return':
      case 'partially_returned':
      case 'مرتجع':
      case 'إرجاع':
        return OrderStatus.returned;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'ملغي':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

/// State Machine enforcing valid business transitions for Order Lifecycles.
class OrderStatusStateMachine {
  OrderStatusStateMachine._();

  /// Valid transition graph from current state to allowable next states.
  static final Map<OrderStatus, Set<OrderStatus>> _validTransitions = {
    OrderStatus.pending: {
      OrderStatus.processing,
      OrderStatus.returned,
      OrderStatus.cancelled,
    },
    OrderStatus.processing: {
      OrderStatus.shipped,
      OrderStatus.returned,
      OrderStatus.cancelled,
      OrderStatus.pending,
    },
    OrderStatus.shipped: {
      OrderStatus.delivered,
      OrderStatus.returned,
      OrderStatus.cancelled,
      OrderStatus.processing,
    },
    OrderStatus.delivered: {
      // Delivered orders can be returned (full/partial refund) or administratively adjusted
      OrderStatus.returned,
      OrderStatus.shipped,
      OrderStatus.processing,
    },
    OrderStatus.returned: {
      // Re-opening returned order if needed
      OrderStatus.delivered,
      OrderStatus.processing,
    },
    OrderStatus.cancelled: {
      // Re-opening cancelled order
      OrderStatus.pending,
      OrderStatus.processing,
    },
  };

  /// Returns true if transitioning from [fromStatus] to [toStatus] is permitted.
  static bool canTransition(OrderStatus fromStatus, OrderStatus toStatus) {
    if (fromStatus == toStatus) return false;
    final allowed = _validTransitions[fromStatus];
    return allowed?.contains(toStatus) ?? true;
  }

  /// Returns all allowable next statuses from [currentStatus].
  static List<OrderStatus> getAvailableTransitions(OrderStatus currentStatus) {
    final allowed = _validTransitions[currentStatus];
    return allowed != null ? allowed.toList() : OrderStatus.values;
  }
}
