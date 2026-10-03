import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardDateFilterBar extends StatelessWidget {
  final DashboardAnalyticsModel analytics;

  const DashboardDateFilterBar({super.key, required this.analytics});

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = analytics.filterStartDate ?? now.subtract(const Duration(days: 7));

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
      final currentEnd = analytics.filterEndDate ?? now;
      final effectiveEnd = picked.isAfter(currentEnd) ? picked : currentEnd;

      context.read<DashboardCubit>().changePeriod(
            DashboardPeriodType.custom,
            customStart: picked,
            customEnd: effectiveEnd,
          );
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = analytics.filterEndDate ?? now;

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
      final currentStart = analytics.filterStartDate ?? picked.subtract(const Duration(days: 7));
      final effectiveStart = picked.isBefore(currentStart) ? picked : currentStart;

      context.read<DashboardCubit>().changePeriod(
            DashboardPeriodType.custom,
            customStart: effectiveStart,
            customEnd: picked,
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

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final activePeriod = analytics.periodType;
    final dateFormat = DateFormat('yyyy/MM/dd');

    final startLabel = analytics.filterStartDate != null
        ? dateFormat.format(analytics.filterStartDate!)
        : 'from_date'.tr;
    final endLabel = analytics.filterEndDate != null
        ? dateFormat.format(analytics.filterEndDate!)
        : 'to_date'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
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
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // 1. Label and Active Period Status
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
                    'dashboard_date_filter_title'.tr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  Text(
                    activePeriod == DashboardPeriodType.today
                        ? 'filter_today'.tr
                        : (activePeriod == DashboardPeriodType.allTime
                            ? 'filter_all'.tr
                            : (analytics.filterStartDate != null ? '$startLabel - $endLabel' : 'filter_all'.tr)),
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

          // 2. Simplified Controls: [اليوم] + Dual Date Pickers [من تاريخ] -> [إلى تاريخ] + [الكل]
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Button 1: اليوم (Today)
              _buildActionButton(
                context: context,
                label: 'filter_today'.tr,
                icon: Icons.today_rounded,
                isSelected: activePeriod == DashboardPeriodType.today,
                isDark: isDark,
                onTap: () => context.read<DashboardCubit>().changePeriod(DashboardPeriodType.today),
              ),

              // Button 2: كافة الفترات (All Time)
              _buildActionButton(
                context: context,
                label: 'filter_all'.tr,
                icon: Icons.all_inclusive_rounded,
                isSelected: activePeriod == DashboardPeriodType.allTime,
                isDark: isDark,
                onTap: () => context.read<DashboardCubit>().changePeriod(DashboardPeriodType.allTime),
              ),

              Container(
                height: 24,
                width: 1,
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                margin: const EdgeInsets.symmetric(horizontal: 2),
              ),

              // Calendar 1: من تاريخ (Start Date)
              _buildDatePickerPill(
                context: context,
                prefixText: 'from_label'.tr,
                dateText: startLabel,
                isDark: isDark,
                isActive: activePeriod == DashboardPeriodType.custom,
                onTap: () => _pickStartDate(context),
              ),

              // Arrow Separator
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),

              // Calendar 2: إلى تاريخ (End Date)
              _buildDatePickerPill(
                context: context,
                prefixText: 'to_label'.tr,
                dateText: endLabel,
                isDark: isDark,
                isActive: activePeriod == DashboardPeriodType.custom,
                onTap: () => _pickEndDate(context),
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
}
