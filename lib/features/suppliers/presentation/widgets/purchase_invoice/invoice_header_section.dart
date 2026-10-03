import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/formatters/formatters.dart';
import '../../../../../core/helper/helper_fun.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../settings/data/models/store_branch_model.dart';
import '../../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../data/models/supplier_model.dart';
import '../../cubit/supplier_cubit.dart';
import '../../cubit/supplier_state.dart';
import '../supplier_form_dialog.dart';

class InvoiceHeaderSection extends StatelessWidget {
  final SupplierModel? selectedSupplier;
  final ValueChanged<SupplierModel?> onSupplierChanged;
  final String? targetBranchId;
  final ValueChanged<StoreBranchModel?> onBranchChanged;
  final TextEditingController invoiceNumberController;
  final DateTime invoiceDate;
  final ValueChanged<DateTime> onInvoiceDateChanged;
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onDueDateChanged;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;

  const InvoiceHeaderSection({
    super.key,
    required this.selectedSupplier,
    required this.onSupplierChanged,
    this.targetBranchId,
    required this.onBranchChanged,
    required this.invoiceNumberController,
    required this.invoiceDate,
    required this.onInvoiceDateChanged,
    required this.dueDate,
    required this.onDueDateChanged,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Supplier Picker & Invoice #
        BlocBuilder<SupplierCubit, SupplierState>(
          builder: (context, supState) {
            final suppliers = supState is SupplierLoaded
                ? supState.suppliers.where((s) => s.isActive).toList()
                : <SupplierModel>[];

            final currentSupId = selectedSupplier?.id;
            final hasMatch = suppliers.any((s) => s.id == currentSupId);
            final effectiveSupId = hasMatch
                ? currentSupId
                : (suppliers.isNotEmpty ? suppliers.first.id : null);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'supplier_vendor_required'.tr,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          InkWell(
                            onTap: () => SupplierFormDialog.show(context),
                            child: Text(
                              'btn_new_supplier_short'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('sup_$effectiveSupId'),
                        initialValue: effectiveSupId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon:
                              Icon(Icons.business_rounded, size: 18),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: suppliers.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final found = suppliers
                                .where((s) => s.id == id)
                                .firstOrNull;
                            onSupplierChanged(found);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, settingsState) {
                      final branches = settingsState is SettingsLoaded &&
                              settingsState.settings.branches.isNotEmpty
                          ? settingsState.settings.branches
                          : [
                              const StoreBranchModel(
                                id: 'main_branch',
                                name: 'المخزن الرئيسي / الفرع الرئيسي',
                                isPrimary: true,
                              ),
                            ];

                      final effectiveBranchId = targetBranchId != null &&
                              branches.any((b) => b.id == targetBranchId)
                          ? targetBranchId
                          : (branches.isNotEmpty
                              ? branches.first.id
                              : 'main_branch');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'target_branch_label'.tr,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: ValueKey('branch_$effectiveBranchId'),
                            initialValue: effectiveBranchId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon:
                                  Icon(Icons.warehouse_rounded, size: 18),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: branches.map((b) {
                              return DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final found = branches
                                    .where((b) => b.id == id)
                                    .firstOrNull;
                                onBranchChanged(found);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'invoice_number_label_req'.tr,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.tag_rounded, size: 18),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Dates & Payment Method
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'invoice_date_label'.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        onInvoiceDateChanged(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColor.darkBorder
                              : AppColor.lightBorder,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(AppFormatters.formatDate(invoiceDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'due_date_optional'.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        onDueDateChanged(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColor.darkBorder
                              : AppColor.lightBorder,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(dueDate != null
                              ? AppFormatters.formatDate(dueDate!)
                              : 'immediate_or_open'.tr),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'payment_method_label_col'.tr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('pm_$paymentMethod'),
                    initialValue: paymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      'Cash',
                      'Instapay',
                      'Bank Transfer',
                      'Vodafone Cash',
                      'Cheque'
                    ].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        onPaymentMethodChanged(val ?? 'Cash'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
