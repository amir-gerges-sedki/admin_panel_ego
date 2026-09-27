import 'package:flutter/foundation.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getCustomers();
  Stream<List<CustomerModel>> getCustomersStream();
  Stream<CustomerModel?> watchCustomer(CustomerModel initialCustomer);
}

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  final Map<String, int> _orderCountsByUid = {};
  final Map<String, double> _orderSpentByUid = {};
  final Map<String, int> _orderCountsByEmail = {};
  final Map<String, double> _orderSpentByEmail = {};

  CustomerRepositoryImpl({CustomerRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? CustomerRemoteDataSourceImpl();

  void _aggregateOrders(List<Map<String, dynamic>> rawOrders) {
    _orderCountsByUid.clear();
    _orderSpentByUid.clear();
    _orderCountsByEmail.clear();
    _orderSpentByEmail.clear();

    for (final data in rawOrders) {
      final status = (data['status'] ?? data['orderStatus'] ?? data['Status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      if (status != 'delivered') continue;

      final uid = (data['userId'] ?? data['customerId'] ?? data['uid'] ?? '').toString().trim();
      final email = (data['customerEmail'] ?? data['email'] ?? data['userEmail'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      final amount = (data['totalPrice'] ??
              data['totalAmount'] ??
              data['total'] ??
              data['subTotal'] as num?)
          ?.toDouble() ??
          0.0;

      if (uid.isNotEmpty && uid != 'guest') {
        _orderCountsByUid[uid] = (_orderCountsByUid[uid] ?? 0) + 1;
        _orderSpentByUid[uid] = (_orderSpentByUid[uid] ?? 0.0) + amount;
      }

      if (email.isNotEmpty) {
        _orderCountsByEmail[email] = (_orderCountsByEmail[email] ?? 0) + 1;
        _orderSpentByEmail[email] = (_orderSpentByEmail[email] ?? 0.0) + amount;
      }
    }
  }

  List<CustomerModel> _mapRawUsersToCustomers(List<Map<String, dynamic>> rawUsers) {
    return rawUsers.map((rawUser) {
      final data = Map<String, dynamic>.from(rawUser);
      final id = data['id']?.toString() ?? '';
      final email = (data['email'] ?? '').toString().toLowerCase().trim();

      final ordersFromUid = id.isNotEmpty ? (_orderCountsByUid[id] ?? 0) : 0;
      final ordersFromEmail = email.isNotEmpty ? (_orderCountsByEmail[email] ?? 0) : 0;
      final computedOrders = ordersFromUid > 0 ? ordersFromUid : ordersFromEmail;

      final spentFromUid = id.isNotEmpty ? (_orderSpentByUid[id] ?? 0.0) : 0.0;
      final spentFromEmail = email.isNotEmpty ? (_orderSpentByEmail[email] ?? 0.0) : 0.0;
      final computedSpent = spentFromUid > 0 ? spentFromUid : spentFromEmail;

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
}
