import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/formatters/formatters.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../data/models/purchase_invoice_model.dart';

class InvoiceItemsTable extends StatelessWidget {
  final List<PurchaseInvoiceItemModel> items;
  final void Function(int index, int newQty) onUpdateQuantity;
  final void Function(int index) onRemoveItem;
  final VoidCallback onClearAll;

  const InvoiceItemsTable({
    super.key,
    required this.items,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${'line_items_count_title'.trParams({'count': '${items.length}'})} (${items.fold<int>(0, (sum, i) => sum + i.quantity)} ${'units'.tr})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'clear_all'.tr,
                style: const TextStyle(fontSize: 11, color: AppColor.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final it = items[index];
            final attrs = it.variationAttributes.values.join(' • ');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Title & Variation SKU
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

                  // Qty Stepper Controls
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkCard : AppColor.lightCard,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            isDark ? AppColor.darkBorder : AppColor.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 14),
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              onUpdateQuantity(index, it.quantity - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${it.quantity}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 14),
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              onUpdateQuantity(index, it.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Cost Price
                  Text(
                    '× ${AppFormatters.formatEGP(it.unitCost)}',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),

                  // Subtotal
                  Expanded(
                    flex: 2,
                    child: Text(
                      AppFormatters.formatEGP(it.subtotal),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Delete Icon
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColor.error),
                    onPressed: () => onRemoveItem(index),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
