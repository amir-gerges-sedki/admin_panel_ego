import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/algorithms/search_indexer.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import 'order_state.dart';

export 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository orderRepository;
  final SearchIndexer<OrderModel> _searchIndexer;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  final Set<String> _knownOrderIds = {};
  bool _isInitialLoad = true;

  OrderCubit(this.orderRepository)
      : _searchIndexer = SearchIndexer<OrderModel>(
          tokenExtractor: (o) => [
            o.id,
            o.shippingAddress.name,
            o.shippingAddress.phoneNumber,
            o.shippingAddress.alternatePhone,
            o.shippingAddress.city,
            o.shippingAddress.governorate,
            o.shippingAddress.street,
            o.paymentMethod,
            o.paymentStatus,
            o.status,
            ...o.items.map((i) => i.title),
            ...o.items.map((i) => i.productId),
            ...o.items.expand((i) => i.selectedVariation.values),
          ],
        ),
        super(const OrderInitial());

  Future<void> loadOrders() async {
    emit(const OrderLoading());
    try {
      final orders = await orderRepository.getOrders();
      _searchIndexer.indexAll(orders);
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
        _searchIndexer.indexAll(orders);

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
            sourceFilter: currentState.sourceFilter,
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
    if (order.isPosSale) return; // Do not alert for in-store physical POS sales done by local cashier
    HelperFun.showNotificationAlert(
      title: '🛍️ طلب أونلاين جديد #${order.id}',
      message: 'العميل: ${order.shippingAddress.name.isNotEmpty ? order.shippingAddress.name : 'عميل EGO'} • ${order.totalAmount} ج.م • (${order.items.length} منتج)',
    );
  }

  List<OrderModel> _filterList({
    required List<OrderModel> source,
    required String status,
    required String sourceFilter,
    required String query,
  }) {
    final s = status;
    final sf = sourceFilter;
    final q = query.trim();

    // Use fast inverted index for query matches when available on source
    final List<OrderModel> candidates = q.isNotEmpty
        ? _searchIndexer.search(q)
        : source;

    return candidates.where((o) {
      final matchesStatus = s == 'ALL' || o.status.toLowerCase() == s.toLowerCase();
      final matchesSource = sf == 'ALL' ||
          (sf == 'ONLINE' && o.isOnlineOrder) ||
          (sf == 'POS' && o.isPosSale);
      return matchesStatus && matchesSource;
    }).toList();
  }

  void filterOrders({String? status, String? sourceFilter, String? query}) {
    if (state is! OrderLoaded) return;
    final currentState = state as OrderLoaded;

    final s = status ?? currentState.statusFilter;
    final sf = sourceFilter ?? currentState.sourceFilter;
    final q = (query ?? currentState.searchQuery).trim();

    final filtered = _filterList(
      source: currentState.orders,
      status: s,
      sourceFilter: sf,
      query: q,
    );

    emit(currentState.copyWith(
      filteredOrders: filtered,
      statusFilter: s,
      sourceFilter: sf,
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

  /// Bulk update status for multiple selected orders with notification dispatch
  Future<bool> updateMultipleStatuses(List<String> orderIds, String newStatus) async {
    if (orderIds.isEmpty) return false;
    try {
      int successCount = 0;
      for (final id in orderIds) {
        try {
          await orderRepository.updateOrderStatus(id, newStatus);
          successCount++;
        } catch (e) {
          debugPrint('Error updating order $id in bulk: $e');
        }
      }
      await loadOrders();
      HelperFun.successSnackbar(
        'order_status_updated'.tr,
        'bulk_update_success'.trParams({'count': '$successCount'}),
      );
      return successCount > 0;
    } catch (e) {
      HelperFun.errorSnackbar(
        title: 'error'.tr,
        message: 'فشل تحديث حالة الطلبات المحددة: $e',
      );
      return false;
    }
  }

  /// Process full or partial return with automatic stock restoration and customer notification
  Future<bool> processReturn({
    required String orderId,
    required List<Map<String, dynamic>> itemsToReturn,
    required double refundAmount,
    required String reason,
    required bool restockInventory,
    required bool isFullReturn,
    String? performedBy,
  }) async {
    try {
      await orderRepository.processOrderReturn(
        orderId: orderId,
        itemsToReturn: itemsToReturn,
        refundAmount: refundAmount,
        reason: reason,
        restockInventory: restockInventory,
        isFullReturn: isFullReturn,
        performedBy: performedBy,
      );
      await loadOrders();
      HelperFun.successSnackbar(
        'تم تسجيل المرتجع بنجاح',
        'تم استرجاع الأصناف للطلب #$orderId وتحديث المخزون بنجاح',
      );
      return true;
    } catch (e) {
      HelperFun.errorSnackbar(
        title: 'error'.tr,
        message: 'فشل معالجة المرتجع: $e',
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
