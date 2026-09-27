import '../../../products/data/models/product_model.dart';
import '../../data/models/dashboard_analytics_model.dart';

class CatalogAnalyticsResult {
  final int lowStockAlertsCount;
  final List<BrandShareData> brandShares;

  const CatalogAnalyticsResult({
    required this.lowStockAlertsCount,
    required this.brandShares,
  });
}

/// Single Responsibility Calculator for catalog stock alerts and brand market shares using strongly-typed ProductModel.
class CatalogAnalyticsCalculator {
  const CatalogAnalyticsCalculator();

  CatalogAnalyticsResult calculate({
    required List<ProductModel> products,
    int lowStockThreshold = 10,
  }) {
    int lowStockCount = 0;
    final Map<String, int> brandCountMap = {};

    for (final product in products) {
      if (product.stock <= lowStockThreshold) lowStockCount++;

      final brandName = product.brand.name.trim().isNotEmpty
          ? product.brand.name.trim()
          : 'Other';
      brandCountMap[brandName] = (brandCountMap[brandName] ?? 0) + 1;
    }

    final totalProducts = products.isEmpty ? 1 : products.length;
    final brandShares = brandCountMap.entries.map((e) {
      return BrandShareData(
        brandName: e.key,
        sharePercentage: (e.value / totalProducts) * 100,
        totalSold: e.value,
      );
    }).toList();

    return CatalogAnalyticsResult(
      lowStockAlertsCount: lowStockCount,
      brandShares: brandShares,
    );
  }
}
