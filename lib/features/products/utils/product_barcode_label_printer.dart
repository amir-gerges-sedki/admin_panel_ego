import '../../../../core/formatters/formatters.dart';
import '../../suppliers/utils/stub_printer_helper.dart'
    if (dart.library.js_interop) '../../suppliers/utils/web_printer_helper.dart'
    as printer_helper;
import '../data/models/product_model.dart';
import 'barcode_128_generator.dart';

enum BarcodeLabelSize {
  compactRoll38x25('38mm x 25mm (بكرة حرارية صغيرة)', 38, 25, true),
  standardRoll50x30('50mm x 30mm (بكرة حرارية قياسية)', 50, 30, true),
  largeRoll58x40('58mm x 40mm (بكرة حرارية كبيرة)', 58, 40, true),
  a4SheetGrid('ورق A4 مقسم ملصقات (24 ملصق بالورقة)', 210, 297, false);

  final String label;
  final int widthMm;
  final int heightMm;
  final bool isThermalRoll;

  const BarcodeLabelSize(this.label, this.widthMm, this.heightMm, this.isThermalRoll);
}

class BarcodeLabelItem {
  final String productTitle;
  final String brandName;
  final String variationSummary;
  final String sku;
  final double price;
  final int copies;

  const BarcodeLabelItem({
    required this.productTitle,
    this.brandName = '',
    this.variationSummary = '',
    required this.sku,
    required this.price,
    this.copies = 1,
  });

  factory BarcodeLabelItem.fromProduct(
    ProductModel product, {
    ProductVariationModel? variation,
    int copies = 1,
  }) {
    if (variation != null) {
      final varAttrs = variation.attributeValues.entries
          .where((e) => e.key.toLowerCase() != 'type' && e.key.toLowerCase() != 'liquidtype')
          .map((e) => e.value)
          .join(' / ');

      final effectiveSku = variation.sku.isNotEmpty
          ? variation.sku
          : (product.id.isNotEmpty ? '${product.id}-${variation.id}' : 'SKU_${DateTime.now().millisecondsSinceEpoch}');

      final effectivePrice = variation.salePrice > 0
          ? variation.salePrice
          : (variation.price > 0 ? variation.price : product.price);

      return BarcodeLabelItem(
        productTitle: product.title,
        brandName: product.brand.name,
        variationSummary: varAttrs,
        sku: effectiveSku,
        price: effectivePrice,
        copies: copies,
      );
    }

    final effectiveSku = product.productVariations.isNotEmpty
        ? product.productVariations.first.sku
        : (product.id.isNotEmpty ? product.id : 'SKU_${DateTime.now().millisecondsSinceEpoch}');

    final effectivePrice = product.salePrice > 0 ? product.salePrice : product.price;

    return BarcodeLabelItem(
      productTitle: product.title,
      brandName: product.brand.name,
      variationSummary: '',
      sku: effectiveSku,
      price: effectivePrice,
      copies: copies,
    );
  }
}

/// Printing utility for barcode stickers, labels, and product tags
class ProductBarcodeLabelPrinter {
  ProductBarcodeLabelPrinter._();

  /// Prints the generated barcode labels HTML through the browser/system print dialog
  static bool printLabels({
    required List<BarcodeLabelItem> items,
    BarcodeLabelSize size = BarcodeLabelSize.standardRoll50x30,
    String storeName = 'EGO VAPE STORE',
  }) {
    final html = generateLabelsHtml(items: items, size: size, storeName: storeName);
    return printer_helper.printHtmlDocument(html, title: 'EGO-Barcode-Labels');
  }

