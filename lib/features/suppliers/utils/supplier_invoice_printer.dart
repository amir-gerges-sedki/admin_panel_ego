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
import '../data/models/purchase_invoice_model.dart';
import '../data/models/supplier_model.dart';
import '../data/models/supplier_payment_model.dart';
import 'stub_printer_helper.dart'
    if (dart.library.js_interop) 'web_printer_helper.dart' as printer_helper;

/// Professional utility for rendering, previewing, exporting, and printing
/// Supplier Purchase Invoices, Payment Vouchers, and Supplier Account Statements.
class SupplierInvoicePrinter {
  /// Opens a browser print dialog with official styled HTML/CSS document
  static bool printHtml(String htmlContent, {String title = 'Document'}) {
    return printer_helper.printHtmlDocument(htmlContent, title: title);
  }

  // ===========================================================================
  // 1. PURCHASE INVOICE (فاتورة الشراء والتوريد)
  // ===========================================================================

  /// Shows the interactive styled modal preview for a Purchase Invoice
  static void showPurchaseInvoicePreview(
    BuildContext context, {
    required PurchaseInvoiceModel invoice,
    SupplierModel? supplier,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PurchaseInvoicePreviewDialog(
        invoice: invoice,
        supplier: supplier,
      ),
    );
  }

  /// Generates clean HTML template for printing Purchase Invoice
  static String generatePurchaseInvoiceHtml(
    PurchaseInvoiceModel invoice, {
    SupplierModel? supplier,
  }) {
    final statusColor = switch (invoice.paymentStatus) {
      InvoicePaymentStatus.paid => '#10B981',
      InvoicePaymentStatus.partial => '#F59E0B',
      InvoicePaymentStatus.unpaid => '#EF4444',
      InvoicePaymentStatus.overdue => '#DC2626',
    };

    final statusText = switch (invoice.paymentStatus) {
      InvoicePaymentStatus.paid => 'مدفوعة بالكامل (Paid in Full)',
      InvoicePaymentStatus.partial => 'مدفوعة جزئياً (Partially Paid)',
      InvoicePaymentStatus.unpaid => 'غير مدفوعة - آجل (Unpaid / Credit)',
      InvoicePaymentStatus.overdue => 'متأخرة السداد (Overdue)',
    };

    final itemsRows = StringBuffer();
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final attrs = item.variationAttributes.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');
      final skuInfo = item.variationSku != null ? ' (SKU: ${item.variationSku})' : '';
      final fullDesc = attrs.isNotEmpty ? '$attrs$skuInfo' : skuInfo;

      itemsRows.writeln('''
        <tr>
          <td style="text-align:center; width: 40px;">${i + 1}</td>
          <td>
            <strong>${_escape(item.productTitle)}</strong>
            ${fullDesc.isNotEmpty ? '<br><small style="color:#64748b;">${_escape(fullDesc)}</small>' : ''}
          </td>
          <td style="text-align:center; width: 70px;">${item.quantity}</td>
          <td style="text-align:left; width: 110px;">${AppFormatters.formatEGP(item.unitCost)}</td>
          <td style="text-align:left; width: 120px; font-weight: bold; color: #0f172a;">${AppFormatters.formatEGP(item.subtotal)}</td>
        </tr>
      ''');
    }

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>فاتورة شراء #${_escape(invoice.invoiceNumber)}</title>
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
      font-size: 13px;
      line-height: 1.5;
    }
    .invoice-card {
      max-width: 820px;
      margin: 0 auto;
      background: #ffffff;
      padding: 32px;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
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
      color: #0f172a;
      letter-spacing: 0.5px;
    }
    .brand-sub {
      color: #64748b;
      font-size: 12px;
      font-weight: 600;
      margin-top: 2px;
    }
    .invoice-meta {
      text-align: left;
    }
    .invoice-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 800;
      color: white;
      background-color: $statusColor;
      margin-top: 6px;
    }
    .meta-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
      background: #f1f5f9;
      padding: 16px;
      border-radius: 8px;
      margin-bottom: 24px;
    }
    .meta-block strong {
      display: block;
      color: #64748b;
      font-size: 11px;
      margin-bottom: 3px;
    }
    .meta-block span {
      font-weight: 700;
      font-size: 13px;
      color: #0f172a;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }
    th {
      background-color: #0f172a;
      color: #ffffff;
      font-weight: 700;
      padding: 10px 12px;
      text-align: right;
      font-size: 12px;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid #e2e8f0;
      font-size: 12.5px;
    }
    tr:nth-child(even) {
      background-color: #f8fafc;
    }
    .summary-section {
      display: flex;
      justify-content: space-between;
      gap: 24px;
      margin-bottom: 28px;
    }
    .notes-box {
      flex: 1;
      background: #f8fafc;
      border: 1px dashed #cbd5e1;
      padding: 14px;
      border-radius: 8px;
      font-size: 12px;
    }
    .totals-box {
      width: 320px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 14px;
    }
    .totals-row {
      display: flex;
      justify-content: space-between;
      padding: 4px 0;
      font-size: 12px;
      color: #475569;
    }
    .totals-row.grand-total {
      border-top: 2px solid #0f172a;
      border-bottom: 2px solid #0f172a;
      padding: 8px 0;
      margin: 8px 0;
      font-size: 15px;
      font-weight: 900;
      color: #0f172a;
    }
    .signatures-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 20px;
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #e2e8f0;
      text-align: center;
    }
    .sig-line {
      border-bottom: 1px dotted #94a3b8;
      height: 45px;
      margin-bottom: 6px;
    }
    .sig-title {
      font-size: 11px;
      color: #64748b;
      font-weight: 700;
    }
    @media print {
      body {
        background: transparent;
        padding: 0;
      }
      .invoice-card {
        border: none;
        box-shadow: none;
        padding: 0;
        max-width: 100%;
      }
      @page {
        margin: 12mm;
        size: A4 portrait;
      }
    }
  </style>
