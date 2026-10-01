import '../datasources/shift_remote_data_source.dart';
import '../models/cashier_shift_model.dart';
import '../models/shift_transaction_model.dart';

abstract class ShiftRepository {
  Future<CashierShiftModel> openShift(CashierShiftModel shift);
  Future<CashierShiftModel?> getActiveShift({String? cashierId, String? branchId});
  Stream<CashierShiftModel?> getActiveShiftStream({String? cashierId, String? branchId});
  Future<void> recordShiftSale({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  });
  Future<void> recordCashIn({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  });
  Future<void> recordCashOut({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  });
  Future<void> recordShiftReturn({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  });
  Future<CashierShiftModel> closeShift({
    required String shiftId,
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  });
  Future<CashierShiftModel?> getLastClosedShift({String? branchId});
  Future<List<CashierShiftModel>> getShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  });
  Future<List<ShiftTransactionModel>> getShiftTransactions(String shiftId);
}

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftRemoteDataSource remoteDataSource;

  ShiftRepositoryImpl({ShiftRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? ShiftRemoteDataSourceImpl();

  @override
  Future<CashierShiftModel> openShift(CashierShiftModel shift) =>
      remoteDataSource.openShift(shift);

  @override
  Future<CashierShiftModel?> getActiveShift({String? cashierId, String? branchId}) =>
      remoteDataSource.getActiveShift(cashierId: cashierId, branchId: branchId);

  @override
  Stream<CashierShiftModel?> getActiveShiftStream({String? cashierId, String? branchId}) =>
      remoteDataSource.getActiveShiftStream(cashierId: cashierId, branchId: branchId);

  @override
  Future<void> recordShiftSale({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) =>
      remoteDataSource.recordShiftSale(
        shiftId: shiftId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

  @override
  Future<void> recordCashIn({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) =>
      remoteDataSource.recordCashIn(
        shiftId: shiftId,
        amount: amount,
        reason: reason,
        performedBy: performedBy,
      );

  @override
  Future<void> recordCashOut({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) =>
      remoteDataSource.recordCashOut(
        shiftId: shiftId,
        amount: amount,
        reason: reason,
        performedBy: performedBy,
      );

  @override
  Future<void> recordShiftReturn({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) =>
      remoteDataSource.recordShiftReturn(
        shiftId: shiftId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

  @override
  Future<CashierShiftModel> closeShift({
    required String shiftId,
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  }) =>
      remoteDataSource.closeShift(
        shiftId: shiftId,
        actualCountedCash: actualCountedCash,
        closingNotes: closingNotes,
        closedBy: closedBy,
      );

  @override
  Future<CashierShiftModel?> getLastClosedShift({String? branchId}) =>
      remoteDataSource.getLastClosedShift(branchId: branchId);

  @override
  Future<List<CashierShiftModel>> getShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  }) =>
      remoteDataSource.getShiftsHistory(
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
        cashierId: cashierId,
      );

  @override
  Future<List<ShiftTransactionModel>> getShiftTransactions(String shiftId) =>
      remoteDataSource.getShiftTransactions(shiftId);
}
