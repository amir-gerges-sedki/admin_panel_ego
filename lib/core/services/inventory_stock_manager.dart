import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Item specification for atomic stock adjustment
class StockAdjustmentItem {
  final String productId;
  final int quantity;
  final String? variationId;
  final String? sku;
  final Map<String, String>? selectedAttributes;
  final String? title;

  const StockAdjustmentItem({
    required this.productId,
    required this.quantity,
    this.variationId,
    this.sku,
    this.selectedAttributes,
    this.title,
  });
}

/// Thrown when stock is insufficient during an atomic transaction
class InsufficientStockException implements Exception {
  final String productId;
  final String title;
  final int requestedQuantity;
  final int availableStock;

  const InsufficientStockException({
    required this.productId,
    required this.title,
    required this.requestedQuantity,
    required this.availableStock,
  });

  @override
  String toString() {
    return 'الكمية المطلوبة ($requestedQuantity) للمنتج "$title" غير متوفرة في المخزون (المتاح: $availableStock).';
  }
}

/// Centralized Enterprise Stock & Multi-Branch Inventory Manager
/// Guarantees atomic all-or-nothing stock deductions, restorations, and branch transfers.
class InventoryStockManager {
  InventoryStockManager._();

  /// Adjust stock for multiple items atomically inside an EXISTING Firestore transaction.
  ///
  /// Adheres strictly to the Firestore Transaction rule: ALL reads must precede ALL writes.
  static Future<void> adjustStockBatchInTransaction({
    required Transaction transaction,
    required List<StockAdjustmentItem> items,
    required bool isRestock,
    String branchId = 'main_branch',
    bool strictStockCheck = true,
    FirebaseFirestore? firestore,
  }) async {
    if (items.isEmpty) return;

    final fs = firestore ?? FirebaseService.firestore;
    final effectiveBranchId = branchId.isNotEmpty ? branchId : 'main_branch';

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 1: READ PHASE (Fetch all product documents inside the transaction)
    // ─────────────────────────────────────────────────────────────────────────
    final Map<String, DocumentSnapshot<Map<String, dynamic>>> productSnapshots = {};
    final Set<String> productIds = items
        .map((i) => i.productId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final pId in productIds) {
      final docRef = fs.collection('Products').doc(pId);
      final snap = await transaction.get(docRef);
      if (snap.exists && snap.data() != null) {
        productSnapshots[pId] = snap;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 2: VALIDATION & COMPUTATION PHASE
    // ─────────────────────────────────────────────────────────────────────────
    final Map<String, Map<String, dynamic>> productUpdates = {};

    for (final item in items) {
      final pId = item.productId.trim();
      if (pId.isEmpty) continue;

      final snap = productSnapshots[pId];
      if (snap == null) continue;

      // Use either already computed pending update or initial document data
      final currentData = productUpdates.containsKey(pId)
          ? {...snap.data()!, ...productUpdates[pId]!}
          : Map<String, dynamic>.from(snap.data()!);

      final productTitle = item.title ?? currentData['title']?.toString() ?? 'منتج';
      final currentTotalStock = (currentData['stock'] as num?)?.toInt() ?? 0;

      // 1. Calculate Branch Stock
      final rawBranchStock = currentData['branchStock'] ?? currentData['BranchStock'] ?? {};
      final Map<String, int> updatedBranchStock = {};
      if (rawBranchStock is Map) {
        rawBranchStock.forEach((k, v) {
          if (v is num) updatedBranchStock[k.toString()] = v.toInt();
        });
      }

      final currentBranchQty = updatedBranchStock[effectiveBranchId] ?? currentTotalStock;

      if (!isRestock && strictStockCheck && currentBranchQty < item.quantity) {
        throw InsufficientStockException(
          productId: pId,
          title: productTitle,
          requestedQuantity: item.quantity,
          availableStock: currentBranchQty,
        );
      }

      final newBranchQty = isRestock
          ? (currentBranchQty + item.quantity)
          : (currentBranchQty - item.quantity).clamp(0, 999999).toInt();

      updatedBranchStock[effectiveBranchId] = newBranchQty;

      // 2. Handle Product Variations (if variable)
      final rawVars = currentData['productVariations'] ?? currentData['variations'];
      final List<Map<String, dynamic>> updatedVars = [];
      bool variationUpdated = false;

      if (rawVars is List && rawVars.isNotEmpty) {
        for (final v in rawVars) {
          if (v is! Map) continue;
          final vMap = Map<String, dynamic>.from(v);
          final vId = vMap['id']?.toString().trim();
          final vSku = vMap['sku']?.toString().trim();
          final vAttrs = vMap['attributeValues'] ?? vMap['attributes'] ?? {};

          bool isMatch = false;

          // Match by variationId
          if (item.variationId != null && item.variationId!.isNotEmpty && vId == item.variationId) {
            isMatch = true;
          }
          // Match by variation SKU
          else if (item.sku != null && item.sku!.isNotEmpty && vSku == item.sku) {
            isMatch = true;
          }
          // Match by attributeValues map
          else if (item.selectedAttributes != null && item.selectedAttributes!.isNotEmpty && vAttrs is Map) {
            bool allMatch = true;
            item.selectedAttributes!.forEach((k, val) {
              final vVal = vAttrs[k]?.toString().trim().toLowerCase();
              if (vVal != val.trim().toLowerCase()) {
                allMatch = false;
              }
            });
            if (allMatch) isMatch = true;
          }

          if (isMatch && !variationUpdated) {
            final currentVStock = (vMap['stock'] as num?)?.toInt() ?? 0;

            // Variation Branch Stock
            final vBranchRaw = vMap['branchStock'] ?? vMap['BranchStock'] ?? {};
            final Map<String, int> vBranchStock = {};
            if (vBranchRaw is Map) {
              vBranchRaw.forEach((k, val) {
                if (val is num) vBranchStock[k.toString()] = val.toInt();
              });
            }

            final currVBranchQty = vBranchStock[effectiveBranchId] ?? currentVStock;

            if (!isRestock && strictStockCheck && currVBranchQty < item.quantity) {
              throw InsufficientStockException(
                productId: pId,
                title: '$productTitle (${vMap['title'] ?? item.sku ?? ''})',
                requestedQuantity: item.quantity,
                availableStock: currVBranchQty,
              );
            }

            final newVBranchQty = isRestock
                ? (currVBranchQty + item.quantity)
                : (currVBranchQty - item.quantity).clamp(0, 999999).toInt();

            final newVStock = isRestock
                ? (currentVStock + item.quantity)
                : (currentVStock - item.quantity).clamp(0, 999999).toInt();

            vBranchStock[effectiveBranchId] = newVBranchQty;
            vMap['branchStock'] = vBranchStock;
            vMap['stock'] = newVStock;
            variationUpdated = true;
          }

          updatedVars.add(vMap);
        }
      }

      // 3. Recalculate Total Product Stock
      int newTotalStock;
      if (updatedVars.isNotEmpty && variationUpdated) {
        newTotalStock = updatedVars.fold<int>(
          0,
          (acc, v) => acc + ((v['stock'] as num?)?.toInt() ?? 0),
        );
      } else {
        newTotalStock = isRestock
            ? (currentTotalStock + item.quantity)
            : (currentTotalStock - item.quantity).clamp(0, 999999).toInt();
      }

      final updateMap = <String, dynamic>{
        'stock': newTotalStock,
        'branchStock': updatedBranchStock,
        if (updatedVars.isNotEmpty && variationUpdated) 'productVariations': updatedVars,
      };

      productUpdates[pId] = updateMap;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 3: WRITE PHASE (Apply all atomic updates inside the transaction)
    // ─────────────────────────────────────────────────────────────────────────
    for (final entry in productUpdates.entries) {
      final docRef = fs.collection('Products').doc(entry.key);
      transaction.update(docRef, entry.value);
    }
  }

  /// Run an atomic stock adjustment outside of an existing transaction
  static Future<void> executeAtomicStockAdjustment({
    required List<StockAdjustmentItem> items,
    required bool isRestock,
    String branchId = 'main_branch',
    bool strictStockCheck = true,
    FirebaseFirestore? firestore,
  }) async {
    final fs = firestore ?? FirebaseService.firestore;
    await fs.runTransaction((tx) async {
      await adjustStockBatchInTransaction(
        transaction: tx,
        items: items,
        isRestock: isRestock,
        branchId: branchId,
        strictStockCheck: strictStockCheck,
        firestore: fs,
      );
    });
  }

  /// Atomically transfers stock between two branches without modifying global stock
  static Future<void> transferStockBetweenBranches({
    required String productId,
    required int quantity,
    required String fromBranchId,
    required String toBranchId,
    String? variationId,
    String? sku,
    FirebaseFirestore? firestore,
  }) async {
    if (quantity <= 0 || fromBranchId == toBranchId) return;

    final fs = firestore ?? FirebaseService.firestore;
    final prodRef = fs.collection('Products').doc(productId);

    await fs.runTransaction((tx) async {
      final snap = await tx.get(prodRef);
      if (!snap.exists || snap.data() == null) return;

      final data = snap.data()!;
      final currentTotalStock = (data['stock'] as num?)?.toInt() ?? 0;

      // 1. Branch Stock
      final rawBranch = data['branchStock'] ?? data['BranchStock'] ?? {};
      final Map<String, int> branchStock = {};
      if (rawBranch is Map) {
        rawBranch.forEach((k, v) {
          if (v is num) branchStock[k.toString()] = v.toInt();
        });
      }

      final fromQty = branchStock[fromBranchId] ?? currentTotalStock;
      if (fromQty < quantity) {
        throw InsufficientStockException(
          productId: productId,
          title: data['title']?.toString() ?? 'منتج',
          requestedQuantity: quantity,
          availableStock: fromQty,
        );
      }

      final toQty = branchStock[toBranchId] ?? 0;
      branchStock[fromBranchId] = (fromQty - quantity).clamp(0, 999999);
      branchStock[toBranchId] = toQty + quantity;

      // 2. Variations (if any)
      final rawVars = data['productVariations'];
      final List<Map<String, dynamic>> updatedVars = [];

      if (rawVars is List && rawVars.isNotEmpty) {
        for (final v in rawVars) {
          if (v is! Map) continue;
          final vMap = Map<String, dynamic>.from(v);
          final vId = vMap['id']?.toString().trim();
          final vSku = vMap['sku']?.toString().trim();

          if ((variationId != null && vId == variationId) || (sku != null && vSku == sku)) {
            final vBranchRaw = vMap['branchStock'] ?? {};
            final Map<String, int> vBranchStock = {};
            if (vBranchRaw is Map) {
              vBranchRaw.forEach((k, val) {
                if (val is num) vBranchStock[k.toString()] = val.toInt();
              });
            }
            final vFromQty = vBranchStock[fromBranchId] ?? ((vMap['stock'] as num?)?.toInt() ?? 0);
            final vToQty = vBranchStock[toBranchId] ?? 0;

            vBranchStock[fromBranchId] = (vFromQty - quantity).clamp(0, 999999);
            vBranchStock[toBranchId] = vToQty + quantity;
            vMap['branchStock'] = vBranchStock;
          }
          updatedVars.add(vMap);
        }
      }

      final update = <String, dynamic>{
        'branchStock': branchStock,
        if (updatedVars.isNotEmpty) 'productVariations': updatedVars,
      };

      tx.update(prodRef, update);
    });
  }
}
