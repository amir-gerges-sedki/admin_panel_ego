import 'package:equatable/equatable.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../domain/models/admin_role.dart';

class AuthRoleState extends Equatable {
  final bool isAuthenticated;
  final AdminRole activeRole;
  final String activeAdminName;
  final String activeAdminEmail;
  final EmployeeModel? currentEmployee;
  final String activeBranchId;
  final RolePermissionsModel permissionsConfig;
  final SecurityPasscodesModel passcodesConfig;
  final bool isLoading;
  final String? errorMessage;

  const AuthRoleState({
    this.isAuthenticated = false,
    required this.activeRole,
    required this.activeAdminName,
    required this.activeAdminEmail,
    this.currentEmployee,
    this.activeBranchId = 'main_branch',
    required this.permissionsConfig,
    required this.passcodesConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Default role on startup is locked, waiting for staff PIN
  factory AuthRoleState.initial() {
    return AuthRoleState(
      isAuthenticated: false,
      activeRole: AdminRole.staff,
      activeAdminName: 'Store Staff (Guest)',
      activeAdminEmail: 'staff@egovape.com',
      currentEmployee: null,
      activeBranchId: 'main_branch',
      permissionsConfig: RolePermissionsModel.defaultPermissions(),
      passcodesConfig: SecurityPasscodesModel.defaults(),
      isLoading: false,
    );
  }

  bool hasPermission(AdminPermission permission) {
    if (!isAuthenticated) return false;
    return permissionsConfig.hasPermission(activeRole, permission);
  }

  bool get isElevated => activeRole != AdminRole.staff;

  AuthRoleState copyWith({
    bool? isAuthenticated,
    AdminRole? activeRole,
    String? activeAdminName,
    String? activeAdminEmail,
    EmployeeModel? currentEmployee,
    bool clearEmployee = false,
    String? activeBranchId,
    RolePermissionsModel? permissionsConfig,
    SecurityPasscodesModel? passcodesConfig,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthRoleState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      activeRole: activeRole ?? this.activeRole,
      activeAdminName: activeAdminName ?? this.activeAdminName,
      activeAdminEmail: activeAdminEmail ?? this.activeAdminEmail,
      currentEmployee: clearEmployee ? null : (currentEmployee ?? this.currentEmployee),
      activeBranchId: activeBranchId ?? this.activeBranchId,
      permissionsConfig: permissionsConfig ?? this.permissionsConfig,
      passcodesConfig: passcodesConfig ?? this.passcodesConfig,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isAuthenticated,
        activeRole,
        activeAdminName,
        activeAdminEmail,
        currentEmployee,
        activeBranchId,
        permissionsConfig,
        passcodesConfig,
        isLoading,
        errorMessage,
      ];
}
