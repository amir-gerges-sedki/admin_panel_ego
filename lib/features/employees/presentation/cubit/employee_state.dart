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
  final Map<String, double> monthlySalesByEmployee;
  final Map<String, int> monthlyOrdersCountByEmployee;
  final double defaultSalesCommissionRate;
  final String searchQuery;
  final String selectedMonthPeriod; // "YYYY-MM"
  final String? selectedEmployeeFilterId;

  const EmployeeLoaded({
    required this.allEmployees,
    required this.filteredEmployees,
    this.allAdvances = const [],
    this.allPayrollSlips = const [],
    this.monthlySalesByEmployee = const {},
    this.monthlyOrdersCountByEmployee = const {},
    this.defaultSalesCommissionRate = 2.5,
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

  // Helper: Staff Monthly Sales & Commission Calculations
  double getMonthlySalesForEmployee(String employeeId) =>
      monthlySalesByEmployee[employeeId] ?? 0.0;

  int getMonthlyOrdersCountForEmployee(String employeeId) =>
      monthlyOrdersCountByEmployee[employeeId] ?? 0;

  double getEffectiveCommissionRate(EmployeeModel employee) {
    return employee.commissionRate > 0
        ? employee.commissionRate
        : defaultSalesCommissionRate;
  }

  double calculateBonusForEmployee(EmployeeModel employee) {
    final sales = getMonthlySalesForEmployee(employee.id);
    final rate = getEffectiveCommissionRate(employee);
    return (sales * (rate / 100.0)).clamp(0.0, double.infinity);
  }

  double calculateTotalEstimatedPayout(EmployeeModel employee) {
    final bonus = calculateBonusForEmployee(employee);
    final advances = getUnsettledAdvancesAmountForEmployee(employee.id);
    return (employee.baseSalary + bonus - advances).clamp(0.0, double.infinity);
  }

  double get totalCalculatedBonusesInSelectedMonth =>
      allEmployees.where((e) => e.isActive).fold(0.0, (sum, e) => sum + calculateBonusForEmployee(e));

  double get totalMonthlySalesInSelectedMonth =>
      monthlySalesByEmployee.values.fold(0.0, (sum, val) => sum + val);

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
    Map<String, double>? monthlySalesByEmployee,
    Map<String, int>? monthlyOrdersCountByEmployee,
    double? defaultSalesCommissionRate,
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
      monthlySalesByEmployee: monthlySalesByEmployee ?? this.monthlySalesByEmployee,
      monthlyOrdersCountByEmployee: monthlyOrdersCountByEmployee ?? this.monthlyOrdersCountByEmployee,
      defaultSalesCommissionRate: defaultSalesCommissionRate ?? this.defaultSalesCommissionRate,
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
        monthlySalesByEmployee,
        monthlyOrdersCountByEmployee,
        defaultSalesCommissionRate,
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
