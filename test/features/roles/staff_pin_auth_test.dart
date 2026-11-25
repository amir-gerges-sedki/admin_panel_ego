import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/employees/data/models/employee_model.dart';
import 'package:admin_panel_ego/features/employees/data/repositories/employees_repository.dart';
import 'package:admin_panel_ego/features/roles/data/repositories/roles_repository.dart';
import 'package:admin_panel_ego/features/roles/domain/models/admin_role.dart';
import 'package:admin_panel_ego/features/roles/presentation/cubit/auth_role_cubit.dart';

class FakeRolesRepository implements RolesRepository {
  SecurityPasscodesModel passcodes = const SecurityPasscodesModel(
    superAdminPasscode: '999999',
    adminPasscode: '123456',
    defaultToStaff: true,
  );
  RolePermissionsModel permissions = RolePermissionsModel.defaultPermissions();

  @override
  Future<RolePermissionsModel> getPermissionsConfig() async => permissions;

  @override
  Stream<RolePermissionsModel> watchPermissionsConfig() => Stream.value(permissions);

  @override
  Future<void> savePermissionsConfig(RolePermissionsModel config) async {
    permissions = config;
  }

  @override
  Future<SecurityPasscodesModel> getSecurityPasscodes() async => passcodes;

  @override
  Stream<SecurityPasscodesModel> watchSecurityPasscodes() => Stream.value(passcodes);

  @override
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel p) async {
    passcodes = p;
  }

  @override
  Future<void> updateUserRole(String userId, AdminRole role) async {}
}

class FakeEmployeesRepository implements EmployeesRepository {
  final List<EmployeeModel> employees = [];

  @override
  Stream<List<EmployeeModel>> watchEmployees() => Stream.value(employees);

  @override
  Future<List<EmployeeModel>> getEmployees() async => employees;

  @override
  Future<EmployeeModel?> findEmployeeByPin(String pin) async {
    final clean = pin.trim();
    if (clean.isEmpty) return null;
    for (final emp in employees) {
      if (emp.isActive && emp.pinCode.trim() == clean) {
        return emp;
      }
    }
    return null;
  }

  @override
  Future<void> addEmployee(EmployeeModel employee) async => employees.add(employee);

  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    final index = employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) employees[index] = employee;
  }

  @override
  Future<void> deleteEmployee(String id) async => employees.removeWhere((e) => e.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Staff PIN Authentication Tests', () {
    late FakeRolesRepository rolesRepo;
    late FakeEmployeesRepository empRepo;
    late AuthRoleCubit cubit;

    setUp(() {
      rolesRepo = FakeRolesRepository();
      empRepo = FakeEmployeesRepository();

      // Seed a cashier employee
      empRepo.employees.add(EmployeeModel(
        id: 'emp_01',
        name: 'أحمد علي',
        phone: '01012345678',
        jobTitle: 'كاشير مبيعات',
        baseSalary: 6000,
        hireDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        pinCode: '1122',
        role: 'staff',
        branchId: 'tagamoa_branch',
      ));

      // Seed a store manager employee
      empRepo.employees.add(EmployeeModel(
        id: 'emp_02',
        name: 'محمد إبراهيم',
        phone: '01198765432',
        jobTitle: 'مدير فرع',
        baseSalary: 12000,
        hireDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        pinCode: '4455',
        role: 'admin',
        branchId: 'maadi_branch',
      ));

      // Seed an inactive employee
      empRepo.employees.add(EmployeeModel(
        id: 'emp_03',
        name: 'موظف موقف',
        phone: '01200000000',
        jobTitle: 'عامل متوقف',
        baseSalary: 4000,
        hireDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        pinCode: '9988',
        role: 'staff',
        isActive: false,
      ));

      cubit = AuthRoleCubit(rolesRepo, empRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is unauthenticated (lock screen active)', () {
      expect(cubit.state.isAuthenticated, false);
      expect(cubit.state.hasPermission(AdminPermission.pos), false);
      expect(cubit.state.hasPermission(AdminPermission.orders), false);
    });

    test('Authenticates Super Admin with Master Passcode 999999', () async {
      final success = await cubit.loginWithPin('999999');
      expect(success, true);
      expect(cubit.state.isAuthenticated, true);
      expect(cubit.state.activeRole, AdminRole.superAdmin);
      expect(cubit.state.activeAdminName, 'Super Admin (Owner)');
      expect(cubit.state.hasPermission(AdminPermission.settings), true);
    });

    test('Authenticates Staff Cashier with Personal PIN 1122', () async {
      final success = await cubit.loginWithPin('1122');
      expect(success, true);
      expect(cubit.state.isAuthenticated, true);
      expect(cubit.state.activeRole, AdminRole.staff);
      expect(cubit.state.activeAdminName, 'أحمد علي');
      expect(cubit.state.currentEmployee?.id, 'emp_01');
      expect(cubit.state.activeBranchId, 'tagamoa_branch');
    });

    test('Authenticates Store Manager with Personal PIN 4455 and elevates to Admin', () async {
      final success = await cubit.loginWithPin('4455');
      expect(success, true);
      expect(cubit.state.isAuthenticated, true);
      expect(cubit.state.activeRole, AdminRole.admin);
      expect(cubit.state.activeAdminName, 'محمد إبراهيم');
      expect(cubit.state.currentEmployee?.id, 'emp_02');
      expect(cubit.state.activeBranchId, 'maadi_branch');
    });

    test('Rejects invalid PIN code', () async {
      final success = await cubit.loginWithPin('0000');
      expect(success, false);
      expect(cubit.state.isAuthenticated, false);
    });

    test('Rejects deactivated employee PIN code', () async {
      final success = await cubit.loginWithPin('9988');
      expect(success, false);
      expect(cubit.state.isAuthenticated, false);
    });

    test('Lock session resets state and locks out immediately', () async {
      await cubit.loginWithPin('1122');
      expect(cubit.state.isAuthenticated, true);

      cubit.lockSession();
      expect(cubit.state.isAuthenticated, false);
      expect(cubit.state.currentEmployee, isNull);
    });
  });
}
