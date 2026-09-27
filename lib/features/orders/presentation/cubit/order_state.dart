import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderLoaded extends OrderState {
  final List<OrderModel> orders;
  final List<OrderModel>? _filteredOrders;
  final String? _statusFilter;
  final String? _sourceFilter;
  final String? _searchQuery;

  List<OrderModel> get filteredOrders => _filteredOrders ?? orders;
  String get statusFilter => _statusFilter ?? 'ALL';
  String get sourceFilter => _sourceFilter ?? 'ALL'; // 'ALL', 'ONLINE', 'POS'
  String get searchQuery => _searchQuery ?? '';

  int get totalCount => orders.length;
  int get onlineCount => orders.where((o) => o.isOnlineOrder).length;
  int get posCount => orders.where((o) => o.isPosSale).length;
  int get pendingOnlineCount => orders.where((o) => o.isOnlineOrder && o.status.toLowerCase() == 'pending').length;
  int get returnedCount => orders.where((o) => o.isReturned).length;

  const OrderLoaded({
    this.orders = const [],
    List<OrderModel>? filteredOrders,
    String? statusFilter,
    String? sourceFilter,
    String? searchQuery,
  })  : _filteredOrders = filteredOrders ?? orders,
        _statusFilter = statusFilter ?? 'ALL',
        _sourceFilter = sourceFilter ?? 'ALL',
        _searchQuery = searchQuery ?? '';

  OrderLoaded copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? filteredOrders,
    String? statusFilter,
    String? sourceFilter,
    String? searchQuery,
  }) {
    final o = orders ?? this.orders;
    return OrderLoaded(
      orders: o,
      filteredOrders: filteredOrders ?? _filteredOrders ?? o,
      statusFilter: statusFilter ?? _statusFilter ?? 'ALL',
      sourceFilter: sourceFilter ?? _sourceFilter ?? 'ALL',
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [orders, filteredOrders, statusFilter, sourceFilter, searchQuery];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
