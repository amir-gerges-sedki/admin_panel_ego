import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/repositories/employees_repository.dart';
import 'package:admin_panel_ego/features/customers/domain/services/loyalty_service.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/pos_cart_item_model.dart';
import '../../data/models/pos_sale_model.dart';
import '../../data/repositories/pos_repository.dart';
import '../../utils/pos_receipt_printer.dart';
import 'pos_state.dart';

class PosCubit extends Cubit<PosState> {
  final PosRepository _repository;
  final CustomerRepository _customerRepository;
  final EmployeesRepository? _employeesRepository;
  final SettingsRepository? _settingsRepository;
  double _storeDefaultCommissionRate = 2.5;
  StreamSubscription<List<ProductModel>>? _productsSubscription;
  StreamSubscription<List<EmployeeModel>>? _staffSubscription;
  Timer? _customerSearchDebounce;

  final Map<String, int> _pinFailedAttempts = {};
  final Map<String, DateTime> _pinLockoutUntil = {};

  PosCubit({
    PosRepository? repository,
    CustomerRepository? customerRepository,
    this._employeesRepository,
    this._settingsRepository,
  })  : _repository = repository ?? PosRepositoryImpl(),
        _customerRepository = customerRepository ?? CustomerRepositoryImpl(),
        super(const PosState()) {
    init();
  }

  /// Initializes real-time product synchronization and available staff
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

    // 2. Real-time stream subscription for products
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

    // 3. Load and watch active staff members
    loadAvailableStaff();

