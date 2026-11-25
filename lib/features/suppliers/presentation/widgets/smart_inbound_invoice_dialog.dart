import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import 'supplier_form_dialog.dart';

/// Unified Smart Inbound Purchase & Branch Distribution Hub
/// Allows Super Admin to register supplier purchases, track unit costs,
/// and allocate inventory directly across all branches/warehouses in a single seamless flow.
class SmartInboundInvoiceDialog extends StatefulWidget {
  final String? initialSupplierId;
  final String? initialProductId;

  const SmartInboundInvoiceDialog({
    super.key,
    this.initialSupplierId,
    this.initialProductId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialSupplierId,
    String? initialProductId,
  }) {
    final supplierCubit = context.read<SupplierCubit>();
    final productCubit = context.read<ProductCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: supplierCubit),
          BlocProvider.value(value: productCubit),
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: dashboardCubit),
        ],
        child: SmartInboundInvoiceDialog(
          initialSupplierId: initialSupplierId,
          initialProductId: initialProductId,
        ),
      ),
    );
  }

  @override
  State<SmartInboundInvoiceDialog> createState() => _SmartInboundInvoiceDialogState();
}

class _SmartInboundInvoiceDialogState extends State<SmartInboundInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();

  SupplierModel? _selectedSupplier;
  late TextEditingController _invoiceNumberController;
  final DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'Cash';
  final bool _stockReceived = true;

  // Financial fields
  final TextEditingController _paidAmountController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _shippingController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  // Inbound items
  final List<PurchaseInvoiceItemModel> _items = [];

  // Line item picker
  ProductModel? _selectedProduct;
  ProductVariationModel? _selectedVariation;
  final TextEditingController _itemQtyController = TextEditingController(text: '1');
  final TextEditingController _itemCostController = TextEditingController(text: '0');
  final TextEditingController _searchProductController = TextEditingController();

  // Branch allocation controllers per item key and branch ID: Map<"${productId}_${sku}", Map<branchId, TextEditingController>>
  final Map<String, Map<String, TextEditingController>> _allocationControllers = {};

  // Track expanded product IDs for variations dropdown list in distribution matrix
  final Set<String> _expandedProductIds = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
    );

    // Initial product match directly in initState if already loaded
    if (widget.initialProductId != null) {
      final prodState = context.read<ProductCubit>().state;
      if (prodState is ProductLoaded) {
        final p = prodState.products
            .where((prod) => prod.id == widget.initialProductId)
            .firstOrNull;
        if (p != null) {
          _selectedProduct = p;
          _selectedVariation = null;
          if (p.costPrice > 0) {
            _itemCostController.text = p.costPrice.toStringAsFixed(0);
          }
          final currentStock = p.stock;
          _itemQtyController.text = currentStock > 0 ? currentStock.toString() : '1';
        }
      }
    }

    // Initial supplier match & fallback product match
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supState = context.read<SupplierCubit>().state;
      if (supState is SupplierLoaded && supState.suppliers.isNotEmpty) {
        if (widget.initialSupplierId != null) {
          final matched = supState.suppliers
              .where((s) => s.id == widget.initialSupplierId)
              .firstOrNull;
          if (matched != null) {
            setState(() => _selectedSupplier = matched);
          }
        } else {
          setState(() => _selectedSupplier = supState.suppliers.first);
        }
      }

      // Fallback initial product match if not caught in initState
      if (_selectedProduct == null && widget.initialProductId != null) {
        final prodState = context.read<ProductCubit>().state;
        if (prodState is ProductLoaded) {
          final p = prodState.products
              .where((prod) => prod.id == widget.initialProductId)
              .firstOrNull;
          if (p != null) {
            _onSelectProduct(p);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _paidAmountController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    _itemQtyController.dispose();
    _itemCostController.dispose();
    _searchProductController.dispose();
    for (final innerMap in _allocationControllers.values) {
      for (final ctrl in innerMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  String _getItemKey(String productId, String? variationSku) {
    return '${productId}_${variationSku ?? "default"}';
  }

  int get _currentSelectedStock {
    if (_selectedProduct == null) return 0;
    if (_selectedVariation != null) {
      return _selectedVariation!.stock;
    }
    return _selectedProduct!.stock;
  }

  int _getBranchStock(String productId, String? sku, String branchId) {
    final prodState = context.read<ProductCubit>().state;
    if (prodState is ProductLoaded) {
      final p = prodState.products.where((item) => item.id == productId).firstOrNull;
      if (p != null) {
        if (sku != null && p.productVariations.isNotEmpty) {
          final v = p.productVariations.where((v) => v.sku == sku).firstOrNull;
          return v?.getStockForBranch(branchId) ?? 0;
        }
        return p.getStockForBranch(branchId);
      }
    }
    return 0;
  }

  void _onSelectProduct(ProductModel p) {
    setState(() {
      _selectedProduct = p;
      // Default to ALL variations combined (null variation)
      _selectedVariation = null;
      _itemCostController.text = p.costPrice > 0 ? p.costPrice.toStringAsFixed(0) : '0';
      final currentStock = p.stock;
      _itemQtyController.text = currentStock > 0 ? currentStock.toString() : '1';
    });
  }

  List<StoreBranchModel> _getAvailableBranches(BuildContext context) {
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded && settingsState.settings.branches.isNotEmpty) {
      return settingsState.settings.branches;
    }
    return const [
      StoreBranchModel(
        id: 'main_branch',
        name: 'المخزن الرئيسي / الفرع الرئيسي',
        isPrimary: true,
        isWarehouse: true,
      ),
    ];
  }

  void _addItemToInvoice(List<StoreBranchModel> branches) {
    if (_selectedProduct == null) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'يرجى اختيار الصنف أولاً.',
      );
      return;
    }

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    final cost = double.tryParse(_itemCostController.text.trim()) ?? 0.0;

    if (qty <= 0) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'يرجى إدخال كمية صحيحة أكبر من صفر.',
      );
      return;
    }

    final primaryBranch = branches.firstWhere((b) => b.isPrimary || b.isWarehouse, orElse: () => branches.first);

    // CASE 1: Variable Product with "All Variations Combined" selected (_selectedVariation == null)
    if (_selectedProduct!.productVariations.isNotEmpty && _selectedVariation == null) {
      final vars = _selectedProduct!.productVariations;
      final varCount = vars.length;

      // Check if variations already have stock in the system that sums to qty
      final existingStocks = <String, int>{for (final v in vars) v.sku: v.stock};
      final sumExisting = existingStocks.values.fold<int>(0, (s, q) => s + q);
      final useExistingStock = (sumExisting == qty && sumExisting > 0);

      final share = qty ~/ varCount;
      final remainder = qty % varCount;

      setState(() {
        for (int i = 0; i < varCount; i++) {
          final v = vars[i];
          final varQty = useExistingStock
              ? (existingStocks[v.sku] ?? 0)
              : (share + (i == 0 ? remainder : 0));

          if (varQty <= 0) continue;

          final initialAllocations = <String, int>{};
          if (v.branchStock.isNotEmpty) {
            for (final b in branches) {
              initialAllocations[b.id] = v.branchStock[b.id] ?? 0;
            }
            final sumAlloc = initialAllocations.values.fold<int>(0, (acc, val) => acc + val);
            if (sumAlloc != varQty) {
              for (final b in branches) {
                initialAllocations[b.id] = (b.id == primaryBranch.id ? varQty : 0);
              }
            }
          } else {
            for (final b in branches) {
              initialAllocations[b.id] = (b.id == primaryBranch.id ? varQty : 0);
            }
          }

          final itemKey = _getItemKey(_selectedProduct!.id, v.sku);
          final branchControllers = <String, TextEditingController>{};
          for (final b in branches) {
            branchControllers[b.id] = TextEditingController(
              text: (initialAllocations[b.id] ?? 0).toString(),
            );
          }
          _allocationControllers[itemKey] = branchControllers;

          final existingIndex = _items.indexWhere(
            (it) => it.productId == _selectedProduct!.id && it.variationSku == v.sku,
          );

          final newItem = PurchaseInvoiceItemModel(
            productId: _selectedProduct!.id,
            productTitle: _selectedProduct!.displayTitle,
            variationSku: v.sku,
            variationAttributes: v.attributeValues,
            quantity: varQty,
            unitCost: cost,
            subtotal: varQty * cost,
            branchAllocations: initialAllocations,
          );

          if (existingIndex != -1) {
            _items[existingIndex] = newItem;
          } else {
            _items.add(newItem);
          }
        }

        _syncFinancials();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة $qty قطعة وتوزيعها على ${vars.length} متغيرات بنجاح.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sku = _selectedVariation?.sku;
    final itemKey = _getItemKey(_selectedProduct!.id, sku);

    // Initial allocation: Check if product already has branch stock in the system
    final existingBranchStock = _selectedVariation != null
        ? _selectedVariation!.branchStock
        : _selectedProduct!.branchStock;

    final initialAllocations = <String, int>{};
    if (existingBranchStock.isNotEmpty) {
      for (final b in branches) {
        initialAllocations[b.id] = existingBranchStock[b.id] ?? 0;
      }
      final sumAllocated = initialAllocations.values.fold<int>(0, (acc, v) => acc + v);
      if (sumAllocated != qty) {
        for (final b in branches) {
          initialAllocations[b.id] = (b.id == primaryBranch.id ? qty : 0);
        }
      }
    } else {
      for (final b in branches) {
        initialAllocations[b.id] = (b.id == primaryBranch.id ? qty : 0);
      }
    }

    // Initialize text controllers for allocations
    final branchControllers = <String, TextEditingController>{};
    for (final b in branches) {
      branchControllers[b.id] = TextEditingController(
        text: (initialAllocations[b.id] ?? 0).toString(),
      );
    }
    _allocationControllers[itemKey] = branchControllers;

    final existingIndex = _items.indexWhere(
      (it) => it.productId == _selectedProduct!.id && it.variationSku == sku,
    );

    setState(() {
      final newItem = PurchaseInvoiceItemModel(
        productId: _selectedProduct!.id,
        productTitle: _selectedProduct!.displayTitle,
        variationSku: sku,
        variationAttributes: _selectedVariation?.attributeValues ?? {},
        quantity: qty,
        unitCost: cost,
        subtotal: qty * cost,
        branchAllocations: initialAllocations,
      );

      if (existingIndex != -1) {
        _items[existingIndex] = newItem;
      } else {
        _items.add(newItem);
      }

      // Automatically sync paid amount if Cash
      _syncFinancials();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة الصنف وتخصيص كميته للمخزن.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItem(int index) {
    final it = _items[index];
    final itemKey = _getItemKey(it.productId, it.variationSku);
    _allocationControllers[itemKey]?.forEach((_, ctrl) => ctrl.dispose());
    _allocationControllers.remove(itemKey);

    setState(() {
      _items.removeAt(index);
      _syncFinancials();
    });
  }

  void _removeProduct(String productId) {
    final toRemove = _items.where((it) => it.productId == productId).toList();
    for (final it in toRemove) {
      final itemKey = _getItemKey(it.productId, it.variationSku);
      _allocationControllers[itemKey]?.forEach((_, ctrl) => ctrl.dispose());
      _allocationControllers.remove(itemKey);
    }
    setState(() {
      _items.removeWhere((it) => it.productId == productId);
      _expandedProductIds.remove(productId);
      _syncFinancials();
    });
  }

  void _distributeProductEvenly(String productId, List<StoreBranchModel> branches) {
    if (branches.isEmpty) return;
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        if (it.productId != productId) continue;
        final totalQty = it.quantity;
        final share = totalQty ~/ branches.length;
        final remainder = totalQty % branches.length;

        final updatedAllocations = <String, int>{};
        final itemKey = _getItemKey(it.productId, it.variationSku);
        final controllers = _allocationControllers[itemKey];

        for (int bIdx = 0; bIdx < branches.length; bIdx++) {
          final b = branches[bIdx];
          final qty = bIdx == 0 ? (share + remainder) : share;
          updatedAllocations[b.id] = qty;
          controllers?[b.id]?.text = qty.toString();
        }

        _items[i] = it.copyWith(branchAllocations: updatedAllocations);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تقسيم الصنف بالتساوي على جميع الفروع.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _distributeProductToMainWarehouse(String productId, List<StoreBranchModel> branches) {
    if (branches.isEmpty) return;
    final primaryBranch = branches.firstWhere((b) => b.isPrimary || b.isWarehouse, orElse: () => branches.first);

    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        if (it.productId != productId) continue;
        final updatedAllocations = <String, int>{
          for (final b in branches) b.id: (b.id == primaryBranch.id ? it.quantity : 0),
        };
        final itemKey = _getItemKey(it.productId, it.variationSku);
        final controllers = _allocationControllers[itemKey];
        for (final b in branches) {
          controllers?[b.id]?.text = (updatedAllocations[b.id] ?? 0).toString();
        }
        _items[i] = it.copyWith(branchAllocations: updatedAllocations);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم توجيه الصنف إلى ${primaryBranch.name}.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateBranchAllocation({
    required int itemIndex,
    required String branchId,
    required int quantity,
  }) {
    final it = _items[itemIndex];
    final updatedAllocations = Map<String, int>.from(it.branchAllocations);
    updatedAllocations[branchId] = quantity.clamp(0, 999999);

    setState(() {
      _items[itemIndex] = it.copyWith(branchAllocations: updatedAllocations);
    });
  }

  void _distributeEvenly(int itemIndex, List<StoreBranchModel> branches) {
    if (branches.isEmpty) return;
    final it = _items[itemIndex];
    final totalQty = it.quantity;
    final share = totalQty ~/ branches.length;
    final remainder = totalQty % branches.length;

    final updatedAllocations = <String, int>{};
    final itemKey = _getItemKey(it.productId, it.variationSku);
    final controllers = _allocationControllers[itemKey];

    for (int i = 0; i < branches.length; i++) {
      final b = branches[i];
      final qty = i == 0 ? (share + remainder) : share;
      updatedAllocations[b.id] = qty;
      controllers?[b.id]?.text = qty.toString();
    }

    setState(() {
      _items[itemIndex] = it.copyWith(branchAllocations: updatedAllocations);
    });
  }

  void _distributeAllEvenly(List<StoreBranchModel> branches) {
    if (branches.isEmpty || _items.isEmpty) return;
    setState(() {
      for (int itemIndex = 0; itemIndex < _items.length; itemIndex++) {
        final it = _items[itemIndex];
        final totalQty = it.quantity;
        final share = totalQty ~/ branches.length;
        final remainder = totalQty % branches.length;

        final updatedAllocations = <String, int>{};
        final itemKey = _getItemKey(it.productId, it.variationSku);
        final controllers = _allocationControllers[itemKey];

        for (int i = 0; i < branches.length; i++) {
          final b = branches[i];
          final qty = i == 0 ? (share + remainder) : share;
          updatedAllocations[b.id] = qty;
          controllers?[b.id]?.text = qty.toString();
        }

        _items[itemIndex] = it.copyWith(branchAllocations: updatedAllocations);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تقسيم جميع المتغيرات والأصناف بالتساوي على كافة الفروع.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _distributeAllToMainWarehouse(List<StoreBranchModel> branches) {
    if (branches.isEmpty || _items.isEmpty) return;
    final primaryBranch = branches.firstWhere((b) => b.isPrimary || b.isWarehouse, orElse: () => branches.first);

    setState(() {
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        final updatedAllocations = <String, int>{
          for (final b in branches) b.id: (b.id == primaryBranch.id ? it.quantity : 0),
        };
        final itemKey = _getItemKey(it.productId, it.variationSku);
        final controllers = _allocationControllers[itemKey];
        for (final b in branches) {
          controllers?[b.id]?.text = (updatedAllocations[b.id] ?? 0).toString();
        }
        _items[i] = it.copyWith(branchAllocations: updatedAllocations);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم توجيه جميع الأصناف إلى ${primaryBranch.name}.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double get _subtotal => _items.fold<double>(0.0, (acc, item) => acc + item.subtotal);
  double get _discountAmount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _taxAmount => double.tryParse(_taxController.text.trim()) ?? 0.0;
  double get _shippingCost => double.tryParse(_shippingController.text.trim()) ?? 0.0;
  double get _totalAmount => (_subtotal - _discountAmount + _taxAmount + _shippingCost).clamp(0.0, double.infinity);
  double get _paidAmount => double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  double get _remainingAmount => (_totalAmount - _paidAmount).clamp(0.0, double.infinity);

  void _syncFinancials() {
    if (_paymentMethod == 'Cash') {
      _paidAmountController.text = _totalAmount.toStringAsFixed(0);
    }
  }

  Future<void> _submitInvoice(List<StoreBranchModel> branches) async {
    if (_selectedSupplier == null) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'يرجى اختيار التاجر / المورد أولاً.',
      );
      return;
    }

    if (_items.isEmpty) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'يرجى إضافة صنف واحد على الأقل في الفاتورة.',
      );
      return;
    }

    // Check branch allocations: for every item, sum of allocations must equal item.quantity
    for (final it in _items) {
      final allocatedSum = it.branchAllocations.values.fold<int>(0, (s, q) => s + q);
      if (allocatedSum != it.quantity) {
        HelperFun.errorSnackbar(
          title: 'خطأ في توزيع الكمية',
          message: 'الصنف "${it.productTitle}" إجمالي كميته ${it.quantity} لكن تم توزيع $allocatedSum فقط. يرجى مطابقة الكمية.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final primaryBranch = branches.firstWhere((b) => b.isPrimary || b.isWarehouse, orElse: () => branches.first);

      final invoice = PurchaseInvoiceModel(
        id: '',
        invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty
            ? _invoiceNumberController.text.trim()
            : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        targetBranchId: primaryBranch.id,
        targetBranchName: primaryBranch.name,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: _items,
        subtotal: _subtotal,
        taxAmount: _taxAmount,
        discountAmount: _discountAmount,
        shippingCost: _shippingCost,
        totalAmount: _totalAmount,
        paidAmount: _paidAmount,
        remainingAmount: _remainingAmount,
        paymentStatus: _paidAmount >= _totalAmount && _totalAmount > 0
            ? InvoicePaymentStatus.paid
            : (_paidAmount > 0 ? InvoicePaymentStatus.partial : InvoicePaymentStatus.unpaid),
        paymentMethod: _paymentMethod,
        stockReceived: _stockReceived,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final supplierCubit = context.read<SupplierCubit>();
      final productCubit = context.read<ProductCubit>();
      final dashboardCubit = context.read<DashboardCubit>();

      await supplierCubit.createPurchaseInvoice(
        invoice,
        autoUpdateStock: _stockReceived,
      );

      if (_stockReceived) {
        await productCubit.loadProducts();
        await dashboardCubit.loadDashboard();
      }

      if (mounted) {
        Navigator.pop(context);
        HelperFun.successSnackbar(
          'تم استلام وتوزيع البضاعة بنجاح',
          'تم حفظ فاتورة التوريد وتوزيع الكميات فوراً على أرصدة الفروع وتحديث متوسط التكلفة.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.errorSnackbar(
          title: 'error'.tr,
          message: 'فشلت عملية حفظ التوريد: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final branches = _getAvailableBranches(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 860),
        child: Column(
          children: [
            // ── Top Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131318) : const Color(0xFFF0FDF4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBBF7D0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.input_rounded, color: Color(0xFF0D9488), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'استلام وتوزيع بضاعة من مورد (فاتورة مشتريات)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'سجل تفاصيل التاجر وتكلفة الشراء، ووزّع الكميات بضغطة زر على المخزن والفروع مباشرة.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Supplier & Invoice Header Card
                      _buildSupplierSection(isDark),
                      const SizedBox(height: 18),

                      // 2. Line Item Input & Cost Entry
                      _buildItemInputSection(isDark, branches),
                      const SizedBox(height: 18),

                      // 3. Line Items & Branch Distribution Matrix
                      _buildDistributionMatrixSection(isDark, branches),
                      const SizedBox(height: 18),

                      // 4. Financial Calculations & Summary
                      _buildFinancialSummarySection(isDark),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer Actions ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131318) : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إجمالي الفاتورة: ${AppFormatters.formatEGP(_totalAmount)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                      ),
                      Text(
                        'الأصناف المضافة: ${_items.length} صنف (${_items.fold<int>(0, (s, i) => s + i.quantity)} قطعة)',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitInvoice(branches),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'جاري الحفظ والترحيل...' : 'اعتماد وترحيل الفاتورة والمخزون',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Supplier & Invoice Header ──
  Widget _buildSupplierSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              const Text('بيانات المورد / التاجر والفاتورة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  SupplierFormDialog.show(context);
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF0D9488)),
                label: const Text('مورد جديد', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Dropdown
              Expanded(
                flex: 4,
                child: BlocBuilder<SupplierCubit, SupplierState>(
                  builder: (context, supState) {
                    final suppliers = supState is SupplierLoaded
                        ? supState.suppliers.where((s) => s.isActive).toList()
                        : <SupplierModel>[];

                    return DropdownButtonFormField<SupplierModel>(
                      initialValue: suppliers.where((s) => s.id == _selectedSupplier?.id).firstOrNull,
                      decoration: InputDecoration(
                        labelText: 'التاجر / المورد *',
                        labelStyle: const TextStyle(fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('${s.name} (${s.phone.isNotEmpty ? s.phone : "بدون هاتف"})', style: const TextStyle(fontSize: 12.5)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedSupplier = val);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Invoice Number
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _invoiceNumberController,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'رقم فاتورة التاجر *',
                    labelStyle: const TextStyle(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Payment Method
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'طريقة السداد',
                    labelStyle: const TextStyle(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('نقداً (كاش)', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('تحويل بنكي / إنستاباي', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Credit', child: Text('آجل (مديونية للمورد)', style: TextStyle(fontSize: 12.5))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMethod = val;
                        if (val == 'Credit') {
                          _paidAmountController.text = '0';
                        } else {
                          _syncFinancials();
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Line Item Picker & Cost Entry ──
  Widget _buildItemInputSection(bool isDark, List<StoreBranchModel> branches) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_shopping_cart_rounded, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              const Text('إضافة أصناف إلى الفاتورة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _distributeAllToMainWarehouse(branches),
                  icon: const Icon(Icons.warehouse_rounded, size: 15, color: Color(0xFF06B6D4)),
                  label: const Text('توجيه الكل للمخزن الرئيسي', style: TextStyle(fontSize: 11.5, color: Color(0xFF06B6D4), fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── System Stock Indicator Badge ──
          if (_selectedProduct != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Text(
                    'الرصيد الفعلي المسجل بالسيستم لهذا الصنف: ',
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_currentSelectedStock قطعة',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  if ((_selectedVariation?.costPrice ?? _selectedProduct!.costPrice) > 0) ...[
                    const SizedBox(width: 14),
                    Text(
                      'سعر التكلفة: ${AppFormatters.formatEGP(_selectedVariation?.costPrice ?? _selectedProduct!.costPrice)}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _itemQtyController.text = _currentSelectedStock > 0 ? _currentSelectedStock.toString() : '1';
                      });
                    },
                    icon: const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF0D9488)),
                    label: const Text(
                      'استخدام كمية السيستم بالفاتورة',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, prodState) {
              final products = prodState is ProductLoaded ? prodState.products : <ProductModel>[];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Product Selector
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<ProductModel>(
                      key: ValueKey('prod_dd_${_selectedProduct?.id ?? "none"}'),
                      initialValue: products.where((p) => p.id == _selectedProduct?.id).firstOrNull,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'اختر الصنف *',
                        labelStyle: const TextStyle(fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.displayTitle} (${p.brand.name.isNotEmpty ? p.brand.name : "عام"}) - رصيد: ${p.stock}',
                                  style: const TextStyle(fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _onSelectProduct(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Variation Selector (if variable)
                  if (_selectedProduct != null && _selectedProduct!.productVariations.isNotEmpty) ...[
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<ProductVariationModel?>(
                        key: ValueKey('var_dd_${_selectedVariation?.sku ?? "all"}'),
                        initialValue: _selectedVariation,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'المتغير / النكهة',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem<ProductVariationModel?>(
                            value: null,
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF0D9488)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'جميع المتغيرات بالتساوي (${_selectedProduct!.productVariations.length} متغير)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._selectedProduct!.productVariations.map((v) => DropdownMenuItem<ProductVariationModel?>(
                                value: v,
                                child: Text(
                                  '${v.attributeValues.values.join(" • ")} (رصيد: ${v.stock})',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedVariation = v;
                            if (v != null) {
                              if (v.costPrice > 0) {
                                _itemCostController.text = v.costPrice.toStringAsFixed(0);
                              }
                              final currentStock = v.stock;
                              _itemQtyController.text = currentStock > 0 ? currentStock.toString() : '1';
                            } else {
                              final totalStock = _selectedProduct!.stock;
                              _itemQtyController.text = totalStock > 0 ? totalStock.toString() : '1';
                              if (_selectedProduct!.costPrice > 0) {
                                _itemCostController.text = _selectedProduct!.costPrice.toStringAsFixed(0);
                              }
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Purchased Quantity
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _itemQtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'الكمية *',
                        labelStyle: const TextStyle(fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Unit Purchase Cost
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _itemCostController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'سعر الشراء (ج.م) *',
                        labelStyle: const TextStyle(fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Add Item Button
                  ElevatedButton.icon(
                    onPressed: () => _addItemToInvoice(branches),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('إضافة للفاتورة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 3. Branch Distribution Matrix ──
  Widget _buildDistributionMatrixSection(bool isDark, List<StoreBranchModel> branches) {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkSubCard.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: isDark ? Colors.white30 : Colors.black26),
            const SizedBox(height: 8),
            Text(
              'لم يتم إضافة أصناف إلى الفاتورة بعد.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              'اختر الأصناف وأسعار الشراء بالأعلى لإظهار مصفوفة التوزيع على الفروع والمخازن.',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                const Text(
                  'مصفوفة توزيع البضاعة على الفروع والمخازن',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _distributeAllEvenly(branches),
                  icon: const Icon(Icons.bolt_rounded, size: 15),
                  label: const Text('⚡ تقسيم الكل بالتساوي على الفروع', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _distributeAllToMainWarehouse(branches),
                  icon: const Icon(Icons.warehouse_rounded, size: 14),
                  label: const Text('توجيه الكل للمخزن الرئيسي', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) {
            // Group items by product ID
            final uniqueProductIds = _items.map((e) => e.productId).toSet().toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: uniqueProductIds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, prodIndex) {
                final prodId = uniqueProductIds[prodIndex];
                final productItems = _items.where((it) => it.productId == prodId).toList();
                if (productItems.isEmpty) return const SizedBox.shrink();

                final firstItem = productItems.first;
                final productTitle = firstItem.productTitle;
                final totalProductQty = productItems.fold<int>(0, (sum, it) => sum + it.quantity);
                final totalProductSubtotal = productItems.fold<double>(0.0, (sum, it) => sum + it.subtotal);
                final hasVariations = productItems.length > 1 || productItems.any((it) => it.variationAttributes.isNotEmpty);
                final isExpanded = _expandedProductIds.contains(prodId);

                // Calculate product-level allocations across branches
                final productBranchTotals = <String, int>{};
                for (final b in branches) {
                  int bSum = 0;
                  for (final it in productItems) {
                    bSum += (it.branchAllocations[b.id] ?? 0);
                  }
                  productBranchTotals[b.id] = bSum;
                }
                final totalAllocatedForProduct = productBranchTotals.values.fold<int>(0, (s, q) => s + q);
                final isProductMatch = totalAllocatedForProduct == totalProductQty;
                final isProductOver = totalAllocatedForProduct > totalProductQty;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isProductMatch
                          ? (isDark ? AppColor.darkBorder : AppColor.lightBorder)
                          : (isProductOver ? AppColor.error.withValues(alpha: 0.6) : Colors.amber.withValues(alpha: 0.6)),
                      width: isProductMatch ? 1 : 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master Product Header
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Product Icon / Bullet
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF06B6D4)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          productTitle,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                      ),
                                      if (hasVariations) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${productItems.length} متغير',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'إجمالي الكمية: $totalProductQty علبة • القيمة الإجمالية: ${AppFormatters.formatEGP(totalProductSubtotal)}',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick Action: Distribute this product evenly to branches
                            ElevatedButton.icon(
                              onPressed: () => _distributeProductEvenly(prodId, branches),
                              icon: const Icon(Icons.bolt_rounded, size: 14),
                              label: const Text('تقسيم بالتساوي للbranches', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Quick Action: Send to Main Warehouse
                            OutlinedButton.icon(
                              onPressed: () => _distributeProductToMainWarehouse(prodId, branches),
                              icon: const Icon(Icons.warehouse_rounded, size: 14),
                              label: const Text('للمخزن الرئيسي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                            // Variations Expand/Collapse Toggle Button (السهم الصغير)
                            if (hasVariations) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedProductIds.remove(prodId);
                                    } else {
                                      _expandedProductIds.add(prodId);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isExpanded ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isExpanded ? const Color(0xFF8B5CF6).withValues(alpha: 0.4) : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isExpanded ? 'إخفاء المتغيرات' : 'تعديل المتغيرات',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isExpanded ? const Color(0xFF8B5CF6) : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: isExpanded ? const Color(0xFF8B5CF6) : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            // Delete entire product
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                              tooltip: 'حذف الصنف بالكامل',
                              onPressed: () => _removeProduct(prodId),
                            ),
                          ],
                        ),
                      ),

                      // Product Level Branch Distribution Summary Chips (Always Visible!)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                          border: Border(
                            top: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'توزيع الفروع:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: branches.map((b) {
                                  final allocated = productBranchTotals[b.id] ?? 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: allocated > 0
                                          ? (b.isWarehouse ? const Color(0xFF0D9488).withValues(alpha: 0.12) : const Color(0xFF06B6D4).withValues(alpha: 0.1))
                                          : Colors.grey.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: allocated > 0
                                            ? (b.isWarehouse ? const Color(0xFF0D9488).withValues(alpha: 0.3) : const Color(0xFF06B6D4).withValues(alpha: 0.3))
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          b.isWarehouse ? Icons.warehouse_rounded : Icons.store_rounded,
                                          size: 12,
                                          color: allocated > 0 ? (b.isWarehouse ? const Color(0xFF0D9488) : const Color(0xFF06B6D4)) : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${b.name}: $allocated علبة',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: allocated > 0 ? FontWeight.bold : FontWeight.normal,
                                            color: allocated > 0 ? (b.isWarehouse ? const Color(0xFF0D9488) : const Color(0xFF06B6D4)) : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Match status chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isProductMatch
                                    ? AppColor.success.withValues(alpha: 0.12)
                                    : (isProductOver ? AppColor.error.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isProductMatch ? Icons.check_circle_rounded : (isProductOver ? Icons.error_rounded : Icons.info_rounded),
                                    size: 12,
                                    color: isProductMatch ? AppColor.success : (isProductOver ? AppColor.error : Colors.amber[800]),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isProductMatch
                                        ? 'تم توزيع كامل الكمية ($totalAllocatedForProduct / $totalProductQty علبة)'
                                        : (isProductOver
                                            ? 'فائض ($totalAllocatedForProduct / $totalProductQty)'
                                            : 'متبقي (${totalProductQty - totalAllocatedForProduct})'),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isProductMatch ? AppColor.success : (isProductOver ? AppColor.error : Colors.amber[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // If single item without variations OR Expanded by arrow: show editable inputs
                      if (!hasVariations || isExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: productItems.map((it) {
                              final originalIndex = _items.indexOf(it);
                              final itemKey = _getItemKey(it.productId, it.variationSku);
                              final controllers = _allocationControllers[itemKey] ?? {};

                              final allocatedSum = it.branchAllocations.values.fold<int>(0, (s, q) => s + q);
                              final isMatch = allocatedSum == it.quantity;
                              final isOver = allocatedSum > it.quantity;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isMatch ? (isDark ? AppColor.darkBorder : AppColor.lightBorder) : Colors.amber.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (it.variationAttributes.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              it.variationAttributes.values.join(' • '),
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        else
                                          const Text('المنتج الأساسي', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${it.quantity} علبة × ${AppFormatters.formatEGP(it.unitCost)} = ${AppFormatters.formatEGP(it.subtotal)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () => _distributeEvenly(originalIndex, branches),
                                          icon: const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF06B6D4)),
                                          label: const Text('توزيع متساوي', style: TextStyle(fontSize: 10.5, color: Color(0xFF06B6D4), fontWeight: FontWeight.w700)),
                                        ),
                                        if (hasVariations)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColor.error),
                                            tooltip: 'حذف هذا المتغير فقط',
                                            onPressed: () => _removeItem(originalIndex),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: branches.map((b) {
                                        final ctrl = controllers[b.id];
                                        final currentBranchStock = _getBranchStock(it.productId, it.variationSku, b.id);
                                        return SizedBox(
                                          width: 165,
                                          child: TextFormField(
                                            controller: ctrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              labelText: b.name,
                                              helperText: 'الرصيد: $currentBranchStock',
                                              helperStyle: const TextStyle(fontSize: 9.5, color: Color(0xFF06B6D4)),
                                              labelStyle: TextStyle(
                                                fontSize: 10.5,
                                                color: b.isPrimary || b.isWarehouse ? const Color(0xFF06B6D4) : null,
                                                fontWeight: b.isPrimary || b.isWarehouse ? FontWeight.bold : FontWeight.normal,
                                              ),
                                              prefixIcon: Icon(
                                                b.isWarehouse ? Icons.warehouse_rounded : Icons.store_rounded,
                                                size: 13,
                                                color: b.isPrimary || b.isWarehouse ? const Color(0xFF06B6D4) : Colors.grey,
                                              ),
                                              suffixText: 'علبة',
                                              suffixStyle: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              isDense: true,
                                            ),
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val.trim()) ?? 0;
                                              _updateBranchAllocation(
                                                itemIndex: originalIndex,
                                                branchId: b.id,
                                                quantity: parsed,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isMatch
                                                ? AppColor.success.withValues(alpha: 0.12)
                                                : (isOver ? AppColor.error.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isMatch
                                                ? 'موزع ($allocatedSum / ${it.quantity})'
                                                : (isOver ? 'فائض بمقدار (${allocatedSum - it.quantity})' : 'متبقي (${it.quantity - allocatedSum})'),
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: isMatch ? AppColor.success : (isOver ? AppColor.error : Colors.amber[800]),
                                            ),
                                          ),
                                        ),
                                        if (!isMatch) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _items[originalIndex] = it.copyWith(
                                                  quantity: allocatedSum,
                                                  subtotal: allocatedSum * it.unitCost,
                                                );
                                                _syncFinancials();
                                              });
                                            },
                                            child: Text(
                                              'مطابقة الإجمالي مع الفروع ($allocatedSum)',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF0D9488),
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── 4. Financial Calculations & Notes ──
  Widget _buildFinancialSummarySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              const Text('ملخص الحساب والسداد للمورد', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Discount
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: 'خصم الفاتورة (ج.م)',
                    labelStyle: const TextStyle(fontSize: 11.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              // Shipping Cost
              Expanded(
                child: TextFormField(
                  controller: _shippingController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: 'مصاريف الشحن / النقل',
                    labelStyle: const TextStyle(fontSize: 11.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              // Paid Amount
              Expanded(
                child: TextFormField(
                  controller: _paidAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColor.success),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع كاش (ج.م)',
                    labelStyle: const TextStyle(fontSize: 11.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              // Remaining Amount (Auto Computed)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _remainingAmount > 0 ? AppColor.error.withValues(alpha: 0.1) : AppColor.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _remainingAmount > 0 ? AppColor.error.withValues(alpha: 0.3) : AppColor.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _remainingAmount > 0 ? 'المتبقي آجل على المحل' : 'حالة الفاتورة',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _remainingAmount > 0 ? AppColor.error : AppColor.success,
                        ),
                      ),
                      Text(
                        _remainingAmount > 0 ? AppFormatters.formatEGP(_remainingAmount) : 'مدفوعة بالكامل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _remainingAmount > 0 ? AppColor.error : AppColor.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Notes
          TextFormField(
            controller: _notesController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              labelText: 'ملاحظات إضافية حول التوريد أو الفاتورة...',
              labelStyle: const TextStyle(fontSize: 11.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
