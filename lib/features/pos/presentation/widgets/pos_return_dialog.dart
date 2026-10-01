import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../utils/pos_receipt_printer.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/shift_cubit.dart';

class PosReturnDialog extends StatefulWidget {
  const PosReturnDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<PosCubit>()),
          BlocProvider.value(value: context.read<ShiftCubit>()),
        ],
        child: const PosReturnDialog(),
      ),
    );
  }

  @override
  State<PosReturnDialog> createState() => _PosReturnDialogState();
}

class _PosReturnDialogState extends State<PosReturnDialog> {
  final TextEditingController _invoiceSearchController = TextEditingController();
  final TextEditingController _reasonNotesController = TextEditingController();
  final TextEditingController _refundAmountController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  bool _isSubmitting = false;
  OrderModel? _matchedOrder;
  String? _searchError;

  Map<int, bool> _selectedItems = {};
  Map<int, int> _returnQuantities = {};
  String _selectedReasonKey = 'reason_defective';
  String _refundPaymentMethod = 'cash';
  bool _restockInventory = true;
  bool _autoPrintReceipt = true;

  static const List<String> _commonReasonKeys = [
    'reason_defective',
    'reason_wrong_item',
    'reason_customer_changed_mind',
    'reason_cashier_error',
    'reason_flavor_swap',
    'reason_other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _invoiceSearchController.dispose();
    _reasonNotesController.dispose();
    _refundAmountController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchInvoice() async {
    final query = _invoiceSearchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _matchedOrder = null;
    });

