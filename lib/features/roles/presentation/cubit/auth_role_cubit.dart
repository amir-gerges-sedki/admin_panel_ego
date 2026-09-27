import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/roles_repository.dart';
import '../../domain/models/admin_role.dart';
import 'auth_role_state.dart';

export 'auth_role_state.dart';

class AuthRoleCubit extends Cubit<AuthRoleState> {
  final RolesRepository rolesRepository;
  StreamSubscription<RolePermissionsModel>? _permissionsSub;
  StreamSubscription<SecurityPasscodesModel>? _passcodesSub;

  AuthRoleCubit(this.rolesRepository) : super(AuthRoleState.initial()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final config = await rolesRepository.getPermissionsConfig();
      final passcodes = await rolesRepository.getSecurityPasscodes();

      emit(state.copyWith(
        permissionsConfig: config,
        passcodesConfig: passcodes,
      ));

      _permissionsSub = rolesRepository.watchPermissionsConfig().listen((cfg) {
        emit(state.copyWith(permissionsConfig: cfg));
      });

      _passcodesSub = rolesRepository.watchSecurityPasscodes().listen((pass) {
        emit(state.copyWith(passcodesConfig: pass));
      });
    } catch (_) {}
  }

  /// Verify passcode against target role without modifying state
  bool verifyPasscode(AdminRole targetRole, String inputPasscode) {
    return state.passcodesConfig.verifyPasscode(targetRole, inputPasscode);
  }

  /// Elevate role using security passcode
  bool elevateRole(AdminRole targetRole, String inputPasscode) {
    if (!verifyPasscode(targetRole, inputPasscode)) {
      return false;
    }

    String name = 'Store Staff (Guest)';
    String email = 'staff@egovape.com';
    if (targetRole == AdminRole.superAdmin) {
      name = 'Super Admin (Owner)';
      email = 'admin@egovape.com';
    } else if (targetRole == AdminRole.admin) {
      name = 'Store Admin (Manager)';
      email = 'manager@egovape.com';
    }

    emit(state.copyWith(
      activeRole: targetRole,
      activeAdminName: name,
      activeAdminEmail: email,
    ));
    return true;
  }

  /// Lock session back to Store Staff (Guest) immediately
  void lockToStaff() {
    emit(state.copyWith(
      activeRole: AdminRole.staff,
      activeAdminName: 'Store Staff (Guest)',
      activeAdminEmail: 'staff@egovape.com',
    ));
  }

  /// Switch role directly (used by Super Admin or internally)
  void switchRoleDirect(AdminRole targetRole) {
    String name = 'Store Staff (Guest)';
    String email = 'staff@egovape.com';
    if (targetRole == AdminRole.superAdmin) {
      name = 'Super Admin (Owner)';
      email = 'admin@egovape.com';
    } else if (targetRole == AdminRole.admin) {
      name = 'Store Admin (Manager)';
      email = 'manager@egovape.com';
    }

    emit(state.copyWith(
      activeRole: targetRole,
      activeAdminName: name,
      activeAdminEmail: email,
    ));
  }

  Future<void> updateRolePermissions(
    AdminRole role,
    Set<AdminPermission> newPerms,
  ) async {
    final updated = state.permissionsConfig.copyWithUpdatedRole(role, newPerms);
    emit(state.copyWith(permissionsConfig: updated, isLoading: true));
    try {
      await rolesRepository.savePermissionsConfig(updated);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> updateSecurityPasscodes(SecurityPasscodesModel newPasscodes) async {
    emit(state.copyWith(passcodesConfig: newPasscodes, isLoading: true));
    try {
      await rolesRepository.saveSecurityPasscodes(newPasscodes);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> assignUserRole(String userId, AdminRole role) async {
    try {
      await rolesRepository.updateUserRole(userId, role);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _permissionsSub?.cancel();
    _passcodesSub?.cancel();
    return super.close();
  }
}
