import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final List<ProductModel>? _filteredProducts;
  final String? _searchQuery;
  final String? _selectedCategory;
  final String? _selectedBrand;
  final String? _selectedBranchId;

  List<ProductModel> get filteredProducts => _filteredProducts ?? products;
  String get searchQuery => _searchQuery ?? '';
  String get selectedCategory => _selectedCategory ?? 'ALL';
  String get selectedBrand => _selectedBrand ?? 'ALL';
  String get selectedBranchId => _selectedBranchId ?? 'all';

  const ProductLoaded({
    this.products = const [],
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    String? selectedBrand,
    String? selectedBranchId,
  })  : _filteredProducts = filteredProducts ?? products,
        _searchQuery = searchQuery ?? '',
        _selectedCategory = selectedCategory ?? 'ALL',
        _selectedBrand = selectedBrand ?? 'ALL',
        _selectedBranchId = selectedBranchId ?? 'all';

  ProductLoaded copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    String? selectedBrand,
    String? selectedBranchId,
  }) {
    final p = products ?? this.products;
    return ProductLoaded(
      products: p,
      filteredProducts: filteredProducts ?? _filteredProducts ?? p,
      searchQuery: searchQuery ?? _searchQuery ?? '',
      selectedCategory: selectedCategory ?? _selectedCategory ?? 'ALL',
      selectedBrand: selectedBrand ?? _selectedBrand ?? 'ALL',
      selectedBranchId: selectedBranchId ?? _selectedBranchId ?? 'all',
    );
  }

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        searchQuery,
        selectedCategory,
        selectedBrand,
        selectedBranchId,
      ];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