    try {
      final clean = query.replaceAll('#', '').trim();
      final firestore = FirebaseService.firestore;

      // 1. Try finding by direct document ID
      final idVariants = [query, clean, '#$clean', 'POS-$clean', 'POS-$query'];
      DocumentSnapshot<Map<String, dynamic>>? docSnap;

      for (final idVar in idVariants) {
        try {
          final s = await firestore.collection('Orders').doc(idVar).get();
          if (s.exists) {
            docSnap = s;
            break;
          }
        } catch (_) {}
      }

      // 2. Query by orderId / orderNumber
      if (docSnap == null) {
        try {
          final qSnap = await firestore
              .collection('Orders')
              .where('orderNumber', whereIn: idVariants)
              .limit(1)
              .get();
          if (qSnap.docs.isNotEmpty) {
            docSnap = qSnap.docs.first;
          }
        } catch (_) {}
      }

      if (docSnap == null) {
        try {
          final qSnap = await firestore
              .collection('Orders')
              .where('orderId', whereIn: idVariants)
              .limit(1)
              .get();
          if (qSnap.docs.isNotEmpty) {
            docSnap = qSnap.docs.first;
          }
        } catch (_) {}
      }

      if (docSnap != null && docSnap.exists) {
        final data = docSnap.data() ?? {};
        data['id'] = docSnap.id;
        final order = OrderModel.fromJson(data);

        setState(() {
          _matchedOrder = order;
          _selectedItems = {
            for (int i = 0; i < order.items.length; i++) i: true,
          };
          _returnQuantities = {
            for (int i = 0; i < order.items.length; i++) i: order.items[i].quantity,
          };
          _recalculateDefaultRefund();
        });
      } else {
        setState(() {
          _searchError = 'invoice_not_found_err'.trParams({'query': query});
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'search_error_prefix'.trParams({'error': e.toString()});
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  double _calculateSelectedTotal() {
    if (_matchedOrder == null) return 0.0;
    double total = 0.0;
    for (int i = 0; i < _matchedOrder!.items.length; i++) {
      if (_selectedItems[i] == true) {
        final qty = _returnQuantities[i] ?? _matchedOrder!.items[i].quantity;
        total += _matchedOrder!.items[i].price * qty;
      }
    }
    return total;
  }

  void _recalculateDefaultRefund() {
    final calc = _calculateSelectedTotal();
    _refundAmountController.text = calc.toStringAsFixed(2);
  }

  bool _isFullReturn() {
    if (_matchedOrder == null) return false;
    for (int i = 0; i < _matchedOrder!.items.length; i++) {
      if (_selectedItems[i] != true) return false;
      if ((_returnQuantities[i] ?? 0) < _matchedOrder!.items[i].quantity) return false;
    }
    return true;
  }

  Future<void> _submitPosReturn() async {
    if (_matchedOrder == null) return;

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
      final item = _matchedOrder!.items[index];
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

    try {
      final orderRepo = OrderRepositoryImpl();
      await orderRepo.processOrderReturn(
        orderId: _matchedOrder!.id,
        itemsToReturn: itemsToReturn,
        refundAmount: refundAmount,
        reason: fullReason,
        restockInventory: _restockInventory,
        isFullReturn: _isFullReturn(),
        performedBy: 'Cashier POS',
      );

      // Deduct refund from active shift drawer if a shift is running
      if (mounted) {
        context.read<ShiftCubit>().recordShiftReturn(
              amount: refundAmount,
              paymentMethod: _refundPaymentMethod,
            );
      }

      // Print thermal return receipt if requested
      if (_autoPrintReceipt) {
        PosReceiptPrinter.printThermalReturnReceipt(
          orderNumber: _matchedOrder!.id,
          returnedItems: itemsToReturn,
          refundAmount: refundAmount,
          reason: fullReason,
          cashierName: _matchedOrder!.cashierName.isNotEmpty ? _matchedOrder!.cashierName : 'Branch Staff',
          customerName: _matchedOrder!.shippingAddress.name,
        );
      }

      if (mounted) {
        HelperFun.showNotificationAlert(
          title: 'pos_return_success_title'.tr,
          message: 'pos_return_success_msg'.trParams({
            'count': '${itemsToReturn.length}',
            'amount': AppFormatters.formatEGP(refundAmount),
          }),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        HelperFun.errorSnackbar(
          title: 'pos_return_failed_title'.tr,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
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
                          'pos_branch_returns_title'.tr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'pos_branch_returns_desc'.tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
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

              // 2. Invoice Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _invoiceSearchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchInvoice(),
                      decoration: InputDecoration(
                        hintText: 'scan_or_type_invoice_hint'.tr,
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFFF97316)),
                        suffixIcon: _invoiceSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _invoiceSearchController.clear();
                                    _matchedOrder = null;
                                    _searchError = null;
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchInvoice,
                    icon: _isSearching
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded, size: 16),
                    label: Text('search_invoice_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),

              if (_searchError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColor.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColor.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: const TextStyle(fontSize: 12, color: AppColor.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.sm + 4),

              // 3. Matched Invoice Content
              if (_matchedOrder != null) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Invoice Meta Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'invoice_title_num'.trParams({'id': _matchedOrder!.id}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'invoice_date_prefix'.trParams({
                                      'date': AppFormatters.formatDateTime(_matchedOrder!.orderDate),
                                      'customer': _matchedOrder!.shippingAddress.name,
                                    }),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'original_total'.trParams({'amount': AppFormatters.formatEGP(_matchedOrder!.totalAmount)}),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColor.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // Selectable Items
                        Text(
                          'select_items_quantities_to_return'.tr,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _matchedOrder!.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _matchedOrder!.items[index];
                            final isSelected = _selectedItems[index] == true;
                            final currentQty = _returnQuantities[index] ?? item.quantity;

                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF97316).withValues(alpha: 0.06)
                                    : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                                borderRadius: BorderRadius.circular(10),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.formattedTitleWithBrand,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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
                                          'item_price_and_purchased_qty'.trParams({
                                            'price': AppFormatters.formatEGP(item.price),
                                            'qty': '${item.quantity}',
                                          }),
                                          style: const TextStyle(fontSize: 11, color: AppColor.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
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

                        // Reason and Refund Controls
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'return_reason_label'.tr,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedReasonKey,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: _commonReasonKeys.map((r) {
                                      return DropdownMenuItem(value: r, child: Text(r.tr, style: const TextStyle(fontSize: 12)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedReasonKey = val);
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _reasonNotesController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'return_notes_hint'.tr,
                                      filled: true,
                                      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _refundPaymentMethod,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 'cash', child: Text('refund_cash'.tr, style: const TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'card', child: Text('refund_card'.tr, style: const TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'credit', child: Text('refund_store_credit'.tr, style: const TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _refundPaymentMethod = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Options Checkboxes
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('restock_items_to_inventory'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                value: _restockInventory,
                                dense: true,
                                activeColor: const Color(0xFF10B981),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _restockInventory = val ?? true),
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('print_thermal_return_receipt'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                value: _autoPrintReceipt,
                                dense: true,
                                activeColor: const Color(0xFFF97316),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _autoPrintReceipt = val ?? true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 20),

                // 4. Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'refund_amount_summary'.trParams({
                        'amount': AppFormatters.formatEGP(double.tryParse(_refundAmountController.text) ?? 0.0),
                      }),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFF97316)),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  if (context.mounted && Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: Text('cancel'.tr),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitPosReturn,
                          icon: _isSubmitting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 16),
                          label: Text(
                            _isSubmitting ? 'processing_dots'.tr : 'confirm_return_and_print'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // Empty Prompt
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 12),
                        Text(
                          'pos_return_initial_prompt'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