  /// Generates self-contained HTML for thermal roll or A4 sticker sheet printing
  static String generateLabelsHtml({
    required List<BarcodeLabelItem> items,
    BarcodeLabelSize size = BarcodeLabelSize.standardRoll50x30,
    String storeName = 'EGO VAPE STORE',
  }) {
    final labelBlocks = StringBuffer();

    for (final item in items) {
      for (int i = 0; i < item.copies; i++) {
        labelBlocks.writeln(_buildSingleLabelHtml(item, size, storeName));
      }
    }

    if (size.isThermalRoll) {
      return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>طباعة ملصقات الباركود</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@600;700;800;900&display=swap');
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #000000;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    @page {
      size: ${size.widthMm}mm ${size.heightMm}mm;
      margin: 0;
    }

    body {
      background: #ffffff;
      margin: 0;
      padding: 0;
    }

    .label-page {
      width: ${size.widthMm}mm;
      height: ${size.heightMm}mm;
      max-width: ${size.widthMm}mm;
      max-height: ${size.heightMm}mm;
      padding: 1.5mm 2mm;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;
      page-break-after: always;
      overflow: hidden;
      background: #ffffff;
    }

    .store-brand {
      font-size: ${size == BarcodeLabelSize.compactRoll38x25 ? '7px' : '8.5px'};
      font-weight: 800;
      letter-spacing: 0.5px;
      text-align: center;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 100%;
      line-height: 1.1;
    }

    .product-title {
      font-size: ${size == BarcodeLabelSize.compactRoll38x25 ? '8.5px' : '10px'};
      font-weight: 800;
      text-align: center;
      line-height: 1.15;
      max-height: ${size == BarcodeLabelSize.compactRoll38x25 ? '10px' : '14px'};
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      width: 100%;
    }

    .variation-badge {
      font-size: ${size == BarcodeLabelSize.compactRoll38x25 ? '7px' : '8px'};
      font-weight: 700;
      background: #000000;
      color: #ffffff;
      padding: 0.5px 4px;
      border-radius: 2px;
      text-align: center;
      max-width: 95%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin: 0.5mm 0;
      line-height: 1.2;
    }

    .barcode-container {
      width: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      margin: 0 auto;
    }

    .price-tag {
      font-size: ${size == BarcodeLabelSize.compactRoll38x25 ? '9px' : '11px'};
      font-weight: 900;
      text-align: center;
      letter-spacing: 0.3px;
      line-height: 1.1;
    }
  </style>
</head>
<body>
  $labelBlocks
</body>
</html>
      ''';
    } else {
      // A4 Sheet Grid Layout (3 columns x 8 rows = 24 labels)
      return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>طباعة ملصقات الباركود A4</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@600;700;800;900&display=swap');
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #000000;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    @page {
      size: A4 portrait;
      margin: 8mm 6mm;
    }

    body {
      background: #ffffff;
    }

    .a4-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      grid-gap: 3mm;
      page-break-inside: avoid;
    }

    .label-page {
      height: 33mm;
      border: 1px dashed #ccc;
      border-radius: 4px;
      padding: 2mm;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;
      overflow: hidden;
      background: #ffffff;
      page-break-inside: avoid;
    }

    .store-brand {
      font-size: 8px;
      font-weight: 800;
      letter-spacing: 0.5px;
      text-align: center;
    }

    .product-title {
      font-size: 9.5px;
      font-weight: 800;
      text-align: center;
      line-height: 1.2;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      width: 100%;
    }

    .variation-badge {
      font-size: 7.5px;
      font-weight: 700;
      background: #000000;
      color: #ffffff;
      padding: 0.5px 4px;
      border-radius: 2px;
      text-align: center;
      max-width: 95%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .barcode-container {
      width: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .price-tag {
      font-size: 10.5px;
      font-weight: 900;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="a4-grid">
    $labelBlocks
  </div>
</body>
</html>
      ''';
    }
  }

  static String _buildSingleLabelHtml(
    BarcodeLabelItem item,
    BarcodeLabelSize size,
    String storeName,
  ) {
    final double svgWidth = size == BarcodeLabelSize.compactRoll38x25
        ? 135
        : (size == BarcodeLabelSize.largeRoll58x40 ? 190 : 165);
    final double svgHeight = size == BarcodeLabelSize.compactRoll38x25
        ? 34
        : (size == BarcodeLabelSize.largeRoll58x40 ? 46 : 40);
    final double fontSize = size == BarcodeLabelSize.compactRoll38x25 ? 8.5 : 10;

    final svgCode = Barcode128Generator.generateSvg(
      item.sku,
      width: svgWidth,
      height: svgHeight,
      fontSize: fontSize,
      showText: true,
    );

    final brandDisplay = item.brandName.isNotEmpty ? '${_escape(item.brandName)} • ' : '';

    return '''
    <div class="label-page">
      <div class="store-brand">$brandDisplay${_escape(storeName)}</div>
      <div class="product-title">${_escape(item.productTitle)}</div>
      ${item.variationSummary.isNotEmpty ? '<div class="variation-badge">${_escape(item.variationSummary)}</div>' : ''}
      <div class="barcode-container">
        $svgCode
      </div>
      <div class="price-tag">${AppFormatters.formatEGP(item.price)}</div>
    </div>
    ''';
  }

  static String _escape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
