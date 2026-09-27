import '../datasources/supplier_remote_data_source.dart';
import '../models/purchase_invoice_model.dart';
import '../models/supplier_model.dart';
import '../models/supplier_payment_model.dart';

abstract class SupplierRepository {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel?> getSupplierById(String id);
  Future<SupplierModel> addSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);

  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  });
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  });
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice);
  Future<void> deletePurchaseInvoice(String invoiceId);

  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  });
  Future<SupplierPaymentModel> recordSupplierPayment(SupplierPaymentModel payment);
}

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;

  SupplierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SupplierModel>> getSuppliers() => remoteDataSource.getSuppliers();

  @override
  Future<SupplierModel?> getSupplierById(String id) =>
      remoteDataSource.getSupplierById(id);

  @override
  Future<SupplierModel> addSupplier(SupplierModel supplier) =>
      remoteDataSource.addSupplier(supplier);

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) =>
      remoteDataSource.updateSupplier(supplier);

  @override
  Future<void> deleteSupplier(String id) => remoteDataSource.deleteSupplier(id);

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  }) =>
      remoteDataSource.getPurchaseInvoices(
        supplierId: supplierId,
        limit: limit,
      );

  @override
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  }) =>
      remoteDataSource.createPurchaseInvoice(
        invoice,
        autoUpdateStock: autoUpdateStock,
      );

  @override
  Future<void> updatePurchaseInvoice(PurchaseInvoiceModel invoice) =>
      remoteDataSource.updatePurchaseInvoice(invoice);

  @override
  Future<void> deletePurchaseInvoice(String invoiceId) =>
      remoteDataSource.deletePurchaseInvoice(invoiceId);

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  }) =>
      remoteDataSource.getSupplierPayments(
        supplierId: supplierId,
        limit: limit,
      );

  @override
  Future<SupplierPaymentModel> recordSupplierPayment(
          SupplierPaymentModel payment) =>
      remoteDataSource.recordSupplierPayment(payment);
}
