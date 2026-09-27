import 'package:equatable/equatable.dart';
import '../../domain/models/admin_role.dart';

class AuthRoleState extends Equatable {
  final AdminRole activeRole;
  final String activeAdminName;
  final String activeAdminEmail;
  final RolePermissionsModel permissionsConfig;
  final SecurityPasscodesModel passcodesConfig;
  final bool isLoading;
  final String? errorMessage;

  const AuthRoleState({
    required this.activeRole,
    required this.activeAdminName,
    required this.activeAdminEmail,
    required this.permissionsConfig,
    required this.passcodesConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Default role on startup is Store Staff / Guest (Orders only)
  factory AuthRoleState.initial() {
    return AuthRoleState(
      activeRole: AdminRole.staff,
      activeAdminName: 'Store Staff (Guest)',
      activeAdminEmail: 'staff@egovape.com',
      permissionsConfig: RolePermissionsModel.defaultPermissions(),
      passcodesConfig: SecurityPasscodesModel.defaults(),
      isLoading: false,
    );
  }

  bool hasPermission(AdminPermission permission) {
    return permissionsConfig.hasPermission(activeRole, permission);
  }

  bool get isElevated => activeRole != AdminRole.staff;

  AuthRoleState copyWith({
    AdminRole? activeRole,
    String? activeAdminName,
    String? activeAdminEmail,
    RolePermissionsModel? permissionsConfig,
    SecurityPasscodesModel? passcodesConfig,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthRoleState(
      activeRole: activeRole ?? this.activeRole,
      activeAdminName: activeAdminName ?? this.activeAdminName,
      activeAdminEmail: activeAdminEmail ?? this.activeAdminEmail,
      permissionsConfig: permissionsConfig ?? this.permissionsConfig,
      passcodesConfig: passcodesConfig ?? this.passcodesConfig,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        activeRole,
        activeAdminName,
        activeAdminEmail,
        permissionsConfig,
        passcodesConfig,
        isLoading,
        errorMessage,
      ];
}
