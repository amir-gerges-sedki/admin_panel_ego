import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_state.dart';

export 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository customerRepository;
  StreamSubscription<List<CustomerModel>>? _customersSubscription;

  CustomerCubit(this.customerRepository) : super(CustomerInitial());

  Future<void> loadCustomers() async {
    emit(CustomerLoading());
    try {
      final customers = await customerRepository.getCustomers();
      final query = state is CustomerLoaded ? (state as CustomerLoaded).searchQuery : '';
      final filtered = _filterCustomersList(customers, query);
      emit(CustomerLoaded(
        customers: customers,
        filteredCustomers: filtered,
        searchQuery: query,
      ));

      // Subscribe to real-time Firestore updates
      _subscribeToCustomersStream();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _subscribeToCustomersStream() {
    _customersSubscription?.cancel();
    _customersSubscription = customerRepository.getCustomersStream().listen(
      (customers) {
        if (state is CustomerLoaded) {
          final currentState = state as CustomerLoaded;
          final query = currentState.searchQuery;
          final filtered = _filterCustomersList(customers, query);
          emit(currentState.copyWith(
            customers: customers,
            filteredCustomers: filtered,
          ));
        } else {
          emit(CustomerLoaded(
            customers: customers,
            filteredCustomers: customers,
          ));
        }
      },
      onError: (e) {
        debugPrint('Customers stream error: $e');
      },
    );
  }

  Stream<CustomerModel?> watchCustomer(CustomerModel initialCustomer) {
    return customerRepository.watchCustomer(initialCustomer);
  }

  void updateCustomerLocally(CustomerModel updatedCustomer) {
    if (state is! CustomerLoaded) return;
    final currentState = state as CustomerLoaded;

    final updatedList = currentState.customers.map((c) {
      return c.id == updatedCustomer.id ? updatedCustomer : c;
    }).toList();

    final filtered = _filterCustomersList(updatedList, currentState.searchQuery);
    emit(currentState.copyWith(
      customers: updatedList,
      filteredCustomers: filtered,
    ));
  }

  void filterCustomers(String query) {
    if (state is! CustomerLoaded) return;
    final currentState = state as CustomerLoaded;
    final q = query.trim();

    final filtered = _filterCustomersList(currentState.customers, q);
    emit(currentState.copyWith(
      filteredCustomers: filtered,
      searchQuery: q,
    ));
  }

  List<CustomerModel> _filterCustomersList(List<CustomerModel> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          c.role.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> close() {
    _customersSubscription?.cancel();
    return super.close();
  }
}
