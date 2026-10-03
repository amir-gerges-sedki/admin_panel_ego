import 'package:equatable/equatable.dart';
import '../../data/models/inventory_audit_model.dart';

enum InventoryAuditStatus { initial, loading, loaded, error }

class InventoryAuditState extends Equatable {
  final InventoryAuditStatus status;
  final List<InventoryAuditModel> pastAudits;
  final String? selectedBranchId;
  final String? selectedBranchName;
  final List<InventoryAuditItemModel> currentAuditItems;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;

  const InventoryAuditState({
    this.status = InventoryAuditStatus.initial,
    this.pastAudits = const [],
    this.selectedBranchId,
    this.selectedBranchName,
    this.currentAuditItems = const [],
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
  });

  int get totalCountedUnits => currentAuditItems.fold<int>(0, (prev, i) => prev + i.physicalQuantity);
  int get totalVarianceUnits => currentAuditItems.fold<int>(0, (prev, i) => prev + i.variance);
  int get deficitUnits => currentAuditItems.where((i) => i.variance < 0).fold<int>(0, (prev, i) => prev + i.variance.abs());
  int get surplusUnits => currentAuditItems.where((i) => i.variance > 0).fold<int>(0, (prev, i) => prev + i.variance);
  double get totalVarianceCost => currentAuditItems.fold<double>(0.0, (prev, i) => prev + i.varianceCost);

  InventoryAuditState copyWith({
    InventoryAuditStatus? status,
    List<InventoryAuditModel>? pastAudits,
    String? selectedBranchId,
    String? selectedBranchName,
    List<InventoryAuditItemModel>? currentAuditItems,
    String? errorMessage,
    String? successMessage,
    bool? isSubmitting,
    bool clearErrors = false,
  }) {
    return InventoryAuditState(
      status: status ?? this.status,
      pastAudits: pastAudits ?? this.pastAudits,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedBranchName: selectedBranchName ?? this.selectedBranchName,
      currentAuditItems: currentAuditItems ?? this.currentAuditItems,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearErrors ? null : (successMessage ?? this.successMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pastAudits,
        selectedBranchId,
        selectedBranchName,
        currentAuditItems,
        errorMessage,
        successMessage,
        isSubmitting,
      ];
}
