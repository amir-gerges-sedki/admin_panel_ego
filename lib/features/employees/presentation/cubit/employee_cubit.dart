import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/payroll_slip_model.dart';
import '../../data/models/salary_advance_model.dart';
import '../../data/repositories/employees_repository.dart';
import 'employee_state.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeesRepository employeesRepository;

  StreamSubscription<List<EmployeeModel>>? _employeesSub;
  StreamSubscription<List<SalaryAdvanceModel>>? _advancesSub;
  StreamSubscription<List<PayrollSlipModel>>? _payrollSub;

  EmployeeCubit([EmployeesRepository? repository])
      : employeesRepository = repository ??
            (sl.isRegistered<EmployeesRepository>()
                ? sl<EmployeesRepository>()
                : EmployeesRepositoryImpl()),
        super(const EmployeeInitial());

  static String _getCurrentMonthPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void loadEmployeesData({String? monthPeriod}) {
    emit(const EmployeeLoading());

    final initialMonth = monthPeriod ?? _getCurrentMonthPeriod();

    _employeesSub?.cancel();
    _advancesSub?.cancel();
    _payrollSub?.cancel();

    _employeesSub = employeesRepository.watchEmployees().listen((employees) {
      _updateOrEmitState(employees: employees, initialMonth: initialMonth);
    }, onError: (e) {
      emit(EmployeeError(e.toString()));
    });

    _advancesSub = employeesRepository.watchAdvances().listen((advances) {
      _updateOrEmitState(advances: advances, initialMonth: initialMonth);
    }, onError: (e) {
      emit(EmployeeError(e.toString()));
    });

    _payrollSub = employeesRepository.watchPayrollSlips().listen((slips) {
      _updateOrEmitState(payrollSlips: slips, initialMonth: initialMonth);
    }, onError: (e) {
      emit(EmployeeError(e.toString()));
    });
  }

  void _updateOrEmitState({
    List<EmployeeModel>? employees,
    List<SalaryAdvanceModel>? advances,
    List<PayrollSlipModel>? payrollSlips,
    String? initialMonth,
  }) {
    if (state is EmployeeLoaded) {
      final current = state as EmployeeLoaded;
      final emps = employees ?? current.allEmployees;
      final advs = advances ?? current.allAdvances;
      final slips = payrollSlips ?? current.allPayrollSlips;

      final filtered = _applyFilters(emps, current.searchQuery);

      emit(current.copyWith(
        allEmployees: emps,
        filteredEmployees: filtered,
        allAdvances: advs,
        allPayrollSlips: slips,
      ));
    } else {
      final emps = employees ?? <EmployeeModel>[];
      final advs = advances ?? <SalaryAdvanceModel>[];
      final slips = payrollSlips ?? <PayrollSlipModel>[];

      emit(EmployeeLoaded(
        allEmployees: emps,
        filteredEmployees: emps,
        allAdvances: advs,
        allPayrollSlips: slips,
        selectedMonthPeriod: initialMonth ?? _getCurrentMonthPeriod(),
      ));
    }
  }

  void filterEmployees({String? query, String? monthPeriod, String? employeeFilterId, bool clearEmployeeFilter = false}) {
    if (state is! EmployeeLoaded) return;
    final current = state as EmployeeLoaded;

    final newQuery = query ?? current.searchQuery;
    final newMonth = monthPeriod ?? current.selectedMonthPeriod;
    final newEmpFilter = clearEmployeeFilter ? null : (employeeFilterId ?? current.selectedEmployeeFilterId);

    final filtered = _applyFilters(current.allEmployees, newQuery);

    emit(current.copyWith(
      filteredEmployees: filtered,
      searchQuery: newQuery,
      selectedMonthPeriod: newMonth,
      selectedEmployeeFilterId: newEmpFilter,
      clearEmployeeFilter: clearEmployeeFilter,
    ));
  }

  List<EmployeeModel> _applyFilters(List<EmployeeModel> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase().trim();
    return all.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.phone.toLowerCase().contains(q) ||
          e.jobTitle.toLowerCase().contains(q) ||
          e.nationalId.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    try {
      await employeesRepository.addEmployee(employee);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await employeesRepository.updateEmployee(employee);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await employeesRepository.deleteEmployee(id);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> disburseSalaryAdvance(SalaryAdvanceModel advance) async {
    try {
      await employeesRepository.disburseSalaryAdvance(advance);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> deleteAdvance(String id) async {
    try {
      await employeesRepository.deleteAdvance(id);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> disbursePayroll({
    required PayrollSlipModel slip,
    required List<SalaryAdvanceModel> advancesToDeduct,
    bool recordToExpenses = true,
  }) async {
    try {
      await employeesRepository.disbursePayroll(
        slip: slip,
        advancesToDeduct: advancesToDeduct,
        recordToExpenses: recordToExpenses,
      );
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> deletePayrollSlip(PayrollSlipModel slip) async {
    try {
      await employeesRepository.deletePayrollSlip(slip);
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _employeesSub?.cancel();
    _advancesSub?.cancel();
    _payrollSub?.cancel();
    return super.close();
  }
}
