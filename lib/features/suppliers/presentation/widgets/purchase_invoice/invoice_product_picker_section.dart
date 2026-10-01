import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../products/data/models/product_model.dart';
import '../../../../products/presentation/cubit/product_cubit.dart';
import 'invoice_batch_variation_matrix.dart';

class InvoiceProductPickerSection extends StatelessWidget {
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel?> onProductSelected;
  final ProductVariationModel? selectedVariation;
  final ValueChanged<ProductVariationModel?> onVariationSelected;
  final bool isBatchMode;
  final ValueChanged<bool> onBatchModeChanged;
  final TextEditingController itemQtyController;
  final TextEditingController itemCostController;
  final VoidCallback onAddItem;

  // Batch matrix props
  final Set<String> selectedVariationSkus;
  final Map<String, TextEditingController> batchQtyControllers;
  final Map<String, TextEditingController> batchCostControllers;
  final TextEditingController uniformQtyController;
  final TextEditingController uniformCostController;
  final String variationFilterQuery;
  final ValueChanged<String> onVariationFilterChanged;
  final ValueChanged<bool> onSelectAllVariations;
  final VoidCallback onApplyUniformQty;
  final VoidCallback onApplyUniformCost;
  final void Function(String sku, bool selected) onToggleVariation;
  final VoidCallback onAddBatchToInvoice;

  const InvoiceProductPickerSection({
    super.key,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.selectedVariation,
    required this.onVariationSelected,
    required this.isBatchMode,
    required this.onBatchModeChanged,
    required this.itemQtyController,
    required this.itemCostController,
    required this.onAddItem,
    required this.selectedVariationSkus,
    required this.batchQtyControllers,
    required this.batchCostControllers,
    required this.uniformQtyController,
    required this.uniformCostController,
    required this.variationFilterQuery,
    required this.onVariationFilterChanged,
    required this.onSelectAllVariations,
    required this.onApplyUniformQty,
    required this.onApplyUniformCost,
    required this.onToggleVariation,
    required this.onAddBatchToInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'add_items_to_invoice_title'.tr,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              if (selectedProduct != null &&
                  selectedProduct!.productVariations.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkCard : AppColor.lightCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => onBatchModeChanged(false),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(5)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: !isBatchMode
                                ? AppColor.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(5)),
                          ),
                          child: Text(
                            'single_variation_mode'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: !isBatchMode ? AppColor.primary : null,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onBatchModeChanged(true),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(5)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isBatchMode
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 13,
                                color: isBatchMode
                                    ? const Color(0xFF10B981)
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${'batch_variations_mode'.tr} (${selectedProduct!.productVariations.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isBatchMode
                                      ? const Color(0xFF10B981)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, prodState) {
              final products = prodState is ProductLoaded
                  ? prodState.products
                  : <ProductModel>[];

              final currentProdId = selectedProduct?.id;
              final hasMatchProd =
                  products.any((p) => p.id == currentProdId);
              final effectiveProdId =
                  hasMatchProd ? currentProdId : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Dropdown Selector
                  DropdownButtonFormField<String>(
                    key: ValueKey('prod_$effectiveProdId'),
                    initialValue: effectiveProdId,
                    isExpanded: true,
                    hint: Text('select_product_hint_catalog'.tr),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon:
                          Icon(Icons.inventory_2_outlined, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
                      final val =
                          products.where((p) => p.id == id).firstOrNull;
                      onProductSelected(val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Multi-Variation Batch Matrix Mode vs Single Mode
                  if (selectedProduct != null &&
                      selectedProduct!.productVariations.isNotEmpty &&
                      isBatchMode) ...[
                    InvoiceBatchVariationMatrix(
                      product: selectedProduct!,
                      isDark: isDark,
                      selectedVariationSkus: selectedVariationSkus,
                      batchQtyControllers: batchQtyControllers,
                      batchCostControllers: batchCostControllers,
                      uniformQtyController: uniformQtyController,
                      uniformCostController: uniformCostController,
                      variationFilterQuery: variationFilterQuery,
                      onVariationFilterChanged: onVariationFilterChanged,
                      onSelectAll: onSelectAllVariations,
                      onApplyUniformQty: onApplyUniformQty,
                      onApplyUniformCost: onApplyUniformCost,
                      onToggleVariation: onToggleVariation,
                      onAddBatchToInvoice: onAddBatchToInvoice,
                    ),
                  ] else ...[
                    // Single item row
                    Row(
                      children: [
                        // Variation Selector (if variable)
                        if (selectedProduct != null &&
                            selectedProduct!.productVariations.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final variations =
                                  selectedProduct!.productVariations;
                              final currentSku = selectedVariation?.sku;
                              final hasMatchVar =
                                  variations.any((v) => v.sku == currentSku);
                              final effectiveSku = hasMatchVar
                                  ? currentSku
                                  : variations.firstOrNull?.sku;

                              return Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('var_$effectiveSku'),
                                  initialValue: effectiveSku,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    prefixIcon:
                                        Icon(Icons.hub_rounded, size: 18),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                  ),
                                  items: variations.map((v) {
                                    final label =
                                        v.attributeValues.values.join(' • ');
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
                                    final v = variations
                                        .where((v) => v.sku == sku)
                                        .firstOrNull;
                                    onVariationSelected(v);
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
                            controller: itemQtyController,
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
                            controller: itemCostController,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('add_btn'.tr),
                          onPressed: onAddItem,
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
