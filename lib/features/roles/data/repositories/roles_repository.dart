import '../../domain/models/admin_role.dart';
import '../datasources/roles_remote_data_source.dart';

abstract class RolesRepository {
  Future<RolePermissionsModel> getPermissionsConfig();
  Stream<RolePermissionsModel> watchPermissionsConfig();
  Future<void> savePermissionsConfig(RolePermissionsModel config);

  Future<SecurityPasscodesModel> getSecurityPasscodes();
  Stream<SecurityPasscodesModel> watchSecurityPasscodes();
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel passcodes);

  Future<void> updateUserRole(String userId, AdminRole role);
}

class RolesRepositoryImpl implements RolesRepository {
  final RolesRemoteDataSource remoteDataSource;

  RolesRepositoryImpl({RolesRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? RolesRemoteDataSourceImpl();

  @override
  Future<RolePermissionsModel> getPermissionsConfig() =>
      remoteDataSource.getPermissionsConfig();

  @override
  Stream<RolePermissionsModel> watchPermissionsConfig() =>
      remoteDataSource.watchPermissionsConfig();

  @override
  Future<void> savePermissionsConfig(RolePermissionsModel config) =>
      remoteDataSource.savePermissionsConfig(config);

  @override
  Future<SecurityPasscodesModel> getSecurityPasscodes() =>
      remoteDataSource.getSecurityPasscodes();

  @override
  Stream<SecurityPasscodesModel> watchSecurityPasscodes() =>
      remoteDataSource.watchSecurityPasscodes();

  @override
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel passcodes) =>
      remoteDataSource.saveSecurityPasscodes(passcodes);

  @override
  Future<void> updateUserRole(String userId, AdminRole role) =>
      remoteDataSource.updateUserRole(userId, role);
}
