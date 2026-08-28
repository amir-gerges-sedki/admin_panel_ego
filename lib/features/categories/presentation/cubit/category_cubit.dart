import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final List<CategoryModel>? _filteredCategories;
  final List<BrandModel> brands;
  final List<BrandModel>? _filteredBrands;
  final String categoryQuery;
  final String brandQuery;

  List<CategoryModel> get filteredCategories => _filteredCategories ?? categories;
  List<BrandModel> get filteredBrands => _filteredBrands ?? brands;

  const CategoryLoaded({
    this.categories = const [],
    List<CategoryModel>? filteredCategories,
    this.brands = const [],
    List<BrandModel>? filteredBrands,
    this.categoryQuery = '',
    this.brandQuery = '',
  })  : _filteredCategories = filteredCategories ?? categories,
        _filteredBrands = filteredBrands ?? brands;

  CategoryLoaded copyWith({
    List<CategoryModel>? categories,
    List<CategoryModel>? filteredCategories,
    List<BrandModel>? brands,
    List<BrandModel>? filteredBrands,
    String? categoryQuery,
    String? brandQuery,
  }) {
    final c = categories ?? this.categories;
    final b = brands ?? this.brands;
    return CategoryLoaded(
      categories: c,
      filteredCategories: filteredCategories ?? _filteredCategories ?? c,
      brands: b,
      filteredBrands: filteredBrands ?? _filteredBrands ?? b,
      categoryQuery: categoryQuery ?? this.categoryQuery,
      brandQuery: brandQuery ?? this.brandQuery,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        filteredCategories,
        brands,
        filteredBrands,
        categoryQuery,
        brandQuery,
      ];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryCubit(this.categoryRepository) : super(CategoryInitial());

  Future<void> loadData() async {
    emit(CategoryLoading());
    try {
      final categories = await categoryRepository.getCategories();
      final brands = await categoryRepository.getBrands();
      emit(CategoryLoaded(
        categories: categories,
        filteredCategories: categories,
        brands: brands,
        filteredBrands: brands,
      ));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  void filterCategories(String query) {
    if (state is! CategoryLoaded) return;
    final currentState = state as CategoryLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.categories.where((c) {
      return q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredCategories: filtered,
      categoryQuery: query.trim(),
    ));
  }

  void filterBrands(String query) {
    if (state is! CategoryLoaded) return;
    final currentState = state as CategoryLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.brands.where((b) {
      return q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredBrands: filtered,
      brandQuery: query.trim(),
    ));
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await categoryRepository.addCategory(category);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await categoryRepository.updateCategory(category);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await categoryRepository.deleteCategory(categoryId);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> addBrand(BrandModel brand) async {
    try {
      await categoryRepository.addBrand(brand);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> updateBrand(BrandModel brand) async {
    try {
      await categoryRepository.updateBrand(brand);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> deleteBrand(String brandId) async {
    try {
      await categoryRepository.deleteBrand(brandId);
      await loadData();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
