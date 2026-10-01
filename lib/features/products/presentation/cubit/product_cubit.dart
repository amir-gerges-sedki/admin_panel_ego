import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/algorithms/search_indexer.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import 'product_form_cubit.dart';
import 'product_state.dart';

export 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository productRepository;
  final SearchIndexer<ProductModel> _searchIndexer;

  ProductCubit(this.productRepository)
      : _searchIndexer = SearchIndexer<ProductModel>(
          tokenExtractor: (p) => [
            p.id,
            p.title,
            p.brand.name,
            p.description,
            p.categoryId,
            p.categoryType.name,
            p.categoryType.displayName,
            p.categoryType.arabicName,
            p.badgeId,
            ...p.flavors,
            ...p.productVariations.map((v) => v.sku),
            ...p.productVariations.expand((v) => v.attributeValues.values),
          ],
        ),
        super(const ProductInitial());

  Future<void> loadProducts() async {
    emit(const ProductLoading());
    try {
      final products = await productRepository.getProducts();
      _searchIndexer.indexAll(products);
      GlobalFlavorsPool.harvestFromProducts(products);
      GlobalDeviceSpecsPool.harvestFromProducts(products);
      GlobalDisposableSpecsPool.harvestFromProducts(products);
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
    final q = query.trim();
    final cat = categoryId;
    final br = brandName;

    // Use fast inverted index for query matches when available on source
    final List<ProductModel> candidates = q.isNotEmpty
        ? _searchIndexer.search(q)
        : source;

    return candidates.where((p) {
      final matchesCategory = cat == 'ALL' || p.categoryId == cat;
      final matchesBrand = br == 'ALL' ||
          p.brand.name.toLowerCase() == br.toLowerCase();
      return matchesCategory && matchesBrand;
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

  void filterByBranch(String branchId) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    emit(currentState.copyWith(selectedBranchId: branchId));
  }

  Future<void> updateBranchStock({
    required String productId,
    String? variationSku,
    required String branchId,
    required int newQuantity,
  }) async {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    final productIndex = currentState.products.indexWhere((p) => p.id == productId);
    if (productIndex < 0) return;

    final originalProduct = currentState.products[productIndex];
    ProductModel updatedProduct;

    if (variationSku != null && variationSku.isNotEmpty && originalProduct.productVariations.isNotEmpty) {
      final updatedVariations = originalProduct.productVariations.map((v) {
        if (v.sku == variationSku) {
          final newMap = Map<String, int>.from(v.branchStock);
          newMap[branchId] = newQuantity;
          final totalVarStock = newMap.values.fold<int>(0, (sum, val) => sum + val);
          return v.copyWith(
            branchStock: newMap,
            stock: totalVarStock,
          );
        }
        return v;
      }).toList();

      final totalProdStock = updatedVariations.fold<int>(0, (sum, v) => sum + v.stock);
      updatedProduct = originalProduct.copyWith(
        productVariations: updatedVariations,
        stock: totalProdStock,
      );
    } else {
      final newMap = Map<String, int>.from(originalProduct.branchStock);
      newMap[branchId] = newQuantity;
      final totalProdStock = newMap.values.fold<int>(0, (sum, val) => sum + val);
      updatedProduct = originalProduct.copyWith(
        branchStock: newMap,
        stock: totalProdStock,
      );
    }

    await updateProduct(updatedProduct);
  }

  Future<void> addProduct(ProductModel product) async {
    GlobalFlavorsPool.harvestFromProducts([product]);
    GlobalDeviceSpecsPool.harvestFromProducts([product]);
    GlobalDisposableSpecsPool.harvestFromProducts([product]);
    if (state is ProductLoaded) {
      final current = (state as ProductLoaded).products;
      final updatedList = [product, ...current.where((p) => p.id != product.id)];
      _searchIndexer.indexAll(updatedList);
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
      _searchIndexer.indexItem(product);
      emit(ProductLoaded(products: [product], filteredProducts: [product]));
    }

    try {
      await productRepository.addProduct(product);
    } catch (e) {
      await loadProducts();
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    GlobalFlavorsPool.harvestFromProducts([product]);
    GlobalDeviceSpecsPool.harvestFromProducts([product]);
    GlobalDisposableSpecsPool.harvestFromProducts([product]);
    if (state is ProductLoaded) {
      final current = (state as ProductLoaded).products;
      final updatedList = current.map((p) => p.id == product.id ? product : p).toList();
      _searchIndexer.indexAll(updatedList);
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
      _searchIndexer.indexItem(product);
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
      _searchIndexer.indexAll(updatedList);
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
      _searchIndexer.clear();
      emit(const ProductLoaded(products: [], filteredProducts: []));
    }

    try {
      await productRepository.deleteProduct(productId);
    } catch (e) {
      await loadProducts();
    }
  }
}
