import '../datasources/supplier_remote_data_source.dart';
import '../models/supplier_model.dart';

abstract class SupplierRepository {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel?> getSupplierById(String id);
  Future<SupplierModel> addSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
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
}
