import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/supplier_payment_model.dart';
import '../../utils/supplier_invoice_printer.dart';
import 'create_purchase_invoice_dialog.dart';
import 'record_payment_dialog.dart';

class SupplierLedgerDialog extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierLedgerDialog({super.key, required this.supplier});

  static void show(BuildContext context, {required SupplierModel supplier}) {
    final cubit = context.read<SupplierCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: SupplierLedgerDialog(supplier: supplier),
      ),
    );
  }

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
              child: BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  final invoices = state is SupplierLoaded
                      ? state.invoices.where((i) => i.supplierId == supplier.id).toList()
                      : <PurchaseInvoiceModel>[];
                  final payments = state is SupplierLoaded
                      ? state.payments.where((p) => p.supplierId == supplier.id).toList()
                      : <SupplierPaymentModel>[];

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColor.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'supplier_statement_name'.trParams({'name': supplier.name}),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${supplier.contactPerson.isNotEmpty ? supplier.contactPerson : "Authorized Vendor"} • ${supplier.phone}',
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
                        tooltip: 'print_statement_tooltip'.tr,
                        onPressed: () => SupplierInvoicePrinter.showSupplierStatementPreview(
                          context,
                          supplier: supplier,
                          invoices: invoices,
                          payments: payments,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Financial Balance KPIs
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkCard : AppColor.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildKpi(
                    'total_purchases_kpi'.tr,
                    AppFormatters.formatEGP(supplier.totalPurchases),
                    const Color(0xFF3B82F6),
                    isDark,
                  ),
                  _buildKpi(
                    'total_paid_kpi'.tr,
                    AppFormatters.formatEGP(supplier.totalPaid),
                    const Color(0xFF10B981),
                    isDark,
                  ),
                  _buildKpi(
                    'balance_due_kpi'.tr,
                    AppFormatters.formatEGP(supplier.balanceDue),
                    supplier.balanceDue > 0 ? AppColor.error : const Color(0xFF10B981),
                    isDark,
                  ),
                ],
              ),
            ),

            // Transactions Feed
            Flexible(
              child: BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  if (state is! SupplierLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invoices = state.invoices
                      .where((i) => i.supplierId == supplier.id)
                      .toList();
                  final payments = state.payments
                      .where((p) => p.supplierId == supplier.id)
                      .toList();

                  // Combine into single transaction list
                  final txs = <_LedgerTx>[];
                  for (final inv in invoices) {
                    txs.add(_LedgerTx(
                      date: inv.invoiceDate,
                      title: '${'purchase_invoice_tx'.tr} #${inv.invoiceNumber}',
                      subtitle: '${'items_pieces_count_txt'.trParams({'count': inv.items.length.toString()})} • ${inv.paymentMethod}',
                      amount: inv.totalAmount,
                      isDebit: true, // Inflow of goods, increases payable
                      tag: inv.paymentStatus.value.toUpperCase(),
                      invoice: inv,
                    ));
                  }

                  for (final p in payments) {
                    txs.add(_LedgerTx(
                      date: p.paymentDate,
                      title: '${'payment_voucher_tx'.tr} (${p.paymentMethod})',
                      subtitle: p.referenceNumber.isNotEmpty
                          ? '${'ref_prefix'.tr} ${p.referenceNumber}'
                          : (p.notes.isNotEmpty ? p.notes : 'supplier_payout'.tr),
                      amount: p.amount,
                      isDebit: false, // Outflow of cash, decreases payable
                      tag: 'paid_tag'.tr,
                      payment: p,
                    ));
                  }

                  txs.sort((a, b) => b.date.compareTo(a.date));

                  if (txs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Text(
                          'no_financial_records_supplier'.tr,
                          style: TextStyle(
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: txs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = txs[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tx.isDebit
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                    : const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                tx.isDebit
                                    ? Icons.receipt_long_rounded
                                    : Icons.arrow_outward_rounded,
                                color: tx.isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${AppFormatters.formatDate(tx.date)} • ${tx.subtitle}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tx.isDebit ? "+" : "-"}${AppFormatters.formatEGP(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: tx.isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColor.darkCard : AppColor.lightCard,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tx.tag,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 18),
                              tooltip: tx.invoice != null
                                  ? 'print_invoice_tooltip'.tr
                                  : 'print_voucher_tooltip'.tr,
                              onPressed: () {
                                if (tx.invoice != null) {
                                  SupplierInvoicePrinter.showPurchaseInvoicePreview(
                                    context,
                                    invoice: tx.invoice!,
                                    supplier: supplier,
                                  );
                                } else if (tx.payment != null) {
                                  SupplierInvoicePrinter.showPaymentVoucherPreview(
                                    context,
                                    payment: tx.payment!,
                                    supplier: supplier,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
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
              child: BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  final invoices = state is SupplierLoaded
                      ? state.invoices.where((i) => i.supplierId == supplier.id).toList()
                      : <PurchaseInvoiceModel>[];
                  final payments = state is SupplierLoaded
                      ? state.payments.where((p) => p.supplierId == supplier.id).toList()
                      : <SupplierPaymentModel>[];

                  return Wrap(
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
                          OutlinedButton.icon(
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: Text(
                              'print_statement_btn'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => SupplierInvoicePrinter.showSupplierStatementPreview(
                              context,
                              supplier: supplier,
                              invoices: invoices,
                              payments: payments,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                            label: Text(
                              'new_invoice_btn'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              CreatePurchaseInvoiceDialog.show(context, initialSupplierId: supplier.id);
                            },
                          ),
                          if (supplier.balanceDue > 0)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.payment_rounded, size: 16),
                              label: Text(
                                'pay_vendor_btn'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                RecordPaymentDialog.show(context, initialSupplier: supplier);
                              },
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('close'.tr),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LedgerTx {
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isDebit;
  final String tag;
  final PurchaseInvoiceModel? invoice;
  final SupplierPaymentModel? payment;

  _LedgerTx({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDebit,
    required this.tag,
    this.invoice,
    this.payment,
  });
}

