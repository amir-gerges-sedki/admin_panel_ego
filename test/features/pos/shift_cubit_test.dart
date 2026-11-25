import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel_ego/features/pos/data/models/cashier_shift_model.dart';
import 'package:admin_panel_ego/features/pos/data/models/shift_transaction_model.dart';
import 'package:admin_panel_ego/features/pos/data/repositories/shift_repository.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/shift_cubit.dart';
import 'package:admin_panel_ego/features/pos/presentation/cubit/shift_state.dart';

class FakeShiftRepository implements ShiftRepository {
  CashierShiftModel? activeShift;
  final StreamController<CashierShiftModel?> _streamController =
      StreamController<CashierShiftModel?>.broadcast();
  final List<ShiftTransactionModel> transactions = [];
  final List<CashierShiftModel> shiftsHistory = [];

  void emitActiveShift(CashierShiftModel? shift) {
    activeShift = shift;
    _streamController.add(shift);
  }

  @override
  Stream<CashierShiftModel?> getActiveShiftStream({String? cashierId, String? branchId}) async* {
    yield activeShift;
    yield* _streamController.stream;
  }

  @override
  Future<CashierShiftModel> openShift(CashierShiftModel shift) async {
    final opened = shift.copyWith(id: 'shift_123', status: 'open');
    activeShift = opened;
    _streamController.add(opened);
    return opened;
  }

  @override
  Future<CashierShiftModel?> getActiveShift({String? cashierId, String? branchId}) async =>
      activeShift;

  @override
  Future<void> recordCashIn({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    transactions.add(ShiftTransactionModel(
      id: 'tx_${transactions.length + 1}',
      shiftId: shiftId,
      type: ShiftTransactionType.cashIn,
      amount: amount,
      reason: reason,
      performedBy: performedBy,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> recordCashOut({
    required String shiftId,
    required double amount,
    required String reason,
    required String performedBy,
  }) async {
    transactions.add(ShiftTransactionModel(
      id: 'tx_${transactions.length + 1}',
      shiftId: shiftId,
      type: ShiftTransactionType.cashOut,
      amount: amount,
      reason: reason,
      performedBy: performedBy,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> recordShiftSale({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) async {}

  @override
  Future<void> recordShiftReturn({
    required String shiftId,
    required double amount,
    required String paymentMethod,
  }) async {}

  @override
  Future<CashierShiftModel> closeShift({
    required String shiftId,
    required double actualCountedCash,
    required String closingNotes,
    required String closedBy,
  }) async {
    final closed = activeShift!.copyWith(
      status: 'closed',
      closedAt: DateTime.now(),
      actualCountedCash: actualCountedCash,
      closingNotes: closingNotes,
    );
    activeShift = null;
    _streamController.add(null);
    shiftsHistory.add(closed);
    return closed;
  }

  @override
  Future<CashierShiftModel?> getLastClosedShift({String? branchId}) async =>
      shiftsHistory.isNotEmpty ? shiftsHistory.last : null;

  @override
  Future<List<CashierShiftModel>> getShiftsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? cashierId,
  }) async =>
      shiftsHistory;

  @override
  Future<List<ShiftTransactionModel>> getShiftTransactions(String shiftId) async =>
      transactions.where((t) => t.shiftId == shiftId).toList();

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('ShiftCubit Comprehensive Unit Tests', () {
    late FakeShiftRepository repository;
    late ShiftCubit cubit;

    setUp(() {
      repository = FakeShiftRepository();
      cubit = ShiftCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
      repository.dispose();
    });

    test('Initial state has no active shift and initial action status', () {
      expect(cubit.state.activeShift, isNull);
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.actionStatus, equals(ShiftActionStatus.initial));
    });

    test('openShift creates active shift and sets action status to success', () async {
      final shift = await cubit.openShift(
        branchId: 'main_branch',
        branchName: 'Main Store',
        cashierId: 'emp_01',
        cashierName: 'Mohamed',
        openingCash: 500.0,
        openingNotes: 'Morning Shift Start',
      );

      expect(shift, isNotNull);
      expect(shift?.id, equals('shift_123'));
      expect(cubit.state.hasActiveShift, isTrue);
      expect(cubit.state.activeShift?.openingCash, equals(500.0));
      expect(cubit.state.actionStatus, equals(ShiftActionStatus.success));
    });

    test('addCashIn records transaction and updates active shift transactions', () async {
      await cubit.openShift(
        branchId: 'main_branch',
        branchName: 'Main Store',
        cashierId: 'emp_01',
        cashierName: 'Mohamed',
        openingCash: 500.0,
      );

      final success = await cubit.addCashIn(
        amount: 200.0,
        reason: 'Change from bank',
        performedBy: 'Mohamed',
      );

      expect(success, isTrue);
      expect(repository.transactions.length, equals(1));
      expect(repository.transactions.first.amount, equals(200.0));
      expect(repository.transactions.first.type, equals(ShiftTransactionType.cashIn));
    });

    test('addCashOut records cash out transaction', () async {
      await cubit.openShift(
        branchId: 'main_branch',
        branchName: 'Main Store',
        cashierId: 'emp_01',
        cashierName: 'Mohamed',
        openingCash: 500.0,
      );

      final success = await cubit.addCashOut(
        amount: 50.0,
        reason: 'Office Coffee',
        performedBy: 'Mohamed',
      );

      expect(success, isTrue);
      expect(repository.transactions.length, equals(1));
      expect(repository.transactions.first.amount, equals(50.0));
      expect(repository.transactions.first.type, equals(ShiftTransactionType.cashOut));
    });

    test('closeShift resets active shift and saves to history', () async {
      await cubit.openShift(
        branchId: 'main_branch',
        branchName: 'Main Store',
        cashierId: 'emp_01',
        cashierName: 'Mohamed',
        openingCash: 500.0,
      );

      final closed = await cubit.closeShift(
        actualCountedCash: 700.0,
        closingNotes: 'Shift reconciled cleanly',
        closedBy: 'Mohamed',
      );

      expect(closed, isNotNull);
      expect(closed?.actualCountedCash, equals(700.0));
      expect(cubit.state.hasActiveShift, isFalse);
      expect(cubit.state.activeShift, isNull);
      expect(cubit.state.actionStatus, equals(ShiftActionStatus.success));
    });
  });
}
