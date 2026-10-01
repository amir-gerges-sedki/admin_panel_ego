import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/erp_report_models.dart';

class SupplierPurchasesReportTab extends StatelessWidget {
  final List<SupplierPurchasesReportModel> suppliers;

  const SupplierPurchasesReportTab({super.key, required this.suppliers});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currency = AppLocalizations.of(context).translate('currency_egp');

    if (suppliers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            AppLocalizations.of(context).translate('no_suppliers_found'),
            style: TextStyle(
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('supplier_purchasing_summary'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${suppliers.length} ${AppLocalizations.of(context).translate('active_suppliers')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              ),
              columns: [
                DataColumn(label: Text(AppLocalizations.of(context).translate('supplier_name'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('invoices_count'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('total_purchases'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('total_paid'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('balance_due'))),
              ],
              rows: suppliers.map((s) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        s.supplierName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    DataCell(Text('${s.invoiceCount}')),
                    DataCell(Text('${s.totalPurchases.toStringAsFixed(2)} $currency')),
                    DataCell(Text('${s.totalPaid.toStringAsFixed(2)} $currency')),
                    DataCell(
                      Text(
                        '${s.balanceDue.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: s.balanceDue > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
