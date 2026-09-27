import '../../../../core/formatters/formatters.dart';
import '../../products/utils/barcode_128_generator.dart';
import '../../suppliers/utils/stub_printer_helper.dart'
    if (dart.library.js_interop) '../../suppliers/utils/web_printer_helper.dart'
    as printer_helper;
import '../data/models/pos_sale_model.dart';

/// Professional printing engine for POS Thermal Receipts (80mm / 58mm) and Invoices
class PosReceiptPrinter {
  PosReceiptPrinter._();

  /// Prints the POS thermal receipt directly through the browser/system print dialog
  static bool printThermalReceipt(PosSaleModel sale, {int widthMm = 80}) {
    final html = generateThermalReceiptHtml(sale, widthMm: widthMm);
    return printer_helper.printHtmlDocument(html, title: 'POS-Receipt-${sale.orderNumber}');
  }

  /// Prints a dedicated Thermal Return Receipt for returned POS sales
  static bool printThermalReturnReceipt({
    required String orderNumber,
    required List<Map<String, dynamic>> returnedItems,
    required double refundAmount,
    required String reason,
    required String cashierName,
    String customerName = '',
    int widthMm = 80,
  }) {
    final html = generateThermalReturnReceiptHtml(
      orderNumber: orderNumber,
      returnedItems: returnedItems,
      refundAmount: refundAmount,
      reason: reason,
      cashierName: cashierName,
      customerName: customerName,
      widthMm: widthMm,
    );
    return printer_helper.printHtmlDocument(html, title: 'POS-Return-$orderNumber');
  }

