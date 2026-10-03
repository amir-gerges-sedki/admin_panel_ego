import '../datasources/inventory_audit_remote_data_source.dart';
import '../models/inventory_audit_model.dart';

abstract class InventoryAuditRepository {
  Future<List<InventoryAuditModel>> getAudits({String? branchId});
  Future<String> saveAuditDraft(InventoryAuditModel audit);
  Future<void> reconcileAndCompleteAudit(InventoryAuditModel audit, {required String performedBy});
  Future<void> deleteAudit(String auditId);
}

class InventoryAuditRepositoryImpl implements InventoryAuditRepository {
  final InventoryAuditRemoteDataSource dataSource;

  InventoryAuditRepositoryImpl({InventoryAuditRemoteDataSource? dataSource})
      : dataSource = dataSource ?? InventoryAuditRemoteDataSourceImpl();

  @override
  Future<List<InventoryAuditModel>> getAudits({String? branchId}) =>
      dataSource.getAudits(branchId: branchId);

  @override
  Future<String> saveAuditDraft(InventoryAuditModel audit) =>
      dataSource.saveAuditDraft(audit);

  @override
  Future<void> reconcileAndCompleteAudit(InventoryAuditModel audit, {required String performedBy}) =>
      dataSource.reconcileAndCompleteAudit(audit, performedBy: performedBy);

  @override
  Future<void> deleteAudit(String auditId) =>
      dataSource.deleteAudit(auditId);
}
