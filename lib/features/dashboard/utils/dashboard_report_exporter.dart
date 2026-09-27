import 'package:intl/intl.dart';
import '../../orders/data/models/order_model.dart';
import '../../products/data/models/product_model.dart';
import '../data/models/dashboard_analytics_model.dart';
import 'stub_file_saver.dart'
    if (dart.library.js_interop) 'web_file_saver.dart' as file_saver;

class DashboardReportExporter {
  DashboardReportExporter._();

  static String _escape(dynamic val) {
    if (val == null) return '""';
    final str = val.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Formats a DateTime for CSV display
  static String _formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  /// Timestamp for file names
  static String _fileTimestamp() {
    return DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
  }

  /// 1. Executive Summary Report (KPIs, Trend, Brand Share)
  static String generateExecutiveSummaryCsv({
    required DashboardAnalyticsModel analytics,
    int lowStockThreshold = 10,
  }) {
    final buffer = StringBuffer();
    final generatedAt = _formatDate(DateTime.now());

    buffer.writeln('=== EGO STORE - EXECUTIVE OVERVIEW REPORT ===');
    buffer.writeln('Generated At,$generatedAt');
    buffer.writeln('');

    // Section 1: KPI Metrics
    buffer.writeln('--- KEY PERFORMANCE INDICATORS ---');
    buffer.writeln('Metric,Value,Unit');
    buffer.writeln('${_escape("Total Revenue")},${_escape(analytics.totalRevenue.toStringAsFixed(2))},EGP');
    buffer.writeln('${_escape("Total Cost (COGS)")},${_escape(analytics.totalCost.toStringAsFixed(2))},EGP');
    buffer.writeln('${_escape("Net Profit")},${_escape(analytics.netProfit.toStringAsFixed(2))},EGP');
    buffer.writeln('${_escape("Net Profit Margin")},${_escape("${analytics.profitMargin.toStringAsFixed(1)}%")},%');
    buffer.writeln('${_escape("Today's Orders")},${_escape(analytics.todayOrders)},Orders');
    buffer.writeln('${_escape("Active Customers")},${_escape(analytics.activeCustomers)},Users');
    buffer.writeln('${_escape("Average Order Value")},${_escape(analytics.avgOrderValue.toStringAsFixed(2))},EGP');
    buffer.writeln('${_escape("Pending Orders")},${_escape(analytics.pendingOrdersCount)},Orders');
    buffer.writeln('${_escape("Low Stock Threshold")},${_escape(lowStockThreshold)},Units');
    buffer.writeln('${_escape("Low Stock Alert Items")},${_escape(analytics.lowStockAlertsCount)},Items');
    buffer.writeln('');

    // Section 2: Weekly Revenue & Orders Trend
    buffer.writeln('--- WEEKLY REVENUE & ORDERS TREND ---');
    buffer.writeln('Day,Revenue (EGP),Orders Count');
    for (final point in analytics.weeklyTrend) {
      buffer.writeln('${_escape(point.label)},${_escape(point.revenue.toStringAsFixed(2))},${_escape(point.ordersCount)}');
    }
    buffer.writeln('');

    // Section 3: Brand Market Share
    buffer.writeln('--- BRAND DISTRIBUTION & HARDWARE SHARE ---');
    buffer.writeln('Brand Name,Share %,Units Tracked');
    for (final brand in analytics.brandShares) {
      buffer.writeln('${_escape(brand.brandName)},${_escape(brand.sharePercentage.toStringAsFixed(1))}%,${_escape(brand.totalSold)}');
    }

    return buffer.toString();
  }

  /// 2. Detailed Orders & Sales Manifest
  static String generateOrdersReportCsv({
    required List<OrderModel> orders,
  }) {
    final buffer = StringBuffer();
    final generatedAt = _formatDate(DateTime.now());

    buffer.writeln('=== EGO STORE - ORDERS & SALES MANIFEST ===');
    buffer.writeln('Generated At,$generatedAt');
    buffer.writeln('Total Orders Count,${orders.length}');
    buffer.writeln('');

    buffer.writeln(
      'Order ID,Date,Customer Name,Phone Number,City / Governorate,Address,Order Status,Payment Status,Payment Method,Subtotal (EGP),Shipping Fee (EGP),Discount (EGP),Total Amount (EGP),Items Count,Customer Notes',
    );

    for (final order in orders) {
      final customerName = order.shippingAddress.name.isNotEmpty
          ? order.shippingAddress.name
          : 'Customer';
      final phone = order.shippingAddress.phoneNumber.isNotEmpty
          ? order.shippingAddress.phoneNumber
          : '';
      final city = order.shippingAddress.city;
      final address = order.shippingAddress.street;
      final itemsCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

      buffer.writeln([
        _escape(order.id),
        _escape(_formatDate(order.orderDate)),
        _escape(customerName),
        _escape(phone),
        _escape(city),
        _escape(address),
        _escape(order.status.toUpperCase()),
        _escape(order.paymentStatus.toUpperCase()),
        _escape(order.paymentMethod.toUpperCase()),
        _escape(order.subTotal.toStringAsFixed(2)),
        _escape(order.shippingCost.toStringAsFixed(2)),
        _escape(order.discount.toStringAsFixed(2)),
        _escape(order.totalAmount.toStringAsFixed(2)),
        _escape(itemsCount),
        _escape(order.orderNotes),
      ].join(','));
    }

    return buffer.toString();
  }

  /// 3. Catalog Inventory & Stock Health Report
  static String generateInventoryReportCsv({
    required List<ProductModel> products,
    int lowStockThreshold = 10,
  }) {
    final buffer = StringBuffer();
    final generatedAt = _formatDate(DateTime.now());

    buffer.writeln('=== EGO STORE - INVENTORY & STOCK HEALTH REPORT ===');
    buffer.writeln('Generated At,$generatedAt');
    buffer.writeln('Total Products In Catalog,${products.length}');
    buffer.writeln('Low Stock Alert Threshold,$lowStockThreshold units');
    buffer.writeln('');

    buffer.writeln(
      'Product ID,Product Title,Brand,Category,Product Type,Cost Price (EGP),Regular Price (EGP),Sale Price (EGP),Profit Margin %,Total Stock,Alert Status,Variations Count',
    );

    for (final product in products) {
      final isLowStock = product.stock <= lowStockThreshold;
      final alertStatus = product.stock == 0
          ? 'OUT OF STOCK'
          : isLowStock
              ? 'URGENT LOW STOCK'
              : 'OPTIMAL';

      buffer.writeln([
        _escape(product.id),
        _escape(product.displayTitle),
        _escape(product.brand.name),
        _escape(product.categoryType.displayName),
        _escape(product.productType.toUpperCase()),
        _escape(product.costPrice.toStringAsFixed(2)),
        _escape(product.price.toStringAsFixed(2)),
        _escape(product.salePrice > 0 ? product.salePrice.toStringAsFixed(2) : product.price.toStringAsFixed(2)),
        _escape('${product.profitMarginPercent.toStringAsFixed(1)}%'),
        _escape(product.stock),
        _escape(alertStatus),
        _escape(product.productVariations.length),
      ].join(','));
    }

    return buffer.toString();
  }

  /// 4. Consolidated Master Report (Financials + Orders + Inventory)
  static String generateMasterReportCsv({
    required DashboardAnalyticsModel analytics,
    required List<OrderModel> orders,
    required List<ProductModel> products,
    int lowStockThreshold = 10,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(generateExecutiveSummaryCsv(analytics: analytics, lowStockThreshold: lowStockThreshold));
    buffer.writeln('');
    buffer.writeln('================================================================');
    buffer.writeln('');
    buffer.writeln(generateOrdersReportCsv(orders: orders));
    buffer.writeln('');
    buffer.writeln('================================================================');
    buffer.writeln('');
    buffer.writeln(generateInventoryReportCsv(products: products, lowStockThreshold: lowStockThreshold));
    return buffer.toString();
  }

  /// Triggers browser download / platform share
  static Future<bool> downloadReport({
    required String fileNamePrefix,
    required String csvContent,
  }) async {
    final fileName = '${fileNamePrefix}_${_fileTimestamp()}.csv';
    return file_saver.saveOrDownloadFile(
      fileName: fileName,
      content: csvContent,
      mimeType: 'text/csv;charset=utf-8',
    );
  }
}

