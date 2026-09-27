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
import 'supplier_form_dialog.dart';

class CreatePurchaseInvoiceDialog extends StatefulWidget {
  final String? initialSupplierId;

  const CreatePurchaseInvoiceDialog({super.key, this.initialSupplierId});

  static void show(BuildContext context, {String? initialSupplierId}) {
    final supplierCubit = context.read<SupplierCubit>();
    final productCubit = context.read<ProductCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: supplierCubit),
          BlocProvider.value(value: productCubit),
        ],
        child: CreatePurchaseInvoiceDialog(
          initialSupplierId: initialSupplierId,
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
  late TextEditingController _invoiceNumberController;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'Cash';
  bool _stockReceived = true;

  final List<PurchaseInvoiceItemModel> _items = [];

  // Line item picker state
  ProductModel? _selectedProduct;
  ProductVariationModel? _selectedVariation;
  final TextEditingController _itemQtyController = TextEditingController(text: '10');
  final TextEditingController _itemCostController = TextEditingController(text: '0');

  // Overall financial controllers
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _shippingController = TextEditingController(text: '0');
  final TextEditingController _paidAmountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final seq = 1000 + (now.millisecondsSinceEpoch % 9000);
    _invoiceNumberController = TextEditingController(
      text: 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-$seq',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supplierState = context.read<SupplierCubit>().state;
      if (supplierState is SupplierLoaded && supplierState.suppliers.isNotEmpty) {
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
    _taxController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
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

    final unitCost = double.tryParse(_itemCostController.text.trim()) ?? 0.0;

    final item = PurchaseInvoiceItemModel(
      productId: _selectedProduct!.id,
      productTitle: _selectedProduct!.displayTitle,
      variationSku: _selectedVariation?.sku,
      variationAttributes: _selectedVariation?.attributeValues ?? {},
      quantity: qty,
      unitCost: unitCost,
      subtotal: qty * unitCost,
    );

    setState(() {
      _items.add(item);
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
    final dialogWidth = width > 860 ? 820.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 900),
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
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
                      // Supplier Picker & Invoice #
                      BlocBuilder<SupplierCubit, SupplierState>(
                        builder: (context, supState) {
                          final suppliers = supState is SupplierLoaded
                              ? supState.suppliers.where((s) => s.isActive).toList()
                              : <SupplierModel>[];

                          final currentSupId = _selectedSupplier?.id;
                          final hasMatch = suppliers.any((s) => s.id == currentSupId);
                          final effectiveSupId = hasMatch
                              ? currentSupId
                              : (suppliers.isNotEmpty ? suppliers.first.id : null);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'supplier_vendor_required'.tr,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        InkWell(
                                          onTap: () => SupplierFormDialog.show(context),
                                          child: Text(
                                            'btn_new_supplier_short'.tr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey('sup_$effectiveSupId'),
                                      initialValue: effectiveSupId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        prefixIcon: Icon(Icons.business_rounded, size: 18),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: suppliers.map((s) {
                                        return DropdownMenuItem<String>(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (id) {
                                        if (id != null) {
                                          final found = suppliers.where((s) => s.id == id).firstOrNull;
                                          setState(() => _selectedSupplier = found);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'invoice_number_label_req'.tr,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _invoiceNumberController,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.tag_rounded, size: 18),
                                        isDense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Dates & Payment Method
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'invoice_date_label'.tr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _invoiceDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() => _invoiceDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16),
                                        const SizedBox(width: 8),
                                        Text(AppFormatters.formatDate(_invoiceDate)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'due_date_optional'.tr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setState(() => _dueDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_available_rounded, size: 16),
                                        const SizedBox(width: 8),
                                        Text(_dueDate != null
                                            ? AppFormatters.formatDate(_dueDate!)
                                            : 'immediate_or_open'.tr),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'payment_method_label_col'.tr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  key: ValueKey('pm_$_paymentMethod'),
                                  initialValue: _paymentMethod,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: ['Cash', 'Instapay', 'Bank Transfer', 'Vodafone Cash', 'Cheque'].map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Section: Line Items Adder
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm + 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'add_items_to_invoice_title'.tr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            BlocBuilder<ProductCubit, ProductState>(
                              builder: (context, prodState) {
                                final products = prodState is ProductLoaded
                                    ? prodState.products
                                    : <ProductModel>[];

                                final currentProdId = _selectedProduct?.id;
                                final hasMatchProd = products.any((p) => p.id == currentProdId);
                                final effectiveProdId = hasMatchProd ? currentProdId : null;

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Product Selector
                                        Expanded(
                                          flex: 3,
                                          child: DropdownButtonFormField<String>(
                                            key: ValueKey('prod_$effectiveProdId'),
                                            initialValue: effectiveProdId,
                                            isExpanded: true,
                                            hint: Text('select_product_hint_catalog'.tr),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            ),
                                            items: products.map((p) {
                                              return DropdownMenuItem<String>(
                                                value: p.id,
                                                child: Text(
                                                  p.displayTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (id) {
                                              setState(() {
                                                final val = products.where((p) => p.id == id).firstOrNull;
                                                _selectedProduct = val;
                                                _selectedVariation = val?.productVariations.firstOrNull;
                                                if (val != null && val.costPrice > 0) {
                                                  _itemCostController.text = val.costPrice.toStringAsFixed(0);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Variation Selector (if applicable)
                                        if (_selectedProduct != null && _selectedProduct!.productVariations.isNotEmpty) ...[
                                          Builder(
                                            builder: (context) {
                                              final variations = _selectedProduct!.productVariations;
                                              final currentSku = _selectedVariation?.sku;
                                              final hasMatchVar = variations.any((v) => v.sku == currentSku);
                                              final effectiveSku = hasMatchVar ? currentSku : variations.firstOrNull?.sku;

                                              return Expanded(
                                                flex: 2,
                                                child: DropdownButtonFormField<String>(
                                                  key: ValueKey('var_$effectiveSku'),
                                                  initialValue: effectiveSku,
                                                  isExpanded: true,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    prefixIcon: Icon(Icons.hub_rounded, size: 18),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  ),
                                                  items: variations.map((v) {
                                                    final label = v.attributeValues.values.join(' • ');
                                                    return DropdownMenuItem<String>(
                                                      value: v.sku,
                                                      child: Text(
                                                        '${v.sku} ${label.isNotEmpty ? "($label)" : ""}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 11),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (sku) {
                                                    setState(() {
                                                      _selectedVariation = variations.where((v) => v.sku == sku).firstOrNull;
                                                    });
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                        ],

                                        // Qty
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: _itemQtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'qty_label'.tr,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Unit Cost
                                        SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: _itemCostController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'cost_price_label'.tr,
                                              suffixText: 'EGP',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Add Button
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                          icon: const Icon(Icons.add_rounded, size: 18),
                                          label: Text('add_btn'.tr),
                                          onPressed: _addItemToInvoice,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Items List / Table
                            if (_items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _items.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final it = _items[index];
                                  final attrs = it.variationAttributes.values.join(' • ');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                it.productTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              if (it.variationSku != null)
                                                Text(
                                                  '${it.variationSku} ${attrs.isNotEmpty ? "($attrs)" : ""}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? AppColor.textMutedDark
                                                        : AppColor.textMutedLight,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${it.quantity} × ${AppFormatters.formatEGP(it.unitCost)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            AppFormatters.formatEGP(it.subtotal),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                                          onPressed: () => _removeItem(index),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Financial Breakdown Inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _taxController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'tax_vat_label'.tr,
                                prefixIcon: const Icon(Icons.percent_rounded, size: 16),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'discount_commercial_label'.tr,
                                prefixIcon: const Icon(Icons.local_offer_outlined, size: 16),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _shippingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'shipping_freight_label'.tr,
                                prefixIcon: const Icon(Icons.local_shipping_outlined, size: 16),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _paidAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'advance_paid_amount_label'.tr,
                                prefixIcon: const Icon(Icons.payments_rounded, size: 16),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Grand Totals Summary Card
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm + 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'items_subtotal_label'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.formatEGP(_subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'net_total_amount_label'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.formatEGP(_totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'balance_due_label'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.formatEGP(_remainingAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _remainingAmount > 0
                                        ? AppColor.error
                                        : AppColor.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Auto Inflow Checkbox
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _stockReceived,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) => setState(() => _stockReceived = val ?? true),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'auto_replenish_stock_title'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Text(
                                    'auto_replenish_stock_desc'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Notes
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'invoice_notes_label'.tr,
                          hintText: 'invoice_notes_hint'.tr,
                          prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                          isDense: true,
                        ),
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
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

