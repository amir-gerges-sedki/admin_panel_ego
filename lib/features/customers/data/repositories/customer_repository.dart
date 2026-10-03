import 'package:flutter/foundation.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getCustomers();
  Stream<List<CustomerModel>> getCustomersStream();
  Stream<CustomerModel?> watchCustomer(CustomerModel initialCustomer);
  Future<CustomerModel?> findCustomerByPhone(String phone);
  Future<void> updateCustomerPoints({
    required String customerId,
    required int pointsDelta,
    String? reason,
  });
}

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  final Map<String, int> _orderCountsByUid = {};
  final Map<String, double> _orderSpentByUid = {};
  final Map<String, int> _orderCountsByEmail = {};
  final Map<String, double> _orderSpentByEmail = {};
  final Map<String, int> _orderCountsByPhone = {};
  final Map<String, double> _orderSpentByPhone = {};

  CustomerRepositoryImpl({CustomerRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? CustomerRemoteDataSourceImpl();

  void _aggregateOrders(List<Map<String, dynamic>> rawOrders) {
    _orderCountsByUid.clear();
    _orderSpentByUid.clear();
    _orderCountsByEmail.clear();
    _orderSpentByEmail.clear();
    _orderCountsByPhone.clear();
    _orderSpentByPhone.clear();

    for (final data in rawOrders) {
      final status = (data['status'] ?? data['orderStatus'] ?? data['Status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      if (status != 'delivered' && status != 'completed') continue;

      final uid = (data['customerId'] ?? data['userId'] ?? data['uid'] ?? '').toString().trim();
      final email = (data['customerEmail'] ?? data['email'] ?? data['userEmail'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final phone = (data['customerPhone'] ??
              data['phone'] ??
              (data['shippingAddress'] is Map ? data['shippingAddress']['phoneNumber'] : ''))
          .toString()
          .replaceAll(RegExp(r'\s+|-'), '')
          .trim();

      final amount = (data['totalPrice'] ??
              data['totalAmount'] ??
              data['total'] ??
              data['subTotal'] as num?)
          ?.toDouble() ??
          0.0;

      if (uid.isNotEmpty && uid != 'guest' && uid != 'pos_cashier') {
        _orderCountsByUid[uid] = (_orderCountsByUid[uid] ?? 0) + 1;
        _orderSpentByUid[uid] = (_orderSpentByUid[uid] ?? 0.0) + amount;
      }

      if (email.isNotEmpty && !email.contains('walkin.customer') && !email.contains('pos_instore')) {
        _orderCountsByEmail[email] = (_orderCountsByEmail[email] ?? 0) + 1;
        _orderSpentByEmail[email] = (_orderSpentByEmail[email] ?? 0.0) + amount;
      }

      if (phone.isNotEmpty) {
        _orderCountsByPhone[phone] = (_orderCountsByPhone[phone] ?? 0) + 1;
        _orderSpentByPhone[phone] = (_orderSpentByPhone[phone] ?? 0.0) + amount;
      }
    }
  }

  List<CustomerModel> _mapRawUsersToCustomers(List<Map<String, dynamic>> rawUsers) {
    return rawUsers.map((rawUser) {
      final data = Map<String, dynamic>.from(rawUser);
      final id = data['id']?.toString() ?? '';
      final email = (data['email'] ?? '').toString().toLowerCase().trim();
      final phone = (data['phone'] ?? data['phoneNumber'] ?? data['PhoneNumber'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+|-'), '')
          .trim();

      final ordersFromUid = id.isNotEmpty ? (_orderCountsByUid[id] ?? 0) : 0;
      final ordersFromEmail = email.isNotEmpty ? (_orderCountsByEmail[email] ?? 0) : 0;
      final ordersFromPhone = phone.isNotEmpty ? (_orderCountsByPhone[phone] ?? 0) : 0;
      final docOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;

      final computedOrders = ordersFromPhone > 0
          ? ordersFromPhone
          : (ordersFromUid > 0 ? ordersFromUid : (ordersFromEmail > 0 ? ordersFromEmail : docOrders));

      final spentFromUid = id.isNotEmpty ? (_orderSpentByUid[id] ?? 0.0) : 0.0;
      final spentFromEmail = email.isNotEmpty ? (_orderSpentByEmail[email] ?? 0.0) : 0.0;
      final spentFromPhone = phone.isNotEmpty ? (_orderSpentByPhone[phone] ?? 0.0) : 0.0;
      final docSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;

      final computedSpent = spentFromPhone > 0
          ? spentFromPhone
          : (spentFromUid > 0 ? spentFromUid : (spentFromEmail > 0 ? spentFromEmail : docSpent));

      data['totalOrders'] = computedOrders;
      data['totalSpent'] = computedSpent;

      return CustomerModel.fromJson(data);
    }).toList();
  }

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final results = await Future.wait([
        remoteDataSource.getRawUsers(),
        remoteDataSource.getRawOrders(),
      ]);

      _aggregateOrders(results[1]);
      return _mapRawUsersToCustomers(results[0]);
    } catch (e) {
      debugPrint('Customers get error: $e');
      return [];
    }
  }

  @override
  Stream<List<CustomerModel>> getCustomersStream() {
    return remoteDataSource.watchRawUsers().map((rawUsers) {
      return _mapRawUsersToCustomers(rawUsers);
    });
  }

  @override
  Stream<CustomerModel?> watchCustomer(CustomerModel initialCustomer) {
    return remoteDataSource.watchRawUser(initialCustomer.id).map((rawUser) {
      if (rawUser == null) return null;
      final updated = CustomerModel.fromJson(rawUser);
      return updated.copyWith(
        totalOrders: initialCustomer.totalOrders,
        totalSpent: initialCustomer.totalSpent,
      );
    });
  }

  @override
  Future<CustomerModel?> findCustomerByPhone(String phone) async {
    final raw = await remoteDataSource.findUserByPhone(phone);
    if (raw == null) return null;
    return CustomerModel.fromJson(raw);
  }

  @override
  Future<void> updateCustomerPoints({
    required String customerId,
    required int pointsDelta,
    String? reason,
  }) {
    return remoteDataSource.updateCustomerPoints(
      userId: customerId,
      pointsDelta: pointsDelta,
      reason: reason,
    );
  }
}
