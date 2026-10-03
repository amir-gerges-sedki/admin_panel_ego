import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../dashboard/utils/stub_file_saver.dart'
    if (dart.library.js_interop) '../../dashboard/utils/web_file_saver.dart'
    as file_saver;
import '../../products/utils/barcode_128_generator.dart';
import '../../suppliers/utils/stub_printer_helper.dart'
    if (dart.library.js_interop) '../../suppliers/utils/web_printer_helper.dart'
    as printer_helper;
import '../data/models/order_model.dart';

/// Professional utility for generating, previewing, printing, and exporting
/// Customer Sales Order Invoices and Delivery Receipts.
class OrderInvoicePrinter {
  OrderInvoicePrinter._();

  /// Opens browser native print dialog with styled HTML document
  static bool printHtml(String htmlContent, {String title = 'Order Invoice'}) {
    return printer_helper.printHtmlDocument(htmlContent, title: title);
  }

  /// Print order invoice directly (A4 format)
  static bool printOrderInvoice(OrderModel order) {
    final html = generateOrderInvoiceHtml(order);
    return printHtml(html, title: 'EGO-Order-${order.id}');
  }

  /// Print compact palm-sized thermal receipt directly (80mm / 58mm POS standard)
  static bool printThermalOrderReceipt(OrderModel order, {int widthMm = 80}) {
    final html = generateThermalOrderReceiptHtml(order, widthMm: widthMm);
    return printHtml(html, title: 'EGO-Thermal-Order-${order.id}');
  }

