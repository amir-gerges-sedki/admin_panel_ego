import 'package:equatable/equatable.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/payroll_slip_model.dart';
import '../../data/models/salary_advance_model.dart';

abstract class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class EmployeeInitial extends EmployeeState {
  const EmployeeInitial();
}

class EmployeeLoading extends EmployeeState {
  const EmployeeLoading();
}

class EmployeeLoaded extends EmployeeState {
  final List<EmployeeModel> allEmployees;
  final List<EmployeeModel> filteredEmployees;
  final List<SalaryAdvanceModel> allAdvances;
  final List<PayrollSlipModel> allPayrollSlips;
  final String searchQuery;
  final String selectedMonthPeriod; // "YYYY-MM"
  final String? selectedEmployeeFilterId;

  const EmployeeLoaded({
    required this.allEmployees,
    required this.filteredEmployees,
    this.allAdvances = const [],
    this.allPayrollSlips = const [],
    this.searchQuery = '',
    required this.selectedMonthPeriod,
    this.selectedEmployeeFilterId,
  });

  // --- Financial & HR KPIs ---

  int get activeEmployeesCount => allEmployees.where((e) => e.isActive).length;

  double get totalMonthlyBaseSalaries =>
      allEmployees.where((e) => e.isActive).fold(0.0, (sum, e) => sum + e.baseSalary);

  double get totalAdvancesInSelectedMonth => allAdvances
      .where((a) => a.monthPeriod == selectedMonthPeriod)
      .fold(0.0, (sum, a) => sum + a.amount);

  double get totalUnsettledAdvancesInSelectedMonth => allAdvances
      .where((a) => a.monthPeriod == selectedMonthPeriod && !a.isDeductedFromPayroll)
      .fold(0.0, (sum, a) => sum + a.amount);

  double get totalPaidSalariesInSelectedMonth => allPayrollSlips
      .where((p) => p.monthPeriod == selectedMonthPeriod)
      .fold(0.0, (sum, p) => sum + p.netSalary);

  // Helper: Get unsettled advances for specific employee in current selected month
  List<SalaryAdvanceModel> getUnsettledAdvancesForEmployee(String employeeId) {
    return allAdvances.where((a) {
      return a.employeeId == employeeId &&
          a.monthPeriod == selectedMonthPeriod &&
          !a.isDeductedFromPayroll;
    }).toList();
  }

  double getUnsettledAdvancesAmountForEmployee(String employeeId) {
    return getUnsettledAdvancesForEmployee(employeeId).fold(0.0, (sum, a) => sum + a.amount);
  }

  // Helper: Check if payroll was already disbursed for employee in this month
  PayrollSlipModel? getPayrollSlipForEmployee(String employeeId) {
    for (final slip in allPayrollSlips) {
      if (slip.employeeId == employeeId && slip.monthPeriod == selectedMonthPeriod) {
        return slip;
      }
    }
    return null;
  }

  EmployeeLoaded copyWith({
    List<EmployeeModel>? allEmployees,
    List<EmployeeModel>? filteredEmployees,
    List<SalaryAdvanceModel>? allAdvances,
    List<PayrollSlipModel>? allPayrollSlips,
    String? searchQuery,
    String? selectedMonthPeriod,
    String? selectedEmployeeFilterId,
    bool clearEmployeeFilter = false,
  }) {
    return EmployeeLoaded(
      allEmployees: allEmployees ?? this.allEmployees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      allAdvances: allAdvances ?? this.allAdvances,
      allPayrollSlips: allPayrollSlips ?? this.allPayrollSlips,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMonthPeriod: selectedMonthPeriod ?? this.selectedMonthPeriod,
      selectedEmployeeFilterId: clearEmployeeFilter
          ? null
          : (selectedEmployeeFilterId ?? this.selectedEmployeeFilterId),
    );
  }

  @override
  List<Object?> get props => [
        allEmployees,
        filteredEmployees,
        allAdvances,
        allPayrollSlips,
        searchQuery,
        selectedMonthPeriod,
        selectedEmployeeFilterId,
      ];
}

class EmployeeError extends EmployeeState {
  final String message;

  const EmployeeError(this.message);

  @override
  List<Object?> get props => [message];
}
