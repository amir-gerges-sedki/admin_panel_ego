import 'package:equatable/equatable.dart';
import '../../data/models/customer_model.dart';

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