  /// Exports order invoice data to a clean UTF-8 CSV spreadsheet
  static Future<bool> exportOrderInvoiceCsv(OrderModel order) async {
    final buffer = StringBuffer();

    // 1. Order Summary Header
    buffer.writeln('فاتورة طلب مبيعات - EGO VAPE STORE');
    buffer.writeln('رقم الطلب,${order.id}');
    buffer.writeln('تاريخ الطلب,${AppFormatters.formatDateTime(order.orderDate)}');
    buffer.writeln('حالة الطلب,${order.status}');
    buffer.writeln('طريقة الدفع,${order.paymentMethod}');
    buffer.writeln('حالة الدفع,${order.paymentStatus}');
    buffer.writeln();

    // 2. Customer & Delivery Info
    final addr = order.shippingAddress;
    buffer.writeln('بيانات العميل والشحن');
    buffer.writeln('اسم العميل,${addr.name}');
    buffer.writeln('رقم الهاتف,${addr.phoneNumber}');
    if (addr.alternatePhone.isNotEmpty) {
      buffer.writeln('هاتف بديل,${addr.alternatePhone}');
    }
    if (addr.email.isNotEmpty) {
      buffer.writeln('البريد الإلكتروني,${addr.email}');
    }
    buffer.writeln('المحافظة / المدينة,${addr.governorate.isNotEmpty ? addr.governorate : addr.city}');
    buffer.writeln('العنوان التفصيلي,"${addr.formattedFullAddress.replaceAll('"', '""')}"');
    if (order.orderNotes.isNotEmpty) {
      buffer.writeln('ملاحظات الطلب,"${order.orderNotes.replaceAll('"', '""')}"');
    }
    buffer.writeln();

    // 3. Items Table Header
    buffer.writeln('#,اسم الصنف,المواصفات / النكهة,الباركود SKU,الكمية,سعر الوحدة (ج.م),الإجمالي (ج.م)');

    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      final variations = item.selectedVariation.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');
      final title = item.formattedTitleWithBrand.replaceAll('"', '""');
      final desc = variations.replaceAll('"', '""');
      final sku = item.sku.replaceAll('"', '""');
      final qty = item.quantity;
      final unitPrice = item.price.toStringAsFixed(2);
      final total = item.totalItemPrice.toStringAsFixed(2);

      buffer.writeln('${i + 1},"$title","$desc","$sku",$qty,$unitPrice,$total');
    }

    buffer.writeln();

    // 4. Financial Summary
    buffer.writeln('الملخص المالي');
    buffer.writeln('إجمالي الأصناف,${order.subTotal.toStringAsFixed(2)} ج.م');
    buffer.writeln('مصاريف الشحن والتوصيل,${order.shippingCost > 0 ? "${order.shippingCost.toStringAsFixed(2)} ج.م" : "مجاناً"}');
    if (order.discount > 0) {
      final coupon = order.couponCode.isNotEmpty ? ' (كوبون: ${order.couponCode})' : '';
      buffer.writeln('الخصم الترويجي$coupon,-${order.discount.toStringAsFixed(2)} ج.م');
    }
    if (order.taxFee > 0) {
      buffer.writeln('الضريبة / الرسوم,${order.taxFee.toStringAsFixed(2)} ج.م');
    }
    buffer.writeln('المجموع الكلي النهائي,${order.totalAmount.toStringAsFixed(2)} ج.م');

    final fileName = 'ego_order_${order.id}_invoice.csv';
    return file_saver.saveOrDownloadFile(
      fileName: fileName,
      content: buffer.toString(),
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  /// Displays the interactive modal dialog for previewing, printing, and exporting
  static void showOrderInvoicePreview(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _OrderInvoicePreviewDialog(order: order),
    );
  }

  /// Generates the HTML template with embedded print CSS for sales order invoice
  static String generateOrderInvoiceHtml(OrderModel order) {
    final statusBadge = switch (order.status.toLowerCase().trim()) {
      'delivered' => ('#10B981', 'تم التوصيل بنجاح (Delivered)'),
      'shipped' => ('#3B82F6', 'تم الشحن مع المندوب (Shipped)'),
      'processing' => ('#F59E0B', 'قيد التجهيز (Processing)'),
      'cancelled' => ('#EF4444', 'ملغي (Cancelled)'),
      _ => ('#6366F1', 'جديد قيد المراجعة (Pending)'),
    };

    final itemsRows = StringBuffer();
    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      final attrs = item.selectedVariation.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');
      final skuInfo = item.sku.isNotEmpty ? 'SKU: ${item.sku}' : '';
      final subInfo = [
        if (item.brand.isNotEmpty && !item.title.toLowerCase().contains(item.brand.toLowerCase())) item.brand,
        if (attrs.isNotEmpty) attrs,
        if (skuInfo.isNotEmpty) skuInfo,
      ].join(' • ');

      itemsRows.writeln('''
        <tr>
          <td style="text-align:center; width: 35px;">${i + 1}</td>
          <td>
            <strong style="color: #0f172a; font-size: 13.5px;">${_escape(item.title)}</strong>
            ${subInfo.isNotEmpty ? '<br><small style="color: #64748b; font-size: 11px;">${_escape(subInfo)}</small>' : ''}
          </td>
          <td style="text-align:center; width: 60px; font-weight: 700; font-size: 13px;">${item.quantity}</td>
          <td style="text-align:left; width: 100px; font-size: 12.5px;">${AppFormatters.formatEGP(item.price)}</td>
          <td style="text-align:left; width: 115px; font-weight: 800; color: #0f172a; font-size: 13.5px;">${AppFormatters.formatEGP(item.totalItemPrice)}</td>
        </tr>
      ''');
    }

    final addr = order.shippingAddress;
    final deliveryFeeDisplay = order.shippingCost > 0
        ? AppFormatters.formatEGP(order.shippingCost)
        : '<span style="color: #10b981; font-weight: 700;">مجاناً (Free)</span>';

    final discountRow = order.discount > 0
        ? '''
        <tr>
          <td style="padding: 6px 0; color: #dc2626; font-size: 12.5px;">الخصم الترويجي ${order.couponCode.isNotEmpty ? '(${_escape(order.couponCode)})' : ''}</td>
          <td style="padding: 6px 0; text-align: left; color: #dc2626; font-weight: 700; font-size: 13px;">-${AppFormatters.formatEGP(order.discount)}</td>
        </tr>
      '''
        : '';

    final taxRow = order.taxFee > 0
        ? '''
        <tr>
          <td style="padding: 6px 0; color: #64748b; font-size: 12.5px;">الضريبة / الرسوم</td>
          <td style="padding: 6px 0; text-align: left; color: #0f172a; font-weight: 600; font-size: 13px;">${AppFormatters.formatEGP(order.taxFee)}</td>
        </tr>
      '''
        : '';

    final notesSection = order.orderNotes.isNotEmpty
        ? '''
        <div style="margin-top: 18px; padding: 12px 14px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 8px;">
          <div style="font-weight: 700; color: #92400e; font-size: 12px; margin-bottom: 4px;">📝 ملاحظات العميل الخاصة بالطلب:</div>
          <div style="font-size: 12px; color: #78350f; line-height: 1.5;">${_escape(order.orderNotes)}</div>
        </div>
      '''
        : '';

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>فاتورة طلب #${_escape(order.id)} - EGO STORE</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&display=swap');
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    
    body {
      background-color: #f8fafc;
      color: #0f172a;
      padding: 24px;
      line-height: 1.4;
      font-size: 12px;
      direction: rtl;
    }
    
    .invoice-card {
      max-width: 800px;
      margin: 0 auto;
      background: #ffffff;
      padding: 36px 40px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.06);
      border: 1px solid #e2e8f0;
    }
    
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 20px;
      margin-bottom: 24px;
    }
    
