import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final List<CustomerModel>? _filteredCustomers;
  final String? _searchQuery;

  List<CustomerModel> get filteredCustomers => _filteredCustomers ?? customers;
  String get searchQuery => _searchQuery ?? '';

  const CustomerLoaded({
    this.customers = const [],
    List<CustomerModel>? filteredCustomers,
    String? searchQuery,
  })  : _filteredCustomers = filteredCustomers ?? customers,
        _searchQuery = searchQuery ?? '';

  CustomerLoaded copyWith({
    List<CustomerModel>? customers,
    List<CustomerModel>? filteredCustomers,
    String? searchQuery,
  }) {
    final c = customers ?? this.customers;
    return CustomerLoaded(
      customers: c,
      filteredCustomers: filteredCustomers ?? _filteredCustomers ?? c,
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [customers, filteredCustomers, searchQuery];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);
  @override
  List<Object?> get props => [message];
}

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository customerRepository;

  CustomerCubit(this.customerRepository) : super(CustomerInitial());

  Future<void> loadCustomers() async {
    emit(CustomerLoading());
    try {
      final customers = await customerRepository.getCustomers();
      emit(CustomerLoaded(customers: customers, filteredCustomers: customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void filterCustomers(String query) {
    if (state is! CustomerLoaded) return;
    final currentState = state as CustomerLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.customers.where((c) {
      return q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          c.role.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredCustomers: filtered,
      searchQuery: query.trim(),
    ));
  }
}
