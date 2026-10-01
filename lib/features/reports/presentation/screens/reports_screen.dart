import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/expenses_report_tab.dart';
import '../widgets/inventory_valuation_report_tab.dart';
import '../widgets/sales_performance_report_tab.dart';
import '../widgets/supplier_purchases_report_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<ReportsCubit>().loadReport(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selection Bar
                  _buildPeriodFilterBar(context, state, isDark),
                  const SizedBox(height: 16),

                  // Tab Buttons (Sales, Inventory, Suppliers, Expenses)
                  _buildTabSelectionBar(context, state, isDark),
                  const SizedBox(height: 20),

                  if (state.status == ReportsStatus.loading &&
                      state.report.topProducts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildActiveTabContent(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTabContent(ReportsState state) {
    switch (state.selectedTab) {
      case ReportTab.sales:
        return SalesPerformanceReportTab(products: state.report.topProducts);
      case ReportTab.inventory:
        return InventoryValuationReportTab(
          valuation: state.report.inventoryValuation,
        );
      case ReportTab.suppliers:
        return SupplierPurchasesReportTab(
          suppliers: state.report.supplierPurchases,
        );
      case ReportTab.expenses:
        return ExpensesReportTab(
          categories: state.report.expenseCategories,
        );
    }
  }

  Widget _buildPeriodFilterBar(
    BuildContext context,
    ReportsState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('report_period'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              ReportPeriod.today,
              ReportPeriod.thisWeek,
              ReportPeriod.thisMonth,
              ReportPeriod.lastMonth,
              ReportPeriod.thisYear,
              ReportPeriod.custom,
              ReportPeriod.allTime,
            ].map((period) {
              final isSelected = state.selectedPeriod == period;
              return ChoiceChip(
                label: Text(
                  AppLocalizations.of(context).isArabic
                      ? period.arabicLabel
                      : period.englishLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColor.primary,
                backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                onSelected: (selected) async {
                  if (selected) {
                    if (period == ReportPeriod.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(
                          start: state.customStartDate,
                          end: state.customEndDate,
                        ),
                      );
                      if (picked != null && context.mounted) {
                        context.read<ReportsCubit>().loadReport(
                              period: ReportPeriod.custom,
                              customStart: picked.start,
                              customEnd: picked.end,
                            );
                      }
                    } else {
                      context.read<ReportsCubit>().loadReport(period: period);
                    }
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelectionBar(
    BuildContext context,
    ReportsState state,
    bool isDark,
  ) {
    final tabs = [
      (ReportTab.sales, AppLocalizations.of(context).translate('sales_and_margins'), Icons.trending_up_rounded),
      (ReportTab.inventory, AppLocalizations.of(context).translate('inventory_valuation'), Icons.inventory_2_rounded),
      (ReportTab.suppliers, AppLocalizations.of(context).translate('supplier_procurement'), Icons.business_rounded),
      (ReportTab.expenses, AppLocalizations.of(context).translate('expense_analysis'), Icons.pie_chart_rounded),
    ];

    return Row(
      children: tabs.map((t) {
        final isSelected = state.selectedTab == t.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () => context.read<ReportsCubit>().setTab(t.$1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.primary.withValues(alpha: 0.15)
                    : (isDark ? AppColor.darkCard : AppColor.lightCard),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColor.primary
                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    t.$3,
                    size: 16,
                    color: isSelected
                        ? AppColor.primary
                        : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppColor.primary
                          : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