    .brand-title {
      font-size: 24px;
      font-weight: 900;
      color: #e11d48;
      letter-spacing: 0.5px;
      line-height: 1.1;
    }
    
    .brand-subtitle {
      font-size: 12px;
      color: #64748b;
      margin-top: 4px;
      font-weight: 600;
    }
    
    .doc-meta {
      text-align: left;
    }
    
    .doc-title {
      font-size: 18px;
      font-weight: 800;
      color: #0f172a;
    }
    
    .doc-number {
      font-size: 14px;
      font-weight: 700;
      color: #e11d48;
      margin-top: 2px;
    }
    
    .doc-date {
      font-size: 11px;
      color: #64748b;
      margin-top: 2px;
    }
    
    .status-badge {
      display: inline-block;
      margin-top: 6px;
      padding: 3px 10px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 700;
      color: #ffffff;
      background-color: ${statusBadge.$1};
    }
    
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 24px;
    }
    
    .info-block {
      background: #f8fafc;
      padding: 14px 16px;
      border-radius: 8px;
      border: 1px solid #edf2f7;
    }
    
    .info-block-title {
      font-size: 12px;
      font-weight: 800;
      color: #334155;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 6px;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 4px;
    }
    
    .info-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 4px;
      font-size: 11.5px;
    }
    
    .info-label {
      color: #64748b;
      font-weight: 600;
    }
    
    .info-val {
      color: #0f172a;
      font-weight: 700;
      text-align: left;
    }
    
    table.items-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }
    
    table.items-table th {
      background: #0f172a;
      color: #ffffff;
      font-weight: 700;
      font-size: 11.5px;
      padding: 10px 12px;
      text-align: right;
    }
    
    table.items-table td {
      padding: 10px 12px;
      border-bottom: 1px solid #e2e8f0;
      font-size: 12px;
    }
    
    table.items-table tr:nth-child(even) {
      background: #f8fafc;
    }
    
    .summary-section {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 24px;
      margin-top: 16px;
    }
    
    .payment-badge-box {
      flex: 1;
      background: #f1f5f9;
      padding: 14px;
      border-radius: 8px;
      border: 1px solid #e2e8f0;
    }
    
    .totals-box {
      width: 320px;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 16px;
    }
    
    .totals-table {
      width: 100%;
      border-collapse: collapse;
    }
    
    .grand-total-row {
      border-top: 2px solid #0f172a;
      margin-top: 8px;
      padding-top: 8px;
    }
    
    .grand-total-val {
      font-size: 18px;
      font-weight: 900;
      color: #e11d48;
    }
    
    .footer {
      margin-top: 36px;
      padding-top: 16px;
      border-top: 1px solid #e2e8f0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      color: #64748b;
      font-size: 10.5px;
    }
    
    @media print {
      @page {
        size: A4 portrait;
        margin: 12mm 15mm;
      }
      body {
        background: #ffffff;
        padding: 0;
      }
      .invoice-card {
        border: none;
        box-shadow: none;
        padding: 0;
        max-width: 100%;
      }
      .no-print {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="invoice-card">
    <!-- Header -->
    <div class="header">
      <div>
        <div class="brand-title">EGO VAPE STORE</div>
        <div class="brand-subtitle">متجر إيجو - مستلزمات الفيب الأصلية والإلكترونيات</div>
        <div style="font-size: 11px; color: #64748b; margin-top: 2px;">خدمة العملاء: support@egovapestore.com</div>
      </div>
      <div class="doc-meta">
        <div class="doc-title">فاتورة طلب مبيعات</div>
        <div class="doc-number">#${_escape(order.id)}</div>
        <div class="doc-date">التاريخ: ${AppFormatters.formatDateTime(order.orderDate)}</div>
        <div class="status-badge">${statusBadge.$2}</div>
      </div>
    </div>
    
    <!-- Info Grid -->
    <div class="info-grid">
      <!-- Customer Info -->
      <div class="info-block">
        <div class="info-block-title">👤 بيانات العميل والشحن</div>
        <div class="info-row">
          <span class="info-label">اسم العميل:</span>
          <span class="info-val">${_escape(addr.name)}</span>
        </div>
        <div class="info-row">
          <span class="info-label">رقم الهاتف:</span>
          <span class="info-val" dir="ltr">${_escape(addr.phoneNumber)}</span>
        </div>
        ${addr.alternatePhone.isNotEmpty ? '''
        <div class="info-row">
          <span class="info-label">هاتف بديل:</span>
          <span class="info-val" dir="ltr">${_escape(addr.alternatePhone)}</span>
        </div>
        ''' : ''}
        <div class="info-row">
          <span class="info-label">المحافظة / المدينة:</span>
          <span class="info-val">${_escape(addr.governorate.isNotEmpty ? addr.governorate : addr.city)}</span>
        </div>
        <div class="info-row" style="flex-direction: column; gap: 2px; margin-top: 4px;">
          <span class="info-label">العنوان التفصيلي:</span>
          <span class="info-val" style="text-align: right; font-size: 11px; color: #1e293b;">${_escape(addr.formattedFullAddress)}</span>
        </div>
      </div>
      
      <!-- Order / Payment Meta -->
      <div class="info-block">
        <div class="info-block-title">💳 تفاصيل الدفع والشحن</div>
        <div class="info-row">
          <span class="info-label">طريقة الدفع:</span>
          <span class="info-val">${_escape(order.paymentMethod)}</span>
        </div>
        <div class="info-row">
          <span class="info-label">حالة الدفع:</span>
          <span class="info-val">${_escape(order.paymentStatus)}</span>
        </div>
        <div class="info-row">
          <span class="info-label">شركة الشحن:</span>
          <span class="info-val">${order.shippingCarrier.isNotEmpty ? _escape(order.shippingCarrier) : 'مندوب المتجر'}</span>
        </div>
        ${order.trackingNumber.isNotEmpty ? '''
        <div class="info-row">
          <span class="info-label">رقم التتبع:</span>
          <span class="info-val" dir="ltr">${_escape(order.trackingNumber)}</span>
        </div>
        ''' : ''}
        ${order.couponCode.isNotEmpty ? '''
        <div class="info-row">
          <span class="info-label">كوبون الخصم:</span>
          <span class="info-val" style="color: #dc2626;">${_escape(order.couponCode)}</span>
        </div>
        ''' : ''}
      </div>
    </div>
    
    <!-- Items Table -->
    <table class="items-table">
      <thead>
        <tr>
          <th style="text-align:center;">#</th>
          <th>الصنف والمواصفات</th>
          <th style="text-align:center;">الكمية</th>
          <th style="text-align:left;">سعر الوحدة</th>
          <th style="text-align:left;">الإجمالي</th>
        </tr>
      </thead>
      <tbody>
        $itemsRows
      </tbody>
    </table>
    
    <!-- Summary Section -->
    <div class="summary-section">
      <div class="payment-badge-box">
        <div style="font-weight: 700; color: #0f172a; font-size: 12px; margin-bottom: 6px;">ملاحظات وتعليمات الشحنة:</div>
        <div style="font-size: 11px; color: #475569; line-height: 1.5;">
          • يُرجى التأكد من سلامة وسلامة تغليف الطرد عند الاستلام.<br>
          • في حالة وجود أي استفسار، يُرجى التواصل مع الدعم مع ذكر رقم الطلب <strong>#${_escape(order.id)}</strong>.<br>
          • شكراً لاختياركم متجر EGO Store!
        </div>
      </div>
      
      <div class="totals-box">
        <table class="totals-table">
          <tr>
            <td style="padding: 4px 0; color: #64748b;">إجمالي المنتجات:</td>
            <td style="padding: 4px 0; text-align: left; font-weight: 700; color: #0f172a;">${AppFormatters.formatEGP(order.subTotal)}</td>
          </tr>
          <tr>
            <td style="padding: 4px 0; color: #64748b;">مصاريف الشحن والتوصيل:</td>
            <td style="padding: 4px 0; text-align: left; font-weight: 700;">$deliveryFeeDisplay</td>
          </tr>
          $discountRow
          $taxRow
          <tr class="grand-total-row">
            <td style="padding-top: 8px; font-weight: 900; font-size: 14px; color: #0f172a;">المجموع النهائي:</td>
            <td style="padding-top: 8px; text-align: left;" class="grand-total-val">${AppFormatters.formatEGP(order.totalAmount)}</td>
          </tr>
        </table>
      </div>
    </div>
    
    $notesSection
    
    <!-- Footer -->
    <div class="footer">
      <div>EGO VAPE STORE • All rights reserved &copy; ${DateTime.now().year}</div>
      <div>تمت الطباعة: ${AppFormatters.formatDateTime(DateTime.now())}</div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generates clean, palm-sized HTML template for 80mm / 58mm thermal receipt printers
  /// Auto-adjusts height to content with embedded Code-128 barcode
  static String generateThermalOrderReceiptHtml(OrderModel order, {int widthMm = 80}) {
    final addr = order.shippingAddress;
    final itemRows = StringBuffer();

    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      final attrs = item.selectedVariation.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');

      itemRows.writeln('''
        <tr>
          <td style="text-align: right; padding: 4px 0; vertical-align: top;">
            <div style="font-weight: 700; font-size: 11.5px; color: #000;">${_escape(item.title)}</div>
            ${attrs.isNotEmpty ? '<div style="font-size: 9.5px; color: #444;">${_escape(attrs)}</div>' : ''}
            ${item.sku.isNotEmpty ? '<div style="font-size: 9px; color: #666;">SKU: ${_escape(item.sku)}</div>' : ''}
          </td>
          <td style="text-align: center; padding: 4px 2px; vertical-align: top; font-weight: 700; font-size: 11.5px;">${item.quantity}</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-size: 11px;">${AppFormatters.formatEGP(item.price)}</td>
          <td style="text-align: left; padding: 4px 0; vertical-align: top; font-weight: 800; font-size: 12px;">${AppFormatters.formatEGP(item.totalItemPrice)}</td>
        </tr>
      ''');
    }

    final deliveryFeeDisplay = order.shippingCost > 0
        ? AppFormatters.formatEGP(order.shippingCost)
        : 'مجاناً (Free)';

    final discountRow = order.discount > 0
        ? '''
        <tr>
          <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px; color: #000;">الخصم الترويجي ${order.couponCode.isNotEmpty ? '(${_escape(order.couponCode)})' : ''}:</td>
          <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px; color: #000;">-${AppFormatters.formatEGP(order.discount)}</td>
        </tr>
      '''
        : '';

    final taxRow = order.taxFee > 0
        ? '''
        <tr>
          <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">الضريبة / الخدمة:</td>
          <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px;">${AppFormatters.formatEGP(order.taxFee)}</td>
        </tr>
      '''
        : '';

    // Code-128 Barcode for the Order ID
    final barcodeSvg = Barcode128Generator.generateSvg(
      order.id,
      width: (widthMm * 2.2).clamp(140.0, 220.0),
      height: 42,
      showText: true,
      fontSize: 9.5,
    );

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>إيصال استلام #${_escape(order.id)}</title>
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
      padding: 4px;
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
    
    .info-box {
      background: #f8fafc;
      border: 1px dashed #000;
      padding: 6px;
      margin: 6px 0;
      border-radius: 4px;
      font-size: 10.5px;
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
    
    .barcode-container {
      text-align: center;
      margin-top: 8px;
      padding-top: 4px;
    }
    
    .footer-note {
      text-align: center;
      font-size: 9.5px;
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
      <div class="brand-sub">متجر إيجو - مستلزمات الفيب والأجهزة</div>
      <div style="font-size: 9.5px;">إيصال تسليم طلبية شحن / Delivery Slip</div>
    </div>
    
    <div class="divider-solid"></div>
    
    <!-- Meta Info -->
    <div class="meta-row">
      <span>رقم الطلب:</span>
      <strong>#${_escape(order.id)}</strong>
    </div>
    <div class="meta-row">
      <span>تاريخ الطلب:</span>
      <span>${AppFormatters.formatDateTime(order.orderDate)}</span>
    </div>
    <div class="meta-row">
      <span>حالة الطلب:</span>
      <span>${_escape(order.status)}</span>
    </div>
    
    <!-- Customer Delivery Box -->
    <div class="info-box">
      <div style="font-weight: 800; margin-bottom: 2px;">👤 بيانات العميل والشحن:</div>
      <div><strong>العميل:</strong> ${_escape(addr.name)}</div>
      <div dir="ltr" style="text-align: right;"><strong>الهاتف:</strong> ${_escape(addr.phoneNumber)} ${addr.alternatePhone.isNotEmpty ? " / ${_escape(addr.alternatePhone)}" : ""}</div>
      <div><strong>المحافظة:</strong> ${_escape(addr.governorate.isNotEmpty ? addr.governorate : addr.city)}</div>
      <div><strong>العنوان:</strong> ${_escape(addr.formattedFullAddress)}</div>
      ${order.orderNotes.isNotEmpty ? '<div style="margin-top: 3px; font-weight: 700; color: #000;"><strong>ملاحظات:</strong> ${_escape(order.orderNotes)}</div>' : ''}
    </div>
    
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
    
    <!-- Financial Summary -->
    <table style="width: 100%; border-collapse: collapse;">
      <tr>
        <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">إجمالي المنتجات:</td>
        <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px;">${AppFormatters.formatEGP(order.subTotal)}</td>
      </tr>
      <tr>
        <td colspan="3" style="text-align: right; padding: 2px 0; font-size: 11px;">مصاريف التوصيل:</td>
        <td style="text-align: left; padding: 2px 0; font-weight: 700; font-size: 11px;">$deliveryFeeDisplay</td>
      </tr>
      $discountRow
      $taxRow
    </table>
    
    <!-- Grand Total Banner -->
    <div class="grand-total-box">
      <span class="grand-total-label">المجموع المطلوب تحصيله:</span>
      <span class="grand-total-val">${AppFormatters.formatEGP(order.totalAmount)}</span>
    </div>
    
    <!-- Payment Method -->
    <div class="meta-row" style="margin-top: 4px;">
      <span>طريقة الدفع:</span>
      <strong>${_escape(order.paymentMethod)} (${_escape(order.paymentStatus)})</strong>
    </div>
    
    <!-- Barcode Section -->
    <div class="barcode-container">
      $barcodeSvg
    </div>
    
    <div class="divider-dashed"></div>
    
    <!-- Footer -->
    <div class="footer-note">
      <div>شكراً لتعاملكم مع متجر EGO Store! 🙏</div>
      <div style="font-size: 8.5px; margin-top: 2px; color: #444;">
        خدمة العملاء: support@egovapestore.com
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

/// Interactive Modal Dialog displaying styled invoice preview with actions
class _OrderInvoicePreviewDialog extends StatelessWidget {
  final OrderModel order;

  const _OrderInvoicePreviewDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 850),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColor.primary, size: 22),
                  ),
                  const SizedBox(width: AppSizes.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'invoice_title'.tr} #${order.id}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${AppFormatters.formatDateTime(order.orderDate)} • ${order.paymentMethod}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'close'.tr,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Action Toolbar (Thermal Receipt, A4 Invoice, Export CSV, Copy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final slip = _generatePlainTextSlip(order);
                      Clipboard.setData(ClipboardData(text: slip));
                      HelperFun.showNotificationAlert(
                        title: 'copied_to_clipboard'.tr,
                        message: 'invoice_title'.tr,
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: Text('copy_courier_slip'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final success = await OrderInvoicePrinter.exportOrderInvoiceCsv(order);
                      if (context.mounted && success) {
                        HelperFun.showNotificationAlert(
                          title: 'export_csv'.tr,
                          message: 'ego_order_${order.id}_invoice.csv',
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final success = OrderInvoicePrinter.printThermalOrderReceipt(order);
                      if (!success && context.mounted) {
                        HelperFun.showNotificationAlert(
                          title: 'طباعة إيصال حراري (80mm)',
                          message: 'Printing initialized in browser',
                        );
                      }
                    },
                    icon: const Icon(Icons.receipt_rounded, size: 16),
                    label: Text('receipt_thermal_80mm'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final success = OrderInvoicePrinter.printOrderInvoice(order);
                      if (!success && context.mounted) {
                        HelperFun.showNotificationAlert(
                          title: 'print_invoice'.tr,
                          message: 'printing_initialized'.tr,
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: Text('invoice_a4'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Invoice Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Invoice Sheet Card
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md + 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sheet Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EGO VAPE STORE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColor.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'متجر إيجو - مستلزمات الفيب والأجهزة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '#${order.id}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.formatDateTime(order.orderDate),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Customer & Order Info Rows
                          Container(
                            padding: const EdgeInsets.all(AppSizes.sm + 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 15, color: AppColor.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${'customer'.tr}: ${order.shippingAddress.name}',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                    const Spacer(),
                                    Text(
                                      order.shippingAddress.phoneNumber,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 15, color: AppColor.statusPending),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${'shipping_address'.tr}: ${order.shippingAddress.formattedFullAddress}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.orderNotes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${'customer_notes'.tr}: ${order.orderNotes}',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Items Table
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(4),
                              1: FlexColumnWidth(1.2),
                              2: FlexColumnWidth(1.8),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text('item'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text('quantity'.tr, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text('price'.tr, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text('total'.tr, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              ...order.items.map((itm) {
                                final variations = itm.selectedVariation.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(', ');
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itm.title,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                          if (variations.isNotEmpty || itm.sku.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              [
                                                if (variations.isNotEmpty) variations,
                                                if (itm.sku.isNotEmpty) 'SKU: ${itm.sku}',
                                              ].join(' • '),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Text(
                                        '${itm.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Text(
                                        AppFormatters.formatEGP(itm.price),
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: Text(
                                        AppFormatters.formatEGP(itm.totalItemPrice),
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColor.primary),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const Divider(height: 20),

                          // Financial Breakdown Rows
                          _buildSummaryRow(isDark, 'subtotal'.tr, AppFormatters.formatEGP(order.subTotal)),
                          _buildSummaryRow(
                            isDark,
                            'shipping_fee'.tr,
                            order.shippingCost > 0 ? AppFormatters.formatEGP(order.shippingCost) : 'free_delivery_notice'.tr,
                            isFree: order.shippingCost <= 0,
                          ),
                          if (order.discount > 0)
                            _buildSummaryRow(
                              isDark,
                              '${'discount'.tr} ${order.couponCode.isNotEmpty ? "(${order.couponCode})" : ""}',
                              '-${AppFormatters.formatEGP(order.discount)}',
                              isDiscount: true,
                            ),
                          if (order.taxFee > 0)
                            _buildSummaryRow(isDark, 'tax_fee'.tr, AppFormatters.formatEGP(order.taxFee)),

                          const Divider(height: 16),

                          // Grand Total Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${'payment'.tr}: ${order.paymentMethod}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                ),
                              ),
                              Text(
                                '${'grand_total'.tr}: ${AppFormatters.formatEGP(order.totalAmount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColor.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark, String label, String value, {bool isFree = false, bool isDiscount = false}) {
    Color? valueColor;
    if (isFree) valueColor = AppColor.success;
    if (isDiscount) valueColor = AppColor.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  static String _generatePlainTextSlip(OrderModel order) {
    final buffer = StringBuffer();
    buffer.writeln('🧾 فاتورة طلب #${order.id}');
    buffer.writeln('التاريخ: ${AppFormatters.formatDateTime(order.orderDate)}');
    buffer.writeln('العميل: ${order.shippingAddress.name} - ${order.shippingAddress.phoneNumber}');
    buffer.writeln('العنوان: ${order.shippingAddress.formattedFullAddress}');
    buffer.writeln('─' * 30);
    for (final itm in order.items) {
      buffer.writeln('• ${itm.quantity}x ${itm.title} (${AppFormatters.formatEGP(itm.totalItemPrice)})');
    }
    buffer.writeln('─' * 30);
    buffer.writeln('المجموع الكلي: ${AppFormatters.formatEGP(order.totalAmount)}');
    buffer.writeln('طريقة الدفع: ${order.paymentMethod}');
    return buffer.toString();
  }
}
