import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/stock_transfer_model.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import 'stock_transfer_state.dart';

class StockTransferCubit extends Cubit<StockTransferState> {
  final StockTransferRepository repository;
  StreamSubscription<List<StockTransferModel>>? _subscription;

  StockTransferCubit({required this.repository}) : super(const StockTransferState());

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void filterByBranch(String branchId) {
    emit(state.copyWith(selectedBranchId: branchId));
    loadTransfers(branchId: branchId);
  }

  void filterByStatus(StockTransferStatus? status) {
    if (status == null) {
      emit(state.copyWith(clearStatusFilter: true));
    } else {
      emit(state.copyWith(statusFilter: status));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> loadTransfers({String? branchId}) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      final targetBranch = branchId ?? state.selectedBranchId;
      final transfers = await repository.getTransfers(
        branchId: targetBranch == 'all' ? null : targetBranch,
      );
      emit(state.copyWith(
        isLoading: false,
        transfers: transfers,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void startWatchingTransfers({String? branchId}) {
    _subscription?.cancel();
    final targetBranch = branchId ?? state.selectedBranchId;
    _subscription = repository
        .watchTransfers(branchId: targetBranch == 'all' ? null : targetBranch)
        .listen(
      (transfers) {
        emit(state.copyWith(transfers: transfers, isLoading: false));
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString(), isLoading: false));
      },
    );
  }

  /// Create a new merchandise transfer request from source branch to destination branch
  Future<bool> createTransferRequest({
    required String fromBranchId,
    required String fromBranchName,
    required String toBranchId,
    required String toBranchName,
    required List<StockTransferItemModel> items,
    StockTransferPriority priority = StockTransferPriority.normal,
    String notes = '',
    String requestedBy = 'Cashier',
    String shiftId = '',
  }) async {
    if (items.isEmpty) {
      emit(state.copyWith(errorMessage: 'يرجى إضافة صنف واحد على الأقل للطلب'));
      return false;
    }

    emit(state.copyWith(isCreating: true, clearError: true, clearSuccess: true));
    try {
      final now = DateTime.now();
      final dateCode = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final randomSuffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
      final transferNumber = 'TR-$dateCode-$randomSuffix';

      final newTransfer = StockTransferModel(
        id: '',
        transferNumber: transferNumber,
        fromBranchId: fromBranchId,
        fromBranchName: fromBranchName,
        toBranchId: toBranchId,
        toBranchName: toBranchName,
        status: StockTransferStatus.pending,
        priority: priority,
        items: items,
        notes: notes,
        requestedBy: requestedBy,
        shiftId: shiftId,
        createdAt: now,
      );

      await repository.createTransfer(newTransfer);
      await loadTransfers();

      emit(state.copyWith(
        isCreating: false,
        successMessage: 'تم إرسال طلب تحويل البضاعة بنجاح ($transferNumber)',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        errorMessage: 'فشل إرسال طلب التحويل: $e',
      ));
      return false;
    }
  }

  /// Approve transfer (from source branch manager or admin)
  Future<bool> approveTransfer(String transferId, {String? performedBy}) async {
    return _updateStatus(
      transferId,
      StockTransferStatus.approved,
      performedBy: performedBy,
      successMsg: 'تمت الموافقة على طلب التحويل',
    );
  }

  /// Mark transfer as dispatched / in transit
  Future<bool> dispatchTransfer(String transferId, {String? performedBy, String? notes}) async {
    return _updateStatus(
      transferId,
      StockTransferStatus.inTransit,
      performedBy: performedBy,
      notes: notes,
      successMsg: 'تم شحن البضاعة وهي الآن في طريقها للفرع',
    );
  }

  /// Confirm receipt of goods at destination branch
  Future<bool> receiveTransfer(
    String transferId, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
  }) async {
    return _updateStatus(
      transferId,
      StockTransferStatus.received,
      performedBy: performedBy,
      receivedQuantities: receivedQuantities,
      notes: notes,
      successMsg: 'تم استلام وتأكيد وصول البضاعة في الفرع بنجاح',
    );
  }

  /// Reject transfer
  Future<bool> rejectTransfer(String transferId, {String? performedBy, String? reason}) async {
    return _updateStatus(
      transferId,
      StockTransferStatus.rejected,
      performedBy: performedBy,
      notes: reason,
      successMsg: 'تم رفض طلب التحويل',
    );
  }

  /// Cancel transfer
  Future<bool> cancelTransfer(String transferId, {String? performedBy, String? reason}) async {
    return _updateStatus(
      transferId,
      StockTransferStatus.cancelled,
      performedBy: performedBy,
      notes: reason,
      successMsg: 'تم إلغاء طلب التحويل',
    );
  }

  Future<bool> _updateStatus(
    String transferId,
    StockTransferStatus status, {
    String? performedBy,
    Map<String, int>? receivedQuantities,
    String? notes,
    required String successMsg,
  }) async {
    emit(state.copyWith(isUpdating: true, clearError: true, clearSuccess: true));
    try {
      await repository.updateTransferStatus(
        transferId,
        status,
        performedBy: performedBy,
        receivedQuantities: receivedQuantities,
        notes: notes,
      );
      await loadTransfers();
      emit(state.copyWith(
        isUpdating: false,
        successMessage: successMsg,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        errorMessage: 'فشل تحديث حالة الطلب: $e',
      ));
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
