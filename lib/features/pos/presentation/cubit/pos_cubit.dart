import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/pos_cart_item_model.dart';
import '../../data/models/pos_sale_model.dart';
import '../../data/repositories/pos_repository.dart';
import '../../utils/pos_receipt_printer.dart';
import 'pos_state.dart';

class PosCubit extends Cubit<PosState> {
  final PosRepository _repository;
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  PosCubit({PosRepository? repository})
      : _repository = repository ?? PosRepositoryImpl(),
        super(const PosState()) {
    init();
  }

  /// Initializes real-time product synchronization from repository
  Future<void> init() async {
    // 1. Immediate fetch from repository to populate catalog instantly
    try {
      final initialProducts = await _repository.getProducts();
      if (initialProducts.isNotEmpty) {
        final filtered = _applyFilters(initialProducts, state.searchQuery, state.selectedCategory);
        emit(state.copyWith(
          allProducts: initialProducts,
          filteredProducts: filtered,
        ));
      }
    } catch (_) {}

    // 2. Real-time stream subscription
    _productsSubscription?.cancel();
    _productsSubscription = _repository.getProductsStream().listen(
      (products) {
        final filtered = _applyFilters(products, state.searchQuery, state.selectedCategory);
        emit(state.copyWith(
          allProducts: products,
          filteredProducts: filtered,
        ));
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );
  }

  /// Filters product catalog by keyword and category
  void filterProducts({
    String? query,
    ProductCategoryType? category,
    bool clearCategory = false,
  }) {
    final effectiveQuery = query ?? state.searchQuery;
    final effectiveCategory = clearCategory ? null : (category ?? state.selectedCategory);

    final filtered = _applyFilters(state.allProducts, effectiveQuery, effectiveCategory);
    emit(state.copyWith(
      searchQuery: effectiveQuery,
      selectedCategory: effectiveCategory,
      clearCategory: clearCategory,
      filteredProducts: filtered,
    ));
  }

  List<ProductModel> _applyFilters(
    List<ProductModel> products,
    String query,
    ProductCategoryType? category,
  ) {
    var list = products;
    if (category != null) {
      list = list.where((p) => p.categoryType == category).toList();
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final queryWords = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      list = list.where((p) {
        final searchableParts = <String>[
          p.title.toLowerCase(),
          p.brand.name.toLowerCase(),
          p.id.toLowerCase(),
          p.description.toLowerCase(),
          ...p.flavors.map((f) => f.toLowerCase()),
          ...p.productVariations.map((v) => v.sku.toLowerCase()),
          ...p.productVariations.map((v) => v.id.toLowerCase()),
          ...p.productVariations.expand((v) => v.attributeValues.entries.map((e) => '${e.key}:${e.value}'.toLowerCase())),
          ...p.productVariations.expand((v) => v.attributeValues.values.map((val) => val.toString().toLowerCase())),
        ];

        final combinedSearchText = searchableParts.join(' ');
        return queryWords.every((word) => combinedSearchText.contains(word));
      }).toList();
    }

    return list;
  }

  /// Handles hardware barcode scanner input (or quick-code scan)
  /// Returns the matched product if variation selection dialog is required, otherwise null.
  ProductModel? handleBarcodeScanned(String rawBarcode, {bool showErrorIfNotFound = true}) {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return null;

    // 1. Try finding an exact match on Variation SKU
    for (final product in state.allProducts) {
      for (final variation in product.productVariations) {
        if (variation.sku.trim().toLowerCase() == barcode.toLowerCase()) {
          if (variation.stock <= 0) {
            emit(state.copyWith(
              barcodeFeedbackMessage: '⚠️ الصنف "${product.title} (${variation.sku})" نفذ من المخزون (المتاح: 0)!',
            ));
            return null;
          }
          addToCart(product, variation: variation);
          _triggerScanHaptic();
          return null;
        }
      }
    }

    // 2. Try finding exact match on Product ID or barcode spec
    for (final product in state.allProducts) {
      final barcodeSpec = product.specifications['barcode']?.toString().trim().toLowerCase();
      if (product.id.trim().toLowerCase() == barcode.toLowerCase() ||
          (barcodeSpec != null && barcodeSpec == barcode.toLowerCase())) {
        if (product.isVariable && product.productVariations.length > 1) {
          // Requires variation popup selection
          return product;
        } else {
          final firstVar = product.productVariations.isNotEmpty ? product.productVariations.first : null;
          final availableStock = firstVar != null ? firstVar.stock : product.stock;
          if (availableStock <= 0) {
            emit(state.copyWith(
              barcodeFeedbackMessage: '⚠️ الصنف "${product.title}" نفذ من المخزون (المتاح: 0)!',
            ));
            return null;
          }
          addToCart(product, variation: firstVar);
          _triggerScanHaptic();
          return null;
        }
      }
    }

    // 3. Try finding by matching title prefix or full title
    final matching = state.allProducts.where((p) => p.title.toLowerCase().trim() == barcode.toLowerCase()).toList();
    if (matching.isNotEmpty) {
      final p = matching.first;
      if (p.isVariable && p.productVariations.length > 1) {
        return p;
      }
      final firstVar = p.productVariations.isNotEmpty ? p.productVariations.first : null;
      final availableStock = firstVar != null ? firstVar.stock : p.stock;
      if (availableStock <= 0) {
        emit(state.copyWith(
          barcodeFeedbackMessage: '⚠️ الصنف "${p.title}" نفذ من المخزون (المتاح: 0)!',
        ));
        return null;
      }
      addToCart(p, variation: firstVar);
      _triggerScanHaptic();
      return null;
    }

    // Not found
    if (showErrorIfNotFound) {
      emit(state.copyWith(
        barcodeFeedbackMessage: '⚠️ لم يتم العثور على صنف بالباركود: $barcode',
      ));
    }
    return null;
  }

  void _triggerScanHaptic() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Adds a product to the register cart with automatic stacking of identical variations
  /// and strict stock limits enforcement.
  void addToCart(
    ProductModel product, {
    ProductVariationModel? variation,
    int quantity = 1,
  }) {
    final maxStock = variation != null ? variation.stock : product.stock;
    final itemDisplayName = variation != null && variation.sku.isNotEmpty
        ? '${product.title} (${variation.sku})'
        : product.title;

    if (maxStock <= 0) {
      emit(state.copyWith(
        barcodeFeedbackMessage: '⚠️ المنتج "$itemDisplayName" نفذ من المخزون بالكامل (المتاح: 0)!',
      ));
      return;
    }

    final newItem = PosCartItemModel.fromProduct(product, variation: variation, quantity: quantity);
    final items = List<PosCartItemModel>.from(state.cartItems);

    final existingIndex = items.indexWhere((item) {
      if (item.productId != newItem.productId) return false;
      if (newItem.variationId != null && newItem.variationId!.isNotEmpty) {
        return item.variationId == newItem.variationId;
      }
      return mapEquals(item.selectedVariation, newItem.selectedVariation);
    });

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      final currentQty = existing.quantity;

      if (currentQty >= maxStock) {
        emit(state.copyWith(
          barcodeFeedbackMessage: '⚠️ لا يمكن إضافة المزيد! الكمية المتاحة في المخزون من "$itemDisplayName" هي $maxStock فقط.',
        ));
        return;
      }

      if (currentQty + quantity > maxStock) {
        items[existingIndex] = existing.copyWith(quantity: maxStock);
        emit(state.copyWith(
          cartItems: items,
          barcodeFeedbackMessage: '⚠️ تم الوصول لأقصى كمية متاحة في المخزون ($maxStock) للصنف "$itemDisplayName".',
        ));
        return;
      }

      final newQty = currentQty + quantity;
      items[existingIndex] = existing.copyWith(quantity: newQty);
      emit(state.copyWith(
        cartItems: items,
        barcodeFeedbackMessage: 'تمت إضافة: $itemDisplayName',
      ));
    } else {
      if (quantity > maxStock) {
        items.add(newItem.copyWith(quantity: maxStock));
        emit(state.copyWith(
          cartItems: items,
          barcodeFeedbackMessage: '⚠️ تم إضافة أقصى كمية متاحة ($maxStock) للصنف "$itemDisplayName".',
        ));
        return;
      }

      items.add(newItem);
      emit(state.copyWith(
        cartItems: items,
        barcodeFeedbackMessage: 'تمت إضافة: $itemDisplayName',
      ));
    }
  }

