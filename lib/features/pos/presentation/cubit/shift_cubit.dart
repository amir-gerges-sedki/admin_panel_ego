import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/repositories/shift_repository.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftRepository repository;
  StreamSubscription<CashierShiftModel?>? _activeShiftSubscription;

  ShiftCubit({required this.repository}) : super(const ShiftState()) {
    init();
  }

  void init({String? cashierId, String? branchId}) {
    _activeShiftSubscription?.cancel();
    _activeShiftSubscription = repository
        .getActiveShiftStream(cashierId: cashierId, branchId: branchId)
        .listen(
      (shift) {
        emit(state.copyWith(
          activeShift: shift,
          clearActiveShift: shift == null,
        ));
        if (shift != null) {
          loadActiveShiftTransactions(shift.id);
        }
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );

    loadShiftsHistory();
  }

  Future<CashierShiftModel?> openShift({
    required String branchId,
    required String branchName,
    required String cashierId,
    required String cashierName,
    required double openingCash,
    String openingNotes = '',
  }) async {
    emit(state.copyWith(actionStatus: ShiftActionStatus.loading, clearError: true));
    try {
      final shift = CashierShiftModel(
        id: '',
        branchId: branchId,
        branchName: branchName,
        cashierId: cashierId,
        cashierName: cashierName,
        openedAt: DateTime.now(),
        openingCash: openingCash,
        expectedCash: openingCash,
        openingNotes: openingNotes,
        status: 'open',
      );

      final created = await repository.openShift(shift);
      emit(state.copyWith(
        activeShift: created,
        actionStatus: ShiftActionStatus.success,
      ));
      loadShiftsHistory();
      return created;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ShiftActionStatus.error,
        errorMessage: 'فشل في فتح الوردية: $e',
      ));
      return null;
    }
  }

  Future<bool> addCashIn({
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    if (state.activeShift == null) return false;
    emit(state.copyWith(actionStatus: ShiftActionStatus.loading));
    try {
      await repository.recordCashIn(
        shiftId: state.activeShift!.id,
        amount: amount,
        reason: reason,
        performedBy: performedBy,
      );
      loadActiveShiftTransactions(state.activeShift!.id);
      emit(state.copyWith(actionStatus: ShiftActionStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ShiftActionStatus.error,
        errorMessage: 'فشل في تسجيل وارد النقدية: $e',
      ));
      return false;
    }
  }

  Future<bool> addCashOut({
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    if (state.activeShift == null) return false;
    emit(state.copyWith(actionStatus: ShiftActionStatus.loading));
    try {
      await repository.recordCashOut(
        shiftId: state.activeShift!.id,
        amount: amount,
        reason: reason,
        performedBy: performedBy,
      );
      loadActiveShiftTransactions(state.activeShift!.id);
      emit(state.copyWith(actionStatus: ShiftActionStatus.success));
      return true;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ShiftActionStatus.error,
        errorMessage: 'فشل في تسجيل منصرف النقدية: $e',
      ));
      return false;
    }
  }

  Future<void> recordShiftSale({
    required double amount,
    required String paymentMethod,
  }) async {
    if (state.activeShift == null) return;
    try {
      await repository.recordShiftSale(
        shiftId: state.activeShift!.id,
        amount: amount,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> recordShiftReturn({
    required double amount,
    required String paymentMethod,
  }) async {
    if (state.activeShift == null) return;
    try {
      await repository.recordShiftReturn(
        shiftId: state.activeShift!.id,
        amount: amount,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<CashierShiftModel?> closeShift({
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  }) async {
    if (state.activeShift == null) return null;
    emit(state.copyWith(actionStatus: ShiftActionStatus.loading));
    try {
      final closed = await repository.closeShift(
        shiftId: state.activeShift!.id,
        actualCountedCash: actualCountedCash,
        closingNotes: closingNotes,
        closedBy: closedBy,
      );

      emit(state.copyWith(
        activeShift: null,
        clearActiveShift: true,
        actionStatus: ShiftActionStatus.success,
      ));

      loadShiftsHistory();
      return closed;
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ShiftActionStatus.error,
        errorMessage: 'فشل في إغلاق الوردية: $e',
      ));
      return null;
    }
  }

  Future<void> loadShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  }) async {
    try {
      final list = await repository.getShiftsHistory(
        startDate: startDate ?? state.filterStartDate,
        endDate: endDate ?? state.filterEndDate,
        branchId: branchId ?? state.filterBranchId,
        cashierId: cashierId ?? state.filterCashierId,
      );
      emit(state.copyWith(
        historyShifts: list,
        filterStartDate: startDate ?? state.filterStartDate,
        filterEndDate: endDate ?? state.filterEndDate,
        filterBranchId: branchId ?? state.filterBranchId,
        filterCashierId: cashierId ?? state.filterCashierId,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<CashierShiftModel?> getLastClosedShift({String? branchId}) =>
      repository.getLastClosedShift(branchId: branchId);

  Future<void> loadActiveShiftTransactions(String shiftId) async {
    try {
      final txs = await repository.getShiftTransactions(shiftId);
      emit(state.copyWith(activeShiftTransactions: txs));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _activeShiftSubscription?.cancel();
    return super.close();
  }
}
