import 'package:equatable/equatable.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/shift_transaction_model.dart';

enum ShiftActionStatus {
  initial,
  loading,
  success,
  error,
}

class ShiftState extends Equatable {
  final CashierShiftModel? activeShift;
  final ShiftActionStatus actionStatus;
  final List<CashierShiftModel> historyShifts;
  final List<ShiftTransactionModel> activeShiftTransactions;
  final String? errorMessage;
  final String? filterBranchId;
  final String? filterCashierId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  const ShiftState({
    this.activeShift,
    this.actionStatus = ShiftActionStatus.initial,
    this.historyShifts = const [],
    this.activeShiftTransactions = const [],
    this.errorMessage,
    this.filterBranchId,
    this.filterCashierId,
    this.filterStartDate,
    this.filterEndDate,
  });

  bool get hasActiveShift => activeShift != null && activeShift!.isOpen;

  ShiftState copyWith({
    CashierShiftModel? activeShift,
    bool clearActiveShift = false,
    ShiftActionStatus? actionStatus,
    List<CashierShiftModel>? historyShifts,
    List<ShiftTransactionModel>? activeShiftTransactions,
    String? errorMessage,
    bool clearError = false,
    String? filterBranchId,
    String? filterCashierId,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) {
    return ShiftState(
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      actionStatus: actionStatus ?? this.actionStatus,
      historyShifts: historyShifts ?? this.historyShifts,
      activeShiftTransactions:
          activeShiftTransactions ?? this.activeShiftTransactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filterBranchId: filterBranchId ?? this.filterBranchId,
      filterCashierId: filterCashierId ?? this.filterCashierId,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
    );
  }

  @override
  List<Object?> get props => [
        activeShift,
        actionStatus,
        historyShifts,
        activeShiftTransactions,
        errorMessage,
        filterBranchId,
        filterCashierId,
        filterStartDate,
        filterEndDate,
      ];
}
