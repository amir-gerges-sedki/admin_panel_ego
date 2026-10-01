import 'package:equatable/equatable.dart';

/// Consolidated summary of treasury channels and liquid balances.
class TreasurySummaryModel extends Equatable {
  final double cashBalance;
  final double cardBalance;
  final double instapayBalance;
  final double vodafoneCashBalance;
  final double supplierPayables;
  final double customerReceivables;
  final double inventoryCostValue;
  final DateTime lastUpdated;

  const TreasurySummaryModel({
    this.cashBalance = 0.0,
    this.cardBalance = 0.0,
    this.instapayBalance = 0.0,
    this.vodafoneCashBalance = 0.0,
    this.supplierPayables = 0.0,
    this.customerReceivables = 0.0,
    this.inventoryCostValue = 0.0,
    required this.lastUpdated,
  });

  double get totalLiquidAssets =>
      cashBalance + cardBalance + instapayBalance + vodafoneCashBalance;

  double get netWorkingCapital =>
      totalLiquidAssets + inventoryCostValue - supplierPayables;

  TreasurySummaryModel copyWith({
    double? cashBalance,
    double? cardBalance,
    double? instapayBalance,
    double? vodafoneCashBalance,
    double? supplierPayables,
    double? customerReceivables,
    double? inventoryCostValue,
    DateTime? lastUpdated,
  }) {
    return TreasurySummaryModel(
      cashBalance: cashBalance ?? this.cashBalance,
      cardBalance: cardBalance ?? this.cardBalance,
      instapayBalance: instapayBalance ?? this.instapayBalance,
      vodafoneCashBalance: vodafoneCashBalance ?? this.vodafoneCashBalance,
      supplierPayables: supplierPayables ?? this.supplierPayables,
      customerReceivables: customerReceivables ?? this.customerReceivables,
      inventoryCostValue: inventoryCostValue ?? this.inventoryCostValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        cashBalance,
        cardBalance,
        instapayBalance,
        vodafoneCashBalance,
        supplierPayables,
        customerReceivables,
        inventoryCostValue,
        lastUpdated,
      ];
}
