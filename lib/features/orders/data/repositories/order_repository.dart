import '../datasources/order_remote_data_source.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders();
  Stream<List<OrderModel>> getOrdersStream();
  Future<void> updateOrderStatus(String orderId, String newStatus);
  Future<void> processOrderReturn({
    required String orderId,
    required List<Map<String, dynamic>> itemsToReturn,
    required double refundAmount,
    required String reason,
    required bool restockInventory,
    required bool isFullReturn,
    String? performedBy,
  });
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({OrderRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? OrderRemoteDataSourceImpl();

  @override
  Future<List<OrderModel>> getOrders() => remoteDataSource.getOrders();

  @override
  Stream<List<OrderModel>> getOrdersStream() =>
      remoteDataSource.getOrdersStream();

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) =>
      remoteDataSource.updateOrderStatus(orderId, newStatus);

  @override
  Future<void> processOrderReturn({
    required String orderId,
    required List<Map<String, dynamic>> itemsToReturn,
    required double refundAmount,
    required String reason,
    required bool restockInventory,
    required bool isFullReturn,
    String? performedBy,
  }) =>
      remoteDataSource.processOrderReturn(
        orderId: orderId,
        itemsToReturn: itemsToReturn,
        refundAmount: refundAmount,
        reason: reason,
        restockInventory: restockInventory,
        isFullReturn: isFullReturn,
        performedBy: performedBy,
      );
}
