import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_cubit.dart';

class OrderReturnDialog extends StatefulWidget {
  final OrderModel order;

  const OrderReturnDialog({super.key, required this.order});

  static Future<bool?> show(BuildContext context, OrderModel order) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<OrderCubit>(),
        child: OrderReturnDialog(order: order),
      ),
    );
  }

  @override
  State<OrderReturnDialog> createState() => _OrderReturnDialogState();
}

class _OrderReturnDialogState extends State<OrderReturnDialog> {
  late final Map<int, bool> _selectedItems;
  late final Map<int, int> _returnQuantities;
  final TextEditingController _reasonNotesController = TextEditingController();
  final TextEditingController _refundAmountController = TextEditingController();

  String _selectedReasonKey = 'reason_defective';
  bool _restockInventory = true;
  bool _isSubmitting = false;

  static const List<String> _commonReasonKeys = [
    'reason_defective',
    'reason_wrong_item',
    'reason_customer_changed_mind',
    'reason_delivery_error',
    'reason_unwanted',
    'reason_other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedItems = {
      for (int i = 0; i < widget.order.items.length; i++) i: true,
    };
    _returnQuantities = {
      for (int i = 0; i < widget.order.items.length; i++) i: widget.order.items[i].quantity,
    };
    _recalculateDefaultRefund();
  }

  @override
  void dispose() {
    _reasonNotesController.dispose();
    _refundAmountController.dispose();
    super.dispose();
  }

  double _calculateSelectedTotal() {
    double total = 0.0;
    for (int i = 0; i < widget.order.items.length; i++) {
      if (_selectedItems[i] == true) {
        final qty = _returnQuantities[i] ?? widget.order.items[i].quantity;
        total += widget.order.items[i].price * qty;
      }
    }
    return total;
  }

  void _recalculateDefaultRefund() {
    final calc = _calculateSelectedTotal();
    _refundAmountController.text = calc.toStringAsFixed(2);
  }

  bool _isFullReturn() {
    for (int i = 0; i < widget.order.items.length; i++) {
      if (_selectedItems[i] != true) return false;
      if ((_returnQuantities[i] ?? 0) < widget.order.items[i].quantity) return false;
    }
    return true;
  }

  Future<void> _submitReturn() async {
    final selectedIndices = _selectedItems.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedIndices.isEmpty) {
      HelperFun.errorSnackbar(
        title: 'alert'.tr,
        message: 'select_at_least_one_item_return'.tr,
      );
      return;
    }

    final refundAmount = double.tryParse(_refundAmountController.text.trim()) ?? _calculateSelectedTotal();
    final notes = _reasonNotesController.text.trim();
    final reasonName = _selectedReasonKey.tr;
    final fullReason = notes.isNotEmpty ? '$reasonName - $notes' : reasonName;

    final List<Map<String, dynamic>> itemsToReturn = [];
    for (final index in selectedIndices) {
      final item = widget.order.items[index];
      final returnQty = _returnQuantities[index] ?? item.quantity;
      itemsToReturn.add({
        'productId': item.productId,
        'title': item.formattedTitleWithBrand,
        'brand': item.brand,
        'sku': item.sku,
        'price': item.price,
        'quantity': returnQty,
        'selectedVariation': item.selectedVariation,
        'totalRefund': item.price * returnQty,
      });
    }

    setState(() => _isSubmitting = true);

    final cubit = context.read<OrderCubit>();
    final success = await cubit.processReturn(
      orderId: widget.order.id,
      itemsToReturn: itemsToReturn,
      refundAmount: refundAmount,
      reason: fullReason,
      restockInventory: _restockInventory,
      isFullReturn: _isFullReturn(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final calculatedTotal = _calculateSelectedTotal();

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: const Icon(Icons.assignment_return_rounded, color: Color(0xFFF97316), size: 24),
                  ),
                  const SizedBox(width: AppSizes.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'process_order_return_title'.trParams({'id': widget.order.id}),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'order_return_customer_meta'.trParams({
                            'name': widget.order.shippingAddress.name,
                            'amount': AppFormatters.formatEGP(widget.order.totalAmount),
                          }),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 2. Select Items List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'select_items_quantities_to_return'.tr,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (int i = 0; i < widget.order.items.length; i++) {
                                      _selectedItems[i] = true;
                                      _returnQuantities[i] = widget.order.items[i].quantity;
                                    }
                                    _recalculateDefaultRefund();
                                  });
                                },
                                child: Text('select_all'.tr, style: const TextStyle(fontSize: 11.5)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (int i = 0; i < widget.order.items.length; i++) {
                                      _selectedItems[i] = false;
                                    }
                                    _recalculateDefaultRefund();
                                  });
                                },
                                child: Text('unselect_all'.tr, style: const TextStyle(fontSize: 11.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Items loop
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.order.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = widget.order.items[index];
                          final isSelected = _selectedItems[index] == true;
                          final currentQty = _returnQuantities[index] ?? item.quantity;

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF97316).withValues(alpha: 0.06)
                                  : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF97316).withValues(alpha: 0.4)
                                    : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFF97316),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedItems[index] = val ?? false;
                                      _recalculateDefaultRefund();
                                    });
                                  },
                                ),
                                const SizedBox(width: 6),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.formattedTitleWithBrand,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.selectedVariation.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.selectedVariation.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        'unit_price_and_shipped_qty'.trParams({
                                          'price': AppFormatters.formatEGP(item.price),
                                          'qty': '${item.quantity}',
                                        }),
                                        style: const TextStyle(fontSize: 11, color: AppColor.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                if (isSelected) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColor.darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_rounded, size: 16),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          onPressed: currentQty > 1
                                              ? () {
                                                  setState(() {
                                                    _returnQuantities[index] = currentQty - 1;
                                                    _recalculateDefaultRefund();
                                                  });
                                                }
                                              : null,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '$currentQty',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_rounded, size: 16),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          onPressed: currentQty < item.quantity
                                              ? () {
                                                  setState(() {
                                                    _returnQuantities[index] = currentQty + 1;
                                                    _recalculateDefaultRefund();
                                                  });
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 3. Return Reason & Settings
                      Text(
                        'return_reason_and_notes'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedReasonKey,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _commonReasonKeys.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r.tr, style: const TextStyle(fontSize: 12.5)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReasonKey = val);
                        },
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _reasonNotesController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'return_notes_detail_hint'.tr,
                          filled: true,
                          fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 4. Financial & Restock Controls
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'refund_amount_label'.tr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _refundAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF97316)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                    prefixIcon: const Icon(Icons.payments_rounded, size: 18, color: Color(0xFFF97316)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  'restock_title'.tr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  'restock_desc'.tr,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                value: _restockInventory,
                                activeThumbColor: const Color(0xFF10B981),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (val) => setState(() => _restockInventory = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 20),

              // 5. Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'selected_items_total'.trParams({'amount': AppFormatters.formatEGP(calculatedTotal)}),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _isFullReturn() ? 'full_return_type'.tr : 'partial_return_type'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isFullReturn() ? const Color(0xFFF97316) : AppColor.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReturn,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(
                          _isSubmitting ? 'processing_dots'.tr : 'confirm_return_submission'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
