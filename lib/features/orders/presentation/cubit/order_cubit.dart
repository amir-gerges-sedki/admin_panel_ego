import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderLoaded extends OrderState {
  final List<OrderModel> orders;
  final List<OrderModel>? _filteredOrders;
  final String? _statusFilter;
  final String? _searchQuery;

  List<OrderModel> get filteredOrders => _filteredOrders ?? orders;
  String get statusFilter => _statusFilter ?? 'ALL';
  String get searchQuery => _searchQuery ?? '';

  const OrderLoaded({
    this.orders = const [],
    List<OrderModel>? filteredOrders,
    String? statusFilter,
    String? searchQuery,
  })  : _filteredOrders = filteredOrders ?? orders,
        _statusFilter = statusFilter ?? 'ALL',
        _searchQuery = searchQuery ?? '';

  OrderLoaded copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? filteredOrders,
    String? statusFilter,
    String? searchQuery,
  }) {
    final o = orders ?? this.orders;
    return OrderLoaded(
      orders: o,
      filteredOrders: filteredOrders ?? _filteredOrders ?? o,
      statusFilter: statusFilter ?? _statusFilter ?? 'ALL',
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [orders, filteredOrders, statusFilter, searchQuery];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository orderRepository;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  final Set<String> _knownOrderIds = {};
  bool _isInitialLoad = true;

  OrderCubit(this.orderRepository) : super(OrderInitial());

  Future<void> loadOrders() async {
    emit(OrderLoading());
    try {
      final orders = await orderRepository.getOrders();
      _knownOrderIds.addAll(orders.map((o) => o.id));
      _isInitialLoad = false;
      emit(OrderLoaded(orders: orders, filteredOrders: orders));

      // Start listening to real-time incoming orders stream
      _subscribeToOrdersStream();
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  void _subscribeToOrdersStream() {
    _ordersSubscription?.cancel();
    _ordersSubscription = orderRepository.getOrdersStream().listen(
      (orders) {
        if (_isInitialLoad) {
          _knownOrderIds.addAll(orders.map((o) => o.id));
          _isInitialLoad = false;
          return;
        }

        // Check for new incoming orders
        for (final order in orders) {
          if (!_knownOrderIds.contains(order.id)) {
            _knownOrderIds.add(order.id);
            _onNewIncomingOrder(order);
          }
        }

        if (state is OrderLoaded) {
          final currentState = state as OrderLoaded;
          final filtered = _filterList(
            source: orders,
            status: currentState.statusFilter,
            query: currentState.searchQuery,
          );
          emit(currentState.copyWith(
            orders: orders,
            filteredOrders: filtered,
          ));
        } else {
          emit(OrderLoaded(orders: orders, filteredOrders: orders));
        }
      },
      onError: (e) {
        debugPrint('Order stream error: $e');
      },
    );
  }

  /// Trigger alert banner & sound in Admin Panel for incoming order
  void _onNewIncomingOrder(OrderModel order) {
    // Play sound chime and show floating notification banner in Admin Panel
    HelperFun.showNotificationAlert(
      title: '🛍️ طلب جديد #${order.id}',
      message: 'العميل: ${order.shippingAddress.name.isNotEmpty ? order.shippingAddress.name : 'عميل EGO'} • ${order.totalAmount} ج.م • (${order.items.length} منتج)',
    );
  }

  List<OrderModel> _filterList({
    required List<OrderModel> source,
    required String status,
    required String query,
  }) {
    final s = status;
    final q = query.trim().toLowerCase();

    return source.where((o) {
      final matchesStatus = s == 'ALL' || o.status.toLowerCase() == s.toLowerCase();
      final matchesQuery = q.isEmpty ||
          o.id.toLowerCase().contains(q) ||
          o.shippingAddress.name.toLowerCase().contains(q) ||
          o.shippingAddress.phoneNumber.toLowerCase().contains(q) ||
          o.shippingAddress.city.toLowerCase().contains(q) ||
          o.shippingAddress.street.toLowerCase().contains(q) ||
          o.paymentMethod.toLowerCase().contains(q) ||
          o.status.toLowerCase().contains(q) ||
          o.items.any((item) =>
              item.title.toLowerCase().contains(q) ||
              item.productId.toLowerCase().contains(q) ||
              item.selectedVariation.values.any((v) => v.toLowerCase().contains(q)));
      return matchesStatus && matchesQuery;
    }).toList();
  }

  void filterOrders({String? status, String? query}) {
    if (state is! OrderLoaded) return;
    final currentState = state as OrderLoaded;

    final s = status ?? currentState.statusFilter;
    final q = (query ?? currentState.searchQuery).trim();

    final filtered = _filterList(
      source: currentState.orders,
      status: s,
      query: q,
    );

    emit(currentState.copyWith(
      filteredOrders: filtered,
      statusFilter: s,
      searchQuery: q,
    ));
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      await orderRepository.updateOrderStatus(orderId, newStatus);
      await loadOrders();
      HelperFun.successSnackbar(
        'order_status_updated'.tr,
        'تم تحديث حالة الطلب #$orderId وإرسال الإشعار للعميل بنجاح',
      );
    } catch (e) {
      HelperFun.errorSnackbar(
        title: 'error'.tr,
        message: 'فشل تحديث حالة الطلب: $e',
      );
      emit(OrderError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
