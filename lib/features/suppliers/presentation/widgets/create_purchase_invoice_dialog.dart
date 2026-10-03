import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import 'purchase_invoice/invoice_financial_section.dart';
import 'purchase_invoice/invoice_header_section.dart';
import 'purchase_invoice/invoice_items_table.dart';
import 'purchase_invoice/invoice_product_picker_section.dart';

import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class CreatePurchaseInvoiceDialog extends StatefulWidget {
  final String? initialSupplierId;
  final String? initialBranchId;
  final String? initialBranchName;
  final List<PurchaseInvoiceItemModel>? initialItems;

  const CreatePurchaseInvoiceDialog({
    super.key,
    this.initialSupplierId,
    this.initialBranchId,
    this.initialBranchName,
    this.initialItems,
  });

  static void show(
    BuildContext context, {
    String? initialSupplierId,
    String? initialBranchId,
    String? initialBranchName,
    List<PurchaseInvoiceItemModel>? initialItems,
  }) {
    final supplierCubit = context.read<SupplierCubit>();
    final productCubit = context.read<ProductCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: supplierCubit),
          BlocProvider.value(value: productCubit),
          BlocProvider.value(value: settingsCubit),
        ],
        child: CreatePurchaseInvoiceDialog(
          initialSupplierId: initialSupplierId,
          initialBranchId: initialBranchId,
          initialBranchName: initialBranchName,
          initialItems: initialItems,
        ),
      ),
    );
  }

  @override
  State<CreatePurchaseInvoiceDialog> createState() =>
      _CreatePurchaseInvoiceDialogState();
}

