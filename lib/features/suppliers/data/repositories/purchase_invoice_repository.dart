import '../datasources/purchase_invoice_data_source.dart';
import '../models/purchase_invoice_model.dart';

abstract class PurchaseInvoiceRepository {
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  });
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  });
  Future<void> updatePurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    double oldPaidAmount = 0.0,
    double oldTotalAmount = 0.0,
  });
  Future<void> deletePurchaseInvoice(String invoiceId);
}

class PurchaseInvoiceRepositoryImpl implements PurchaseInvoiceRepository {
  final PurchaseInvoiceDataSource dataSource;

  PurchaseInvoiceRepositoryImpl({required this.dataSource});

  @override
  Future<List<PurchaseInvoiceModel>> getPurchaseInvoices({
    String? supplierId,
    int limit = 100,
  }) =>
      dataSource.getPurchaseInvoices(
        supplierId: supplierId,
        limit: limit,
      );

  @override
  Future<PurchaseInvoiceModel> createPurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    bool autoUpdateStock = true,
  }) =>
      dataSource.createPurchaseInvoice(
        invoice,
        autoUpdateStock: autoUpdateStock,
      );

  @override
  Future<void> updatePurchaseInvoice(
    PurchaseInvoiceModel invoice, {
    double oldPaidAmount = 0.0,
    double oldTotalAmount = 0.0,
  }) =>
      dataSource.updatePurchaseInvoice(
        invoice,
        oldPaidAmount: oldPaidAmount,
        oldTotalAmount: oldTotalAmount,
      );

  @override
  Future<void> deletePurchaseInvoice(String invoiceId) =>
      dataSource.deletePurchaseInvoice(invoiceId);
}
