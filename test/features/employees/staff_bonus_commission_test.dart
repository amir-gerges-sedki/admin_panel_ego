import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/employees/data/models/employee_model.dart';
import 'package:admin_panel_ego/features/employees/data/models/payroll_slip_model.dart';
import 'package:admin_panel_ego/features/employees/data/models/salary_advance_model.dart';
import 'package:admin_panel_ego/features/employees/data/models/staff_sales_summary.dart';
import 'package:admin_panel_ego/features/employees/data/repositories/employees_repository.dart';
import 'package:admin_panel_ego/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:admin_panel_ego/features/employees/presentation/cubit/employee_state.dart';
import 'package:admin_panel_ego/features/employees/presentation/widgets/disburse_payroll_dialog.dart';
import 'package:admin_panel_ego/features/employees/presentation/widgets/employee_form_dialog.dart';
import 'package:admin_panel_ego/features/settings/presentation/widgets/cards/staff_commission_settings_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_panel_ego/features/roles/domain/models/admin_role.dart';
import 'package:admin_panel_ego/features/roles/presentation/cubit/auth_role_cubit.dart';
import 'package:admin_panel_ego/features/roles/data/repositories/roles_repository.dart';

class MockTestEmployeesRepository implements EmployeesRepository {
  List<EmployeeModel> employees = [];
  List<SalaryAdvanceModel> advances = [];
  List<PayrollSlipModel> payrollSlips = [];
  Map<String, double> monthlySales = {};
  Map<String, int> monthlyOrders = {};
  PayrollSlipModel? lastDisbursedSlip;

  @override
  Stream<List<EmployeeModel>> watchEmployees() => Stream.value(employees);
  @override
  Future<List<EmployeeModel>> getEmployees() async => employees;
  @override
  Future<EmployeeModel?> findEmployeeByPin(String pin) async => null;
  @override
  Future<void> addEmployee(EmployeeModel employee) async => employees.add(employee);
  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    final idx = employees.indexWhere((e) => e.id == employee.id);
    if (idx != -1) employees[idx] = employee;
  }
  @override
  Future<void> deleteEmployee(String id) async => employees.removeWhere((e) => e.id == id);

  @override
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId}) =>
      Stream.value(advances);
  @override
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId}) async => advances;
  @override
  Future<void> disburseSalaryAdvance(SalaryAdvanceModel advance) async => advances.add(advance);
  @override
  Future<void> deleteAdvance(String id) async => advances.removeWhere((a) => a.id == id);

  @override
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId}) =>
      Stream.value(payrollSlips);
  @override
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId}) async => payrollSlips;
  @override
  Future<void> disbursePayroll({
    required PayrollSlipModel slip,
    required List<SalaryAdvanceModel> advancesToDeduct,
    bool recordToExpenses = true,
  }) async {
    lastDisbursedSlip = slip;
    payrollSlips.add(slip);
  }
  @override
  Future<void> deletePayrollSlip(PayrollSlipModel slip) async => payrollSlips.removeWhere((p) => p.id == slip.id);

  @override
  Stream<Map<String, double>> watchMonthlySales(String monthPeriod) => Stream.value(monthlySales);
  @override
  Stream<Map<String, int>> watchMonthlyOrdersCount(String monthPeriod) => Stream.value(monthlyOrders);
  @override
  Future<Map<String, double>> getMonthlySales(String monthPeriod) async => monthlySales;
}

class MockRolesRepository implements RolesRepository {
  @override
  Future<RolePermissionsModel> getPermissionsConfig() async => RolePermissionsModel.defaultPermissions();
  @override
  Future<SecurityPasscodesModel> getSecurityPasscodes() async => SecurityPasscodesModel.defaults();
  @override
  Stream<RolePermissionsModel> watchPermissionsConfig() => Stream.value(RolePermissionsModel.defaultPermissions());
  @override
  Stream<SecurityPasscodesModel> watchSecurityPasscodes() => Stream.value(SecurityPasscodesModel.defaults());
  @override
  Future<void> savePermissionsConfig(RolePermissionsModel config) async {}
  @override
  Future<void> saveSecurityPasscodes(SecurityPasscodesModel passcodes) async {}
  @override
  Future<void> updateUserRole(String userId, AdminRole role) async {}
}