class _CreatePurchaseInvoiceDialogState
    extends State<CreatePurchaseInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();

  SupplierModel? _selectedSupplier;
  late String _selectedBranchId;
  late String _selectedBranchName;
  late TextEditingController _invoiceNumberController;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'Cash';
  bool _stockReceived = true;

  final List<PurchaseInvoiceItemModel> _items = [];

  // Line item picker state
  ProductModel? _selectedProduct;
  ProductVariationModel? _selectedVariation;
  final TextEditingController _itemQtyController =
      TextEditingController(text: '10');
  final TextEditingController _itemCostController =
      TextEditingController(text: '0');

  // Batch variation matrix state
  bool _isBatchMode = true;
  Set<String>? _selectedVariationSkusSet;
  Set<String> get _selectedVariationSkus =>
      _selectedVariationSkusSet ??= <String>{};

  Map<String, TextEditingController>? _batchQtyControllersMap;
  Map<String, TextEditingController> get _batchQtyControllers =>
      _batchQtyControllersMap ??= <String, TextEditingController>{};

  Map<String, TextEditingController>? _batchCostControllersMap;
  Map<String, TextEditingController> get _batchCostControllers =>
      _batchCostControllersMap ??= <String, TextEditingController>{};

  TextEditingController? _uniformQtyControllerInst;
  TextEditingController get _uniformQtyController =>
      _uniformQtyControllerInst ??= TextEditingController(text: '10');

  TextEditingController? _uniformCostControllerInst;
  TextEditingController get _uniformCostController =>
      _uniformCostControllerInst ??= TextEditingController();

  String _variationFilterQuery = '';

  // Overall financial controllers
  final TextEditingController _taxController =
      TextEditingController(text: '0');
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  final TextEditingController _shippingController =
      TextEditingController(text: '0');
  final TextEditingController _paidAmountController =
      TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranchId ?? 'main_branch';
    _selectedBranchName =
        widget.initialBranchName ?? 'المخزن الرئيسي / الفرع الرئيسي';

    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _items.addAll(widget.initialItems!);
    }

    final now = DateTime.now();
    final seq = 1000 + (now.millisecondsSinceEpoch % 9000);
    _invoiceNumberController = TextEditingController(
      text: 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-$seq',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supplierState = context.read<SupplierCubit>().state;
      if (supplierState is SupplierLoaded &&
          supplierState.suppliers.isNotEmpty) {
        if (widget.initialSupplierId != null) {
          final found = supplierState.suppliers
              .where((s) => s.id == widget.initialSupplierId)
              .firstOrNull;
          if (found != null) {
            setState(() => _selectedSupplier = found);
            return;
          }
        }
        setState(() => _selectedSupplier = supplierState.suppliers.first);
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _itemQtyController.dispose();
    _itemCostController.dispose();
    _uniformQtyControllerInst?.dispose();
    _uniformCostControllerInst?.dispose();
    _clearBatchControllers();
    _taxController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearBatchControllers() {
    if (_batchQtyControllersMap != null) {
      for (final c in _batchQtyControllersMap!.values) {
        c.dispose();
      }
      _batchQtyControllersMap!.clear();
    }
    if (_batchCostControllersMap != null) {
      for (final c in _batchCostControllersMap!.values) {
        c.dispose();
      }
      _batchCostControllersMap!.clear();
    }
    _selectedVariationSkusSet?.clear();
  }

  void _initBatchForProduct(ProductModel product) {
    _clearBatchControllers();
    if (product.productVariations.isNotEmpty) {
      final defaultQty = _uniformQtyController.text.trim().isNotEmpty
          ? _uniformQtyController.text.trim()
          : '10';
      for (final v in product.productVariations) {
        _selectedVariationSkus.add(v.sku);
        _batchQtyControllers[v.sku] =
            TextEditingController(text: defaultQty);
        final cost =
            v.costPrice > 0 ? v.costPrice : product.costPrice;
        _batchCostControllers[v.sku] = TextEditingController(
            text: cost > 0 ? cost.toStringAsFixed(0) : '0');
      }
      _uniformCostController.text = product.costPrice > 0
          ? product.costPrice.toStringAsFixed(0)
          : '';
    }
  }

  void _onProductSelected(ProductModel? p) {
    setState(() {
      _selectedProduct = p;
      _selectedVariation = p?.productVariations.firstOrNull;
      if (p != null) {
        if (p.costPrice > 0) {
          _itemCostController.text = p.costPrice.toStringAsFixed(0);
        }
        _initBatchForProduct(p);
        if (p.productVariations.isNotEmpty) {
          _isBatchMode = true;
        }
      } else {
        _clearBatchControllers();
      }
    });
  }

  void _selectAllVariations(bool selectAll) {
    if (_selectedProduct == null) return;
    setState(() {
      if (selectAll) {
        _selectedVariationSkus.addAll(
            _selectedProduct!.productVariations.map((v) => v.sku));
      } else {
        _selectedVariationSkus.clear();
      }
    });
  }

  void _applyUniformQtyToSelected() {
    final qtyStr = _uniformQtyController.text.trim();
    if (qtyStr.isEmpty) return;
    for (final sku in _selectedVariationSkus) {
      _batchQtyControllers[sku]?.text = qtyStr;
    }
    setState(() {});
  }

  void _applyUniformCostToSelected() {
    final costStr = _uniformCostController.text.trim();
    if (costStr.isEmpty) return;
    for (final sku in _selectedVariationSkus) {
      _batchCostControllers[sku]?.text = costStr;
    }
    setState(() {});
  }

  void _addBatchVariationsToInvoice() {
    if (_selectedProduct == null ||
        _selectedProduct!.productVariations.isEmpty) {
      return;
    }

    if (_selectedVariationSkus.isEmpty) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'no_vars_selected_warning'.tr,
      );
      return;
    }

    int addedCount = 0;
    for (final v in _selectedProduct!.productVariations) {
      if (_selectedVariationSkus.contains(v.sku)) {
        final qty =
            int.tryParse(_batchQtyControllers[v.sku]?.text.trim() ?? '0') ??
                0;
        final unitCost = double.tryParse(
                _batchCostControllers[v.sku]?.text.trim() ?? '0') ??
            (v.costPrice > 0 ? v.costPrice : _selectedProduct!.costPrice);

        if (qty > 0) {
          final existingIndex = _items.indexWhere(
            (it) =>
                it.productId == _selectedProduct!.id &&
                it.variationSku == v.sku &&
                it.unitCost == unitCost,
          );

          if (existingIndex != -1) {
            final old = _items[existingIndex];
            final newQty = old.quantity + qty;
            _items[existingIndex] = old.copyWith(
              quantity: newQty,
              subtotal: newQty * old.unitCost,
            );
          } else {
            _items.add(
              PurchaseInvoiceItemModel(
                productId: _selectedProduct!.id,
                productTitle: _selectedProduct!.displayTitle,
                variationSku: v.sku,
                variationAttributes: v.attributeValues,
                quantity: qty,
                unitCost: unitCost,
                subtotal: qty * unitCost,
              ),
            );
          }
          addedCount++;
        }
      }
    }

    if (addedCount == 0) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'no_vars_selected_warning'.tr,
      );
      return;
    }

    setState(() {});

    HelperFun.showNotificationAlert(
      title: 'saved_successfully'.tr,
      message: 'vars_added_success_msg'
          .trParams({'count': '$addedCount'}),
      context: context,
    );
  }

  void _updateItemQuantity(int index, int newQty) {
    if (newQty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      final old = _items[index];
      _items[index] = old.copyWith(
        quantity: newQty,
        subtotal: newQty * old.unitCost,
      );
    });
  }

  double get _subtotal =>
      _items.fold(0.0, (acc, item) => acc + item.subtotal);

  double get _taxAmount =>
      double.tryParse(_taxController.text.trim()) ?? 0.0;

  double get _discountAmount =>
      double.tryParse(_discountController.text.trim()) ?? 0.0;

  double get _shippingCost =>
      double.tryParse(_shippingController.text.trim()) ?? 0.0;

  double get _totalAmount {
    final net = _subtotal + _taxAmount + _shippingCost - _discountAmount;
    return net > 0 ? net : 0.0;
  }

  double get _paidAmount =>
      double.tryParse(_paidAmountController.text.trim()) ?? 0.0;

  double get _remainingAmount {
    final rem = _totalAmount - _paidAmount;
    return rem > 0 ? rem : 0.0;
  }

  void _addItemToInvoice() {
    if (_selectedProduct == null) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'select_product_first_warning'.tr,
      );
      return;
    }

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'enter_valid_quantity_warning'.tr,
      );
      return;
    }

    final unitCost =
        double.tryParse(_itemCostController.text.trim()) ?? 0.0;

    final existingIndex = _items.indexWhere(
      (it) =>
          it.productId == _selectedProduct!.id &&
          it.variationSku == _selectedVariation?.sku &&
          it.unitCost == unitCost,
    );

    if (existingIndex != -1) {
      final old = _items[existingIndex];
      final newQty = old.quantity + qty;
      _items[existingIndex] = old.copyWith(
        quantity: newQty,
        subtotal: newQty * old.unitCost,
      );
    } else {
      _items.add(
        PurchaseInvoiceItemModel(
          productId: _selectedProduct!.id,
          productTitle: _selectedProduct!.displayTitle,
          variationSku: _selectedVariation?.sku,
          variationAttributes:
              _selectedVariation?.attributeValues ?? {},
          quantity: qty,
          unitCost: unitCost,
          subtotal: qty * unitCost,
        ),
      );
    }

    setState(() {
      _itemQtyController.text = '10';
      _itemCostController.text = '0';
      _selectedVariation = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitInvoice() async {
    if (_selectedSupplier == null) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'please_select_supplier_warning'.tr,
      );
      return;
    }

    if (_items.isEmpty) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'add_at_least_one_item_warning'.tr,
      );
      return;
    }

    if (_paidAmount > _totalAmount) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'paid_amount_exceeds_total_error'.trParams({
          'paid': AppFormatters.formatEGP(_paidAmount),
          'total': AppFormatters.formatEGP(_totalAmount),
        }),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supplierCubit = context.read<SupplierCubit>();
      final productCubit = context.read<ProductCubit>();
      final dashboardCubit = context.read<DashboardCubit>();

      final invoice = PurchaseInvoiceModel(
        id: '',
        invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty
            ? _invoiceNumberController.text.trim()
            : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        targetBranchId: _selectedBranchId,
        targetBranchName: _selectedBranchName,
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
        paymentStatus:
            _paidAmount >= _totalAmount && _totalAmount > 0
                ? InvoicePaymentStatus.paid
                : (_paidAmount > 0
                    ? InvoicePaymentStatus.partial
                    : InvoicePaymentStatus.unpaid),
        paymentMethod: _paymentMethod,
        stockReceived: _stockReceived,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

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
          'invoice_saved_success_title'.tr,
          'invoice_saved_success_msg'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.errorSnackbar(
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth =
        width > 980 ? 920.0 : (width > 860 ? 840.0 : width - 32);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 920),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md - 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'create_new_purchase_invoice_title'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'create_new_purchase_invoice_desc'.tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Supplier & Dates Header Section
                      InvoiceHeaderSection(
                        selectedSupplier: _selectedSupplier,
                        onSupplierChanged: (SupplierModel? s) =>
                            setState(() => _selectedSupplier = s),
                        targetBranchId: _selectedBranchId,
                        onBranchChanged: (StoreBranchModel? b) {
                          if (b != null) {
                            setState(() {
                              _selectedBranchId = b.id;
                              _selectedBranchName = b.name;
                            });
                          }
                        },
                        invoiceNumberController: _invoiceNumberController,
                        invoiceDate: _invoiceDate,
                        onInvoiceDateChanged: (d) =>
                            setState(() => _invoiceDate = d),
                        dueDate: _dueDate,
                        onDueDateChanged: (d) =>
                            setState(() => _dueDate = d),
                        paymentMethod: _paymentMethod,
                        onPaymentMethodChanged: (pm) =>
                            setState(() => _paymentMethod = pm),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 2. Product & Variations Adder Section
                      InvoiceProductPickerSection(
                        selectedProduct: _selectedProduct,
                        onProductSelected: _onProductSelected,
                        selectedVariation: _selectedVariation,
                        onVariationSelected: (v) {
                          setState(() {
                            _selectedVariation = v;
                            if (v != null && v.costPrice > 0) {
                              _itemCostController.text =
                                  v.costPrice.toStringAsFixed(0);
                            }
                          });
                        },
                        isBatchMode: _isBatchMode,
                        onBatchModeChanged: (b) =>
                            setState(() => _isBatchMode = b),
                        itemQtyController: _itemQtyController,
                        itemCostController: _itemCostController,
                        onAddItem: _addItemToInvoice,
                        selectedVariationSkus: _selectedVariationSkus,
                        batchQtyControllers: _batchQtyControllers,
                        batchCostControllers: _batchCostControllers,
                        uniformQtyController: _uniformQtyController,
                        uniformCostController: _uniformCostController,
                        variationFilterQuery: _variationFilterQuery,
                        onVariationFilterChanged: (q) =>
                            setState(() => _variationFilterQuery = q),
                        onSelectAllVariations: _selectAllVariations,
                        onApplyUniformQty: _applyUniformQtyToSelected,
                        onApplyUniformCost: _applyUniformCostToSelected,
                        onToggleVariation: (sku, selected) {
                          setState(() {
                            if (selected) {
                              _selectedVariationSkus.add(sku);
                            } else {
                              _selectedVariationSkus.remove(sku);
                            }
                          });
                        },
                        onAddBatchToInvoice:
                            _addBatchVariationsToInvoice,
                      ),

                      // 3. Line Items Table
                      InvoiceItemsTable(
                        items: _items,
                        onUpdateQuantity: _updateItemQuantity,
                        onRemoveItem: _removeItem,
                        onClearAll: () => setState(() => _items.clear()),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 4. Financial Calculations, Shortcuts & Summary Section
                      InvoiceFinancialSection(
                        taxController: _taxController,
                        discountController: _discountController,
                        shippingController: _shippingController,
                        paidAmountController: _paidAmountController,
                        notesController: _notesController,
                        subtotal: _subtotal,
                        totalAmount: _totalAmount,
                        paidAmount: _paidAmount,
                        remainingAmount: _remainingAmount,
                        stockReceived: _stockReceived,
                        onStockReceivedChanged: (val) =>
                            setState(() => _stockReceived = val),
                        onStateChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardRadiusLg),
                ),
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      'confirm_save_invoice_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isSubmitting ? null : _submitInvoice,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
