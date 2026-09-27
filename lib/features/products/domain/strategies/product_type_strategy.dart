import '../../data/models/product_model.dart';
import '../../presentation/cubit/product_form_cubit.dart';
import 'accessory_type_strategy.dart';
import 'coils_pods_type_strategy.dart';
import 'device_type_strategy.dart';
import 'disposable_type_strategy.dart';
import 'liquid_type_strategy.dart';

/// Strategy interface encapsulating all product-category-specific business logic,
/// variations generation, specifications extraction, and attribute building (Open/Closed Principle).
abstract class ProductTypeStrategy {
  ProductCategoryType get categoryType;

  /// Default category ID used in database queries and taxonomy
  String resolveCategoryId(ProductFormState state);

  /// Builds product attributes strictly adhering to this category's taxonomy
  List<ProductAttribute> buildProductAttributes(ProductFormState state);

  /// Builds specifications map persisted in Firestore
  Map<String, dynamic> buildSpecifications(ProductFormState state);

  /// Generates dynamic product variations / matrix using combinatorial algorithms
  List<ProductVariationModel> generateVariations(ProductFormState state);

  /// Resolves the canonical product title (e.g. Empty for Liquids which derive from Brand & Flavor)
  String resolveTitle(ProductFormState state);

  /// Factory method to obtain strategy by ProductCategoryType
  static ProductTypeStrategy forType(ProductCategoryType type) {
    switch (type) {
      case ProductCategoryType.liquid:
        return const LiquidTypeStrategy();
      case ProductCategoryType.disposable:
        return const DisposableTypeStrategy();
      case ProductCategoryType.device:
        return const DeviceTypeStrategy();
      case ProductCategoryType.pod:
      case ProductCategoryType.coil:
        return const CoilsPodsTypeStrategy();
      case ProductCategoryType.accessory:
        return const AccessoryTypeStrategy();
    }
  }
}
