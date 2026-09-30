import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/payroll_slip_model.dart';
import '../../data/models/salary_advance_model.dart';
import '../cubit/employee_cubit.dart';
import '../cubit/employee_state.dart';
import '../widgets/disburse_payroll_dialog.dart';
import '../widgets/employee_form_dialog.dart';
import '../widgets/salary_advance_form_dialog.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<EmployeeCubit>().loadEmployeesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeleteEmployee(EmployeeModel employee) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 24),
            const SizedBox(width: 8),
            Text('delete_employee_title'.tr),
          ],
        ),
        content: Text('${"delete_employee_confirm".tr} "${employee.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<EmployeeCubit>().deleteEmployee(employee.id);
              if (mounted) {
                HelperFun.showNotificationAlert(
                  title: 'success'.tr,
                  message: 'employee_deleted_success'.tr,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAdvance(SalaryAdvanceModel advance) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 24),
            const SizedBox(width: 8),
            Text('delete_advance_title'.tr),
          ],
        ),
        content: Text('${"delete_advance_confirm".tr} (${AppFormatters.formatEGP(advance.amount)}) ${"for_employee".tr} ${advance.employeeName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<EmployeeCubit>().deleteAdvance(advance.id);
              if (mounted) {
                HelperFun.showNotificationAlert(
                  title: 'success'.tr,
                  message: 'advance_deleted_success'.tr,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayroll(PayrollSlipModel slip) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 24),
            const SizedBox(width: 8),
            Text('delete_payroll_title'.tr),
          ],
        ),
        content: Text('${"delete_payroll_confirm".tr} "${slip.employeeName}" (${slip.monthPeriod})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<EmployeeCubit>().deletePayrollSlip(slip);
              if (mounted) {
                HelperFun.showNotificationAlert(
                  title: 'success'.tr,
                  message: 'payroll_deleted_success'.tr,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        if (state is EmployeeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is EmployeeError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<EmployeeCubit>().loadEmployeesData(),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (state is! EmployeeLoaded) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: AppSizes.md),

              // KPI Cards
              _buildKpisRow(state, isDark),
              const SizedBox(height: AppSizes.lg),

              // Tab Bar & Month Selector Bar
              _buildTabBarAndMonthFilter(state, isDark),
              const SizedBox(height: AppSizes.md),

              // Tab Views
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Employees List
                    _buildEmployeesTable(state, isDark),

                    // Tab 2: Salary Advances
                    _buildAdvancesTable(state, isDark),

                    // Tab 3: Payroll Slips History
                    _buildPayrollTable(state, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'employees_management_title'.tr,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'employees_management_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Actions Row
        Wrap(
          spacing: 8,
          children: [
            // Disburse Payroll Button
            ElevatedButton.icon(
              onPressed: () => DisbursePayrollDialog.show(context),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(
                'disburse_payroll_btn'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
              ),
            ),

            // Disburse Advance Button
            ElevatedButton.icon(
              onPressed: () => SalaryAdvanceFormDialog.show(context),
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: Text(
                'disburse_advance_btn'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
              ),
            ),

            // Add Employee Button
            ElevatedButton.icon(
              onPressed: () => EmployeeFormDialog.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'add_employee_btn'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpisRow(EmployeeLoaded state, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final cardWidth = isMobile
            ? (constraints.maxWidth - AppSizes.sm) / 2
            : (constraints.maxWidth - (AppSizes.md * 3)) / 4;

        return Wrap(
          spacing: isMobile ? AppSizes.sm : AppSizes.md,
          runSpacing: AppSizes.sm,
          children: [
            _buildKpiCard(
              title: 'kpi_total_monthly_salaries'.tr,
              value: AppFormatters.formatEGP(state.totalMonthlyBaseSalaries),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_current_month_advances'.tr,
              value: AppFormatters.formatEGP(state.totalAdvancesInSelectedMonth),
              icon: Icons.payments_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_disbursed_salaries_this_month'.tr,
              value: AppFormatters.formatEGP(state.totalPaidSalariesInSelectedMonth),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_active_employees_count'.tr,
              value: '${state.activeEmployeesCount} ${"employees".tr}',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSizes.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarAndMonthFilter(EmployeeLoaded state, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tab Bar
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColor.primary,
              labelColor: AppColor.primary,
              unselectedLabelColor: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              tabs: [
                Tab(
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  text: '${"employees_tab".tr} (${state.allEmployees.length})',
                ),
                Tab(
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  text: '${"advances_tab".tr} (${state.allAdvances.length})',
                ),
                Tab(
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  text: '${"payroll_tab".tr} (${state.allPayrollSlips.length})',
                ),
              ],
            ),
          ),

          // Active Month Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColor.primary),
                const SizedBox(width: 6),
                Text(
                  '${"month_period".tr}: ${state.selectedMonthPeriod}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTable(EmployeeLoaded state, bool isDark) {
    final columns = [
      DataTableColumn(label: 'employee_name'.tr),
      DataTableColumn(label: 'job_title_position'.tr),
      DataTableColumn(label: 'employee_phone'.tr),
      DataTableColumn(label: 'base_monthly_salary'.tr, isNumeric: true),
      DataTableColumn(label: 'current_month_advances'.tr, isNumeric: true),
      DataTableColumn(label: 'net_salary_due'.tr, isNumeric: true),
      DataTableColumn(label: 'status'.tr),
      DataTableColumn(label: 'actions'.tr),
    ];

    final rows = state.filteredEmployees.map((emp) {
      final unsettledAdvances = state.getUnsettledAdvancesAmountForEmployee(emp.id);
      final netEstimated = (emp.baseSalary - unsettledAdvances).clamp(0.0, double.infinity);
      final hasDisbursedPayroll = state.getPayrollSlipForEmployee(emp.id) != null;

      return DataRow(
        cells: [
          // 1. Name & National ID
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emp.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                if (emp.nationalId.isNotEmpty)
                  Text(
                    emp.nationalId,
                    style: TextStyle(fontSize: 10.5, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                  ),
              ],
            ),
          ),

          // 2. Job Title
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                emp.jobTitle,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
              ),
            ),
          ),

          // 3. Phone
          DataCell(Text(emp.phone, style: const TextStyle(fontSize: 12))),

          // 4. Base Salary
          DataCell(
            Text(
              AppFormatters.formatEGP(emp.baseSalary),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),

          // 5. Unsettled Advances
          DataCell(
            Text(
              unsettledAdvances > 0 ? AppFormatters.formatEGP(unsettledAdvances) : AppFormatters.formatEGP(0),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: unsettledAdvances > 0 ? const Color(0xFFF59E0B) : Colors.grey,
              ),
            ),
          ),

          // 6. Net Estimated Salary
          DataCell(
            Text(
              AppFormatters.formatEGP(netEstimated),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            ),
          ),

          // 7. Status Badge
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (emp.isActive ? const Color(0xFF10B981) : AppColor.error).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                emp.isActive ? 'active'.tr : 'inactive'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: emp.isActive ? const Color(0xFF10B981) : AppColor.error,
                ),
              ),
            ),
          ),

          // 8. Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Disburse Payroll Button
                IconButton(
                  icon: Icon(
                    hasDisbursedPayroll ? Icons.receipt_long_rounded : Icons.payments_rounded,
                    size: 18,
                    color: hasDisbursedPayroll ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                  tooltip: hasDisbursedPayroll ? 'payroll_already_disbursed'.tr : 'disburse_payroll_btn'.tr,
                  onPressed: () => DisbursePayrollDialog.show(context, initialEmployee: emp),
                ),

                // Quick Advance Button
                IconButton(
                  icon: const Icon(Icons.add_card_rounded, size: 18, color: Color(0xFFF59E0B)),
                  tooltip: 'disburse_advance_btn'.tr,
                  onPressed: () => SalaryAdvanceFormDialog.show(context, initialEmployee: emp),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColor.primary),
                  tooltip: 'edit'.tr,
                  onPressed: () => EmployeeFormDialog.show(context, employee: emp),
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                  tooltip: 'delete'.tr,
                  onPressed: () => _confirmDeleteEmployee(emp),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return CustomDataTable(
      title: 'employees_list_title'.tr,
      subtitle: '${state.filteredEmployees.length} ${"records_found".tr}',
      searchHint: 'search_employees_hint'.tr,
      onSearchChanged: (q) => context.read<EmployeeCubit>().filterEmployees(query: q),
      columns: columns,
      rows: rows,
      emptyMessage: 'no_employees_found'.tr,
      emptyIcon: Icons.badge_outlined,
      emptyAction: ElevatedButton.icon(
        onPressed: () => EmployeeFormDialog.show(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('add_employee_btn'.tr),
      ),
    );
  }

  Widget _buildAdvancesTable(EmployeeLoaded state, bool isDark) {
    final columns = [
      DataTableColumn(label: 'date_time'.tr),
      DataTableColumn(label: 'employee_name'.tr),
      DataTableColumn(label: 'advance_amount_egp'.tr, isNumeric: true),
      DataTableColumn(label: 'month_period'.tr),
      DataTableColumn(label: 'payment_method'.tr),
      DataTableColumn(label: 'status'.tr),
      DataTableColumn(label: 'disbursed_by'.tr),
      DataTableColumn(label: 'notes'.tr),
      DataTableColumn(label: 'actions'.tr),
    ];

    final rows = state.allAdvances.map((adv) {
      return DataRow(
        cells: [
          DataCell(Text(AppFormatters.formatDateTime(adv.date), style: const TextStyle(fontSize: 12))),
          DataCell(Text(adv.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          DataCell(
            Text(
              AppFormatters.formatEGP(adv.amount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
            ),
          ),
          DataCell(Text(adv.monthPeriod, style: const TextStyle(fontSize: 12))),
          DataCell(Text('payment_method_${adv.paymentMethod}'.tr, style: const TextStyle(fontSize: 11.5))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (adv.isDeductedFromPayroll ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                adv.isDeductedFromPayroll ? 'deducted_from_payroll'.tr : 'pending_deduction'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: adv.isDeductedFromPayroll ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
          DataCell(Text(adv.disbursedBy, style: const TextStyle(fontSize: 11.5))),
          DataCell(Text(adv.notes.isNotEmpty ? adv.notes : 'no_notes'.tr, style: const TextStyle(fontSize: 11.5))),
          DataCell(
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
              tooltip: 'delete'.tr,
              onPressed: () => _confirmDeleteAdvance(adv),
            ),
          ),
        ],
      );
    }).toList();

    return CustomDataTable(
      title: 'advances_list_title'.tr,
      subtitle: '${state.allAdvances.length} ${"records_found".tr}',
      columns: columns,
      rows: rows,
      emptyMessage: 'no_advances_found'.tr,
      emptyIcon: Icons.payments_outlined,
      emptyAction: ElevatedButton.icon(
        onPressed: () => SalaryAdvanceFormDialog.show(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('disburse_advance_btn'.tr),
      ),
    );
  }

  Widget _buildPayrollTable(EmployeeLoaded state, bool isDark) {
    final columns = [
      DataTableColumn(label: 'payment_date'.tr),
      DataTableColumn(label: 'month_period'.tr),
      DataTableColumn(label: 'employee_name'.tr),
      DataTableColumn(label: 'base_monthly_salary'.tr, isNumeric: true),
      DataTableColumn(label: 'bonuses_and_rewards'.tr, isNumeric: true),
      DataTableColumn(label: 'advances_deducted'.tr, isNumeric: true),
      DataTableColumn(label: 'penalties_and_deductions'.tr, isNumeric: true),
      DataTableColumn(label: 'net_paid'.tr, isNumeric: true),
      DataTableColumn(label: 'payment_method'.tr),
      DataTableColumn(label: 'disbursed_by'.tr),
      DataTableColumn(label: 'actions'.tr),
    ];

    final rows = state.allPayrollSlips.map((slip) {
      return DataRow(
        cells: [
          DataCell(Text(DateFormat('yyyy/MM/dd').format(slip.paymentDate), style: const TextStyle(fontSize: 12))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(slip.monthPeriod, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColor.primary)),
            ),
          ),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slip.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(slip.jobTitle, style: TextStyle(fontSize: 10.5, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight)),
              ],
            ),
          ),
          DataCell(Text(AppFormatters.formatEGP(slip.baseSalary), style: const TextStyle(fontSize: 12))),
          DataCell(
            Text(
              '+ ${AppFormatters.formatEGP(slip.totalBonuses)}',
              style: TextStyle(fontSize: 12, color: slip.totalBonuses > 0 ? const Color(0xFF10B981) : Colors.grey),
            ),
          ),
          DataCell(
            Text(
              '- ${AppFormatters.formatEGP(slip.totalAdvances)}',
              style: TextStyle(fontSize: 12, color: slip.totalAdvances > 0 ? const Color(0xFFF59E0B) : Colors.grey),
            ),
          ),
          DataCell(
            Text(
              '- ${AppFormatters.formatEGP(slip.totalDeductions)}',
              style: TextStyle(fontSize: 12, color: slip.totalDeductions > 0 ? AppColor.error : Colors.grey),
            ),
          ),
          DataCell(
            Text(
              AppFormatters.formatEGP(slip.netSalary),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
            ),
          ),
          DataCell(Text('payment_method_${slip.paymentMethod}'.tr, style: const TextStyle(fontSize: 11.5))),
          DataCell(Text(slip.disbursedBy, style: const TextStyle(fontSize: 11.5))),
          DataCell(
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
              tooltip: 'delete'.tr,
              onPressed: () => _confirmDeletePayroll(slip),
            ),
          ),
        ],
      );
    }).toList();

    return CustomDataTable(
      title: 'payroll_slips_history_title'.tr,
      subtitle: '${state.allPayrollSlips.length} ${"records_found".tr}',
      columns: columns,
      rows: rows,
      emptyMessage: 'no_payroll_slips_found'.tr,
      emptyIcon: Icons.receipt_long_outlined,
      emptyAction: ElevatedButton.icon(
        onPressed: () => DisbursePayrollDialog.show(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('disburse_payroll_btn'.tr),
      ),
    );
  }
}
