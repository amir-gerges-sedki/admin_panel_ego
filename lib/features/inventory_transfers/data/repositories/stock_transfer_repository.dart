import '../datasources/stock_transfer_remote_data_source.dart';
import '../models/stock_transfer_model.dart';

abstract class StockTransferRepository {
  Future<String> createTransfer(StockTransferModel transfer);
  Future<List<StockTransferModel>> getTransfers({String? branchId, StockTransferStatus? status});
  Stream<List<StockTransferModel>> watchTransfers({String? branchId});
  Future<void> updateTransferStatus(
    String transferId,
    StockTransferStatus status, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
  });
  Future<void> deleteTransfer(String transferId);
}

class StockTransferRepositoryImpl implements StockTransferRepository {
  final StockTransferRemoteDataSource remoteDataSource;

  StockTransferRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> createTransfer(StockTransferModel transfer) {
    return remoteDataSource.createTransfer(transfer);
  }

  @override
  Future<List<StockTransferModel>> getTransfers({String? branchId, StockTransferStatus? status}) {
    return remoteDataSource.getTransfers(branchId: branchId, status: status);
  }

  @override
  Stream<List<StockTransferModel>> watchTransfers({String? branchId}) {
    return remoteDataSource.watchTransfers(branchId: branchId);
  }

  @override
  Future<void> updateTransferStatus(
    String transferId,
    StockTransferStatus status, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
  }) {
    return remoteDataSource.updateTransferStatus(
      transferId,
      status,
      performedBy: performedBy,
      receivedQuantities: receivedQuantities,
      notes: notes,
    );
  }

  @override
  Future<void> deleteTransfer(String transferId) {
    return remoteDataSource.deleteTransfer(transferId);
  }
}
