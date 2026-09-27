import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/supplier_payment_model.dart';
import '../../data/repositories/supplier_repository.dart';
import 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository repository;

  SupplierCubit(this.repository) : super(SupplierInitial());

  Future<void> loadSuppliersData() async {
    try {
      emit(SupplierLoading());
      final suppliers = await repository.getSuppliers();
      final invoices = await repository.getPurchaseInvoices(limit: 200);
      final payments = await repository.getSupplierPayments(limit: 200);

      emit(SupplierLoaded(
        suppliers: suppliers,
        filteredSuppliers: suppliers,
        invoices: invoices,
        filteredInvoices: invoices,
        payments: payments,
        filteredPayments: payments,
      ));
    } catch (e) {
      debugPrint('SupplierCubit loadSuppliersData error: $e');
      emit(SupplierError(e.toString()));
    }
  }

  void filterSuppliers(String query) {
    if (state is! SupplierLoaded) return;
    final currentState = state as SupplierLoaded;
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      emit(currentState.copyWith(
        filteredSuppliers: currentState.suppliers,
        supplierSearchQuery: '',
      ));
      return;
    }

    final filtered = currentState.suppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.contactPerson.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.taxNumber.toLowerCase().contains(q) ||
          s.suppliedCategories.any((cat) => cat.toLowerCase().contains(q));
    }).toList();

    emit(currentState.copyWith(
      filteredSuppliers: filtered,
      supplierSearchQuery: query,
    ));
  }

  void filterInvoices({
    String? query,
    InvoicePaymentStatus? status,
    bool clearStatus = false,
    String? supplierId,
    bool clearSupplierId = false,
  }) {
    if (state is! SupplierLoaded) return;
    final currentState = state as SupplierLoaded;

    final targetQuery = query ?? currentState.invoiceSearchQuery;
    final targetStatus = clearStatus
        ? null
        : (status ?? currentState.paymentStatusFilter);
    final targetSupplierId = clearSupplierId
        ? null
        : (supplierId ?? currentState.selectedSupplierId);

    final q = targetQuery.trim().toLowerCase();

    final filtered = currentState.invoices.where((inv) {
      final matchesQuery = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.supplierName.toLowerCase().contains(q) ||
          inv.notes.toLowerCase().contains(q) ||
          inv.items.any((item) =>
              item.productTitle.toLowerCase().contains(q) ||
              (item.variationSku?.toLowerCase().contains(q) ?? false));

      final matchesStatus = targetStatus == null || inv.paymentStatus == targetStatus;
      final matchesSupplier =
          targetSupplierId == null || inv.supplierId == targetSupplierId;

      return matchesQuery && matchesStatus && matchesSupplier;
    }).toList();

    emit(currentState.copyWith(
      filteredInvoices: filtered,
      invoiceSearchQuery: targetQuery,
      paymentStatusFilter: targetStatus,
      clearPaymentStatusFilter: clearStatus,
      selectedSupplierId: targetSupplierId,
      clearSelectedSupplierId: clearSupplierId,
    ));
  }

  List<SupplierModel> _applySupplierFilter(List<SupplierModel> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.contactPerson.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.taxNumber.toLowerCase().contains(q) ||
          s.suppliedCategories.any((cat) => cat.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    if (state is! SupplierLoaded) {
      await repository.addSupplier(supplier);
      await loadSuppliersData();
      return;
    }
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      final added = await repository.addSupplier(supplier);
      final updatedList = List<SupplierModel>.from(currentState.suppliers)..add(added);
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final filtered = _applySupplierFilter(updatedList, currentState.supplierSearchQuery);

      emit(currentState.copyWith(
        suppliers: updatedList,
        filteredSuppliers: filtered,
        isSubmitting: false,
      ));
    } catch (e) {
      debugPrint('SupplierCubit addSupplier error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (state is! SupplierLoaded) {
      await repository.updateSupplier(supplier);
      await loadSuppliersData();
      return;
    }
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      await repository.updateSupplier(supplier);
      final updatedList = currentState.suppliers.map((s) {
        return s.id == supplier.id ? supplier : s;
      }).toList();
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final filtered = _applySupplierFilter(updatedList, currentState.supplierSearchQuery);

      emit(currentState.copyWith(
        suppliers: updatedList,
        filteredSuppliers: filtered,
        isSubmitting: false,
      ));
    } catch (e) {
      debugPrint('SupplierCubit updateSupplier error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    if (state is! SupplierLoaded) {
      await repository.deleteSupplier(id);
      await loadSuppliersData();
      return;
    }
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      await repository.deleteSupplier(id);
      final updatedList = currentState.suppliers.where((s) => s.id != id).toList();

      final filtered = _applySupplierFilter(updatedList, currentState.supplierSearchQuery);

      emit(currentState.copyWith(
        suppliers: updatedList,
        filteredSuppliers: filtered,
        isSubmitting: false,
      ));
    } catch (e) {
      debugPrint('SupplierCubit deleteSupplier error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  }) async {
    if (state is! SupplierLoaded) {
      return await repository.createPurchaseInvoice(invoice, autoUpdateStock: autoUpdateStock);
    }
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      final created = await repository.createPurchaseInvoice(
        invoice,
        autoUpdateStock: autoUpdateStock,
      );

      // Refresh data to reflect updated balances and stock counts accurately
      await loadSuppliersData();
      return created;
    } catch (e) {
      debugPrint('SupplierCubit createPurchaseInvoice error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> recordPayment(SupplierPaymentModel payment) async {
    if (state is! SupplierLoaded) return;
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      await repository.recordSupplierPayment(payment);
      await loadSuppliersData();
    } catch (e) {
      debugPrint('SupplierCubit recordPayment error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    if (state is! SupplierLoaded) return;
    final currentState = state as SupplierLoaded;
    try {
      emit(currentState.copyWith(isSubmitting: true));
      await repository.deletePurchaseInvoice(invoiceId);
      final updated = currentState.invoices.where((i) => i.id != invoiceId).toList();
      emit(currentState.copyWith(
        invoices: updated,
        filteredInvoices: updated,
        isSubmitting: false,
      ));
    } catch (e) {
      debugPrint('SupplierCubit deleteInvoice error: $e');
      emit(currentState.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
