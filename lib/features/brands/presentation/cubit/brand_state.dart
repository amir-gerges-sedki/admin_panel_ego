import 'package:equatable/equatable.dart';
import '../../data/models/brand_model.dart';

abstract class BrandState extends Equatable {
  const BrandState();
  @override
  List<Object?> get props => [];
}

class BrandInitial extends BrandState {
  const BrandInitial();
}

class BrandLoading extends BrandState {
  const BrandLoading();
}

enum BrandSortField { sortOrder, name, productsCount, status }

class BrandLoaded extends BrandState {
  final List<BrandModel> brands;
  final List<BrandModel>? _filteredBrands;
  final String brandQuery;
  final BrandSortField sortField;
  final bool sortAscending;

  List<BrandModel> get filteredBrands => _filteredBrands ?? brands;

  const BrandLoaded({
    this.brands = const [],
    List<BrandModel>? filteredBrands,
    this.brandQuery = '',
    this.sortField = BrandSortField.sortOrder,
    this.sortAscending = true,
  }) : _filteredBrands = filteredBrands ?? brands;

  BrandLoaded copyWith({
    List<BrandModel>? brands,
    List<BrandModel>? filteredBrands,
    String? brandQuery,
    BrandSortField? sortField,
    bool? sortAscending,
  }) {
    final b = brands ?? this.brands;
    return BrandLoaded(
      brands: b,
      filteredBrands: filteredBrands ?? _filteredBrands ?? b,
      brandQuery: brandQuery ?? this.brandQuery,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [brands, filteredBrands, brandQuery, sortField, sortAscending];
}

class BrandError extends BrandState {
  final String message;
  const BrandError(this.message);
  @override
  List<Object?> get props => [message];
}
