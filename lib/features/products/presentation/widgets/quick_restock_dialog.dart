import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/stock_movement_cubit.dart';
import 'product_creation_wizard.dart';

class QuickRestockDialog extends StatefulWidget {
  final ProductModel product;
  final String? initialVariationSku;
  final int defaultThreshold;

  const QuickRestockDialog({
    super.key,
    required this.product,
    this.initialVariationSku,
    this.defaultThreshold = 10,
  });

  static void show(
    BuildContext context, {
    required ProductModel product,
    String? initialVariationSku,
    int defaultThreshold = 10,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => QuickRestockDialog(
        product: product,
        initialVariationSku: initialVariationSku,
        defaultThreshold: defaultThreshold,
      ),
    );
  }

  @override
  State<QuickRestockDialog> createState() => _QuickRestockDialogState();
}

class _QuickRestockDialogState extends State<QuickRestockDialog> {
  late ProductVariationModel? _selectedVariation;
  late TextEditingController _qtyController;
  late TextEditingController _costPriceController;
  late TextEditingController _supplierController;
  late TextEditingController _invoiceController;
  late TextEditingController _notesController;

  bool _isBatchMode = false;
  final Map<String, int> _batchQuantities = {};
  final Map<String, double> _batchCostPrices = {};
  String _variationSearchQuery = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.product.productVariations.isNotEmpty) {
      if (widget.initialVariationSku != null && widget.initialVariationSku!.isNotEmpty) {
        _selectedVariation = widget.product.productVariations.firstWhere(
          (v) => v.sku.toLowerCase() == widget.initialVariationSku!.toLowerCase(),
          orElse: () => widget.product.productVariations.first,
        );
      } else {
        _selectedVariation = widget.product.productVariations.first;
      }
    } else {
      _selectedVariation = null;
    }

    final initialCost = _selectedVariation != null
        ? _selectedVariation!.costPrice
        : widget.product.costPrice;

    _qtyController = TextEditingController(text: '20');
    _costPriceController = TextEditingController(
      text: initialCost > 0 ? initialCost.toStringAsFixed(0) : '',
    );
    _supplierController = TextEditingController();
    _invoiceController = TextEditingController();
    _notesController = TextEditingController();

    // Init batch defaults
    for (final v in widget.product.productVariations) {
      _batchQuantities[v.sku] = 0;
      _batchCostPrices[v.sku] = v.costPrice;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costPriceController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onVariationChanged(String? sku) {
    if (sku == null) return;
    final v = widget.product.productVariations
        .where((varItem) => varItem.sku == sku)
        .firstOrNull;
    if (v == null) return;
    setState(() {
      _selectedVariation = v;
      if (v.costPrice > 0) {
        _costPriceController.text = v.costPrice.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final product = widget.product;
    final color = product.categoryType.accentColor;

    final parsedQty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final parsedCost = double.tryParse(_costPriceController.text.trim()) ??
        (_selectedVariation?.costPrice ?? product.costPrice);

    final currentStock = _selectedVariation != null ? _selectedVariation!.stock : product.stock;
    final newStock = currentStock + (parsedQty > 0 ? parsedQty : 0);
    final totalRestockCost = parsedQty > 0 ? parsedQty * parsedCost : 0.0;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _isBatchMode ? 720 : 540,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
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
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'smart_stock_replenishment'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${product.displayTitle} • ${product.brand.name.isNotEmpty ? product.brand.name : "general_brand".tr}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (product.productVariations.length > 1)
                    ActionChip(
                      avatar: Icon(
                        _isBatchMode ? Icons.view_agenda_rounded : Icons.auto_awesome_motion_rounded,
                        size: 14,
                        color: color,
                      ),
                      label: Text(
                        _isBatchMode
                            ? 'single_sku_mode'.tr
                            : 'batch_matrix_mode'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      backgroundColor: color.withValues(alpha: 0.12),
                      onPressed: () {
                        setState(() => _isBatchMode = !_isBatchMode);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: _isBatchMode
                    ? _buildBatchModeView(isDark, color)
                    : _buildSingleModeView(
                        isDark,
                        color,
                        currentStock,
                        newStock,
                        totalRestockCost,
                      ),
              ),
            ),

            // Footer Actions
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;

                  final fullEditorBtn = TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ProductCreationWizard.show(
                        context,
                        initialProduct: widget.product,
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text('full_editor_btn'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                      visualDensity: VisualDensity.compact,
                    ),
                  );

                  final cancelBtn = TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  );

                  final submitBtn = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                      _isBatchMode
                          ? 'confirm_batch_restock'.tr
                          : 'confirm_restock'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isSubmitting ? null : _submitRestock,
                  );

                  if (isCompact) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: fullEditorBtn),
                            const SizedBox(width: 8),
                            cancelBtn,
                          ],
                        ),
                        const SizedBox(height: 6),
                        submitBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Flexible(child: fullEditorBtn),
                      const SizedBox(width: 8),
                      const Spacer(),
                      cancelBtn,
                      const SizedBox(width: 8),
                      submitBtn,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleModeView(
    bool isDark,
    Color color,
    int currentStock,
    int newStock,
    double totalRestockCost,
  ) {
    final product = widget.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Variation Picker (if product has variations)
        if (product.productVariations.isNotEmpty) ...[
          Text(
            'select_variation_to_restock'.tr,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final currentSku = _selectedVariation?.sku;
              final hasMatch = product.productVariations.any((v) => v.sku == currentSku);
              final effectiveSku = hasMatch ? currentSku : product.productVariations.firstOrNull?.sku;

              return DropdownButtonFormField<String>(
                key: ValueKey('var_$effectiveSku'),
                initialValue: effectiveSku,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.hub_rounded, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: product.productVariations.map((v) {
                  final attrs = v.attributeValues.values.join(' • ');
                  final isLow = v.stock <= (v.lowStockThreshold ?? widget.defaultThreshold);

                  return DropdownMenuItem<String>(
                    value: v.sku,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${v.sku} ${attrs.isNotEmpty ? "($attrs)" : ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLow
                                ? AppColor.error.withValues(alpha: 0.15)
                                : AppColor.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stock: ${v.stock}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isLow ? AppColor.error : AppColor.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onVariationChanged,
              );
            },
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Live Stock Comparison Banner
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'current_stock_label'.trParams({'count': currentStock.toString()}),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: currentStock <= widget.defaultThreshold
                            ? AppColor.error
                            : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'reorder_threshold_label'.trParams({
                        'count': widget.defaultThreshold.toString(),
                      }),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColor.success),
                    const SizedBox(width: 4),
                    Text(
                      'new_stock_label'.trParams({'count': newStock.toString()}),
                      style: const TextStyle(
                        color: AppColor.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Restock Quantity Input with quick preset chips
        Text(
          'quantity_to_add_label'.tr,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 20',
            prefixIcon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            suffixText: 'units_short'.tr,
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [5, 10, 20, 50, 100, 200].map((preset) {
            final isSelected = _qtyController.text == preset.toString();
            return ChoiceChip(
              label: Text('+$preset'),
              selected: isSelected,
              selectedColor: color.withValues(alpha: 0.2),
              backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : null,
              ),
              onSelected: (_) {
                setState(() {
                  _qtyController.text = preset.toString();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.md),

        // Batch Cost Price
        Text(
          'batch_cost_price_label'.tr,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _costPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '0',
            prefixIcon: Icon(Icons.price_change_outlined, size: 18, color: Color(0xFFF59E0B)),
            prefixText: 'EGP ',
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        if (totalRestockCost > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'total_inflow_expenditure'.trParams({
                'amount': AppFormatters.formatEGP(totalRestockCost),
              }),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        const SizedBox(height: AppSizes.md),

        // Supplier & Invoice Fields (Collapsible / Sleek)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: 'supplier_name_label'.tr,
                  hintText: 'e.g. Vaporesso Official',
                  prefixIcon: const Icon(Icons.local_shipping_outlined, size: 18),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _invoiceController,
                decoration: InputDecoration(
                  labelText: 'invoice_ref_label'.tr,
                  hintText: 'e.g. INV-9042',
                  prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'restock_notes_label'.tr,
            hintText: 'restock_notes_hint'.tr,
            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBatchModeView(bool isDark, Color color) {
    final vars = widget.product.productVariations;
    final filtered = _variationSearchQuery.isEmpty
        ? vars
        : vars.where((v) {
            final query = _variationSearchQuery.toLowerCase();
            final matchesSku = v.sku.toLowerCase().contains(query);
            final matchesAttr = v.attributeValues.values.any(
              (val) => val.toLowerCase().contains(query),
            );
            return matchesSku || matchesAttr;
          }).toList();

    int totalBatchAdded = _batchQuantities.values.fold(0, (sum, q) => sum + q);
    double totalBatchCost = 0.0;
    _batchQuantities.forEach((sku, qty) {
      if (qty > 0) {
        final c = _batchCostPrices[sku] ?? 0.0;
        totalBatchCost += qty * c;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar in Batch Mode
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search_variations_hint'.tr,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) => setState(() => _variationSearchQuery = val.trim()),
              ),
            ),
            const SizedBox(width: 8),
            // Quick Apply to All Visible
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 14),
              label: Text('plus_10_all'.tr, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                setState(() {
                  for (final v in filtered) {
                    _batchQuantities[v.sku] = (_batchQuantities[v.sku] ?? 0) + 10;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Batch Summary Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total_units_added'.trParams({'count': totalBatchAdded.toString()}),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'total_cost_label'.trParams({
                  'amount': AppFormatters.formatEGP(totalBatchCost),
                }),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Variations List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final v = filtered[idx];
            final qty = _batchQuantities[v.sku] ?? 0;
            final cost = _batchCostPrices[v.sku] ?? v.costPrice;
            final isLow = v.stock <= (v.lowStockThreshold ?? widget.defaultThreshold);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // SKU & Attributes
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              v.sku,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isLow)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColor.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Low (${v.stock})',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          v.attributeValues.values.join(' • '),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColor.textSecondaryDark
                                : AppColor.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Batch Cost Price
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: cost > 0 ? cost.toStringAsFixed(0) : '',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: 'EGP ',
                        labelText: 'cost_label'.tr,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      ),
                      onChanged: (val) {
                        final c = double.tryParse(val) ?? 0.0;
                        _batchCostPrices[v.sku] = c;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quantity to Add
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      key: ValueKey('batch_qty_${v.sku}_$qty'),
                      initialValue: qty > 0 ? qty.toString() : '',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColor.primary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'qty_label'.tr,
                        hintText: '0',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      ),
                      onChanged: (val) {
                        final q = int.tryParse(val) ?? 0;
                        _batchQuantities[v.sku] = q;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _submitRestock() async {
    final product = widget.product;

    setState(() => _isSubmitting = true);

    try {
      final stockCubit = context.read<StockMovementCubit>();
      final productCubit = context.read<ProductCubit>();
      final dashboardCubit = context.read<DashboardCubit>();

      if (_isBatchMode) {
        final validQuantities = Map<String, int>.from(_batchQuantities)
          ..removeWhere((k, v) => v <= 0);

        if (validQuantities.isEmpty) {
          HelperFun.warningSnackbar(
            title: 'warning_title'.tr,
            message: 'enter_qty_for_at_least_one_msg'.tr,
          );
          setState(() => _isSubmitting = false);
          return;
        }

        await stockCubit.executeBatchRestock(
          product: product,
          skuQuantities: validQuantities,
          skuCostPrices: _batchCostPrices,
          supplier: _supplierController.text.trim(),
          invoiceNumber: _invoiceController.text.trim(),
          notes: _notesController.text.trim(),
        );
      } else {
        final qtyToAdd = int.tryParse(_qtyController.text.trim()) ?? 0;
        if (qtyToAdd <= 0) {
          HelperFun.warningSnackbar(
            title: 'warning_title'.tr,
            message: 'enter_valid_qty_msg'.tr,
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0.0;

        await stockCubit.executeRestock(
          product: product,
          variationSku: _selectedVariation?.sku,
          quantityAdded: qtyToAdd,
          costPrice: costPrice,
          supplier: _supplierController.text.trim(),
          invoiceNumber: _invoiceController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      // Sync local product cubit & dashboard
      await productCubit.loadProducts();
      await dashboardCubit.loadDashboard();

      if (mounted) {
        Navigator.pop(context);
        HelperFun.successSnackbar(
          'restock_confirmed_title'.tr,
          'restock_product_success_msg'.trParams({'title': product.displayTitle}),
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFun.errorSnackbar(
          title: 'restock_failed_title'.tr,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
