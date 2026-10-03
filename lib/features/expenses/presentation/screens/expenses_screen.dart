import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/expense_model.dart';
import '../cubit/expense_cubit.dart';
import '../widgets/expense_form_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedDateFilterKey = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ExpenseCubit>().loadExpenses();
  }

  void _applyQuickDateFilter(String key) {
    setState(() => _selectedDateFilterKey = key);
    final now = DateTime.now();
    final cubit = context.read<ExpenseCubit>();

    switch (key) {
      case 'today':
        cubit.filterExpenses(
          dateRange: DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday % 7));
        cubit.filterExpenses(
          dateRange: DateTimeRange(
            start: DateTime(weekStart.year, weekStart.month, weekStart.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'this_month':
        cubit.filterExpenses(
          dateRange: DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'all':
      default:
        cubit.filterExpenses(clearDateRange: true);
        break;
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final currentState = context.read<ExpenseCubit>().state;
    final currentRange = currentState is ExpenseLoaded ? currentState.selectedDateRange : null;
    final initial = currentRange?.start ?? now.subtract(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: 'select_start_date'.tr,
      cancelText: 'cancel'.tr,
      confirmText: 'confirm'.tr,
      builder: (context, child) => _buildPickerTheme(context, child!),
    );

    if (picked != null && context.mounted) {
      setState(() => _selectedDateFilterKey = 'custom');
      final currentEnd = currentRange?.end ?? now;
      final effectiveEnd = picked.isAfter(currentEnd) ? picked : currentEnd;

      context.read<ExpenseCubit>().filterExpenses(
            dateRange: DateTimeRange(
              start: picked,
              end: DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day, 23, 59, 59),
            ),
          );
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final currentState = context.read<ExpenseCubit>().state;
    final currentRange = currentState is ExpenseLoaded ? currentState.selectedDateRange : null;
    final initial = currentRange?.end ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: 'select_end_date'.tr,
      cancelText: 'cancel'.tr,
      confirmText: 'confirm'.tr,
      builder: (context, child) => _buildPickerTheme(context, child!),
    );

    if (picked != null && context.mounted) {
      setState(() => _selectedDateFilterKey = 'custom');
      final currentStart = currentRange?.start ?? picked.subtract(const Duration(days: 7));
      final effectiveStart = picked.isBefore(currentStart) ? picked : currentStart;

      context.read<ExpenseCubit>().filterExpenses(
            dateRange: DateTimeRange(
              start: DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day),
              end: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
            ),
          );
    }
  }

  Widget _buildPickerTheme(BuildContext context, Widget child) {
    final isDark = HelperFun.isDarkMode(context);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: isDark
            ? ColorScheme.dark(
                primary: AppColor.primary,
                onPrimary: Colors.white,
                surface: AppColor.darkCard,
                onSurface: AppColor.textPrimaryDark,
              )
            : ColorScheme.light(
                primary: AppColor.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColor.textPrimaryLight,
              ),
      ),
      child: child,
    );
  }

  void _confirmDeleteExpense(ExpenseModel expense) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 24),
            const SizedBox(width: 8),
            Text('delete_expense_title'.tr),
          ],
        ),
        content: Text(
          '${'delete_expense_confirm'.tr} "${expense.title}" (${AppFormatters.formatEGP(expense.amount)})؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<ExpenseCubit>().deleteExpense(expense.id);
              if (mounted) {
                HelperFun.showNotificationAlert(
                  title: 'success'.tr,
                  message: 'expense_deleted_success'.tr,
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

    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ExpenseError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ExpenseCubit>().loadExpenses(),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (state is! ExpenseLoaded) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Header
              _buildHeader(context, isDark),
              const SizedBox(height: AppSizes.md),

              // KPI Cards Row
              _buildKpisRow(state, isDark),
              const SizedBox(height: AppSizes.lg),

              // Category & Date Filter Bar
              _buildFilterBar(state, isDark),
              const SizedBox(height: AppSizes.md),

              // Data Table
              _buildDataTable(state, isDark),
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
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'expenses_title'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'expenses_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Add Expense Button
        ElevatedButton.icon(
          onPressed: () => ExpenseFormDialog.show(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'add_expense_btn'.tr,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpisRow(ExpenseLoaded state, bool isDark) {
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
              title: 'kpi_expenses_this_month'.tr,
              value: AppFormatters.formatEGP(state.thisMonthAmount),
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_expenses_today'.tr,
              value: AppFormatters.formatEGP(state.todayAmount),
              icon: Icons.today_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_expenses_filtered_total'.tr,
              value: AppFormatters.formatEGP(state.totalFilteredAmount),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColor.primary,
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_expenses_top_category'.tr,
              value: state.topCategory != null ? state.topCategory!.labelKey.tr : 'no_data_placeholder'.tr,
              icon: state.topCategory?.icon ?? Icons.category_rounded,
              color: state.topCategory?.color ?? const Color(0xFFF59E0B),
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

  Widget _buildFilterBar(ExpenseLoaded state, bool isDark) {
    final startLabel = state.selectedDateRange != null
        ? AppFormatters.formatDate(state.selectedDateRange!.start)
        : 'from_date'.tr;
    final endLabel = state.selectedDateRange != null
        ? AppFormatters.formatDate(state.selectedDateRange!.end)
        : 'to_date'.tr;

    String activePeriodLabel = 'filter_all'.tr;
    if (_selectedDateFilterKey == 'today') {
      activePeriodLabel = 'filter_today'.tr;
    } else if (_selectedDateFilterKey == 'this_week') {
      activePeriodLabel = 'filter_this_week'.tr;
    } else if (_selectedDateFilterKey == 'this_month') {
      activePeriodLabel = 'filter_this_month'.tr;
    } else if (_selectedDateFilterKey == 'custom' && state.selectedDateRange != null) {
      activePeriodLabel = '$startLabel - $endLabel';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dual Date Pickers & Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Label and active period indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range_rounded, size: 20, color: AppColor.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'filter_date_range'.tr,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Text(
                        activePeriodLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Controls: [اليوم] + [هذا الأسبوع] + [هذا الشهر] + [الكل] + Dual Pickers [من] ➔ [إلى]
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildActionButton(
                    context: context,
                    label: 'filter_today'.tr,
                    icon: Icons.today_rounded,
                    isSelected: _selectedDateFilterKey == 'today',
                    isDark: isDark,
                    onTap: () => _applyQuickDateFilter('today'),
                  ),
                  _buildActionButton(
                    context: context,
                    label: 'filter_this_week'.tr,
                    icon: Icons.view_week_rounded,
                    isSelected: _selectedDateFilterKey == 'this_week',
                    isDark: isDark,
                    onTap: () => _applyQuickDateFilter('this_week'),
                  ),
                  _buildActionButton(
                    context: context,
                    label: 'filter_this_month'.tr,
                    icon: Icons.calendar_month_rounded,
                    isSelected: _selectedDateFilterKey == 'this_month',
                    isDark: isDark,
                    onTap: () => _applyQuickDateFilter('this_month'),
                  ),
                  _buildActionButton(
                    context: context,
                    label: 'filter_all'.tr,
                    icon: Icons.all_inclusive_rounded,
                    isSelected: _selectedDateFilterKey == 'all',
                    isDark: isDark,
                    onTap: () => _applyQuickDateFilter('all'),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                  ),

                  // Calendar 1: من تاريخ
                  _buildDatePickerPill(
                    context: context,
                    prefixText: 'from_label'.tr,
                    dateText: startLabel,
                    isDark: isDark,
                    isActive: _selectedDateFilterKey == 'custom',
                    onTap: () => _pickStartDate(context),
                  ),

                  // Arrow Separator
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),

                  // Calendar 2: إلى تاريخ
                  _buildDatePickerPill(
                    context: context,
                    prefixText: 'to_label'.tr,
                    dateText: endLabel,
                    isDark: isDark,
                    isActive: _selectedDateFilterKey == 'custom',
                    onTap: () => _pickEndDate(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.sm),

          // 2. Category Filter Chips
          Row(
            children: [
              Text(
                'expense_category'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('filter_all_categories'.tr),
                        selected: state.selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<ExpenseCubit>().filterExpenses(clearCategory: true);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ...ExpenseCategory.values.map((cat) {
                        final isSelected = state.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                            label: Text(cat.labelKey.tr),
                            selected: isSelected,
                            selectedColor: cat.color,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              context.read<ExpenseCubit>().filterExpenses(
                                category: selected ? cat : null,
                                clearCategory: !selected,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerPill({
    required BuildContext context,
    required String prefixText,
    required String dateText,
    required bool isDark,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isActive
              ? AppColor.primary.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isActive ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: isActive ? AppColor.primary : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              prefixText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppColor.primary
                    : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(ExpenseLoaded state, bool isDark) {
    final rows = state.filteredExpenses.map((expense) {
      return DataRow(
        cells: [
          // 1. Date & Time
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppFormatters.formatDate(expense.date),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppFormatters.formatTime(expense.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          // 2. Title
          DataCell(
            Text(
              expense.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),

          // 3. Category Badge
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: expense.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: expense.category.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(expense.category.icon, size: 14, color: expense.category.color),
                  const SizedBox(width: 4),
                  Text(
                    expense.category.labelKey.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: expense.category.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Amount (EGP)
          DataCell(
            Text(
              AppFormatters.formatEGP(expense.amount),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: AppColor.error,
              ),
            ),
          ),

          // 5. Payment Method
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'payment_method_${expense.paymentMethod}'.tr,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 6. Recorded By
          DataCell(
            Text(
              expense.recordedBy,
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // 7. Notes
          DataCell(
            Text(
              expense.notes.isNotEmpty ? expense.notes : 'no_notes'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 8. Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'edit'.tr,
                  splashRadius: 18,
                  onPressed: () => ExpenseFormDialog.show(context, expense: expense),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                  tooltip: 'delete'.tr,
                  splashRadius: 18,
                  onPressed: () => _confirmDeleteExpense(expense),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return CustomDataTable(
      title: 'expenses_list_title'.tr,
      subtitle: '${state.filteredExpenses.length} ${'records_found'.tr}',
      searchHint: 'search_expenses_hint'.tr,
      onSearchChanged: (q) => context.read<ExpenseCubit>().filterExpenses(query: q),
      columns: [
        DataTableColumn(label: 'date_time'.tr),
        DataTableColumn(label: 'expense_title'.tr),
        DataTableColumn(label: 'expense_category'.tr),
        DataTableColumn(label: 'expense_amount_egp'.tr, isNumeric: true),
        DataTableColumn(label: 'payment_method'.tr),
        DataTableColumn(label: 'expense_recorded_by'.tr),
        DataTableColumn(label: 'notes'.tr),
        DataTableColumn(label: 'actions'.tr),
      ],
      rows: rows,
      emptyMessage: 'no_expenses_found'.tr,
      emptyIcon: Icons.receipt_long_outlined,
      emptyAction: ElevatedButton.icon(
        onPressed: () => ExpenseFormDialog.show(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('add_first_expense'.tr),
      ),
    );
  }
}
