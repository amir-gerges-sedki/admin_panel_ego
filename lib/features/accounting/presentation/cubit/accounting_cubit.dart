import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/treasury_transaction_model.dart';
import '../../data/repositories/accounting_repository.dart';
import 'accounting_state.dart';

class AccountingCubit extends Cubit<AccountingState> {
  final AccountingRepository repository;

  AccountingCubit({required this.repository})
      : super(AccountingState.initial());

  Future<void> loadAccountingData({
    AccountingPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
    String? branchId,
  }) async {
    emit(state.copyWith(
      status: AccountingStatus.loading,
      selectedPeriod: period ?? state.selectedPeriod,
      selectedBranchId: branchId ?? state.selectedBranchId,
    ));

    final effectivePeriod = period ?? state.selectedPeriod;
    final range = _resolveDateRange(
      effectivePeriod,
      customStart ?? state.customStartDate,
      customEnd ?? state.customEndDate,
    );

    try {
      final results = await Future.wait([
        repository.getTreasurySummary(branchId: state.selectedBranchId),
        repository.getProfitAndLoss(
          startDate: range.$1,
          endDate: range.$2,
          branchId: state.selectedBranchId,
        ),
        repository.getTreasuryTransactions(
          limit: 100,
          branchId: state.selectedBranchId,
        ),
      ]);

      emit(state.copyWith(
        status: AccountingStatus.loaded,
        treasurySummary: results[0] as dynamic,
        profitLoss: results[1] as dynamic,
        transactions: results[2] as List<TreasuryTransactionModel>,
        customStartDate: range.$1,
        customEndDate: range.$2,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AccountingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<bool> recordTransaction({
    required TreasuryTransactionType type,
    required PaymentChannelType channel,
    required double amount,
    required String reason,
    String referenceNumber = '',
    String branchId = '',
    String branchName = '',
    String performedBy = '',
  }) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final newTx = TreasuryTransactionModel(
        id: '',
        type: type,
        channel: channel,
        amount: amount,
        reason: reason,
        referenceNumber: referenceNumber,
        branchId: branchId.isNotEmpty ? branchId : (state.selectedBranchId ?? ''),
        branchName: branchName,
        performedBy: performedBy,
        createdAt: DateTime.now(),
      );

      await repository.recordTreasuryTransaction(newTx);
      emit(state.copyWith(isSubmitting: false));
      // Reload updated financial position
      await loadAccountingData();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<bool> updateTransaction(TreasuryTransactionModel transaction) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await repository.updateTreasuryTransaction(transaction);
      emit(state.copyWith(isSubmitting: false));
      // Reload updated financial position
      await loadAccountingData();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await repository.deleteTreasuryTransaction(transactionId);
      emit(state.copyWith(isSubmitting: false));
      // Reload updated financial position
      await loadAccountingData();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  (DateTime, DateTime) _resolveDateRange(
    AccountingPeriod period,
    DateTime customStart,
    DateTime customEnd,
  ) {
    final now = DateTime.now();
    switch (period) {
      case AccountingPeriod.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.yesterday:
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day, 0, 0, 0);
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final cleanStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
        final cleanEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (cleanStart, cleanEnd);
      case AccountingPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.allTime:
        final start = DateTime(2020, 1, 1, 0, 0, 0);
        final end = DateTime(now.year + 1, 1, 1, 23, 59, 59);
        return (start, end);
      case AccountingPeriod.custom:
        return (customStart, customEnd);
    }
  }
}
