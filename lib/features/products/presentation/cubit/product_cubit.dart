import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final List<ProductModel>? _filteredProducts;
  final String? _searchQuery;
  final String? _selectedCategory;
  final String? _selectedBrand;

  List<ProductModel> get filteredProducts => _filteredProducts ?? products;
  String get searchQuery => _searchQuery ?? '';
  String get selectedCategory => _selectedCategory ?? 'ALL';
  String get selectedBrand => _selectedBrand ?? 'ALL';

  const ProductLoaded({
    this.products = const [],
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    String? selectedBrand,
  })  : _filteredProducts = filteredProducts ?? products,
        _searchQuery = searchQuery ?? '',
        _selectedCategory = selectedCategory ?? 'ALL',
        _selectedBrand = selectedBrand ?? 'ALL';

  ProductLoaded copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    String? selectedBrand,
  }) {
    final p = products ?? this.products;
    return ProductLoaded(
      products: p,
      filteredProducts: filteredProducts ?? _filteredProducts ?? p,
      searchQuery: searchQuery ?? _searchQuery ?? '',
      selectedCategory: selectedCategory ?? _selectedCategory ?? 'ALL',
      selectedBrand: selectedBrand ?? _selectedBrand ?? 'ALL',
    );
  }

  @override
  List<Object?> get props => [products, filteredProducts, searchQuery, selectedCategory, selectedBrand];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository productRepository;

  ProductCubit(this.productRepository) : super(ProductInitial());

  Future<void> loadProducts() async {
    emit(ProductLoading());
    try {
      final products = await productRepository.getProducts();
      emit(ProductLoaded(products: products, filteredProducts: products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  List<ProductModel> _filterList({
    required List<ProductModel> source,
    required String query,
    required String categoryId,
    required String brandName,
  }) {
    final q = query.trim().toLowerCase();
    final cat = categoryId;
    final br = brandName;

    return source.where((p) {
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.brand.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.categoryId.toLowerCase().contains(q) ||
          p.categoryType.name.toLowerCase().contains(q) ||
          p.categoryType.displayName.toLowerCase().contains(q) ||
          p.categoryType.arabicName.toLowerCase().contains(q) ||
          p.badgeId.toLowerCase().contains(q) ||
          p.flavors.any((f) => f.toLowerCase().contains(q)) ||
          p.productVariations.any((v) =>
              v.sku.toLowerCase().contains(q) ||
              v.attributeValues.values.any((val) => val.toLowerCase().contains(q)));

      final matchesCategory = cat == 'ALL' || p.categoryId == cat;
      final matchesBrand = br == 'ALL' || p.brand.name.toLowerCase() == br.toLowerCase();

      return matchesQuery && matchesCategory && matchesBrand;
    }).toList();
  }

  void filterProducts({String? query, String? categoryId, String? brandName}) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;

    final q = (query ?? currentState.searchQuery).trim();
    final cat = categoryId ?? currentState.selectedCategory;
    final br = brandName ?? currentState.selectedBrand;

    final filtered = _filterList(
      source: currentState.products,
      query: q,
      categoryId: cat,
      brandName: br,
    );

    emit(currentState.copyWith(
      filteredProducts: filtered,
      searchQuery: q,
      selectedCategory: cat,
      selectedBrand: br,
    ));
  }

  Future<void> addProduct(ProductModel product) async {
    if (state is ProductLoaded) {
      final current = (state as ProductLoaded).products;
      final updatedList = [product, ...current.where((p) => p.id != product.id)];
      final currentState = state as ProductLoaded;
      final filtered = _filterList(
        source: updatedList,
        query: currentState.searchQuery,
        categoryId: currentState.selectedCategory,
        brandName: currentState.selectedBrand,
      );
      emit(currentState.copyWith(
        products: updatedList,
        filteredProducts: filtered,
      ));
    } else {
      emit(ProductLoaded(products: [product], filteredProducts: [product]));
    }

    try {
      await productRepository.addProduct(product);
    } catch (e) {
      await loadProducts();
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    if (state is ProductLoaded) {
      final current = (state as ProductLoaded).products;
      final updatedList = current.map((p) => p.id == product.id ? product : p).toList();
      final currentState = state as ProductLoaded;
      final filtered = _filterList(
        source: updatedList,
        query: currentState.searchQuery,
        categoryId: currentState.selectedCategory,
        brandName: currentState.selectedBrand,
      );
      emit(currentState.copyWith(
        products: updatedList,
        filteredProducts: filtered,
      ));
    } else {
      emit(ProductLoaded(products: [product], filteredProducts: [product]));
    }

    try {
      await productRepository.updateProduct(product);
    } catch (e) {
      await loadProducts();
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (state is ProductLoaded) {
      final current = (state as ProductLoaded).products;
      final updatedList = current.where((p) => p.id != productId).toList();
      final currentState = state as ProductLoaded;
      final filtered = _filterList(
        source: updatedList,
        query: currentState.searchQuery,
        categoryId: currentState.selectedCategory,
        brandName: currentState.selectedBrand,
      );
      emit(currentState.copyWith(
        products: updatedList,
        filteredProducts: filtered,
      ));
    } else {
      emit(const ProductLoaded(products: [], filteredProducts: []));
    }

    try {
      await productRepository.deleteProduct(productId);
    } catch (e) {
      await loadProducts();
    }
  }
}
