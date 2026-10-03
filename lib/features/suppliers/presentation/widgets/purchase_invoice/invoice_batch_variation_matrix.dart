import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/formatters/formatters.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../products/data/models/product_model.dart';

class InvoiceBatchVariationMatrix extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final Set<String> selectedVariationSkus;
  final Map<String, TextEditingController> batchQtyControllers;
  final Map<String, TextEditingController> batchCostControllers;
  final TextEditingController uniformQtyController;
  final TextEditingController uniformCostController;
  final String variationFilterQuery;
  final ValueChanged<String> onVariationFilterChanged;
  final ValueChanged<bool> onSelectAll;
  final VoidCallback onApplyUniformQty;
  final VoidCallback onApplyUniformCost;
  final void Function(String sku, bool selected) onToggleVariation;
  final VoidCallback onAddBatchToInvoice;

  const InvoiceBatchVariationMatrix({
    super.key,
    required this.product,
    required this.isDark,
    required this.selectedVariationSkus,
    required this.batchQtyControllers,
    required this.batchCostControllers,
    required this.uniformQtyController,
    required this.uniformCostController,
    required this.variationFilterQuery,
    required this.onVariationFilterChanged,
    required this.onSelectAll,
    required this.onApplyUniformQty,
    required this.onApplyUniformCost,
    required this.onToggleVariation,
    required this.onAddBatchToInvoice,
  });

  @override
  Widget build(BuildContext context) {
    if (product.productVariations.isEmpty) {
      return const SizedBox.shrink();
    }

    final variations = product.productVariations;
    final filtered = variations.where((v) {
      if (variationFilterQuery.trim().isEmpty) return true;
      final q = variationFilterQuery.trim().toLowerCase();
      final skuMatch = v.sku.toLowerCase().contains(q);
      final attrMatch =
          v.attributeValues.values.any((val) => val.toLowerCase().contains(q));
      return skuMatch || attrMatch;
    }).toList();

    int totalSelectedUnits = 0;
    double totalSelectedCost = 0.0;
    for (final v in variations) {
      if (selectedVariationSkus.contains(v.sku)) {
        final q =
            int.tryParse(batchQtyControllers[v.sku]?.text.trim() ?? '0') ?? 0;
        final c =
            double.tryParse(batchCostControllers[v.sku]?.text.trim() ?? '0') ??
                (v.costPrice > 0 ? v.costPrice : product.costPrice);
        totalSelectedUnits += q;
        totalSelectedCost += (q * c);
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Controls Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusSm - 1)),
              border: Border(
                  bottom: BorderSide(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                // Search field
                SizedBox(
                  width: 190,
                  height: 32,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'search_vars_hint'.tr,
                      hintStyle: const TextStyle(fontSize: 11),
                      prefixIcon: const Icon(Icons.search_rounded, size: 15),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11.5),
                    onChanged: onVariationFilterChanged,
                  ),
                ),

                // Select / Deselect All
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onSelectAll(true),
                      icon: const Icon(Icons.check_box_rounded, size: 14),
                      label: Text('select_all_variations'.tr),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () => onSelectAll(false),
                      icon: const Icon(Icons.check_box_outline_blank_rounded,
                          size: 14),
                      label: Text('deselect_all_variations'.tr),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),

                // Apply Uniform Qty Bar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'apply_uniform_qty'.tr,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 50,
                      height: 30,
                      child: TextField(
                        controller: uniformQtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: onApplyUniformQty,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      child: Text('apply_btn'.tr),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        uniformQtyController.text = '5';
                        onApplyUniformQty();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('+5',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary)),
                      ),
                    ),
                    const SizedBox(width: 3),
                    InkWell(
                      onTap: () {
                        uniformQtyController.text = '10';
                        onApplyUniformQty();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('+10',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary)),
                      ),
                    ),
                  ],
                ),

                // Apply Uniform Cost Bar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'apply_uniform_cost'.tr,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 65,
                      height: 30,
                      child: TextField(
                        controller: uniformCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: onApplyUniformCost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      child: Text('apply_btn'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Variations Scrollable List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('no_matching_variations'.tr,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final v = filtered[idx];
                      final isSelected =
                          selectedVariationSkus.contains(v.sku);
                      final qtyCtrl = batchQtyControllers[v.sku] ??
                          TextEditingController(text: '0');
                      final costCtrl = batchCostControllers[v.sku] ??
                          TextEditingController(text: '0');

                      final currentQty =
                          int.tryParse(qtyCtrl.text.trim()) ?? 0;
                      final currentCost = double.tryParse(
                              costCtrl.text.trim()) ??
                          (v.costPrice > 0 ? v.costPrice : product.costPrice);
                      final rowSubtotal = currentQty * currentCost;
                      final attrs = v.attributeValues.values.join(' • ');

                      return Container(
                        color: isSelected
                            ? const Color(0xFF10B981).withValues(alpha: 0.05)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            // Checkbox
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF10B981),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) =>
                                  onToggleVariation(v.sku, val == true),
                            ),

                            // Thumbnail or icon
                            if (v.image.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  v.image,
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.inventory_2_outlined,
                                          size: 20),
                                ),
                              )
                            else
                              const Icon(Icons.tune_rounded,
                                  size: 20, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),

                            // SKU & Attributes
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.sku,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (attrs.isNotEmpty)
                                    Text(
                                      attrs,
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

                            // Current Stock Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: v.stock <= 5
                                    ? AppColor.error.withValues(alpha: 0.12)
                                    : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${'stock_label'.tr}: ${v.stock}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: v.stock <= 5
                                      ? AppColor.error
                                      : (isDark
                                          ? AppColor.textSecondaryDark
                                          : AppColor.textSecondaryLight),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Qty Input
                            SizedBox(
                              width: 65,
                              height: 32,
                              child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11.5, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  hintText: 'qty_label'.tr,
                                ),
                                onChanged: (val) {
                                  if (!isSelected) {
                                    onToggleVariation(v.sku, true);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Cost Price Input
                            SizedBox(
                              width: 75,
                              height: 32,
                              child: TextField(
                                controller: costCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11.5, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  hintText: 'cost_price_label'.tr,
                                  suffixText: 'EGP',
                                  suffixStyle: const TextStyle(fontSize: 9),
                                ),
                                onChanged: (val) {
                                  if (!isSelected) {
                                    onToggleVariation(v.sku, true);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Row Subtotal
                            SizedBox(
                              width: 80,
                              child: Text(
                                AppFormatters.formatEGP(rowSubtotal),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected && currentQty > 0
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Matrix Footer with Summary and Add Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.borderRadiusSm - 1)),
              border: Border(
                  top: BorderSide(
                      color:
                          isDark ? AppColor.darkBorder : AppColor.lightBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'batch_vars_summary'.trParams({
                      'selected': '${selectedVariationSkus.length}',
                      'total': '${variations.length}',
                      'qty': '$totalSelectedUnits',
                      'amount': AppFormatters.formatEGP(totalSelectedCost),
                    }),
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: selectedVariationSkus.isNotEmpty
                      ? onAddBatchToInvoice
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                  label: Text('add_selected_vars_btn'.trParams(
                      {'count': '${selectedVariationSkus.length}'})),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
