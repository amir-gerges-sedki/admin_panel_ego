import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';
import 'pos_checkout_dialog.dart';

/// The active POS Register Cart and Financial Total breakdown panel
class PosCartPanel extends StatelessWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        final hasItems = state.hasItems;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, size: 18, color: AppColor.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'current_bill_cart'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (hasItems)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'items_pieces_count'.trParams({'count': '${state.totalItemsCount}'}),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    if (hasItems) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _confirmClearCart(context),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColor.error),
                        tooltip: 'clear_cart'.tr,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Items List or Empty State
              Expanded(
                child: !hasItems
                    ? _buildEmptyCartPlaceholder(isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.sm + 2),
                        itemCount: state.cartItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = state.cartItems[index];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.fullTitle,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.selectedVariation.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: item.selectedVariation.entries.map((e) {
                                                final isColor = e.key.toLowerCase().contains('color') ||
                                                    e.key.contains('لون') ||
                                                    e.value.contains('#');
                                                if (isColor) {
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ColorUtils.buildColorIndicator(e.value, size: 10),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        ColorUtils.getReadableColorName(e.value),
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                return Text(
                                                  '${e.key}: ${e.value}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ] else if (item.variationSummary.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.variationSummary,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                          if (item.availableStock < 999) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  'available_stock_count'.trParams({'count': '${item.availableStock}'}),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: item.quantity >= item.availableStock
                                                        ? AppColor.warning
                                                        : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                                                  ),
                                                ),
                                                if (item.quantity >= item.availableStock) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColor.warning.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      'max_quantity'.tr,
                                                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColor.warning),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                          if (item.discount > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '-${AppFormatters.formatEGP(item.totalLineDiscount)}',
                                              style: const TextStyle(fontSize: 10.5, color: AppColor.error, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.formatEGP(item.lineTotal),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                            color: AppColor.primary,
                                          ),
                                        ),
                                        Text(
                                          '(${AppFormatters.formatEGP(item.unitPrice)})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Quantity selector & Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Item Discount Button
                                    InkWell(
                                      onTap: () => _showItemDiscountDialog(context, index, item.discount, item.unitPrice),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.local_offer_outlined, size: 12, color: AppColor.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.discount > 0
                                                  ? 'item_discount_badge'.trParams({'amount': item.discount.toStringAsFixed(0)})
                                                  : 'add_discount'.tr,
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColor.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Quantity Stepper
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildStepperButton(
                                          icon: Icons.remove,
                                          onTap: () => context.read<PosCubit>().updateQuantity(index, item.quantity - 1),
                                          isDark: isDark,
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 32),
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: item.quantity >= item.availableStock ? AppColor.warning : null,
                                            ),
                                          ),
                                        ),
                                        _buildStepperButton(
                                          icon: Icons.add,
                                          onTap: () => context.read<PosCubit>().updateQuantity(index, item.quantity + 1),
                                          isDark: isDark,
                                          isMuted: item.quantity >= item.availableStock,
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          onPressed: () => context.read<PosCubit>().removeItem(index),
                                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColor.error),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'delete'.tr,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),

              // Totals & Checkout Button
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'items_subtotal'.tr,
                          style: TextStyle(fontSize: 11.5, color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                        ),
                        Text(
                          AppFormatters.formatEGP(state.subTotal),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (state.totalDiscount > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'total_discount_label'.tr,
                            style: const TextStyle(fontSize: 11.5, color: AppColor.error, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '-${AppFormatters.formatEGP(state.totalDiscount)}',
                            style: const TextStyle(fontSize: 12, color: AppColor.error, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 14),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'net_grand_total'.tr,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          AppFormatters.formatEGP(state.grandTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Giant Checkout Button
                    ElevatedButton.icon(
                      onPressed: hasItems ? () => PosCheckoutDialog.show(context) : null,
                      icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                      label: Text(
                        hasItems
                            ? 'complete_sale_pay_amount'.trParams({'amount': AppFormatters.formatEGP(state.grandTotal)})
                            : 'empty_cart_title'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCartPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColor.primary),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'empty_cart_title'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'empty_cart_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isMuted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isMuted
                ? (isDark ? AppColor.darkBorder.withValues(alpha: 0.5) : AppColor.lightBorder.withValues(alpha: 0.5))
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isMuted ? Colors.grey.withValues(alpha: 0.6) : AppColor.primary,
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_clear_cart_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text('confirm_clear_cart_msg'.tr),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PosCubit>().clearCart();
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('clear'.tr),
          ),
        ],
      ),
    );
  }

  void _showItemDiscountDialog(BuildContext context, int index, double currentDiscount, double unitPrice) {
    final controller = TextEditingController(text: currentDiscount > 0 ? currentDiscount.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('item_discount_title'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'unit_cost_price'.tr}: ${AppFormatters.formatEGP(unitPrice)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'item_discount_input_label'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              context.read<PosCubit>().updateItemDiscount(index, val);
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            child: Text('apply_discount'.tr),
          ),
        ],
      ),
    );
  }
}

