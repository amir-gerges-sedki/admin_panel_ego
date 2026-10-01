import 'package:equatable/equatable.dart';
import '../../data/models/stock_transfer_model.dart';

class StockTransferState extends Equatable {
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;
  final List<StockTransferModel> transfers;
  final String selectedBranchId;
  final StockTransferStatus? statusFilter;
  final String searchQuery;

  const StockTransferState({
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
    this.transfers = const [],
    this.selectedBranchId = 'all',
    this.statusFilter,
    this.searchQuery = '',
  });

  /// Filtered transfers matching search and status filter
  List<StockTransferModel> get filteredTransfers {
    return transfers.where((t) {
      if (statusFilter != null && t.status != statusFilter) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchNum = t.transferNumber.toLowerCase().contains(q);
        final matchFrom = t.fromBranchName.toLowerCase().contains(q);
        final matchTo = t.toBranchName.toLowerCase().contains(q);
        final matchItems = t.items.any((i) =>
            i.productTitle.toLowerCase().contains(q) ||
            i.variationSku.toLowerCase().contains(q));
        if (!matchNum && !matchFrom && !matchTo && !matchItems) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Incoming transfers where destination is [branchId]
  List<StockTransferModel> incomingTransfers(String branchId) {
    if (branchId.isEmpty || branchId == 'all') return filteredTransfers;
    return filteredTransfers.where((t) => t.toBranchId == branchId).toList();
  }

  /// Outgoing transfers where source is [branchId]
  List<StockTransferModel> outgoingTransfers(String branchId) {
    if (branchId.isEmpty || branchId == 'all') return filteredTransfers;
    return filteredTransfers.where((t) => t.fromBranchId == branchId).toList();
  }

  /// Count of transfers in-transit to [branchId] awaiting receipt confirmation
  int awaitingReceiptCount(String branchId) {
    return transfers.where((t) {
      final isDest = branchId.isEmpty || branchId == 'all' || t.toBranchId == branchId;
      return isDest && (t.status == StockTransferStatus.inTransit || t.status == StockTransferStatus.approved);
    }).length;
  }

  StockTransferState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    String? errorMessage,
    String? successMessage,
    List<StockTransferModel>? transfers,
    String? selectedBranchId,
    StockTransferStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StockTransferState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      transfers: transfers ?? this.transfers,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCreating,
        isUpdating,
        errorMessage,
        successMessage,
        transfers,
        selectedBranchId,
        statusFilter,
        searchQuery,
      ];
}