  /// Generates HTML for POS return / refund thermal receipt
  static String generateThermalReturnReceiptHtml({
    required String orderNumber,
    required List<Map<String, dynamic>> returnedItems,
    required double refundAmount,
    required String reason,
    required String cashierName,
    String customerName = '',
    int widthMm = 80,
  }) {
    final itemRows = StringBuffer();
    int totalQty = 0;
    for (final item in returnedItems) {
      final title = item['title']?.toString() ?? 'Item';
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final total = (item['totalRefund'] as num?)?.toDouble() ?? (price * qty);
      totalQty += qty;

      itemRows.writeln('''
        <tr>
          <td style="text-align: right; padding: 4px 0; vertical-align: top;">
            <div style="font-weight: 700; font-size: 11.5px; color: #000;">${_escape(title)}</div>
          </td>
          <td style="text-align: center; padding: 4px 2px; vertical-align: top; font-weight: 700; font-size: 11.5px;">$qty</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-size: 11px;">${AppFormatters.formatEGP(price)}</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-weight: 800; font-size: 12px; color: #dc2626;">-${AppFormatters.formatEGP(total)}</td>
        </tr>
      ''');
    }

    final barcodeSvg = Barcode128Generator.generateSvg(
      orderNumber,
      width: (widthMm * 2.2).clamp(130.0, 200.0),
      height: 38,
      showText: true,
      fontSize: 9.5,
    );

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>إيصال مرتجع #${_escape(orderNumber)}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&display=swap');
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #000000;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    body {
      background-color: #fff;
      display: flex;
      justify-content: center;
      padding: 0;
    }
    .receipt-container {
      width: ${widthMm}mm;
      max-width: 100%;
      padding: 8px;
    }
    .header {
      text-align: center;
      margin-bottom: 8px;
    }
    .store-name {
      font-size: 18px;
      font-weight: 900;
      letter-spacing: 1px;
    }
    .return-badge {
      display: inline-block;
      border: 2px solid #000;
      padding: 2px 8px;
      font-size: 12px;
      font-weight: 900;
      margin-top: 4px;
    }
    .divider-dashed {
      border-bottom: 1px dashed #000;
      margin: 6px 0;
    }
    .meta-row {
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      margin-bottom: 2px;
    }
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 6px 0;
    }
    .items-table th {
      border-bottom: 1px solid #000;
      font-size: 11px;
      font-weight: 800;
      padding-bottom: 3px;
    }
    .refund-box {
      border: 1.5px solid #000;
      padding: 6px 8px;
      margin-top: 6px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #f4f4f5;
    }
    .refund-val {
      font-size: 15px;
      font-weight: 900;
    }
    .barcode-box {
      text-align: center;
      margin-top: 8px;
      padding-top: 4px;
    }
    @media print {
      @page {
        size: ${widthMm}mm auto;
        margin: 0;
      }
      body {
        padding: 2mm;
      }
      .receipt-container {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="receipt-container">
    <div class="header">
      <div class="store-name">EGO VAPE STORE</div>
      <div class="return-badge">إيصال مرتجع / REFUND VOUCHER</div>
    </div>

    <div class="meta-row">
      <span>رقم الفاتورة الأصلية:</span>
      <strong>#${_escape(orderNumber)}</strong>
    </div>
    <div class="meta-row">
      <span>تاريخ الإرجاع:</span>
      <span>${AppFormatters.formatDateTime(DateTime.now())}</span>
    </div>
    <div class="meta-row">
      <span>الكاشير:</span>
      <span>${_escape(cashierName)}</span>
    </div>
    ${customerName.isNotEmpty ? '<div class="meta-row"><span>العميل:</span><span>${_escape(customerName)}</span></div>' : ''}
    <div class="meta-row">
      <span>سبب الإرجاع:</span>
      <span>${_escape(reason)}</span>
    </div>

    <div class="divider-dashed"></div>

    <table class="items-table">
      <thead>
        <tr>
          <th style="text-align: right;">الصنف المرتجع</th>
          <th style="text-align: center; width: 28px;">العدد</th>
          <th style="text-align: left; width: 45px;">السعر</th>
          <th style="text-align: left; width: 55px;">المسترد</th>
        </tr>
      </thead>
      <tbody>
        $itemRows
      </tbody>
    </table>

    <div class="divider-dashed"></div>

    <div class="refund-box">
      <span style="font-weight: 800; font-size: 12px;">المبلغ المسترد للعميل ($totalQty صنف):</span>
      <span class="refund-val">${AppFormatters.formatEGP(refundAmount)}</span>
    </div>

    <div class="barcode-box">
      $barcodeSvg
    </div>

    <div style="font-size: 9px; text-align: center; margin-top: 8px; color: #333;">
      تمت معالجة المرتجع وإعادة الأصناف للمخزون بنجاح.<br>
      EGO Store - نسعد دائماً بخدمتكم 🙏
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Generates clean HTML template for 80mm / 58mm thermal receipt printers
  static String generateThermalReceiptHtml(PosSaleModel sale, {int widthMm = 80}) {
    final itemRows = StringBuffer();
    for (int i = 0; i < sale.items.length; i++) {
      final item = sale.items[i];
      final variation = item.variationSummary;
      final discountInfo = item.discount > 0
          ? '<br><small style="color: #475569;">خصم: -${AppFormatters.formatEGP(item.totalLineDiscount)}</small>'
          : '';

      itemRows.writeln('''
        <tr>
          <td style="text-align: right; padding: 4px 0; vertical-align: top;">
            <div style="font-weight: 700; font-size: 11.5px; color: #000;">${_escape(item.fullTitle)}</div>
            ${variation.isNotEmpty ? '<div style="font-size: 10px; color: #333;">${_escape(variation)}</div>' : ''}
            $discountInfo
          </td>
          <td style="text-align: center; padding: 4px 2px; vertical-align: top; font-weight: 700; font-size: 11.5px;">${item.quantity}</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-size: 11px;">${AppFormatters.formatEGP(item.unitPrice)}</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-weight: 800; font-size: 12px;">${AppFormatters.formatEGP(item.lineTotal)}</td>
        </tr>
      ''');
    }

    final discountRow = sale.discount > 0
        ? '''
        <tr>
          <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">الخصم الإضافي:</td>
          <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px; color: #000;">-${AppFormatters.formatEGP(sale.discount)}</td>
        </tr>
      '''
        : '';

    final taxRow = sale.taxFee > 0
        ? '''
        <tr>
          <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">الضريبة / الخدمة:</td>
          <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px;">${AppFormatters.formatEGP(sale.taxFee)}</td>
        </tr>
      '''
        : '';

    final paymentMethodText = switch (sale.paymentMethod.toLowerCase()) {
      'card' => 'بطاقة بنكية / فيزا (Card)',
      'instapay' => 'إنستاباي / محفظة إلكترونية (InstaPay)',
      'split' => 'دفع مختلط (Split)',
      _ => 'نقداً (Cash)',
    };

    final cashDetails = sale.paymentMethod.toLowerCase() == 'cash' && sale.paidAmount > 0
        ? '''
        <div style="border-top: 1px dashed #000; margin-top: 4px; padding-top: 4px; font-size: 11px;">
          <div style="display: flex; justify-content: space-between;">
            <span>المبلغ المدفوع:</span>
            <strong>${AppFormatters.formatEGP(sale.paidAmount)}</strong>
          </div>
          <div style="display: flex; justify-content: space-between; margin-top: 2px;">
            <span>الباقي للعميل:</span>
            <strong>${AppFormatters.formatEGP(sale.changeAmount)}</strong>
          </div>
        </div>
      '''
        : '';

    final barcodeSvg = Barcode128Generator.generateSvg(
      sale.orderNumber,
      width: (widthMm * 2.2).clamp(130.0, 200.0),
      height: 38,
      showText: true,
      fontSize: 9.5,
    );

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>إيصال كاشير #${_escape(sale.orderNumber)}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&display=swap');
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #000000;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    
    body {
      background: #fff;
      padding: 6px;
      font-size: 11px;
      line-height: 1.35;
      direction: rtl;
    }
    
    .receipt-wrapper {
      width: ${widthMm}mm;
      max-width: 100%;
      margin: 0 auto;
      padding: 4px;
    }
    
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .text-left { text-align: left; }
    
    .brand-title {
      font-size: 16px;
      font-weight: 900;
      letter-spacing: 0.5px;
      margin-bottom: 2px;
    }
    
    .brand-sub {
      font-size: 10px;
      font-weight: 600;
      margin-bottom: 4px;
    }
    
    .divider-solid {
      border-bottom: 1.5px solid #000;
      margin: 6px 0;
    }
    
    .divider-dashed {
      border-bottom: 1px dashed #000;
      margin: 6px 0;
    }
    
    .meta-row {
      display: flex;
      justify-content: space-between;
      font-size: 10.5px;
      margin-bottom: 2px;
    }
    
    table.items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 6px 0;
    }
    
    table.items-table th {
      border-bottom: 1.5px solid #000;
      padding: 3px 0;
      font-size: 10.5px;
      font-weight: 800;
    }
    
    .grand-total-box {
      border-top: 1.5px solid #000;
      border-bottom: 1.5px solid #000;
      padding: 6px 0;
      margin: 6px 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .grand-total-label {
      font-size: 13px;
      font-weight: 900;
    }
    
    .grand-total-val {
      font-size: 15px;
      font-weight: 900;
    }
    
    .barcode-box {
      text-align: center;
      margin-top: 8px;
      padding-top: 4px;
    }
    
    .footer-note {
      text-align: center;
      font-size: 10px;
      margin-top: 8px;
      line-height: 1.4;
    }
    
    @media print {
      @page {
        size: ${widthMm}mm auto;
        margin: 0;
      }
      body {
        padding: 2mm;
      }
      .receipt-wrapper {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="receipt-wrapper">
    <!-- Header -->
    <div class="text-center">
      <div class="brand-title">EGO VAPE STORE</div>
      <div class="brand-sub">مستلزمات الفيب الأصلية والإلكترونيات</div>
      <div style="font-size: 9.5px;">خدمة العملاء: support@egovapestore.com</div>
    </div>
    
    <div class="divider-solid"></div>
    
    <!-- Meta Info -->
    <div class="meta-row">
      <span>رقم الإيصال:</span>
      <strong>#${_escape(sale.orderNumber)}</strong>
    </div>
    <div class="meta-row">
      <span>التاريخ:</span>
      <span>${AppFormatters.formatDateTime(sale.createdAt)}</span>
    </div>
    <div class="meta-row">
      <span>الكاشير:</span>
      <span>${_escape(sale.cashierName)}</span>
    </div>
    ${sale.customerName.isNotEmpty && sale.customerName != 'Walk-in Customer (عميل مباشر)' ? '''
    <div class="meta-row">
      <span>العميل:</span>
      <span>${_escape(sale.customerName)} ${sale.customerPhone.isNotEmpty ? "(${_escape(sale.customerPhone)})" : ""}</span>
    </div>
    ''' : ''}
    
    <div class="divider-dashed"></div>
    
    <!-- Items Table -->
    <table class="items-table">
      <thead>
        <tr>
          <th style="text-align: right;">الصنف</th>
          <th style="text-align: center; width: 28px;">العدد</th>
          <th style="text-align: left; width: 45px;">السعر</th>
          <th style="text-align: left; width: 55px;">الإجمالي</th>
        </tr>
      </thead>
      <tbody>
        $itemRows
      </tbody>
    </table>
    
    <div class="divider-dashed"></div>
    
    <!-- Summary -->
    <table style="width: 100%; border-collapse: collapse;">
      <tr>
        <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">إجمالي الأصناف (${sale.totalItemsCount}):</td>
        <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px;">${AppFormatters.formatEGP(sale.subTotal)}</td>
      </tr>
      $discountRow
      $taxRow
    </table>
    
    <!-- Grand Total Banner -->
    <div class="grand-total-box">
      <span class="grand-total-label">المجموع النهائي:</span>
      <span class="grand-total-val">${AppFormatters.formatEGP(sale.totalAmount)}</span>
    </div>
    
    <!-- Payment Method & Details -->
    <div class="meta-row" style="margin-top: 4px;">
      <span>طريقة الدفع:</span>
      <strong>$paymentMethodText</strong>
    </div>
    $cashDetails
    
    <!-- Barcode Section -->
    <div class="barcode-box">
      $barcodeSvg
    </div>
    
    <div class="divider-dashed"></div>
    
    <!-- Footer Policy -->
    <div class="footer-note">
      <div>شكراً لزيارتكم متجر EGO Store! 🙏</div>
      <div style="font-size: 9px; margin-top: 3px; color: #333;">
        • الاستبدال والاسترجاع خلال 14 يوماً مع إحضار الإيصال والعلبة الأصلية بحالتها.<br>
        • يرجى فحص المنتج والجهاز قبل مغادرة المتجر.
      </div>
      <div style="font-size: 8.5px; margin-top: 4px; color: #555;">
        ${sale.id}
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
}
