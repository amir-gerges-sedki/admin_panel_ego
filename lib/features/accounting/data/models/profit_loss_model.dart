import 'package:equatable/equatable.dart';

/// Period financial breakdown calculating Revenue, COGS, Operating Expenses, and Net Profit.
class ProfitLossModel extends Equatable {
  final double grossSales;
  final double discountsGiven;
  final double netRevenue;
  final double totalCogs; // Cost of Goods Sold
  final double operatingExpenses;
  final double payrollExpenses;
  final double damagedStockLoss;
  final int totalOrders;
  final int totalItemsSold;
  final DateTime startDate;
  final DateTime endDate;

  const ProfitLossModel({
    this.grossSales = 0.0,
    this.discountsGiven = 0.0,
    this.netRevenue = 0.0,
    this.totalCogs = 0.0,
    this.operatingExpenses = 0.0,
    this.payrollExpenses = 0.0,
    this.damagedStockLoss = 0.0,
    this.totalOrders = 0,
    this.totalItemsSold = 0,
    required this.startDate,
    required this.endDate,
  });

  /// Gross Profit = Net Sales Revenue - COGS
  double get grossProfit => netRevenue - totalCogs;

  /// Gross Profit Margin Percentage
  double get grossProfitMargin =>
      netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0.0;

  /// Total Overhead & Operating Costs
  double get totalOperatingExpenses =>
      operatingExpenses + payrollExpenses + damagedStockLoss;

  /// Net Profit = Gross Profit - Operating Expenses - Payroll - Damaged Stock
  double get netProfit => grossProfit - totalOperatingExpenses;

  /// Net Profit Margin Percentage
  double get netProfitMargin =>
      netRevenue > 0 ? (netProfit / netRevenue) * 100 : 0.0;

  @override
  List<Object?> get props => [
        grossSales,
        discountsGiven,
        netRevenue,
        totalCogs,
        operatingExpenses,
        payrollExpenses,
        damagedStockLoss,
        totalOrders,
        totalItemsSold,
        startDate,
        endDate,
      ];
}