  /// Updates quantity of an item at a specific cart index with stock limit enforcement
  void updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= state.cartItems.length) return;
    final items = List<PosCartItemModel>.from(state.cartItems);
    final item = items[index];

    if (newQuantity <= 0) {
      items.removeAt(index);
      emit(state.copyWith(cartItems: items));
      return;
    }

    if (newQuantity > item.availableStock) {
      items[index] = item.copyWith(quantity: item.availableStock);
      emit(state.copyWith(
        cartItems: items,
        barcodeFeedbackMessage: '⚠️ لا يمكن زيادة الكمية! الكمية المتاحة في المخزون من "${item.fullTitle}" هي ${item.availableStock} فقط.',
      ));
      return;
    }

    items[index] = item.copyWith(quantity: newQuantity);
    emit(state.copyWith(cartItems: items));
  }

  /// Updates per-item unit discount
  void updateItemDiscount(int index, double discount) {
    if (index < 0 || index >= state.cartItems.length) return;
    final items = List<PosCartItemModel>.from(state.cartItems);
    items[index] = items[index].copyWith(discount: discount.clamp(0.0, items[index].unitPrice));
    emit(state.copyWith(cartItems: items));
  }

  /// Removes an item from the cart
  void removeItem(int index) {
    if (index < 0 || index >= state.cartItems.length) return;
    final items = List<PosCartItemModel>.from(state.cartItems);
    items.removeAt(index);
    emit(state.copyWith(cartItems: items));
  }

  /// Clears the active cart and resets customer info
  void clearCart() {
    emit(state.copyWith(
      cartItems: const [],
      cartDiscount: 0.0,
      customerName: '',
      customerPhone: '',
      orderNotes: '',
      paidAmount: 0.0,
      saleStatus: PosSaleStatus.initial,
      clearFeedback: true,
    ));
  }

  /// Sets overall bill-level discount in EGP
  void setCartDiscount(double discount) {
    emit(state.copyWith(cartDiscount: discount.clamp(0.0, state.subTotal)));
  }

  /// Updates customer metadata for receipt
  void setCustomerInfo({String? name, String? phone, String? notes}) {
    emit(state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
      orderNotes: notes ?? state.orderNotes,
    ));
  }

  /// Updates selected payment method
  void setPaymentMethod(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  /// Updates paid cash amount
  void setPaidAmount(double amount) {
    emit(state.copyWith(paidAmount: amount));
  }

  /// Clears transient barcode feedback message
  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  /// Submits and completes the POS in-store sale
  Future<bool> completeSale({
    String cashierName = 'Store Staff',
    String cashierId = '',
    bool autoPrint = true,
  }) async {
    if (state.cartItems.isEmpty) {
      emit(state.copyWith(errorMessage: 'السلة فارغة! يرجى إضافة أصناف أولاً.'));
      return false;
    }

    emit(state.copyWith(saleStatus: PosSaleStatus.loading));

    try {
      final double finalPaidAmount = state.paymentMethod == 'cash'
          ? (state.paidAmount > 0 ? state.paidAmount : state.grandTotal)
          : state.grandTotal;

      final sale = PosSaleModel(
        id: '',
        orderNumber: 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
        cashierName: cashierName,
        cashierId: cashierId,
        customerName: state.customerName.trim().isNotEmpty
            ? state.customerName.trim()
            : 'Walk-in Customer (عميل مباشر)',
        customerPhone: state.customerPhone.trim(),
        items: state.cartItems,
        subTotal: state.subTotal,
        discount: state.totalDiscount,
        taxFee: 0.0,
        totalAmount: state.grandTotal,
        paidAmount: finalPaidAmount,
        changeAmount: (finalPaidAmount - state.grandTotal).clamp(0.0, double.infinity),
        paymentMethod: state.paymentMethod,
        notes: state.orderNotes,
        status: 'completed',
      );

      final completed = await _repository.submitPosSale(sale);

      if (autoPrint) {
        PosReceiptPrinter.printThermalReceipt(completed);
      }

      emit(state.copyWith(
        saleStatus: PosSaleStatus.success,
        lastCompletedSale: completed,
        cartItems: const [],
        cartDiscount: 0.0,
        customerName: '',
        customerPhone: '',
        orderNotes: '',
        paidAmount: 0.0,
        barcodeFeedbackMessage: '✅ تم إتمام الفاتورة #${completed.orderNumber} بنجاح!',
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        saleStatus: PosSaleStatus.failure,
        errorMessage: 'فشل في إتمام عملية البيع: $e',
      ));
      return false;
    }
  }

  bool mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
