import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/data/repositories/expense_repository.dart';
import '../datasources/employees_remote_data_source.dart';
import '../models/employee_model.dart';
import '../models/payroll_slip_model.dart';
import '../models/salary_advance_model.dart';

abstract class EmployeesRepository {
  // Employees
  Stream<List<EmployeeModel>> watchEmployees();
  Future<List<EmployeeModel>> getEmployees();
  Future<void> addEmployee(EmployeeModel employee);
  Future<void> updateEmployee(EmployeeModel employee);
  Future<void> deleteEmployee(String id);

  // Salary Advances
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId});
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId});
  Future<void> disburseSalaryAdvance(SalaryAdvanceModel advance);
  Future<void> deleteAdvance(String id);

  // Payroll Slips
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId});
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId});
  Future<void> disbursePayroll({
    required PayrollSlipModel slip,
    required List<SalaryAdvanceModel> advancesToDeduct,
    bool recordToExpenses = true,
  });
  Future<void> deletePayrollSlip(PayrollSlipModel slip);
}

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDataSource remoteDataSource;
  final ExpenseRepository _expenseRepository;

  EmployeesRepositoryImpl({
    EmployeesRemoteDataSource? remoteDataSource,
    ExpenseRepository? expenseRepository,
  })  : remoteDataSource = remoteDataSource ?? EmployeesRemoteDataSourceImpl(),
        _expenseRepository = expenseRepository ??
            (sl.isRegistered<ExpenseRepository>()
                ? sl<ExpenseRepository>()
                : ExpenseRepositoryImpl());

  // --- Employees ---

  @override
  Stream<List<EmployeeModel>> watchEmployees() => remoteDataSource.watchEmployees();

  @override
  Future<List<EmployeeModel>> getEmployees() => remoteDataSource.getEmployees();

  @override
  Future<void> addEmployee(EmployeeModel employee) => remoteDataSource.addEmployee(employee);

  @override
  Future<void> updateEmployee(EmployeeModel employee) => remoteDataSource.updateEmployee(employee);

  @override
  Future<void> deleteEmployee(String id) => remoteDataSource.deleteEmployee(id);

  // --- Salary Advances ---

  @override
  Stream<List<SalaryAdvanceModel>> watchAdvances({String? monthPeriod, String? employeeId}) =>
      remoteDataSource.watchAdvances(monthPeriod: monthPeriod, employeeId: employeeId);

  @override
  Future<List<SalaryAdvanceModel>> getAdvances({String? monthPeriod, String? employeeId}) =>
      remoteDataSource.getAdvances(monthPeriod: monthPeriod, employeeId: employeeId);

  @override
  Future<void> disburseSalaryAdvance(SalaryAdvanceModel advance) =>
      remoteDataSource.addAdvance(advance);

  @override
  Future<void> deleteAdvance(String id) => remoteDataSource.deleteAdvance(id);

  // --- Payroll Slips ---

  @override
  Stream<List<PayrollSlipModel>> watchPayrollSlips({String? monthPeriod, String? employeeId}) =>
      remoteDataSource.watchPayrollSlips(monthPeriod: monthPeriod, employeeId: employeeId);

  @override
  Future<List<PayrollSlipModel>> getPayrollSlips({String? monthPeriod, String? employeeId}) =>
      remoteDataSource.getPayrollSlips(monthPeriod: monthPeriod, employeeId: employeeId);

  @override
  Future<void> disbursePayroll({
    required PayrollSlipModel slip,
    required List<SalaryAdvanceModel> advancesToDeduct,
    bool recordToExpenses = true,
  }) async {
    try {
      String? linkedExpenseId;

      // 1. Automatically register an Operational Expense under Salaries
      if (recordToExpenses && slip.netSalary > 0) {
        final expenseRecord = ExpenseModel(
          id: '',
          title: 'صرف راتب شهر ${slip.monthPeriod} - ${slip.employeeName}',
          amount: slip.netSalary,
          category: ExpenseCategory.salaries,
          date: slip.paymentDate,
          paymentMethod: slip.paymentMethod,
          recordedBy: slip.disbursedBy,
          notes: 'مسير راتب: أساسي (${slip.baseSalary}) + مكافآت (${slip.totalBonuses}) - سُلف (${slip.totalAdvances}) - خصومات (${slip.totalDeductions})',
          createdAt: DateTime.now(),
        );

        await _expenseRepository.addExpense(expenseRecord);
      }

      final finalSlip = slip.copyWith(expenseId: linkedExpenseId);

      // 2. Save Payroll Slip
      await remoteDataSource.addPayrollSlip(finalSlip);

      // 3. Mark deducted advances as settled
      for (final adv in advancesToDeduct) {
        final updatedAdv = adv.copyWith(
          isDeductedFromPayroll: true,
          payrollSlipId: finalSlip.id,
        );
        await remoteDataSource.updateAdvance(updatedAdv);
      }
    } catch (e) {
      debugPrint('EmployeesRepository disbursePayroll error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePayrollSlip(PayrollSlipModel slip) async {
    try {
      // 1. Delete linked expense if found
      if (slip.expenseId != null && slip.expenseId!.isNotEmpty) {
        try {
          await _expenseRepository.deleteExpense(slip.expenseId!);
        } catch (_) {}
      }

      // 2. Unmark advances associated with this slip
      final allAdvances = await remoteDataSource.getAdvances(employeeId: slip.employeeId);
      final linkedAdvances = allAdvances.where((a) => a.payrollSlipId == slip.id);
      for (final adv in linkedAdvances) {
        final resetAdv = adv.copyWith(
          isDeductedFromPayroll: false,
          payrollSlipId: null,
        );
        await remoteDataSource.updateAdvance(resetAdv);
      }

      // 3. Delete payroll slip
      await remoteDataSource.deletePayrollSlip(slip.id);
    } catch (e) {
      debugPrint('EmployeesRepository deletePayrollSlip error: $e');
      rethrow;
    }
  }
}
