import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../utils/supplier_invoice_printer.dart';
import '../cubit/supplier_cubit.dart';
import 'record_payment_dialog.dart';

class PurchaseInvoiceDetailsDialog extends StatelessWidget {
  final PurchaseInvoiceModel invoice;

  const PurchaseInvoiceDetailsDialog({super.key, required this.invoice});

  static void show(BuildContext context, {required PurchaseInvoiceModel invoice}) {
    final cubit = context.read<SupplierCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: PurchaseInvoiceDetailsDialog(invoice: invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 750 ? 700.0 : width - 32;

    Color statusColor;
    String statusLabel;
    switch (invoice.paymentStatus) {
      case InvoicePaymentStatus.paid:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'status_paid'.tr;
        break;
      case InvoicePaymentStatus.partial:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'status_partial'.tr;
        break;
      case InvoicePaymentStatus.unpaid:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'status_unpaid'.tr;
        break;
      case InvoicePaymentStatus.overdue:
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'status_overdue'.tr;
        break;
    }

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
            // Header
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
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppColor.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${invoice.supplierName} • ${AppFormatters.formatDate(invoice.invoiceDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, size: 20, color: AppColor.primary),
                    tooltip: 'print_preview_invoice_tooltip'.tr,
                    onPressed: () => SupplierInvoicePrinter.showPurchaseInvoicePreview(context, invoice: invoice),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta Details Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'payment_method_label'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.paymentMethod,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'due_date_label'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.dueDate != null
                                    ? AppFormatters.formatDate(invoice.dueDate!)
                                    : 'immediate'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'warehouse_reception_status'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    invoice.stockReceived
                                        ? Icons.check_circle_rounded
                                        : Icons.hourglass_top_rounded,
                                    size: 14,
                                    color: invoice.stockReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    invoice.stockReceived
                                        ? 'received_and_credited'.tr
                                        : 'pending_receipt'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: invoice.stockReceived
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Items List Header
                    Text(
                      'line_items_count_title'.trParams({'count': invoice.items.length.toString()}),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoice.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final it = invoice.items[index];
                          final attrs = it.variationAttributes.values.join(' • ');

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.productTitle,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                      ),
                                      if (it.variationSku != null)
                                        Text(
                                          '${it.variationSku} ${attrs.isNotEmpty ? "($attrs)" : ""}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${it.quantity} × ${AppFormatters.formatEGP(it.unitCost)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    AppFormatters.formatEGP(it.subtotal),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Financial Summary Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'items_subtotal_label'.tr,
                            AppFormatters.formatEGP(invoice.subtotal),
                            isDark,
                          ),
                          if (invoice.taxAmount > 0)
                            _buildSummaryRow(
                              'tax_vat_label'.tr,
                              '+ ${AppFormatters.formatEGP(invoice.taxAmount)}',
                              isDark,
                            ),
                          if (invoice.shippingCost > 0)
                            _buildSummaryRow(
                              'shipping_freight_label'.tr,
                              '+ ${AppFormatters.formatEGP(invoice.shippingCost)}',
                              isDark,
                            ),
                          if (invoice.discountAmount > 0)
                            _buildSummaryRow(
                              'discount_commercial_label'.tr,
                              '- ${AppFormatters.formatEGP(invoice.discountAmount)}',
                              isDark,
                              valueColor: const Color(0xFFEF4444),
                            ),
                          const Divider(height: 12),
                          _buildSummaryRow(
                            'net_invoice_total'.tr,
                            AppFormatters.formatEGP(invoice.totalAmount),
                            isDark,
                            isBold: true,
                            valueColor: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            'col_paid'.tr,
                            AppFormatters.formatEGP(invoice.paidAmount),
                            isDark,
                          ),
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            'balance_due_label'.tr,
                            AppFormatters.formatEGP(invoice.remainingAmount),
                            isDark,
                            isBold: true,
                            valueColor: invoice.remainingAmount > 0
                                ? AppColor.error
                                : const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),

                    if (invoice.notes.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'invoice_notes_label'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: Text(
                          'print_export_btn'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => SupplierInvoicePrinter.showPurchaseInvoicePreview(
                          context,
                          invoice: invoice,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (invoice.remainingAmount > 0)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.payment_rounded, size: 16),
                          label: Text(
                            'record_payment_step_btn'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            RecordPaymentDialog.show(context, initialInvoice: invoice);
                          },
                        ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
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

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13.5 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

