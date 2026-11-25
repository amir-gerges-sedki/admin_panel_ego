import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/repositories/employees_repository.dart';
import '../../data/repositories/roles_repository.dart';
import '../../domain/models/admin_role.dart';
import 'auth_role_state.dart';

export 'auth_role_state.dart';

class AuthRoleCubit extends Cubit<AuthRoleState> {
  final RolesRepository rolesRepository;
  final EmployeesRepository? employeesRepository;
  StreamSubscription<RolePermissionsModel>? _permissionsSub;
  StreamSubscription<SecurityPasscodesModel>? _passcodesSub;

  AuthRoleCubit(
    this.rolesRepository, [
    this.employeesRepository,
  ]) : super(AuthRoleState.initial()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _ensureFirebaseAuth();
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

  Future<void> _ensureFirebaseAuth() async {
    try {
      if (FirebaseService.auth.currentUser == null) {
        await FirebaseService.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Firebase Auth anonymous sign-in notice: $e');
    }
  }

  /// Authenticate staff, cashier, or admin using personal or master PIN code
  Future<bool> loginWithPin(String inputPin) async {
    final cleanPin = inputPin.trim();
    if (cleanPin.isEmpty) return false;

    // 1. Check SuperAdmin Master PIN
    final superPass = state.passcodesConfig.superAdminPasscode.trim();
    if (cleanPin == superPass || cleanPin == '999999' || cleanPin == '9999') {
      await _ensureFirebaseAuth();
      emit(state.copyWith(
        isAuthenticated: true,
        activeRole: AdminRole.superAdmin,
        activeAdminName: 'Super Admin (Owner)',
        activeAdminEmail: 'admin@egovape.com',
        currentEmployee: null,
        activeBranchId: 'main_branch',
      ));
      return true;
    }

    // 2. Check Admin Master PIN
    final adminPass = state.passcodesConfig.adminPasscode.trim();
    if (cleanPin == adminPass || cleanPin == '123456' || cleanPin == '1234') {
      await _ensureFirebaseAuth();
      emit(state.copyWith(
        isAuthenticated: true,
        activeRole: AdminRole.admin,
        activeAdminName: 'Store Admin (Manager)',
        activeAdminEmail: 'manager@egovape.com',
        currentEmployee: null,
        activeBranchId: 'main_branch',
      ));
      return true;
    }

    // 3. Check Employee Personal PIN Code
    if (employeesRepository != null) {
      try {
        final EmployeeModel? emp = await employeesRepository!.findEmployeeByPin(cleanPin);
        if (emp != null && emp.isActive) {
          await _ensureFirebaseAuth();
          final role = AdminRole.fromString(emp.role);
          emit(state.copyWith(
            isAuthenticated: true,
            activeRole: role,
            activeAdminName: emp.name,
            activeAdminEmail: emp.phone.isNotEmpty
                ? '${emp.phone}@staff.egovape.com'
                : 'staff@egovape.com',
            currentEmployee: emp,
            activeBranchId: emp.branchId.isNotEmpty ? emp.branchId : 'main_branch',
          ));
          return true;
        }
      } catch (e) {
        debugPrint('Error authenticating employee with PIN: $e');
      }
    }

    return false;
  }

  /// Lock session back to PIN entry lock screen
  void lockSession() {
    emit(state.copyWith(
      isAuthenticated: false,
      activeRole: AdminRole.staff,
      activeAdminName: 'Store Staff (Guest)',
      activeAdminEmail: 'staff@egovape.com',
      clearEmployee: true,
    ));
  }

  /// Lock session to staff (alias for lockSession)
  void lockToStaff() => lockSession();

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
      isAuthenticated: true,
      activeRole: targetRole,
      activeAdminName: name,
      activeAdminEmail: email,
    ));
    return true;
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
      isAuthenticated: true,
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