    // 4. Load store default sales commission rate from settings
    try {
      final sRepo = _settingsRepository ??
          (sl.isRegistered<SettingsRepository>()
              ? sl<SettingsRepository>()
              : SettingsRepositoryImpl());
      final s = await sRepo.getSettings();
      _storeDefaultCommissionRate = s.defaultSalesCommissionRate;
    } catch (_) {}
  }

  /// Loads and subscribes to active staff members
  void loadAvailableStaff() async {
    EmployeesRepository? repo = _employeesRepository;
    if (repo == null) {
      try {
        repo = EmployeesRepositoryImpl();
      } catch (_) {
        return;
      }
    }

    try {
      final staffList = await repo.getEmployees();
      final activeStaff = staffList.where((e) => e.isActive).toList();
      emit(state.copyWith(availableStaff: activeStaff));
    } catch (_) {}

    _staffSubscription?.cancel();
    try {
      _staffSubscription = repo.watchEmployees().listen((staffList) {
        final activeStaff = staffList.where((e) => e.isActive).toList();
        emit(state.copyWith(availableStaff: activeStaff));
      });
    } catch (_) {}
  }

  /// Check if a staff member is currently locked out due to failed attempts
  bool isStaffLockedOut(String staffId) {
    final lockout = _pinLockoutUntil[staffId];
    if (lockout == null) return false;
    if (DateTime.now().isAfter(lockout)) {
      _pinLockoutUntil.remove(staffId);
      _pinFailedAttempts.remove(staffId);
      return false;
    }
    return true;
  }

  /// Remaining seconds of lockout for a staff member
  int remainingLockoutSeconds(String staffId) {
    final lockout = _pinLockoutUntil[staffId];
    if (lockout == null) return 0;
    final diff = lockout.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Fast PIN verification and active salesperson switching
  Future<({bool success, String? error})> switchSalesPersonWithPin({
    required EmployeeModel staff,
    required String pin,
  }) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) {
      return (success: false, error: 'يرجى إدخال كود PIN الخاص بالموظف');
    }

    if (isStaffLockedOut(staff.id)) {
      final secs = remainingLockoutSeconds(staff.id);
      return (
        success: false,
        error: 'تم حظر المحاولات مؤقتاً لتكرار الخطأ. يرجى المحاولة بعد $secs ثانية.'
      );
    }

    final isValid = staff.verifyPin(cleanPin);
    if (isValid) {
      _pinFailedAttempts.remove(staff.id);
      _pinLockoutUntil.remove(staff.id);
      emit(state.copyWith(activeSalesPerson: staff));
      return (success: true, error: null);
    } else {
      final currentAttempts = (_pinFailedAttempts[staff.id] ?? 0) + 1;
      _pinFailedAttempts[staff.id] = currentAttempts;

      if (currentAttempts >= 5) {
        _pinLockoutUntil[staff.id] = DateTime.now().add(const Duration(minutes: 5));
        return (
          success: false,
          error: 'تم إدخال كود PIN غير صحيح 5 مرات! تم إيقاف المحاولات مؤقتاً لمدة 5 دقائق.'
        );
      } else {
        final remaining = 5 - currentAttempts;
        return (
          success: false,
          error: 'كود PIN غير صحيح! المتبقي $remaining محاولات قبل الإيقاف المؤقت.'
        );
      }
    }
  }

  /// Manually clears the active salesperson
  void clearActiveSalesPerson() {
    emit(state.copyWith(clearActiveSalesPerson: true));
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
        saleStatus: PosSaleStatus.initial,
        barcodeFeedbackMessage: 'تمت إضافة: $itemDisplayName',
      ));
    } else {
      if (quantity > maxStock) {
        items.add(newItem.copyWith(quantity: maxStock));
        emit(state.copyWith(
          cartItems: items,
          saleStatus: PosSaleStatus.initial,
          barcodeFeedbackMessage: '⚠️ تم إضافة أقصى كمية متاحة ($maxStock) للصنف "$itemDisplayName".',
        ));
        return;
      }

      items.add(newItem);
      emit(state.copyWith(
        cartItems: items,
        saleStatus: PosSaleStatus.initial,
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

  /// Updates serial numbers (for hardware, devices, warranties)
  void updateItemSerialNumbers(int index, List<String> serialNumbers) {
    if (index < 0 || index >= state.cartItems.length) return;
    final items = List<PosCartItemModel>.from(state.cartItems);
    items[index] = items[index].copyWith(serialNumbers: serialNumbers);
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
      clearMatchedCustomer: true,
      pointsRedeemed: 0,
      pointsDiscount: 0.0,
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

  /// Automatically searches customer by phone with debounce and manages points
  void onCustomerPhoneChanged(String phone) {
    emit(state.copyWith(customerPhone: phone));
    _customerSearchDebounce?.cancel();

    final cleanPhone = phone.trim();
    if (cleanPhone.length < 8) {
      if (state.matchedCustomer != null) {
        emit(state.copyWith(
          clearMatchedCustomer: true,
          pointsRedeemed: 0,
          pointsDiscount: 0.0,
        ));
      }
      return;
    }

    _customerSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      emit(state.copyWith(isSearchingCustomer: true));
      try {
        final customer = await _customerRepository.findCustomerByPhone(cleanPhone);
        if (customer != null) {
          emit(state.copyWith(
            isSearchingCustomer: false,
            matchedCustomer: customer,
            customerName: (state.customerName.isEmpty ||
                    state.customerName == 'Walk-in Customer' ||
                    state.customerName == 'عميل مباشر')
                ? customer.name
                : state.customerName,
          ));
        } else {
          emit(state.copyWith(
            isSearchingCustomer: false,
            clearMatchedCustomer: true,
            pointsRedeemed: 0,
            pointsDiscount: 0.0,
          ));
        }
      } catch (_) {
        emit(state.copyWith(isSearchingCustomer: false));
      }
    });
  }

  /// Attaches or clears the matched customer profile for loyalty
  void setMatchedCustomer(CustomerModel? customer) {
    if (customer == null) {
      emit(state.copyWith(
        clearMatchedCustomer: true,
        pointsRedeemed: 0,
        pointsDiscount: 0.0,
      ));
      return;
    }

    emit(state.copyWith(
      matchedCustomer: customer,
      customerName: customer.name.isNotEmpty && state.customerName.isEmpty
          ? customer.name
          : state.customerName,
      customerPhone: customer.phone.isNotEmpty && state.customerPhone.isEmpty
          ? customer.phone
          : state.customerPhone,
    ));
  }

  /// Toggles or applies loyalty points redemption on the active bill
  void togglePointsRedemption(bool apply) {
    if (!apply || state.matchedCustomer == null) {
      emit(state.copyWith(
        pointsRedeemed: 0,
        pointsDiscount: 0.0,
      ));
      return;
    }

    final custPoints = state.matchedCustomer!.loyaltyPoints;
    final billBalance = (state.subTotal - (state.itemDiscounts + state.cartDiscount)).clamp(0.0, double.infinity);
    final maxRedeem = LoyaltyService.calculateMaxRedeemablePoints(
      customerPoints: custPoints,
      billTotal: billBalance,
    );

    final discount = LoyaltyService.calculateDiscount(maxRedeem);

    emit(state.copyWith(
      pointsRedeemed: maxRedeem,
      pointsDiscount: discount,
    ));
  }

  /// Updates selected payment method
  void setPaymentMethod(String method) {
    emit(state.copyWith(
      paymentMethod: method,
      saleStatus: PosSaleStatus.initial,
      paidAmount: method != 'cash' ? state.grandTotal : (state.paidAmount > 0 ? state.paidAmount : state.grandTotal),
    ));
  }

  /// Resets sale status back to initial state
  void resetSaleStatus() {
    emit(state.copyWith(saleStatus: PosSaleStatus.initial, errorMessage: null));
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
    String? salesPersonId,
    String? salesPersonName,
    double? commissionRate,
    String branchId = 'main_branch',
    String branchName = 'Main Branch',
    String shiftId = '',
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

      final effectiveSalesPersonId = salesPersonId ??
          (state.activeSalesPerson?.id.isNotEmpty == true
              ? state.activeSalesPerson!.id
              : cashierId);

      final effectiveSalesPersonName = salesPersonName ??
          (state.activeSalesPerson?.name.isNotEmpty == true
              ? state.activeSalesPerson!.name
              : cashierName);

      final effectiveCommissionRate = commissionRate ??
          ((state.activeSalesPerson != null && state.activeSalesPerson!.commissionRate > 0)
              ? state.activeSalesPerson!.commissionRate
              : _storeDefaultCommissionRate);

      final sale = PosSaleModel(
        id: '',
        orderNumber: 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
        cashierName: cashierName,
        cashierId: cashierId,
        salesPersonId: effectiveSalesPersonId,
        salesPersonName: effectiveSalesPersonName,
        commissionRate: effectiveCommissionRate,
        branchId: branchId,
        branchName: branchName,
        shiftId: shiftId,
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
        pointsEarned: state.pointsEarned,
        pointsRedeemed: state.pointsRedeemed,
        pointsDiscount: state.pointsDiscount,
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
        clearMatchedCustomer: true,
        pointsRedeemed: 0,
        pointsDiscount: 0.0,
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
    _staffSubscription?.cancel();
    _customerSearchDebounce?.cancel();
    return super.close();
  }
}
