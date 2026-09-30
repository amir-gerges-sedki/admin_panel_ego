import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/damaged_stock_model.dart';
import '../cubit/damaged_stock_cubit.dart';
import '../cubit/damaged_stock_state.dart';
import '../widgets/damaged_stock_details_dialog.dart';
import '../widgets/damaged_stock_form_dialog.dart';

class DamagedStockScreen extends StatefulWidget {
  const DamagedStockScreen({super.key});

  @override
  State<DamagedStockScreen> createState() => _DamagedStockScreenState();
}

class _DamagedStockScreenState extends State<DamagedStockScreen> {
  String _selectedDateFilterKey = 'all';

  @override
  void initState() {
    super.initState();
    context.read<DamagedStockCubit>().loadDamagedStock();
  }

  void _applyQuickDateFilter(String key) {
    setState(() => _selectedDateFilterKey = key);
    final now = DateTime.now();
    final cubit = context.read<DamagedStockCubit>();

    switch (key) {
      case 'today':
        cubit.filterDamagedStock(
          dateRange: DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday % 7));
        cubit.filterDamagedStock(
          dateRange: DateTimeRange(
            start: DateTime(weekStart.year, weekStart.month, weekStart.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'this_month':
        cubit.filterDamagedStock(
          dateRange: DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
        );
        break;
      case 'all':
      default:
        cubit.filterDamagedStock(clearDateRange: true);
        break;
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final currentState = context.read<DamagedStockCubit>().state;
    final currentRange = currentState is DamagedStockLoaded ? currentState.selectedDateRange : null;
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

      context.read<DamagedStockCubit>().filterDamagedStock(
            dateRange: DateTimeRange(
              start: picked,
              end: DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day, 23, 59, 59),
            ),
          );
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final currentState = context.read<DamagedStockCubit>().state;
    final currentRange = currentState is DamagedStockLoaded ? currentState.selectedDateRange : null;
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

      context.read<DamagedStockCubit>().filterDamagedStock(
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
            ? const ColorScheme.dark(
                primary: AppColor.primary,
                onPrimary: Colors.white,
                surface: AppColor.darkCard,
                onSurface: AppColor.textPrimaryDark,
              )
            : const ColorScheme.light(
                primary: AppColor.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColor.textPrimaryLight,
              ),
      ),
      child: child,
    );
  }

  void _confirmDeleteDamaged(DamagedStockModel record) {
    bool restoreStock = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 24),
              const SizedBox(width: 8),
              Text('delete_damage_record_title'.tr),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${"delete_damage_record_confirm".tr} "${record.productTitle}" (${record.quantity} ${"units".tr})؟',
              ),
              const SizedBox(height: AppSizes.md),
              CheckboxListTile(
                value: restoreStock,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColor.primary,
                title: Text(
                  'restore_stock_on_delete'.tr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'restore_stock_on_delete_subtitle'.tr,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onChanged: (val) {
                  setDialogState(() => restoreStock = val ?? true);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<DamagedStockCubit>().deleteDamage(
                      record,
                      restoreProductStock: restoreStock,
                    );
                if (mounted) {
                  HelperFun.showNotificationAlert(
                    title: 'success'.tr,
                    message: 'damage_record_deleted_success'.tr,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
              child: Text('delete'.tr),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<DamagedStockCubit, DamagedStockState>(
      builder: (context, state) {
        if (state is DamagedStockLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DamagedStockError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<DamagedStockCubit>().loadDamagedStock(),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        if (state is! DamagedStockLoaded) {
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

              // Reason & Date Filter Bar
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'damaged_stock_title'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'damaged_stock_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Log Damaged Stock Button
        ElevatedButton.icon(
          onPressed: () => DamagedStockFormDialog.show(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'log_damage_btn'.tr,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
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

  Widget _buildKpisRow(DamagedStockLoaded state, bool isDark) {
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
              title: 'kpi_total_damage_loss'.tr,
              value: AppFormatters.formatEGP(state.totalFilteredLoss),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_total_damaged_units'.tr,
              value: '${state.totalFilteredUnits} ${"units".tr}',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_this_month_damage_loss'.tr,
              value: AppFormatters.formatEGP(state.thisMonthLoss),
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'kpi_top_damage_reason'.tr,
              value: state.topReason != null ? state.topReason!.labelKey.tr : 'no_data_placeholder'.tr,
              icon: state.topReason?.icon ?? Icons.category_rounded,
              color: state.topReason?.color ?? const Color(0xFFF59E0B),
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

  Widget _buildFilterBar(DamagedStockLoaded state, bool isDark) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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

          // 2. Reason Filter Chips
          Row(
            children: [
              Text(
                'damage_reason'.tr,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('filter_all_reasons'.tr),
                        selected: state.selectedReason == null,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<DamagedStockCubit>().filterDamagedStock(clearReason: true);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ...DamagedReason.values.map((reason) {
                        final isSelected = state.selectedReason == reason;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            avatar: Icon(
                              reason.icon,
                              size: 15,
                              color: isSelected ? Colors.white : reason.color,
                            ),
                            label: Text(reason.labelKey.tr),
                            selected: isSelected,
                            selectedColor: reason.color,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : null,
                            ),
                            onSelected: (selected) {
                              context.read<DamagedStockCubit>().filterDamagedStock(
                                    reason: selected ? reason : null,
                                    clearReason: !selected,
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
          const SizedBox(height: AppSizes.sm),

          // 3. Search Bar
          TextFormField(
            initialValue: state.searchQuery,
            decoration: InputDecoration(
              hintText: 'search_damaged_stock_hint'.tr,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => context.read<DamagedStockCubit>().filterDamagedStock(query: ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
            ),
            onChanged: (q) => context.read<DamagedStockCubit>().filterDamagedStock(query: q),
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
          color: isSelected ? AppColor.primary : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
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
            color: isActive ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
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
                color: isActive ? AppColor.primary : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? (isDark ? Colors.white : Colors.black87) : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(DamagedStockLoaded state, bool isDark) {
    if (state.filteredDamaged.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.xxl),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                size: 56,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'no_damaged_stock_found'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'no_damaged_stock_subtitle'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final columns = [
      DataTableColumn(label: 'date_and_time'.tr),
      DataTableColumn(label: 'product_name'.tr),
      DataTableColumn(label: 'sku_barcode'.tr),
      DataTableColumn(label: 'damage_quantity'.tr, isNumeric: true),
      DataTableColumn(label: 'cost_price_per_unit'.tr, isNumeric: true),
      DataTableColumn(label: 'total_damage_financial_loss'.tr, isNumeric: true),
      DataTableColumn(label: 'damage_reason'.tr),
      DataTableColumn(label: 'recorded_by'.tr),
      DataTableColumn(label: 'actions'.tr),
    ];

    final rows = state.filteredDamaged.map((record) {
      return DataRow(
        cells: [
          // 1. Date & Time
          DataCell(
            Text(
              AppFormatters.formatDateTime(record.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // 2. Product Name & Variation
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.productTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.variationAttributes.isNotEmpty)
                  Text(
                    record.variationAttributes.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
              ],
            ),
          ),

          // 3. SKU
          DataCell(
            Text(
              record.variationSku.isNotEmpty ? record.variationSku : 'no_data_placeholder'.tr,
              style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
            ),
          ),

          // 4. Quantity
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${record.quantity} ${"units".tr}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
              ),
            ),
          ),

          // 5. Unit Cost Price
          DataCell(
            Text(
              AppFormatters.formatEGP(record.costPrice),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // 6. Total Loss
          DataCell(
            Text(
              AppFormatters.formatEGP(record.totalLoss),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEF4444),
              ),
            ),
          ),

          // 7. Reason Badge
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.reason.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(record.reason.icon, size: 13, color: record.reason.color),
                  const SizedBox(width: 4),
                  Text(
                    record.reason.labelKey.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: record.reason.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 8. Recorded By
          DataCell(
            Text(
              record.recordedBy,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),

          // 9. Actions
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColor.primary),
                  tooltip: 'view_details'.tr,
                  onPressed: () => DamagedStockDetailsDialog.show(context, record),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                  tooltip: 'delete'.tr,
                  onPressed: () => _confirmDeleteDamaged(record),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return CustomDataTable(
      title: 'damaged_stock_title'.tr,
      subtitle: '${state.filteredDamaged.length} ${"records_found".tr}',
      searchHint: 'search_damaged_stock_hint'.tr,
      onSearchChanged: (q) => context.read<DamagedStockCubit>().filterDamagedStock(query: q),
      columns: columns,
      rows: rows,
      emptyMessage: 'no_damaged_stock_found'.tr,
      emptyIcon: Icons.delete_sweep_outlined,
      emptyAction: ElevatedButton.icon(
        onPressed: () => DamagedStockFormDialog.show(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('log_damage_btn'.tr),
      ),
    );
  }
}