void main() {
  final peter = EmployeeModel(
    id: 'emp-peter',
    name: 'Peter (بيتر)',
    phone: '01000000001',
    jobTitle: 'Sales Staff (مسؤول مبيعات)',
    baseSalary: 5000.0,
    hireDate: DateTime(2025, 1, 1),
    createdAt: DateTime(2025, 1, 1),
    commissionRate: 2.5, // 2.5%
    role: 'staff',
    isActive: true,
  );

  final john = EmployeeModel(
    id: 'emp-john',
    name: 'John (جون)',
    phone: '01000000002',
    jobTitle: 'Cashier (كاشير)',
    baseSalary: 4000.0,
    hireDate: DateTime(2025, 1, 1),
    createdAt: DateTime(2025, 1, 1),
    commissionRate: 1.0, // 1%
    role: 'staff',
    isActive: true,
  );

  group('Staff Sales Attribution & Bonus Commission Calculations', () {
    test('StaffSalesSummary accurately computes bonus and payout for Peter', () {
      final summary = StaffSalesSummary.fromEmployeeAndSales(
        employee: peter,
        monthPeriod: '2026-11',
        totalSales: 100000.0, // Peter sold 100,000 EGP
        ordersCount: 45,
        unsettledAdvances: 500.0,
      );

      // 100,000 * 2.5% = 2,500 EGP
      expect(summary.calculatedBonus, 2500.0);
      // 5,000 base + 2,500 bonus - 500 advance = 7,000 EGP
      expect(summary.totalEstimatedPayout, 7000.0);
      expect(summary.totalSales, 100000.0);
      expect(summary.ordersCount, 45);
    });

    test('EmployeeLoaded calculates individual and total bonuses across team', () {
      final state = EmployeeLoaded(
        allEmployees: [peter, john],
        filteredEmployees: [peter, john],
        selectedMonthPeriod: '2026-11',
        monthlySalesByEmployee: {
          'emp-peter': 100000.0,
          'emp-john': 50000.0,
        },
        monthlyOrdersCountByEmployee: {
          'emp-peter': 40,
          'emp-john': 20,
        },
      );

      // Peter: 100,000 * 2.5% = 2,500
      expect(state.getMonthlySalesForEmployee('emp-peter'), 100000.0);
      expect(state.calculateBonusForEmployee(peter), 2500.0);
      expect(state.calculateTotalEstimatedPayout(peter), 7500.0);

      // John: 50,000 * 1% = 500
      expect(state.getMonthlySalesForEmployee('emp-john'), 50000.0);
      expect(state.calculateBonusForEmployee(john), 500.0);
      expect(state.calculateTotalEstimatedPayout(john), 4500.0);

      // Total bonuses = 2,500 + 500 = 3,000 EGP
      expect(state.totalCalculatedBonusesInSelectedMonth, 3000.0);
      expect(state.totalMonthlySalesInSelectedMonth, 150000.0);
    });

    test('Employee inherits defaultSalesCommissionRate from store settings when rate is 0', () {
      final defaultStaff = EmployeeModel(
        id: 'emp-default',
        name: 'Default Staff',
        phone: '01000000003',
        jobTitle: 'Sales Staff',
        baseSalary: 6000.0,
        hireDate: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
        commissionRate: 0.0, // 0 = inherit global store settings
      );

      final state = EmployeeLoaded(
        allEmployees: [defaultStaff],
        filteredEmployees: [defaultStaff],
        selectedMonthPeriod: '2026-11',
        defaultSalesCommissionRate: 3.0, // 3.0% store setting
        monthlySalesByEmployee: {
          'emp-default': 100000.0,
        },
        monthlyOrdersCountByEmployee: {
          'emp-default': 50,
        },
      );

      expect(state.getEffectiveCommissionRate(defaultStaff), 3.0);
      // 100,000 * 3.0% = 3,000 EGP
      expect(state.calculateBonusForEmployee(defaultStaff), 3000.0);
      // 6,000 base + 3,000 bonus = 9,000 EGP
      expect(state.calculateTotalEstimatedPayout(defaultStaff), 9000.0);
    });

    test('EmployeeCubit updates state with monthly sales and orders count', () async {
      final repo = MockTestEmployeesRepository();
      repo.employees = [peter];
      repo.monthlySales = {'emp-peter': 100000.0};
      repo.monthlyOrders = {'emp-peter': 35};

      final cubit = EmployeeCubit(repo);
      cubit.loadEmployeesData(monthPeriod: '2026-11');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state, isA<EmployeeLoaded>());
      final loaded = cubit.state as EmployeeLoaded;
      expect(loaded.getMonthlySalesForEmployee('emp-peter'), 100000.0);
      expect(loaded.getMonthlyOrdersCountForEmployee('emp-peter'), 35);
      expect(loaded.calculateBonusForEmployee(peter), 2500.0);

      await cubit.close();
    });
  });

  group('UI Integration: EmployeeFormDialog & DisbursePayrollDialog', () {
    testWidgets('EmployeeFormDialog renders commission presets and dynamic preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockTestEmployeesRepository();
      final cubit = EmployeeCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<EmployeeCubit>.value(
            value: cubit,
            child: Scaffold(
              body: EmployeeFormDialog(employee: peter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check presets exist
      expect(find.text('2.5%'), findsWidgets);
      expect(find.text('5.0%'), findsWidgets);

      // Check calculation preview text is rendered
      expect(find.textContaining('100,000'), findsWidgets);
    });

    testWidgets('DisbursePayrollDialog auto-populates calculated bonus from Peter sales', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final empRepo = MockTestEmployeesRepository();
      empRepo.employees = [peter];
      empRepo.monthlySales = {'emp-peter': 100000.0};
      empRepo.monthlyOrders = {'emp-peter': 42};

      final empCubit = EmployeeCubit(empRepo);
      empCubit.loadEmployeesData(monthPeriod: '2026-11');

      final authCubit = AuthRoleCubit(MockRolesRepository(), empRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EmployeeCubit>.value(value: empCubit),
              BlocProvider<AuthRoleCubit>.value(value: authCubit),
            ],
            child: Scaffold(
              body: DisbursePayrollDialog(initialEmployee: peter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Peter name and base salary
      expect(find.textContaining('Peter'), findsWidgets);
      // Auto-calculated bonus field (100,000 * 2.5% = 2500.00)
      expect(find.text('2500.00'), findsOneWidget);
    });

    testWidgets('StaffCommissionSettingsCard updates commission rate and shows math preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = TextEditingController(text: '2.5');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffCommissionSettingsCard(
              commissionRateController: controller,
              isDark: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Staff Sales Commission'), findsOneWidget);
      expect(find.text('2.5%'), findsOneWidget);
      expect(find.text('5.0%'), findsOneWidget);

      // Tap 5.0% preset chip
      await tester.tap(find.text('5.0%'));
      await tester.pumpAndSettle();

      expect(controller.text, '5.0');
    });
  });
}
