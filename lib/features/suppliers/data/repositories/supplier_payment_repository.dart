import '../datasources/supplier_payment_data_source.dart';
import '../models/supplier_payment_model.dart';

abstract class SupplierPaymentRepository {
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  });
  Future<SupplierPaymentModel> recordSupplierPayment(
      SupplierPaymentModel payment);
}

class SupplierPaymentRepositoryImpl implements SupplierPaymentRepository {
  final SupplierPaymentDataSource dataSource;

  SupplierPaymentRepositoryImpl({required this.dataSource});

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments({
    String? supplierId,
    int limit = 100,
  }) =>
      dataSource.getSupplierPayments(
        supplierId: supplierId,
        limit: limit,
      );

  @override
  Future<SupplierPaymentModel> recordSupplierPayment(
          SupplierPaymentModel payment) =>
      dataSource.recordSupplierPayment(payment);
}
