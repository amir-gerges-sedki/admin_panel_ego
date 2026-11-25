import 'package:equatable/equatable.dart';
import 'employee_model.dart';

/// Aggregated monthly sales and bonus summary for a staff member
class StaffSalesSummary extends Equatable {
  final String staffId;
  final String staffName;
  final String monthPeriod; // "YYYY-MM"
  final double totalSales;
  final int ordersCount;
  final double commissionRate;
  final double calculatedBonus;
  final double baseSalary;
  final double unsettledAdvances;
  final double totalEstimatedPayout;

  const StaffSalesSummary({
    required this.staffId,
    required this.staffName,
    required this.monthPeriod,
    required this.totalSales,
    required this.ordersCount,
    required this.commissionRate,
    required this.calculatedBonus,
    required this.baseSalary,
    this.unsettledAdvances = 0.0,
    required this.totalEstimatedPayout,
  });

  /// Factory helper that calculates bonus and payout from employee model and monthly figures
  factory StaffSalesSummary.fromEmployeeAndSales({
    required EmployeeModel employee,
    required String monthPeriod,
    required double totalSales,
    required int ordersCount,
    double unsettledAdvances = 0.0,
  }) {
    final bonus = (totalSales * (employee.commissionRate / 100.0)).clamp(0.0, double.infinity);
    final payout = (employee.baseSalary + bonus - unsettledAdvances).clamp(0.0, double.infinity);

    return StaffSalesSummary(
      staffId: employee.id,
      staffName: employee.name,
      monthPeriod: monthPeriod,
      totalSales: totalSales,
      ordersCount: ordersCount,
      commissionRate: employee.commissionRate,
      calculatedBonus: bonus,
      baseSalary: employee.baseSalary,
      unsettledAdvances: unsettledAdvances,
      totalEstimatedPayout: payout,
    );
  }

  @override
  List<Object?> get props => [
        staffId,
        staffName,
        monthPeriod,
        totalSales,
        ordersCount,
        commissionRate,
        calculatedBonus,
        baseSalary,
        unsettledAdvances,
        totalEstimatedPayout,
      ];
}
