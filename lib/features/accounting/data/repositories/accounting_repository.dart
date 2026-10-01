import '../datasources/accounting_remote_data_source.dart';
import '../models/profit_loss_model.dart';
import '../models/treasury_summary_model.dart';
import '../models/treasury_transaction_model.dart';

abstract class AccountingRepository {
  Future<TreasurySummaryModel> getTreasurySummary({String? branchId});
  Future<ProfitLossModel> getProfitAndLoss({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  });
  Future<List<TreasuryTransactionModel>> getTreasuryTransactions({
    int limit = 100,
    String? branchId,
  });
  Future<TreasuryTransactionModel> recordTreasuryTransaction(
      TreasuryTransactionModel transaction);
  Future<void> updateTreasuryTransaction(
      TreasuryTransactionModel transaction);
  Future<void> deleteTreasuryTransaction(String id);
}

class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingRemoteDataSource remoteDataSource;

  AccountingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TreasurySummaryModel> getTreasurySummary({String? branchId}) {
    return remoteDataSource.getTreasurySummary(branchId: branchId);
  }

  @override
  Future<ProfitLossModel> getProfitAndLoss({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) {
    return remoteDataSource.getProfitAndLoss(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
    );
  }

  @override
  Future<List<TreasuryTransactionModel>> getTreasuryTransactions({
    int limit = 100,
    String? branchId,
  }) {
    return remoteDataSource.getTreasuryTransactions(
      limit: limit,
      branchId: branchId,
    );
  }

  @override
  Future<TreasuryTransactionModel> recordTreasuryTransaction(
      TreasuryTransactionModel transaction) {
    return remoteDataSource.recordTreasuryTransaction(transaction);
  }

  @override
  Future<void> updateTreasuryTransaction(
      TreasuryTransactionModel transaction) {
    return remoteDataSource.updateTreasuryTransaction(transaction);
  }

  @override
  Future<void> deleteTreasuryTransaction(String id) {
    return remoteDataSource.deleteTreasuryTransaction(id);
  }
}
