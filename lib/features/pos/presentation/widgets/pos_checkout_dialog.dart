import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:admin_panel_ego/features/customers/domain/services/loyalty_service.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';
import '../cubit/shift_cubit.dart';

/// Interactive checkout dialog with cash change calculator, card/instapay selection, and instant thermal printing
class PosCheckoutDialog extends StatefulWidget {
  const PosCheckoutDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<PosCubit>()),
          BlocProvider.value(value: context.read<ShiftCubit>()),
        ],
        child: const PosCheckoutDialog(),
      ),
    );
  }

  @override
  State<PosCheckoutDialog> createState() => _PosCheckoutDialogState();
}

class _PosCheckoutDialogState extends State<PosCheckoutDialog> {
  final TextEditingController _cashPaidController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _autoPrint = true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PosCubit>();
    cubit.resetSaleStatus();
    final state = cubit.state;
    _customerNameController.text = state.customerName;
    _customerPhoneController.text = state.customerPhone;
    _notesController.text = state.orderNotes;
    final initialPaid = state.paidAmount > 0 ? state.paidAmount : state.grandTotal;
    _cashPaidController.text = initialPaid.toStringAsFixed(0);
    cubit.setPaidAmount(initialPaid);
    if (state.customerPhone.trim().length >= 8) {
      cubit.onCustomerPhoneChanged(state.customerPhone.trim());
    }
  }

  @override
  void dispose() {
    _cashPaidController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocConsumer<PosCubit, PosState>(
      listenWhen: (previous, current) =>
          previous.saleStatus != current.saleStatus ||
          previous.customerName != current.customerName,
      listener: (context, state) {
        if (state.customerName.isNotEmpty &&
            _customerNameController.text.trim().isEmpty) {
          _customerNameController.text = state.customerName;
        }
        if (state.saleStatus == PosSaleStatus.success) {
          context.read<PosCubit>().resetSaleStatus();
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        } else if (state.saleStatus == PosSaleStatus.failure && state.errorMessage != null) {
          HelperFun.showNotificationAlert(
            title: 'pos_sale_error'.tr,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final isCash = state.paymentMethod == 'cash';
        final grandTotal = state.grandTotal;
        final paidAmount = state.paidAmount;
        final changeAmount = state.changeAmount;
        final isSubmitting = state.saleStatus == PosSaleStatus.loading;

        return Dialog(
          backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            width: 580,
            height: 720,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: const Icon(Icons.point_of_sale_rounded, color: AppColor.primary, size: 24),
                      ),
                      const SizedBox(width: AppSizes.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'checkout_sale_title'.tr,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'items_count_total_meta'.trParams({
                                'count': '${state.totalItemsCount}',
                                'total': AppFormatters.formatEGP(grandTotal),
                              }),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                if (context.mounted && Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Payment Method Selector Tabs
                          Text(
                            'payment_method_label'.tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPaymentOption(
                                isDark: isDark,
                                isSelected: state.paymentMethod == 'cash',
                                icon: Icons.payments_outlined,
                                label: 'payment_cash_tab'.tr,
                                onTap: () {
                                  context.read<PosCubit>().setPaymentMethod('cash');
                                  _cashPaidController.text = grandTotal.toStringAsFixed(0);
                                  context.read<PosCubit>().setPaidAmount(grandTotal);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildPaymentOption(
                                isDark: isDark,
                                isSelected: state.paymentMethod == 'card',
                                icon: Icons.credit_card_rounded,
                                label: 'payment_card_tab'.tr,
                                onTap: () => context.read<PosCubit>().setPaymentMethod('card'),
                              ),
                              const SizedBox(width: 8),
                              _buildPaymentOption(
                                isDark: isDark,
                                isSelected: state.paymentMethod == 'instapay',
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'payment_instapay_tab'.tr,
                                onTap: () => context.read<PosCubit>().setPaymentMethod('instapay'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Cash Calculator Box (If Cash is selected)
                          if (isCash) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calculate_outlined, size: 16, color: AppColor.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'cash_change_calculator'.tr,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          _cashPaidController.text = grandTotal.toStringAsFixed(0);
                                          context.read<PosCubit>().setPaidAmount(grandTotal);
                                        },
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                        child: Text('exact_amount'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Quick amount chips
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildQuickCashChip(50, grandTotal),
                                      _buildQuickCashChip(100, grandTotal),
                                      _buildQuickCashChip(200, grandTotal),
                                      _buildQuickCashChip(500, grandTotal),
                                      _buildQuickCashChip(1000, grandTotal),
                                      _buildQuickCashChip(2000, grandTotal),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Cash Input Field
                                  TextField(
                                    controller: _cashPaidController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'cash_received_from_customer'.tr,
                                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                                      context.read<PosCubit>().setPaidAmount(parsed);
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // Change Return Card
                                  Builder(builder: (context) {
                                    final isExact = (paidAmount - grandTotal).abs() < 0.01;
                                    final isUnderpaid = paidAmount < grandTotal && !isExact;
                                    final isOverpaid = paidAmount > grandTotal && !isExact;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isExact || isOverpaid
                                            ? AppColor.success.withValues(alpha: 0.12)
                                            : AppColor.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isExact || isOverpaid
                                              ? AppColor.success.withValues(alpha: 0.3)
                                              : AppColor.error.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isExact || isOverpaid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                                size: 16,
                                                color: isExact || isOverpaid ? AppColor.success : AppColor.error,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isExact
                                                    ? 'exact_amount_settled'.tr
                                                    : (isUnderpaid
                                                        ? 'remaining_amount_to_pay'.tr
                                                        : 'change_to_customer'.tr),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isExact || isOverpaid ? AppColor.success : AppColor.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!isExact)
                                            Text(
                                              isUnderpaid
                                                  ? AppFormatters.formatEGP(grandTotal - paidAmount)
                                                  : AppFormatters.formatEGP(changeAmount),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: isUnderpaid ? AppColor.error : AppColor.success,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                          ],

                          // Customer Info (Optional)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customerNameController,
                                  decoration: InputDecoration(
                                    labelText: 'customer_name_optional'.tr,
                                    hintText: 'walk_in_customer'.tr,
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) => context.read<PosCubit>().setCustomerInfo(name: val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _customerPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'customer_phone_optional'.tr,
                                    hintText: '01xxxxxxxxx',
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                    suffixIcon: state.isSearchingCustomer
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : null,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) {
                                    context.read<PosCubit>().onCustomerPhoneChanged(val);
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Loyalty Points Card & Auto-Register Status
                          _buildLoyaltySection(context, state, isDark),
                          const SizedBox(height: 10),

                          // Print Checkbox
                          CheckboxListTile(
                            value: _autoPrint,
                            onChanged: (val) => setState(() => _autoPrint = val ?? true),
                            title: Text('auto_print_receipt_after_sale'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            secondary: const Icon(Icons.print_rounded, size: 20, color: AppColor.primary),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                if (context.mounted && Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                        ),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final activeShift = context.read<ShiftCubit>().state.activeShift;
                                  final success = await context.read<PosCubit>().completeSale(
                                        cashierName: activeShift?.cashierName ?? 'Store Cashier',
                                        cashierId: activeShift?.cashierId ?? '',
                                        branchId: activeShift?.branchId ?? 'main_branch',
                                        branchName: activeShift?.branchName ?? 'Main Branch',
                                        shiftId: activeShift?.id ?? '',
                                        autoPrint: _autoPrint,
                                      );
                                  if (success && activeShift != null && context.mounted) {
                                    context.read<ShiftCubit>().recordShiftSale(
                                          amount: grandTotal,
                                          paymentMethod: state.paymentMethod,
                                        );
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            isSubmitting
                                ? 'processing_sale'.tr
                                : 'complete_sale_pay_amount'.trParams({'amount': AppFormatters.formatEGP(grandTotal)}),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary.withValues(alpha: 0.12)
                : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppColor.primary : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColor.primary : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(double amount, double grandTotal) {
    return ActionChip(
      label: Text(
        '+${amount.toStringAsFixed(0)} EGP',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      padding: EdgeInsets.zero,
      onPressed: () {
        final current = double.tryParse(_cashPaidController.text.trim()) ?? 0.0;
        final next = current > 0 ? (current + amount) : amount;
        _cashPaidController.text = next.toStringAsFixed(0);
        context.read<PosCubit>().setPaidAmount(next);
      },
    );
  }

  Widget _buildLoyaltySection(BuildContext context, PosState state, bool isDark) {
    final matched = state.matchedCustomer;
    final pointsEarned = state.pointsEarned;
    final phoneEntered = state.customerPhone.trim().isNotEmpty;

    if (matched == null && !phoneEntered && pointsEarned <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: matched != null
            ? Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08)
            : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: matched != null
              ? Colors.amber.withValues(alpha: 0.4)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: matched != null ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (matched != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              matched.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'customer_found_badge'.tr,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColor.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'points_balance'.tr}: ${matched.loyaltyPoints} ${'points_count'.trParams({'count': ''})} (${'points_value_egp'.trParams({'amount': AppFormatters.formatEGP(LoyaltyService.calculateDiscount(matched.loyaltyPoints))})})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.amber[300] : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 12),

            // Redemption toggle
            if (matched.loyaltyPoints >= 10) ...[
              SwitchListTile.adaptive(
                value: state.pointsRedeemed > 0,
                onChanged: (apply) {
                  context.read<PosCubit>().togglePointsRedemption(apply);
                  // Update cash paid input if it matches grandTotal
                  final newGrandTotal = context.read<PosCubit>().state.grandTotal;
                  _cashPaidController.text = newGrandTotal.toStringAsFixed(0);
                  context.read<PosCubit>().setPaidAmount(newGrandTotal);
                },
                title: Text(
                  'redeem_points_toggle'.tr,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  state.pointsRedeemed > 0
                      ? 'redeem_points_applied'.trParams({
                          'amount': AppFormatters.formatEGP(state.pointsDiscount),
                          'points': '${state.pointsRedeemed}',
                        })
                      : 'points_value_egp'.trParams({
                          'amount': AppFormatters.formatEGP(LoyaltyService.calculateDiscount(
                            LoyaltyService.calculateMaxRedeemablePoints(
                              customerPoints: matched.loyaltyPoints,
                              billTotal: (state.subTotal - state.itemDiscounts - state.cartDiscount).clamp(0.0, double.infinity),
                            ),
                          )),
                        }),
                  style: TextStyle(
                    fontSize: 11,
                    color: state.pointsRedeemed > 0 ? AppColor.success : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                    fontWeight: state.pointsRedeemed > 0 ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.amber,
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColor.textMutedDark),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'min_points_to_redeem_notice'.tr,
                      style: const TextStyle(fontSize: 11, color: AppColor.textMutedDark),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (phoneEntered) ...[
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColor.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'new_customer_auto_register_notice'.tr,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],

          if (pointsEarned > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColor.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColor.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'points_earned_from_bill_notice'.trParams({'points': '$pointsEarned'}),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
