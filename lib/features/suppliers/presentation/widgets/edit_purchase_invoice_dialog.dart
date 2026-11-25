import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../cubit/supplier_cubit.dart';

/// Modal dialog allowing the Super Admin to update an existing purchase invoice's
/// payment status, paid amount, payment method, due date, and notes.
class EditPurchaseInvoiceDialog extends StatefulWidget {
  final PurchaseInvoiceModel invoice;

  const EditPurchaseInvoiceDialog({
    super.key,
    required this.invoice,
  });

  static Future<void> show(
    BuildContext context, {
    required PurchaseInvoiceModel invoice,
  }) {
    final cubit = context.read<SupplierCubit>();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit,
        child: EditPurchaseInvoiceDialog(invoice: invoice),
      ),
    );
  }

  @override
  State<EditPurchaseInvoiceDialog> createState() => _EditPurchaseInvoiceDialogState();
}

class _EditPurchaseInvoiceDialogState extends State<EditPurchaseInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _paidAmountController;
  late TextEditingController _notesController;
  late String _paymentMethod;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _paidAmountController = TextEditingController(
      text: widget.invoice.paidAmount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.invoice.notes);
    _paymentMethod = widget.invoice.paymentMethod.isNotEmpty ? widget.invoice.paymentMethod : 'Cash';
    _dueDate = widget.invoice.dueDate;
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _enteredPaid => double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  double get _computedRemaining => (widget.invoice.totalAmount - _enteredPaid).clamp(0.0, double.infinity);

  InvoicePaymentStatus get _computedStatus {
    if (_computedRemaining <= 0) {
      return InvoicePaymentStatus.paid;
    }
    if (_enteredPaid > 0) {
      return InvoicePaymentStatus.partial;
    }
    return InvoicePaymentStatus.unpaid;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);
    try {
      final updatedInvoice = widget.invoice.copyWith(
        paidAmount: _enteredPaid,
        remainingAmount: _computedRemaining,
        paymentStatus: _computedStatus,
        paymentMethod: _paymentMethod,
        dueDate: _dueDate,
        notes: _notesController.text.trim(),
      );

      await context.read<SupplierCubit>().updatePurchaseInvoice(
        updatedInvoice,
        oldPaidAmount: widget.invoice.paidAmount,
        oldTotalAmount: widget.invoice.totalAmount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعديل بيانات الفاتورة والمبالغ المسددة بنجاح.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.showNotificationAlert(
          title: 'خطأ',
          message: 'فشل تعديل الفاتورة: $e',
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 650 ? 580.0 : width - 32;

    Color statusColor;
    String statusText;
    switch (_computedStatus) {
      case InvoicePaymentStatus.paid:
        statusColor = const Color(0xFF10B981);
        statusText = 'مسددة بالكامل';
        break;
      case InvoicePaymentStatus.partial:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'سداد جزئي';
        break;
      case InvoicePaymentStatus.unpaid:
        statusColor = const Color(0xFFEF4444);
        statusText = 'غير مدفوعة (آجل)';
        break;
      case InvoicePaymentStatus.overdue:
        statusColor = const Color(0xFFDC2626);
        statusText = 'متأخرة السداد';
        break;
    }

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
        child: Form(
          key: _formKey,
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
                        color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعديل الفاتورة والسداد (${widget.invoice.invoiceNumber})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'المورد: ${widget.invoice.supplierName} • تاريخ الفاتورة: ${AppFormatters.formatDate(widget.invoice.invoiceDate)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
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

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'إجمالي قيمة الفاتورة:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  AppFormatters.formatEGP(widget.invoice.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('حالة السداد المحسوبة: ', style: TextStyle(fontSize: 12)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text('المتبقي للمورد: ', style: TextStyle(fontSize: 12)),
                                    Text(
                                      AppFormatters.formatEGP(_computedRemaining),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: _computedRemaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Editable Paid Amount
                      TextFormField(
                        controller: _paidAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'المبلغ المدفوع فعلياً (ج.م) *',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.payments_rounded, size: 18, color: Color(0xFF0D9488)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          helperText: 'عدّل المبلغ المسدد إذا سجلت الدفع بالخطأ.',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'يرجى إدخال المبلغ المدفوع';
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || numVal < 0) return 'المبلغ غير صحيح';
                          if (numVal > widget.invoice.totalAmount) {
                            return 'المبلغ المدفوع لا يمكن أن يتجاوز إجمالي الفاتورة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Quick set buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.money_off_rounded, size: 14, color: Color(0xFFEF4444)),
                            label: const Text('غير مدفوعة (0 ج.م)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () {
                              setState(() {
                                _paidAmountController.text = '0';
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF10B981)),
                            label: Text(
                              'مدفوعة بالكامل (${widget.invoice.totalAmount.toStringAsFixed(0)} ج.م)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              setState(() {
                                _paidAmountController.text = widget.invoice.totalAmount.toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: 'طريقة الدفع *',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('كاش / نقدي')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('تحويل بنكي / حساب')),
                          DropdownMenuItem(value: 'Deferred', child: Text('آجل / على دفعات')),
                          DropdownMenuItem(value: 'Wallet', child: Text('فودافون كاش / إنستاباي')),
                          DropdownMenuItem(value: 'Check', child: Text('شيك مصرفي')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات الفاتورة والتعديل',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintText: 'مثال: تم تصحيح سداد الفاتورة لعدم دفع المبلغ بالكامل...',
                          hintStyle: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
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
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text(
                        'حفظ التعديلات',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: _isSubmitting ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
