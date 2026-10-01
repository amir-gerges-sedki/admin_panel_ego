import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/supplier_payment_model.dart';

class RecordPaymentDialog extends StatefulWidget {
  final SupplierModel? initialSupplier;
  final PurchaseInvoiceModel? initialInvoice;

  const RecordPaymentDialog({
    super.key,
    this.initialSupplier,
    this.initialInvoice,
  });

  static void show(
    BuildContext context, {
    SupplierModel? initialSupplier,
    PurchaseInvoiceModel? initialInvoice,
  }) {
    final cubit = context.read<SupplierCubit>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: RecordPaymentDialog(
          initialSupplier: initialSupplier,
          initialInvoice: initialInvoice,
        ),
      ),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  SupplierModel? _selectedSupplier;
  PurchaseInvoiceModel? _selectedInvoice;
  late TextEditingController _amountController;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'Cash';
  late TextEditingController _referenceController;
  late TextEditingController _notesController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.initialSupplier;
    _selectedInvoice = widget.initialInvoice;

    final defaultAmount = widget.initialInvoice != null
        ? widget.initialInvoice!.remainingAmount.toStringAsFixed(0)
        : (widget.initialSupplier != null && widget.initialSupplier!.balanceDue > 0
            ? widget.initialSupplier!.balanceDue.toStringAsFixed(0)
            : '0');

    _amountController = TextEditingController(text: defaultAmount);
    _referenceController = TextEditingController();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SupplierCubit>().state;
      if (state is SupplierLoaded && _selectedSupplier == null && state.suppliers.isNotEmpty) {
        setState(() => _selectedSupplier = state.suppliers.first);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplier == null) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'please_select_supplier_warning'.tr,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'enter_valid_amount_warning'.tr,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cubit = context.read<SupplierCubit>();
      final payment = SupplierPaymentModel(
        id: '',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        invoiceId: _selectedInvoice?.id,
        invoiceNumber: _selectedInvoice?.invoiceNumber,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await cubit.recordPayment(payment);

      if (mounted) {
        Navigator.pop(context);
        HelperFun.successSnackbar(
          'payment_recorded_title'.tr,
          'payment_recorded_msg'.tr,
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
    final dialogWidth = width > 600 ? 560.0 : width - 32;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        side: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 750),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'record_payment_voucher_title'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'record_payment_voucher_desc'.tr,
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

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supplier Picker
                      BlocBuilder<SupplierCubit, SupplierState>(
                        builder: (context, supState) {
                          final suppliers = supState is SupplierLoaded
                              ? supState.suppliers
                              : <SupplierModel>[];

                          final currentSupId = _selectedSupplier?.id;
                          final hasMatch = suppliers.any((s) => s.id == currentSupId);
                          final effectiveSupId = hasMatch
                              ? currentSupId
                              : (suppliers.isNotEmpty ? suppliers.first.id : null);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'supplier_payee_req'.tr,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: ValueKey('sup_$effectiveSupId'),
                                initialValue: effectiveSupId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.business_rounded, size: 18),
                                ),
                                items: suppliers.map((s) {
                                  final dueLabel = 'balance_due_badge'.trParams({'amount': AppFormatters.formatEGP(s.balanceDue)});
                                  return DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text('${s.name} $dueLabel'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    final found = suppliers.where((s) => s.id == val).firstOrNull;
                                    _selectedSupplier = found;
                                    _selectedInvoice = null;
                                    if (found != null && found.balanceDue > 0) {
                                      _amountController.text = found.balanceDue.toStringAsFixed(0);
                                    }
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Linked Invoice (Optional)
                      BlocBuilder<SupplierCubit, SupplierState>(
                        builder: (context, supState) {
                          final invoices = (supState is SupplierLoaded && _selectedSupplier != null)
                              ? supState.invoices
                                  .where((i) =>
                                      i.supplierId == _selectedSupplier!.id &&
                                      i.remainingAmount > 0)
                                  .toList()
                              : <PurchaseInvoiceModel>[];

                          if (invoices.isEmpty) return const SizedBox.shrink();

                          final currentInvId = _selectedInvoice?.id;
                          final hasMatch = invoices.any((i) => i.id == currentInvId);
                          final effectiveInvId = hasMatch ? currentInvId : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'link_invoice_optional'.tr,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String?>(
                                key: ValueKey('inv_$effectiveInvId'),
                                initialValue: effectiveInvId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.receipt_rounded, size: 18),
                                ),
                                hint: Text('general_account_payout'.tr),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('general_account_payout'.tr),
                                  ),
                                  ...invoices.map((inv) {
                                    final remLabel = 'remaining_badge'.trParams({'amount': AppFormatters.formatEGP(inv.remainingAmount)});
                                    return DropdownMenuItem<String?>(
                                      value: inv.id,
                                      child: Text('${inv.invoiceNumber} $remLabel'),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    final inv = invoices.where((i) => i.id == val).firstOrNull;
                                    _selectedInvoice = inv;
                                    if (inv != null) {
                                      _amountController.text = inv.remainingAmount.toStringAsFixed(0);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],
                          );
                        },
                      ),

                      // Amount & Payment Method
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'amount_paid_req'.tr,
                                prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                suffixText: 'EGP',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'amount_is_required'.tr;
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num <= 0) {
                                  return 'invalid_amount'.tr;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('pm_$_paymentMethod'),
                              initialValue: _paymentMethod,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'payment_method_field'.tr,
                                isDense: true,
                              ),
                              items: ['Cash', 'Instapay', 'Bank Transfer', 'Vodafone Cash', 'Cheque'].map((m) {
                                return DropdownMenuItem(value: m, child: Text(m));
                              }).toList(),
                              onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                            ),
                          ),
                        ],
                      ),
                      if ((_selectedInvoice != null && _selectedInvoice!.remainingAmount > 0) ||
                          (_selectedSupplier != null && _selectedSupplier!.balanceDue > 0)) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (_selectedInvoice != null && _selectedInvoice!.remainingAmount > 0) ...[
                              InkWell(
                                onTap: () {
                                  final rem = _selectedInvoice!.remainingAmount;
                                  _amountController.text = rem % 1 == 0 ? rem.toInt().toString() : rem.toStringAsFixed(2);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${'pay_full_btn'.tr} (${AppFormatters.formatEGP(_selectedInvoice!.remainingAmount)})',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (_selectedSupplier != null && _selectedSupplier!.balanceDue > 0) ...[
                              InkWell(
                                onTap: () {
                                  final bal = _selectedSupplier!.balanceDue;
                                  _amountController.text = bal % 1 == 0 ? bal.toInt().toString() : bal.toStringAsFixed(2);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${'pay_vendor_btn'.tr} (${AppFormatters.formatEGP(_selectedSupplier!.balanceDue)})',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.primary),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSizes.md),

                      // Date & Reference #
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => _paymentDate = picked);
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
                                    Text(AppFormatters.formatDate(_paymentDate)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _referenceController,
                              decoration: InputDecoration(
                                labelText: 'tx_ref_label'.tr,
                                hintText: 'e.g. IP-89218',
                                prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'payment_notes_field'.tr,
                          hintText: 'payment_notes_hint'.tr,
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
                      backgroundColor: const Color(0xFFF59E0B),
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
                      'confirm_payment_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
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
