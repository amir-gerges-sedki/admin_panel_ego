import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../../utils/supplier_invoice_printer.dart';
import '../widgets/create_purchase_invoice_dialog.dart';
import '../widgets/purchase_invoice_details_dialog.dart';
import '../widgets/record_payment_dialog.dart';
import '../widgets/supplier_form_dialog.dart';
import '../widgets/supplier_ledger_dialog.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SupplierCubit>().loadSuppliersData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SupplierError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SupplierCubit>().loadSuppliersData(),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (state is! SupplierLoaded) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Header
              _buildHeader(context, isDark),
              const SizedBox(height: AppSizes.md),

              // KPI Cards Row
              _buildKpisRow(state, isDark),
              const SizedBox(height: AppSizes.lg),

              // Tab Bar Container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColor.primary,
                  indicatorWeight: 3,
                  labelColor: AppColor.primary,
                  unselectedLabelColor:
                      isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.business_rounded, size: 18),
                      text: 'tab_suppliers_dir_count'.trParams({'count': '${state.suppliers.length}'}),
                    ),
                    Tab(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      text: 'tab_invoices_count'.trParams({'count': '${state.invoices.length}'}),
                    ),
                    Tab(
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      text: 'tab_payments_count'.trParams({'count': '${state.payments.length}'}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Tab Views
              SizedBox(
                height: 750,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSuppliersTab(context, state, isDark),
                    _buildInvoicesTab(context, state, isDark),
                    _buildPaymentsTab(context, state, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'suppliers_inflow_hub'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'suppliers_inflow_desc'.tr,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
          ],
        ),
          Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                'smart_reorder_po_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => _triggerSmartReorderPO(context),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.add_business_rounded, size: 16),
              label: Text(
                'btn_new_supplier'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => SupplierFormDialog.show(context),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: Text(
                'btn_new_invoice'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => CreatePurchaseInvoiceDialog.show(context),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: Text(
                'btn_pay_vendor'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => RecordPaymentDialog.show(context),
            ),
          ],
        ),
      ],
    );
  }

  void _triggerSmartReorderPO(BuildContext context) {
    final prodState = context.read<ProductCubit>().state;
    final allProducts =
        prodState is ProductLoaded ? prodState.products : <ProductModel>[];
    final settingsState = context.read<SettingsCubit>().state;
    final threshold = settingsState is SettingsLoaded
        ? settingsState.settings.lowStockThreshold
        : 10;

    final List<PurchaseInvoiceItemModel> poItems = [];

    for (final p in allProducts) {
      if (p.productVariations.isNotEmpty) {
        final lowVars = p.productVariations.where((v) {
          final t = v.lowStockThreshold ?? p.lowStockThreshold ?? threshold;
          return v.stock <= t;
        }).toList();

        for (final v in lowVars) {
          final reorderQty = (threshold * 2 - v.stock).clamp(5, 50);
          final unitCost = v.costPrice > 0 ? v.costPrice : p.costPrice;

          poItems.add(
            PurchaseInvoiceItemModel(
              productId: p.id,
              productTitle: p.displayTitle,
              variationSku: v.sku,
              variationAttributes: v.attributeValues,
              quantity: reorderQty,
              unitCost: unitCost,
              subtotal: reorderQty * unitCost,
            ),
          );
        }
      } else {
        final t = p.lowStockThreshold ?? threshold;
        if (p.stock <= t) {
          final reorderQty = (t * 2 - p.stock).clamp(5, 50);
          poItems.add(
            PurchaseInvoiceItemModel(
              productId: p.id,
              productTitle: p.displayTitle,
              variationSku: '',
              variationAttributes: const {},
              quantity: reorderQty,
              unitCost: p.costPrice,
              subtotal: reorderQty * p.costPrice,
            ),
          );
        }
      }
    }

    if (poItems.isEmpty) {
      HelperFun.showNotificationAlert(
        title: 'smart_reorder_po_btn'.tr,
        message: 'optimal_stock_badge'.tr,
      );
      return;
    }

    CreatePurchaseInvoiceDialog.show(
      context,
      initialItems: poItems,
    );
  }

  Widget _buildKpisRow(SupplierLoaded state, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        final cards = [
          _buildKpiCard(
            title: 'kpi_active_vendors'.tr,
            value: '${state.activeSuppliersCount} / ${state.suppliers.length}',
            subtitle: 'kpi_authorized_suppliers'.tr,
            icon: Icons.business_center_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          _buildKpiCard(
            title: 'kpi_purchases_volume'.tr,
            value: AppFormatters.formatEGP(state.totalPurchasesAmount),
            subtitle: 'kpi_invoices_logged'.trParams({'count': '${state.invoices.length}'}),
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          _buildKpiCard(
            title: 'kpi_total_paid_out'.tr,
            value: AppFormatters.formatEGP(state.totalPaidAmount),
            subtitle: 'kpi_payment_vouchers'.trParams({'count': '${state.payments.length}'}),
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildKpiCard(
            title: 'kpi_outstanding_payables'.tr,
            value: AppFormatters.formatEGP(state.totalBalanceDue),
            subtitle: 'kpi_pending_invoices'.trParams({'count': '${state.unpaidInvoicesCount}'}),
            icon: Icons.account_balance_wallet_rounded,
            color: state.totalBalanceDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            isDark: isDark,
          ),
        ];

        if (isCompact) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: Suppliers Directory
  // -------------------------------------------------------------
  Widget _buildSuppliersTab(
    BuildContext context,
    SupplierLoaded state,
    bool isDark,
  ) {
    final suppliers = state.filteredSuppliers;

    return CustomDataTable(
      title: 'suppliers_table_title'.tr,
      subtitle: 'suppliers_table_subtitle'.tr,
      searchHint: 'suppliers_search_hint'.tr,
      onSearchChanged: (q) => context.read<SupplierCubit>().filterSuppliers(q),
      emptyMessage: 'no_suppliers_found'.tr,
      emptyIcon: Icons.business_center_outlined,
      columns: [
        DataTableColumn(label: 'col_supplier_name'.tr),
        DataTableColumn(label: 'col_contact_person'.tr),
        DataTableColumn(label: 'col_phone'.tr),
        DataTableColumn(label: 'col_payment_terms'.tr),
        DataTableColumn(label: 'col_purchases'.tr),
        DataTableColumn(label: 'col_balance_due'.tr),
        DataTableColumn(label: 'col_rating'.tr),
        DataTableColumn(label: 'col_status'.tr),
        DataTableColumn(label: 'actions'.tr),
      ],
      rows: suppliers.map((s) {
        return DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColor.primary.withValues(alpha: 0.15),
                    child: Text(
                      s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : 'V',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColor.primary, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(s.contactPerson.isNotEmpty ? s.contactPerson : '-')),
            DataCell(Text(s.phone.isNotEmpty ? s.phone : '-')),
            DataCell(Text(s.paymentTerms)),
            DataCell(
              Text(
                AppFormatters.formatEGP(s.totalPurchases),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.balanceDue > 0
                      ? AppColor.error.withValues(alpha: 0.12)
                      : AppColor.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppFormatters.formatEGP(s.balanceDue),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: s.balanceDue > 0 ? AppColor.error : AppColor.success,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  Text('${s.rating.toStringAsFixed(1)}/5'),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: s.isActive
                      ? AppColor.success.withValues(alpha: 0.12)
                      : AppColor.textSecondaryDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.isActive ? 'status_active'.tr : 'status_inactive'.tr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: s.isActive ? AppColor.success : AppColor.textSecondaryDark,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColor.primary),
                    tooltip: 'tooltip_statement'.tr,
                    onPressed: () => SupplierLedgerDialog.show(context, supplier: s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'tooltip_print_statement'.tr,
                    onPressed: () => SupplierInvoicePrinter.showSupplierStatementPreview(
                      context,
                      supplier: s,
                      invoices: state.invoices,
                      payments: state.payments,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                    tooltip: 'edit'.tr,
                    onPressed: () => SupplierFormDialog.show(context, supplier: s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.payment_rounded, size: 18, color: Color(0xFFF59E0B)),
                    tooltip: 'btn_pay_vendor'.tr,
                    onPressed: () => RecordPaymentDialog.show(context, initialSupplier: s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                    tooltip: 'delete'.tr,
                    onPressed: () => _confirmDeleteSupplier(context, s),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Purchase Invoices Hub
  // -------------------------------------------------------------
  Widget _buildInvoicesTab(
    BuildContext context,
    SupplierLoaded state,
    bool isDark,
  ) {
    final invoices = state.filteredInvoices;

    return CustomDataTable(
      title: 'invoices_table_title'.tr,
      subtitle: 'invoices_table_subtitle'.tr,
      searchHint: 'invoices_search_hint'.tr,
      onSearchChanged: (q) => context.read<SupplierCubit>().filterInvoices(query: q),
      trailingHeaderAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            label: Text('filter_all'.tr),
            selected: state.paymentStatusFilter == null,
            onSelected: (_) =>
                context.read<SupplierCubit>().filterInvoices(clearStatus: true),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text('filter_unpaid'.tr),
            selected: state.paymentStatusFilter == InvoicePaymentStatus.unpaid,
            onSelected: (_) => context
                .read<SupplierCubit>()
                .filterInvoices(status: InvoicePaymentStatus.unpaid),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text('filter_partial'.tr),
            selected: state.paymentStatusFilter == InvoicePaymentStatus.partial,
            onSelected: (_) => context
                .read<SupplierCubit>()
                .filterInvoices(status: InvoicePaymentStatus.partial),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text('filter_paid'.tr),
            selected: state.paymentStatusFilter == InvoicePaymentStatus.paid,
            onSelected: (_) => context
                .read<SupplierCubit>()
                .filterInvoices(status: InvoicePaymentStatus.paid),
          ),
        ],
      ),
      emptyMessage: 'no_invoices_found'.tr,
      emptyIcon: Icons.receipt_long_outlined,
      columns: [
        DataTableColumn(label: 'col_invoice_number'.tr),
        DataTableColumn(label: 'col_supplier_name'.tr),
        DataTableColumn(label: 'col_date'.tr),
        DataTableColumn(label: 'col_items_count'.tr),
        DataTableColumn(label: 'col_total'.tr),
        DataTableColumn(label: 'col_paid'.tr),
        DataTableColumn(label: 'col_remaining'.tr),
        DataTableColumn(label: 'col_payment_status'.tr),
        DataTableColumn(label: 'actions'.tr),
      ],
      rows: invoices.map((inv) {
        Color statusColor;
        String statusText;
        switch (inv.paymentStatus) {
          case InvoicePaymentStatus.paid:
            statusColor = const Color(0xFF10B981);
            statusText = 'filter_paid'.tr;
            break;
          case InvoicePaymentStatus.partial:
            statusColor = const Color(0xFFF59E0B);
            statusText = 'filter_partial'.tr;
            break;
          case InvoicePaymentStatus.unpaid:
            statusColor = const Color(0xFFEF4444);
            statusText = 'filter_unpaid'.tr;
            break;
          case InvoicePaymentStatus.overdue:
            statusColor = const Color(0xFFDC2626);
            statusText = 'overdue'.tr;
            break;
        }

        return DataRow(
          cells: [
            DataCell(
              Text(
                inv.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
            DataCell(Text(inv.supplierName, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(AppFormatters.formatDate(inv.invoiceDate))),
            DataCell(Text('${inv.items.length}')),
            DataCell(
              Text(
                AppFormatters.formatEGP(inv.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            DataCell(Text(AppFormatters.formatEGP(inv.paidAmount))),
            DataCell(
              Text(
                AppFormatters.formatEGP(inv.remainingAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: inv.remainingAmount > 0 ? AppColor.error : const Color(0xFF10B981),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColor.primary),
                    tooltip: 'tooltip_view_details'.tr,
                    onPressed: () => PurchaseInvoiceDetailsDialog.show(context, invoice: inv),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'tooltip_print_invoice'.tr,
                    onPressed: () => SupplierInvoicePrinter.showPurchaseInvoicePreview(context, invoice: inv),
                  ),
                  if (inv.remainingAmount > 0)
                    IconButton(
                      icon: const Icon(Icons.payment_rounded, size: 18, color: Color(0xFFF59E0B)),
                      tooltip: 'payment_voucher_record'.tr,
                      onPressed: () => RecordPaymentDialog.show(context, initialInvoice: inv),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                    tooltip: 'delete'.tr,
                    onPressed: () => _confirmDeleteInvoice(context, inv),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Payments Ledger
  // -------------------------------------------------------------
  Widget _buildPaymentsTab(
    BuildContext context,
    SupplierLoaded state,
    bool isDark,
  ) {
    final payments = state.filteredPayments;

    return CustomDataTable(
      title: 'payments_table_title'.tr,
      subtitle: 'payments_table_subtitle'.tr,
      searchHint: 'payments_search_hint'.tr,
      emptyMessage: 'no_payments_found'.tr,
      emptyIcon: Icons.payment_outlined,
      columns: [
        DataTableColumn(label: 'col_payment_date'.tr),
        DataTableColumn(label: 'col_supplier_name'.tr),
        DataTableColumn(label: 'col_linked_invoice'.tr),
        DataTableColumn(label: 'col_payment_method'.tr),
        DataTableColumn(label: 'col_ref_num'.tr),
        DataTableColumn(label: 'col_amount_paid'.tr),
        DataTableColumn(label: 'notes'.tr),
        DataTableColumn(label: 'actions'.tr),
      ],
      rows: payments.map((p) {
        return DataRow(
          cells: [
            DataCell(Text(AppFormatters.formatDate(p.paymentDate))),
            DataCell(Text(p.supplierName, style: const TextStyle(fontWeight: FontWeight.w700))),
            DataCell(Text(p.invoiceNumber ?? 'general_account_payout'.tr)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(p.paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            DataCell(Text(p.referenceNumber.isNotEmpty ? p.referenceNumber : '-')),
            DataCell(
              Text(
                AppFormatters.formatEGP(p.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            DataCell(Text(p.notes.isNotEmpty ? p.notes : '-')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF10B981)),
                    tooltip: 'tooltip_print_voucher'.tr,
                    onPressed: () => SupplierInvoicePrinter.showPaymentVoucherPreview(context, payment: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF3B82F6)),
                    tooltip: 'tooltip_export_csv'.tr,
                    onPressed: () => SupplierInvoicePrinter.exportPaymentVoucherCsv(p),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _confirmDeleteSupplier(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('confirm_delete_supplier_title'.tr),
        content: Text(
          'confirm_delete_supplier_msg'.trParams({'name': supplier.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<SupplierCubit>().deleteSupplier(supplier.id);
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteInvoice(BuildContext context, PurchaseInvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('confirm_delete_invoice_title'.tr),
        content: Text(
          'confirm_delete_invoice_msg'.trParams({'number': invoice.invoiceNumber}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<SupplierCubit>().deleteInvoice(invoice.id);
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