</head>
<body>
  <div class="invoice-card">
    <div class="header">
      <div>
        <div class="brand-title">EGO STORE</div>
        <div class="brand-sub">منظومة التوريد وإدارة المشتريات والمخازن • VAPE ERP</div>
      </div>
      <div class="invoice-meta">
        <h2 style="font-size: 18px; font-weight: 900; color:#0f172a;">فاتورة شراء بضاعة</h2>
        <div style="font-size: 13px; font-weight: 800; color: #475569;">#${_escape(invoice.invoiceNumber)}</div>
        <div class="invoice-badge">$statusText</div>
      </div>
    </div>

    <div class="meta-grid">
      <div class="meta-block">
        <strong>المورّد / الشركة:</strong>
        <span>${_escape(invoice.supplierName)} ${supplier?.phone.isNotEmpty == true ? '(${supplier!.phone})' : ''}</span>
      </div>
      <div class="meta-block">
        <strong>تاريخ إصدار الفاتورة:</strong>
        <span>${AppFormatters.formatDate(invoice.invoiceDate)}</span>
      </div>
      <div class="meta-block">
        <strong>طريقة الدفع المتفق عليها:</strong>
        <span>${_escape(invoice.paymentMethod)}</span>
      </div>
      <div class="meta-block">
        <strong>تاريخ الاستحقاق:</strong>
        <span>${invoice.dueDate != null ? AppFormatters.formatDate(invoice.dueDate!) : 'فوري (Immediate)'}</span>
      </div>
      <div class="meta-block">
        <strong>استلام المخزن:</strong>
        <span>${invoice.stockReceived ? '✅ تم إيداع الكميات في رصيد المخزن' : '⏳ معلقة قيد الفحص والاستلام'}</span>
      </div>
      <div class="meta-block">
        <strong>الرقم الضريبي للمورّد:</strong>
        <span>${supplier?.taxNumber.isNotEmpty == true ? _escape(supplier!.taxNumber) : 'غير مسجل'}</span>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th style="text-align:center;">#</th>
          <th>الصنف والوصف</th>
          <th style="text-align:center;">الكمية</th>
          <th style="text-align:left;">سعر الوحدة</th>
          <th style="text-align:left;">الإجمالي</th>
        </tr>
      </thead>
      <tbody>
        $itemsRows
      </tbody>
    </table>

    <div class="summary-section">
      <div class="notes-box">
        <strong style="display:block; margin-bottom: 6px; color: #0f172a;">ملاحظات وشروط الفاتورة:</strong>
        <p style="color: #475569;">${invoice.notes.isNotEmpty ? _escape(invoice.notes) : 'لا توجد ملاحظات إضافية. تعتبر هذه الفاتورة مستند توريد رسمي معتمد لقيد المخزون والحسابات.'}</p>
      </div>

      <div class="totals-box">
        <div class="totals-row">
          <span>إجمالي الأصناف:</span>
          <span>${AppFormatters.formatEGP(invoice.subtotal)}</span>
        </div>
        ${invoice.taxAmount > 0 ? '''
        <div class="totals-row">
          <span>ضريبة القيمة المضافة:</span>
          <span>+ ${AppFormatters.formatEGP(invoice.taxAmount)}</span>
        </div>''' : ''}
        ${invoice.shippingCost > 0 ? '''
        <div class="totals-row">
          <span>تكاليف الشحن والتوصيل:</span>
          <span>+ ${AppFormatters.formatEGP(invoice.shippingCost)}</span>
        </div>''' : ''}
        ${invoice.discountAmount > 0 ? '''
        <div class="totals-row" style="color: #dc2626;">
          <span>الخصم الممنوح:</span>
          <span>- ${AppFormatters.formatEGP(invoice.discountAmount)}</span>
        </div>''' : ''}
        <div class="totals-row grand-total">
          <span>صافي إجمالي الفاتورة:</span>
          <span>${AppFormatters.formatEGP(invoice.totalAmount)}</span>
        </div>
        <div class="totals-row" style="color: #10b981; font-weight: bold;">
          <span>المبلغ المسدد:</span>
          <span>${AppFormatters.formatEGP(invoice.paidAmount)}</span>
        </div>
        <div class="totals-row" style="color: ${invoice.remainingAmount > 0 ? '#dc2626' : '#10b981'}; font-weight: 800;">
          <span>الرصيد المتبقي (آجل):</span>
          <span>${AppFormatters.formatEGP(invoice.remainingAmount)}</span>
        </div>
      </div>
    </div>

    <div class="signatures-grid">
      <div>
        <div class="sig-line"></div>
        <div class="sig-title">مسؤول المشتريات والتوريد</div>
      </div>
      <div>
        <div class="sig-line"></div>
        <div class="sig-title">أمين المخزن (استلام البضاعة)</div>
      </div>
      <div>
        <div class="sig-line"></div>
        <div class="sig-title">الإدارة المالية والاعتماد</div>
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Exports Purchase Invoice items as CSV
  static Future<bool> exportPurchaseInvoiceCsv(PurchaseInvoiceModel invoice) async {
    final buffer = StringBuffer();
    buffer.writeln('رقم الفاتورة,المورّد,تاريخ الفاتورة,طريقة الدفع,حالة السداد');
    buffer.writeln(
        '${invoice.invoiceNumber},"${invoice.supplierName}",${AppFormatters.formatDate(invoice.invoiceDate)},${invoice.paymentMethod},${invoice.paymentStatus.value}');
    buffer.writeln();
    buffer.writeln('م,الصنف,الرمز (SKU),الخصائص,الكمية,سعر الوحدة,الإجمالي الفرعي');

    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final attrs = item.variationAttributes.entries
          .map((e) => '${e.key}:${e.value}')
          .join(';');
      buffer.writeln(
          '${i + 1},"${item.productTitle}","${item.variationSku ?? ''}","$attrs",${item.quantity},${item.unitCost},${item.subtotal}');
    }

    buffer.writeln();
    buffer.writeln('إجمالي الأصناف,,,,,,${invoice.subtotal}');
    buffer.writeln('الضريبة,,,,,,${invoice.taxAmount}');
    buffer.writeln('الشحن والنقل,,,,,,${invoice.shippingCost}');
    buffer.writeln('الخصم,,,,,,${invoice.discountAmount}');
    buffer.writeln('الصافي الكلي,,,,,,${invoice.totalAmount}');
    buffer.writeln('المسدد,,,,,,${invoice.paidAmount}');
    buffer.writeln('المتبقي,,,,,,${invoice.remainingAmount}');

    return await file_saver.saveOrDownloadFile(
      fileName: 'invoice_${invoice.invoiceNumber}.csv',
      content: buffer.toString(),
    );
  }

  // ===========================================================================
  // 2. SUPPLIER PAYMENT VOUCHER (سند الصرف والدفع)
  // ===========================================================================

  /// Shows the interactive styled modal preview for a Payment Voucher
  static void showPaymentVoucherPreview(
    BuildContext context, {
    required SupplierPaymentModel payment,
    SupplierModel? supplier,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PaymentVoucherPreviewDialog(
        payment: payment,
        supplier: supplier,
      ),
    );
  }

  /// Generates clean HTML template for printing Payment Voucher
  static String generatePaymentVoucherHtml(
    SupplierPaymentModel payment, {
    SupplierModel? supplier,
  }) {
    final refDisplay = payment.referenceNumber.isNotEmpty
        ? payment.referenceNumber
        : 'PV-${payment.id.length > 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}';

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>سند صرف وسداد - $refDisplay</title>
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
      font-size: 13px;
    }
    .voucher-card {
      max-width: 780px;
      margin: 0 auto;
      background: #ffffff;
      padding: 32px;
      border-radius: 12px;
      border: 2px solid #0f172a;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px dashed #0f172a;
      padding-bottom: 16px;
      margin-bottom: 20px;
    }
    .brand-title {
      font-size: 22px;
      font-weight: 900;
    }
    .voucher-badge {
      background-color: #10b981;
      color: white;
      padding: 4px 14px;
      border-radius: 6px;
      font-weight: 800;
      font-size: 12px;
    }
    .amount-banner {
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      color: #ffffff;
      padding: 16px 20px;
      border-radius: 8px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    .amount-val {
      font-size: 24px;
      font-weight: 900;
      color: #34d399;
    }
    .fields-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }
    .fields-table td {
      padding: 10px 12px;
      border: 1px solid #e2e8f0;
      font-size: 13px;
    }
    .fields-table td.label {
      width: 180px;
      background: #f1f5f9;
      font-weight: 700;
      color: #475569;
    }
    .signatures {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 24px;
      margin-top: 36px;
      text-align: center;
    }
    .sig-box {
      border-top: 1px solid #94a3b8;
      padding-top: 8px;
      font-size: 11px;
      font-weight: 700;
      color: #475569;
    }
    @media print {
      body { background: transparent; padding: 0; }
      .voucher-card { border: 1.5px solid #000; box-shadow: none; padding: 16px; max-width: 100%; }
      @page { margin: 15mm; size: A5 landscape; }
    }
  </style>
</head>
<body>
  <div class="voucher-card">
    <div class="header">
      <div>
        <div class="brand-title">EGO STORE</div>
        <div style="font-size: 11.5px; color: #64748b;">إدارة الحسابات والخزينة • VAPE ERP</div>
      </div>
      <div style="text-align:left;">
        <h2 style="font-size: 16px; font-weight: 900;">سند صرف نقدي / بنكي</h2>
        <div style="font-size: 11.5px; color: #64748b; font-weight: 700;">رقم السند: $refDisplay</div>
      </div>
      <div>
        <span class="voucher-badge">سداد معتمد</span>
      </div>
    </div>

    <div class="amount-banner">
      <div>
        <div style="font-size: 11px; color: #94a3b8;">المبلغ المنصرف (Amount Paid)</div>
        <div style="font-size: 14px; font-weight: 700;">فقط وقدره بالجنيه المصري</div>
      </div>
      <div class="amount-val">${AppFormatters.formatEGP(payment.amount)}</div>
    </div>

    <table class="fields-table">
      <tr>
        <td class="label">يُصرف إلى السادة / المورّد:</td>
        <td><strong>${_escape(payment.supplierName)}</strong> ${supplier?.phone.isNotEmpty == true ? '(${supplier!.phone})' : ''}</td>
      </tr>
      <tr>
        <td class="label">تاريخ الصرف والسداد:</td>
        <td><strong>${AppFormatters.formatDate(payment.paymentDate)}</strong></td>
      </tr>
      <tr>
        <td class="label">طريقة وقناة الدفع:</td>
        <td><strong>${_escape(payment.paymentMethod)}</strong> ${payment.referenceNumber.isNotEmpty ? '• مرجع العملية: ${_escape(payment.referenceNumber)}' : ''}</td>
      </tr>
      <tr>
        <td class="label">البيان / الفاتورة المرتبطة:</td>
        <td>${payment.invoiceNumber != null && payment.invoiceNumber!.isNotEmpty ? 'سداد يخص فاتورة الشراء رقم <strong>${_escape(payment.invoiceNumber!)}</strong>' : 'دفعة تحت الحساب / سداد عام لرصيد المورّد'}</td>
      </tr>
      <tr>
        <td class="label">ملاحظات وتفاصيل إضافية:</td>
        <td>${payment.notes.isNotEmpty ? _escape(payment.notes) : 'تم تسليم المبلغ وقيده في حسابات وسجلات الموردين.'}</td>
      </tr>
    </table>

    <div class="signatures">
      <div>
        <div style="height: 40px;"></div>
        <div class="sig-box">توقيع أمين الخزينة / الحسابات</div>
      </div>
      <div>
        <div style="height: 40px;"></div>
        <div class="sig-box">توقيع المستلم / مندوب المورّد</div>
      </div>
      <div>
        <div style="height: 40px;"></div>
        <div class="sig-box">اعتماد الإدارة والمدير المالي</div>
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Exports Payment Voucher as CSV
  static Future<bool> exportPaymentVoucherCsv(SupplierPaymentModel payment) async {
    final buffer = StringBuffer();
    buffer.writeln('رقم السند,المورّد,تاريخ السداد,طريقة الدفع,رقم المرجع,الفاتورة المرتبطة,المبلغ,ملاحظات');
    buffer.writeln(
        '"${payment.id}","${payment.supplierName}",${AppFormatters.formatDate(payment.paymentDate)},${payment.paymentMethod},"${payment.referenceNumber}","${payment.invoiceNumber ?? 'سداد عام'}",${payment.amount},"${payment.notes}"');

    return await file_saver.saveOrDownloadFile(
      fileName: 'payment_voucher_${payment.id}.csv',
      content: buffer.toString(),
    );
  }

  // ===========================================================================
  // 3. SUPPLIER ACCOUNT STATEMENT (كشف حساب المورّد)
  // ===========================================================================

  /// Shows the interactive styled modal preview for a Supplier Statement of Account
  static void showSupplierStatementPreview(
    BuildContext context, {
    required SupplierModel supplier,
    required List<PurchaseInvoiceModel> invoices,
    required List<SupplierPaymentModel> payments,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SupplierStatementPreviewDialog(
        supplier: supplier,
        invoices: invoices,
        payments: payments,
      ),
    );
  }

  /// Generates clean HTML template for printing Supplier Statement of Account
  static String generateSupplierStatementHtml(
    SupplierModel supplier,
    List<PurchaseInvoiceModel> invoices,
    List<SupplierPaymentModel> payments,
  ) {
    // Combine and order chronologically
    final txs = <_PrintLedgerEntry>[];
    for (final inv in invoices.where((i) => i.supplierId == supplier.id)) {
      txs.add(_PrintLedgerEntry(
        date: inv.invoiceDate,
        type: 'فاتورة شراء',
        ref: inv.invoiceNumber,
        notes: '${inv.items.length} أصناف • ${inv.paymentMethod}',
        debit: inv.totalAmount, // Inflow increases payable
        credit: 0.0,
      ));
    }
    for (final p in payments.where((p) => p.supplierId == supplier.id)) {
      txs.add(_PrintLedgerEntry(
        date: p.paymentDate,
        type: 'سند صرف (${p.paymentMethod})',
        ref: p.referenceNumber.isNotEmpty ? p.referenceNumber : (p.invoiceNumber ?? 'سداد'),
        notes: p.notes.isNotEmpty ? p.notes : 'سداد دفعة للمورّد',
        debit: 0.0,
        credit: p.amount, // Outflow decreases payable
      ));
    }

    txs.sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0.0;
    final txRows = StringBuffer();
    for (int i = 0; i < txs.length; i++) {
      final t = txs[i];
      runningBalance += (t.debit - t.credit);
      txRows.writeln('''
        <tr>
          <td style="text-align:center;">${i + 1}</td>
          <td>${AppFormatters.formatDate(t.date)}</td>
          <td><strong>${_escape(t.type)}</strong></td>
          <td>${_escape(t.ref)}</td>
          <td><small style="color:#64748b;">${_escape(t.notes)}</small></td>
          <td style="text-align:left; color:#ef4444; font-weight:700;">${t.debit > 0 ? AppFormatters.formatEGP(t.debit) : '-'}</td>
          <td style="text-align:left; color:#10b981; font-weight:700;">${t.credit > 0 ? AppFormatters.formatEGP(t.credit) : '-'}</td>
          <td style="text-align:left; font-weight:800; color:${runningBalance > 0 ? '#ef4444' : '#10b981'};">${AppFormatters.formatEGP(runningBalance)}</td>
        </tr>
      ''');
    }

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>كشف حساب المورّد - ${_escape(supplier.name)}</title>
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
      font-size: 12.5px;
    }
    .statement-card {
      max-width: 860px;
      margin: 0 auto;
      background: #ffffff;
      padding: 32px;
      border-radius: 12px;
      border: 1px solid #cbd5e1;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 16px;
      margin-bottom: 20px;
    }
    .brand-title { font-size: 22px; font-weight: 900; }
    .kpi-row {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
      margin-bottom: 24px;
    }
    .kpi-box {
      background: #f1f5f9;
      padding: 12px 16px;
      border-radius: 8px;
      text-align: center;
    }
    .kpi-box .val { font-size: 16px; font-weight: 900; margin-top: 4px; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }
    th {
      background-color: #0f172a;
      color: #ffffff;
      padding: 8px 10px;
      font-size: 11.5px;
    }
    td {
      padding: 8px 10px;
      border-bottom: 1px solid #e2e8f0;
      font-size: 12px;
    }
    tr:nth-child(even) { background-color: #f8fafc; }
    @media print {
      body { background: transparent; padding: 0; }
      .statement-card { border: none; box-shadow: none; padding: 0; max-width: 100%; }
      @page { margin: 12mm; size: A4 portrait; }
    }
  </style>
</head>
<body>
  <div class="statement-card">
    <div class="header">
      <div>
        <div class="brand-title">EGO STORE</div>
        <div style="font-size: 11px; color: #64748b;">كشف حساب تفصيلي للمورّد • VAPE ERP</div>
      </div>
      <div style="text-align: left;">
        <h2 style="font-size: 17px; font-weight: 900;">كشف حساب مورّد</h2>
        <div style="font-size: 13px; font-weight: 800; color: #0f172a;">${_escape(supplier.name)}</div>
        <div style="font-size: 11px; color: #64748b;">${supplier.phone} ${supplier.contactPerson.isNotEmpty ? '• المسؤول: ${_escape(supplier.contactPerson)}' : ''}</div>
      </div>
    </div>

    <div class="kpi-row">
      <div class="kpi-box">
        <div style="font-size: 11px; color: #64748b;">إجمالي المشتريات والتوريدات</div>
        <div class="val" style="color: #2563eb;">${AppFormatters.formatEGP(supplier.totalPurchases)}</div>
      </div>
      <div class="kpi-box">
        <div style="font-size: 11px; color: #64748b;">إجمالي المسدد للمورّد</div>
        <div class="val" style="color: #10b981;">${AppFormatters.formatEGP(supplier.totalPaid)}</div>
      </div>
      <div class="kpi-box">
        <div style="font-size: 11px; color: #64748b;">الرصيد القائم المستحق (آجل)</div>
        <div class="val" style="color: ${supplier.balanceDue > 0 ? '#ef4444' : '#10b981'};">${AppFormatters.formatEGP(supplier.balanceDue)}</div>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th style="text-align:center;">#</th>
          <th style="text-align:right;">التاريخ</th>
          <th style="text-align:right;">نوع الحركة</th>
          <th style="text-align:right;">المرجع / الفاتورة</th>
          <th style="text-align:right;">البيان</th>
          <th style="text-align:left;">مشتريات (+)</th>
          <th style="text-align:left;">مدفوعات (-)</th>
          <th style="text-align:left;">الرصيد التراكمي</th>
        </tr>
      </thead>
      <tbody>
        ${txRows.isNotEmpty ? txRows.toString() : '<tr><td colspan="8" style="text-align:center; padding: 24px; color: #64748b;">لا توجد معاملات مسجلة</td></tr>'}
      </tbody>
    </table>

    <div style="display: flex; justify-content: space-between; margin-top: 30px; font-size: 11px; color: #64748b; border-top: 1px solid #e2e8f0; padding-top: 10px;">
      <div>تاريخ إصدار الكشف: ${AppFormatters.formatDate(DateTime.now())}</div>
      <div>مستند محاسبي معتمد من منظومة EGO ERP</div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Exports Supplier Statement of Account as CSV
  static Future<bool> exportSupplierLedgerCsv(
    SupplierModel supplier,
    List<PurchaseInvoiceModel> invoices,
    List<SupplierPaymentModel> payments,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('كشف حساب المورّد: ${supplier.name}');
    buffer.writeln('الهاتف: ${supplier.phone},المسؤول: ${supplier.contactPerson}');
    buffer.writeln('إجمالي المشتريات: ${supplier.totalPurchases},إجمالي المسدد: ${supplier.totalPaid},الرصيد المستحق: ${supplier.balanceDue}');
    buffer.writeln();
    buffer.writeln('م,التاريخ,نوع الحركة,المرجع,البيان,مشتريات (+),مدفوعات (-),الرصيد');

    final txs = <_PrintLedgerEntry>[];
    for (final inv in invoices.where((i) => i.supplierId == supplier.id)) {
      txs.add(_PrintLedgerEntry(
        date: inv.invoiceDate,
        type: 'فاتورة شراء',
        ref: inv.invoiceNumber,
        notes: '${inv.items.length} أصناف',
        debit: inv.totalAmount,
        credit: 0.0,
      ));
    }
    for (final p in payments.where((p) => p.supplierId == supplier.id)) {
      txs.add(_PrintLedgerEntry(
        date: p.paymentDate,
        type: 'سند صرف (${p.paymentMethod})',
        ref: p.referenceNumber.isNotEmpty ? p.referenceNumber : (p.invoiceNumber ?? 'سداد'),
        notes: p.notes,
        debit: 0.0,
        credit: p.amount,
      ));
    }

    txs.sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0.0;
    for (int i = 0; i < txs.length; i++) {
      final t = txs[i];
      runningBalance += (t.debit - t.credit);
      buffer.writeln(
          '${i + 1},${AppFormatters.formatDate(t.date)},"${t.type}","${t.ref}","${t.notes}",${t.debit},${t.credit},$runningBalance');
    }

    return await file_saver.saveOrDownloadFile(
      fileName: 'supplier_statement_${supplier.name.replaceAll(' ', '_')}.csv',
      content: buffer.toString(),
    );
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

class _PrintLedgerEntry {
  final DateTime date;
  final String type;
  final String ref;
  final String notes;
  final double debit;
  final double credit;

  _PrintLedgerEntry({
    required this.date,
    required this.type,
    required this.ref,
    required this.notes,
    required this.debit,
    required this.credit,
  });
}

// =============================================================================
// MODAL PREVIEWS (Flutter In-App UI Dialogs)
// =============================================================================

class _PurchaseInvoicePreviewDialog extends StatelessWidget {
  final PurchaseInvoiceModel invoice;
  final SupplierModel? supplier;

  const _PurchaseInvoicePreviewDialog({required this.invoice, this.supplier});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 800 ? 760.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md - 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print_rounded, color: AppColor.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'printable_purchase_invoice'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          '${invoice.invoiceNumber} • ${invoice.supplierName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document Preview Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColor.darkBorder : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EGO VAPE STORE',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColor.primary),
                              ),
                              Text(
                                'procurement_erp_title'.tr,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '#${invoice.invoiceNumber}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              Text(
                                AppFormatters.formatDate(invoice.invoiceDate),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Supplier & Meta Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${'supplier_label'.tr}: ${invoice.supplierName}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${'payment_label'.tr}: ${invoice.paymentMethod}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

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
                              color: isDark ? AppColor.darkCard : Colors.grey.shade100,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('item_col'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('qty_col'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('unit_cost_col'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('subtotal_col'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            ],
                          ),
                          ...invoice.items.map((it) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      it.variationSku != null ? '${it.productTitle} (${it.variationSku})' : it.productTitle,
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('${it.quantity}', style: const TextStyle(fontSize: 11.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(AppFormatters.formatEGP(it.unitCost), style: const TextStyle(fontSize: 11.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      AppFormatters.formatEGP(it.subtotal),
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                      const Divider(height: 24),

                      // Totals Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'paid_col'.tr}: ${AppFormatters.formatEGP(invoice.paidAmount)}',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${'remaining_col'.tr}: ${AppFormatters.formatEGP(invoice.remainingAmount)}',
                                  style: TextStyle(
                                    color: invoice.remainingAmount > 0 ? AppColor.error : const Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${'grand_total_col'.tr}: ${AppFormatters.formatEGP(invoice.totalAmount)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColor.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: Text(
                          'print_invoice_action'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          final html = SupplierInvoicePrinter.generatePurchaseInvoiceHtml(
                            invoice,
                            supplier: supplier,
                          );
                          SupplierInvoicePrinter.printHtml(html, title: 'Invoice #${invoice.invoiceNumber}');
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text('export_csv_btn'.tr),
                        onPressed: () async {
                          final ok = await SupplierInvoicePrinter.exportPurchaseInvoiceCsv(invoice);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('invoice_csv_downloaded'.tr)),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'copy_summary_tooltip'.tr,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          final text = 'Purchase Invoice #${invoice.invoiceNumber}\nSupplier: ${invoice.supplierName}\nDate: ${AppFormatters.formatDate(invoice.invoiceDate)}\nTotal: ${AppFormatters.formatEGP(invoice.totalAmount)}\nPaid: ${AppFormatters.formatEGP(invoice.paidAmount)}\nRemaining: ${AppFormatters.formatEGP(invoice.remainingAmount)}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('summary_copied_to_clipboard'.tr)),
                          );
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentVoucherPreviewDialog extends StatelessWidget {
  final SupplierPaymentModel payment;
  final SupplierModel? supplier;

  const _PaymentVoucherPreviewDialog({required this.payment, this.supplier});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 750 ? 680.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md - 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'payment_voucher_receipt'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          '${payment.supplierName} • ${AppFormatters.formatEGP(payment.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document Preview Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColor.darkBorder : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EGO STORE',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColor.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'authorized_voucher'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkCard : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'amount_paid_label'.tr,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              AppFormatters.formatEGP(payment.amount),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details List
                      _buildDetailRow('payee_label'.tr, payment.supplierName, isDark),
                      _buildDetailRow('date_label'.tr, AppFormatters.formatDate(payment.paymentDate), isDark),
                      _buildDetailRow('method_label'.tr, payment.paymentMethod, isDark),
                      if (payment.referenceNumber.isNotEmpty)
                        _buildDetailRow('ref_num_label'.tr, payment.referenceNumber, isDark),
                      _buildDetailRow(
                        'description_label'.tr,
                        payment.invoiceNumber != null && payment.invoiceNumber!.isNotEmpty
                            ? 'for_invoice_num'.trParams({'number': payment.invoiceNumber!})
                            : 'general_account_payment'.tr,
                        isDark,
                      ),
                      if (payment.notes.isNotEmpty)
                        _buildDetailRow('notes_label'.tr, payment.notes, isDark),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: Text(
                          'print_voucher_action'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          final html = SupplierInvoicePrinter.generatePaymentVoucherHtml(
                            payment,
                            supplier: supplier,
                          );
                          SupplierInvoicePrinter.printHtml(html, title: 'Payment Voucher ${payment.id}');
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text('export_csv_btn'.tr),
                        onPressed: () async {
                          final ok = await SupplierInvoicePrinter.exportPaymentVoucherCsv(payment);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('voucher_csv_downloaded'.tr)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierStatementPreviewDialog extends StatelessWidget {
  final SupplierModel supplier;
  final List<PurchaseInvoiceModel> invoices;
  final List<SupplierPaymentModel> payments;

  const _SupplierStatementPreviewDialog({
    required this.supplier,
    required this.invoices,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 850 ? 800.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md - 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'supplier_statement_header'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          '${supplier.name} • ${AppFormatters.formatEGP(supplier.balanceDue)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Financial KPIs
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatementKpi(
                            'total_purchases_kpi'.tr,
                            AppFormatters.formatEGP(supplier.totalPurchases),
                            const Color(0xFF3B82F6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatementKpi(
                            'total_paid_kpi'.tr,
                            AppFormatters.formatEGP(supplier.totalPaid),
                            const Color(0xFF10B981),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatementKpi(
                            'balance_due_kpi'.tr,
                            AppFormatters.formatEGP(supplier.balanceDue),
                            supplier.balanceDue > 0 ? AppColor.error : const Color(0xFF10B981),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    Text(
                      'transaction_history_label'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkSubCard : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColor.darkBorder : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          ...invoices.where((i) => i.supplierId == supplier.id).map((inv) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFFEF4444), size: 18),
                                title: Text('${'purchase_invoice_tx'.tr} #${inv.invoiceNumber}'),
                                subtitle: Text(AppFormatters.formatDate(inv.invoiceDate)),
                                trailing: Text(
                                  '+${AppFormatters.formatEGP(inv.totalAmount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                                ),
                              )),
                          ...payments.where((p) => p.supplierId == supplier.id).map((pay) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.arrow_outward_rounded, color: Color(0xFF10B981), size: 18),
                                title: Text('${'payment_voucher_tx'.tr} (${pay.paymentMethod})'),
                                subtitle: Text(AppFormatters.formatDate(pay.paymentDate)),
                                trailing: Text(
                                  '-${AppFormatters.formatEGP(pay.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: Text(
                          'print_statement_btn'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          final html = SupplierInvoicePrinter.generateSupplierStatementHtml(
                            supplier,
                            invoices,
                            payments,
                          );
                          SupplierInvoicePrinter.printHtml(html, title: 'Statement ${supplier.name}');
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text('export_csv_btn'.tr),
                        onPressed: () async {
                          final ok = await SupplierInvoicePrinter.exportSupplierLedgerCsv(
                            supplier,
                            invoices,
                            payments,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('statement_csv_downloaded'.tr)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementKpi(String label, String val, Color col, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: col)),
        ],
      ),
    );
  }
}
