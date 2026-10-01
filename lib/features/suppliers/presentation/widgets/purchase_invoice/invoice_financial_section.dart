import 'package:flutter/material.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/formatters/formatters.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';

class InvoiceFinancialSection extends StatelessWidget {
  final TextEditingController taxController;
  final TextEditingController discountController;
  final TextEditingController shippingController;
  final TextEditingController paidAmountController;
  final TextEditingController notesController;
  final double subtotal;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final bool stockReceived;
  final ValueChanged<bool> onStockReceivedChanged;
  final VoidCallback onStateChanged;

  const InvoiceFinancialSection({
    super.key,
    required this.taxController,
    required this.discountController,
    required this.shippingController,
    required this.paidAmountController,
    required this.notesController,
    required this.subtotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.stockReceived,
    required this.onStockReceivedChanged,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Breakdown Inputs
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: taxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'tax_vat_label'.tr,
                  prefixIcon: const Icon(Icons.percent_rounded, size: 16),
                  isDense: true,
                ),
                onChanged: (_) => onStateChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'discount_commercial_label'.tr,
                  prefixIcon:
                      const Icon(Icons.local_offer_outlined, size: 16),
                  isDense: true,
                ),
                onChanged: (_) => onStateChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: shippingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'shipping_freight_label'.tr,
                  prefixIcon:
                      const Icon(Icons.local_shipping_outlined, size: 16),
                  isDense: true,
                ),
                onChanged: (_) => onStateChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: paidAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'advance_paid_amount_label'.tr,
                  prefixIcon: const Icon(Icons.payments_rounded, size: 16),
                  isDense: true,
                  errorText: paidAmount > totalAmount && totalAmount > 0
                      ? 'paid_exceeds_total_hint'.trParams({
                          'max': AppFormatters.formatEGP(totalAmount),
                        })
                      : null,
                  suffixIcon: totalAmount > 0
                      ? Tooltip(
                          message: 'pay_full_total_tooltip'.tr,
                          child: IconButton(
                            icon: const Icon(Icons.done_all_rounded,
                                size: 18, color: Color(0xFF10B981)),
                            onPressed: () {
                              paidAmountController.text = totalAmount % 1 == 0
                                  ? totalAmount.toInt().toString()
                                  : totalAmount.toStringAsFixed(2);
                              onStateChanged();
                            },
                          ),
                        )
                      : null,
                ),
                onChanged: (_) => onStateChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Pay Shortcuts
        Row(
          children: [
            Text(
              'payment_label'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColor.textMutedDark
                    : AppColor.textMutedLight,
              ),
            ),
            const SizedBox(width: 8),
            // Full Pay 100%
            InkWell(
              onTap: () {
                paidAmountController.text = totalAmount > 0
                    ? (totalAmount % 1 == 0
                        ? totalAmount.toInt().toString()
                        : totalAmount.toStringAsFixed(2))
                    : '0';
                onStateChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color:
                          const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '${'pay_full_btn'.tr} (${AppFormatters.formatEGP(totalAmount)})',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 50% Pay
            InkWell(
              onTap: () {
                final half = totalAmount / 2;
                paidAmountController.text = half > 0
                    ? (half % 1 == 0
                        ? half.toInt().toString()
                        : half.toStringAsFixed(2))
                    : '0';
                onStateChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: AppColor.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${'pay_half_btn'.tr} (${AppFormatters.formatEGP(totalAmount / 2)})',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 0 Pay (Credit)
            InkWell(
              onTap: () {
                paidAmountController.text = '0';
                onStateChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: isDark
                          ? AppColor.darkBorder
                          : AppColor.lightBorder),
                ),
                child: Text(
                  'pay_zero_btn'.tr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Overpayment Warning Banner
        if (paidAmount > totalAmount && totalAmount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              border:
                  Border.all(color: AppColor.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColor.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'paid_exceeds_warning_banner'.trParams({
                      'paid': AppFormatters.formatEGP(paidAmount),
                      'total': AppFormatters.formatEGP(totalAmount),
                    }),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColor.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    paidAmountController.text = totalAmount > 0
                        ? (totalAmount % 1 == 0
                            ? totalAmount.toInt().toString()
                            : totalAmount.toStringAsFixed(2))
                        : '0';
                    onStateChanged();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'pay_full_btn'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      color: isDark
                          ? AppColor.textMutedDark
                          : AppColor.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatEGP(subtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'net_total_amount_label'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColor.textMutedDark
                          : AppColor.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatEGP(totalAmount),
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
                      color: isDark
                          ? AppColor.textMutedDark
                          : AppColor.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatEGP(remainingAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: remainingAmount > 0
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: stockReceived,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) =>
                    onStockReceivedChanged(val ?? true),
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
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
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
          controller: notesController,
          decoration: InputDecoration(
            labelText: 'invoice_notes_label'.tr,
            hintText: 'invoice_notes_hint'.tr,
            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
