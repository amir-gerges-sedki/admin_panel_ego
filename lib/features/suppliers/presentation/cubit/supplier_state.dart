import 'package:equatable/equatable.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/supplier_payment_model.dart';

abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<SupplierModel> suppliers;
  final List<SupplierModel> filteredSuppliers;
  final List<PurchaseInvoiceModel> invoices;
  final List<PurchaseInvoiceModel> filteredInvoices;
  final List<SupplierPaymentModel> payments;
  final List<SupplierPaymentModel> filteredPayments;

  final String supplierSearchQuery;
  final String invoiceSearchQuery;
  final InvoicePaymentStatus? paymentStatusFilter;
  final String? selectedSupplierId;
  final bool isSubmitting;

  const SupplierLoaded({
    required this.suppliers,
    required this.filteredSuppliers,
    required this.invoices,
    required this.filteredInvoices,
    required this.payments,
    required this.filteredPayments,
    this.supplierSearchQuery = '',
    this.invoiceSearchQuery = '',
    this.paymentStatusFilter,
    this.selectedSupplierId,
    this.isSubmitting = false,
  });

  int get activeSuppliersCount =>
      suppliers.where((s) => s.isActive).length;

  double get totalPurchasesAmount =>
      suppliers.fold(0.0, (acc, s) => acc + s.totalPurchases);

  double get totalPaidAmount =>
      suppliers.fold(0.0, (acc, s) => acc + s.totalPaid);

  double get totalBalanceDue =>
      suppliers.fold(0.0, (acc, s) => acc + s.balanceDue);

  int get unpaidInvoicesCount =>
      invoices.where((inv) => inv.paymentStatus != InvoicePaymentStatus.paid).length;

  SupplierLoaded copyWith({
    List<SupplierModel>? suppliers,
    List<SupplierModel>? filteredSuppliers,
    List<PurchaseInvoiceModel>? invoices,
    List<PurchaseInvoiceModel>? filteredInvoices,
    List<SupplierPaymentModel>? payments,
    List<SupplierPaymentModel>? filteredPayments,
    String? supplierSearchQuery,
    String? invoiceSearchQuery,
    InvoicePaymentStatus? paymentStatusFilter,
    bool clearPaymentStatusFilter = false,
    String? selectedSupplierId,
    bool clearSelectedSupplierId = false,
    bool? isSubmitting,
  }) {
    return SupplierLoaded(
      suppliers: suppliers ?? this.suppliers,
      filteredSuppliers: filteredSuppliers ?? this.filteredSuppliers,
      invoices: invoices ?? this.invoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      supplierSearchQuery: supplierSearchQuery ?? this.supplierSearchQuery,
      invoiceSearchQuery: invoiceSearchQuery ?? this.invoiceSearchQuery,
      paymentStatusFilter: clearPaymentStatusFilter
          ? null
          : (paymentStatusFilter ?? this.paymentStatusFilter),
      selectedSupplierId: clearSelectedSupplierId
          ? null
          : (selectedSupplierId ?? this.selectedSupplierId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        suppliers,
        filteredSuppliers,
        invoices,
        filteredInvoices,
        payments,
        filteredPayments,
        supplierSearchQuery,
        invoiceSearchQuery,
        paymentStatusFilter,
        selectedSupplierId,
        isSubmitting,
      ];
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError(this.message);

  @override
  List<Object?> get props => [message];
}
