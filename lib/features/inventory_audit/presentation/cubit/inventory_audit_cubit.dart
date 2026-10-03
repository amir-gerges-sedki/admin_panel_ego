import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/inventory_audit_model.dart';
import '../../data/repositories/inventory_audit_repository.dart';
import 'inventory_audit_state.dart';

export 'inventory_audit_state.dart';

class InventoryAuditCubit extends Cubit<InventoryAuditState> {
  final InventoryAuditRepository repository;

  InventoryAuditCubit({required this.repository})
    : super(const InventoryAuditState());

  Future<void> loadAudits({String? branchId}) async {
    emit(
      state.copyWith(status: InventoryAuditStatus.loading, clearErrors: true),
    );
    try {
      final audits = await repository.getAudits(branchId: branchId);
      emit(
        state.copyWith(
          status: InventoryAuditStatus.loaded,
          pastAudits: audits,
          selectedBranchId: branchId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InventoryAuditStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Initializes a new physical audit session with all products for the given branch
  void startNewAudit({
    required String branchId,
    required String branchName,
    required List<ProductModel> allProducts,
  }) {
    final List<InventoryAuditItemModel> items = [];

    for (final prod in allProducts) {
      if (prod.productVariations.isNotEmpty) {
        for (final v in prod.productVariations) {
          final sysQty = v.getStockForBranch(branchId);
          items.add(
            InventoryAuditItemModel(
              productId: prod.id,
              productTitle: prod.displayTitle,
              variationSku: v.sku,
              variationAttributes: v.attributeValues,
              systemQuantity: sysQty,
              physicalQuantity: sysQty, // Default to system qty until counted
              unitCost: v.costPrice > 0 ? v.costPrice : prod.costPrice,
            ),
          );
        }
      } else {
        final sysQty = prod.getStockForBranch(branchId);
        items.add(
          InventoryAuditItemModel(
            productId: prod.id,
            productTitle: prod.displayTitle,
            variationSku: '',
            variationAttributes: const {},
            systemQuantity: sysQty,
            physicalQuantity: sysQty, // Default to system qty until counted
            unitCost: prod.costPrice,
          ),
        );
      }
    }

    emit(
      state.copyWith(
        selectedBranchId: branchId,
        selectedBranchName: branchName,
        currentAuditItems: items,
        clearErrors: true,
      ),
    );
  }

  void updatePhysicalQuantity(int index, int newQty) {
    if (index < 0 || index >= state.currentAuditItems.length) return;
    final updatedList = List<InventoryAuditItemModel>.from(
      state.currentAuditItems,
    );
    final item = updatedList[index];
    updatedList[index] = item.copyWith(
      physicalQuantity: newQty.clamp(0, 999999),
    );

    emit(state.copyWith(currentAuditItems: updatedList));
  }

  /// Handles hardware barcode scan during inventory audit session
  bool handleBarcodeScanned(String rawBarcode) {
    final barcode = rawBarcode.trim().toLowerCase();
    if (barcode.isEmpty || state.currentAuditItems.isEmpty) return false;

    final index = state.currentAuditItems.indexWhere((item) {
      if (item.variationSku.trim().toLowerCase() == barcode) return true;
      if (item.productId.trim().toLowerCase() == barcode) return true;
      return false;
    });

    if (index != -1) {
      final item = state.currentAuditItems[index];
      updatePhysicalQuantity(index, item.physicalQuantity + 1);
      return true;
    }
    return false;
  }

  Future<bool> reconcileAndComplete({
    required String auditedBy,
    String notes = '',
  }) async {
    if (state.currentAuditItems.isEmpty) return false;
    emit(state.copyWith(isSubmitting: true, clearErrors: true));

    try {
      final now = DateTime.now();
      final auditNumber =
          'AUD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final audit = InventoryAuditModel(
        id: '',
        auditNumber: auditNumber,
        branchId: state.selectedBranchId ?? 'main_branch',
        branchName: state.selectedBranchName ?? 'Main Branch',
        auditDate: now,
        auditedBy: auditedBy.isNotEmpty ? auditedBy : 'Auditor',
        status: 'completed',
        items: state.currentAuditItems,
        notes: notes,
        completedAt: now,
        createdAt: now,
      );

      await repository.reconcileAndCompleteAudit(audit, performedBy: auditedBy);
      await loadAudits(branchId: state.selectedBranchId);

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage:
              'تم اعتماد وتسوية الجرد الفعلي بنجاح! رقم الجرد: #$auditNumber',
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'فشل في تسوية الجرد: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> saveDraft({required String auditedBy, String notes = ''}) async {
    if (state.currentAuditItems.isEmpty) return false;
    emit(state.copyWith(isSubmitting: true, clearErrors: true));

    try {
      final now = DateTime.now();
      final auditNumber =
          'AUD-DRAFT-${now.millisecondsSinceEpoch.toString().substring(6)}';

      final audit = InventoryAuditModel(
        id: '',
        auditNumber: auditNumber,
        branchId: state.selectedBranchId ?? 'main_branch',
        branchName: state.selectedBranchName ?? 'Main Branch',
        auditDate: now,
        auditedBy: auditedBy.isNotEmpty ? auditedBy : 'Auditor',
        status: 'draft',
        items: state.currentAuditItems,
        notes: notes,
        createdAt: now,
      );

      await repository.saveAuditDraft(audit);
      await loadAudits(branchId: state.selectedBranchId);

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'تم حفظ مسودة الجرد بنجاح!',
        ),
      );
      await loadAudits(branchId: state.selectedBranchId);
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'فشل في حفظ مسودة الجرد: $e',
        ),
      );
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearErrors: true));
  }
}
