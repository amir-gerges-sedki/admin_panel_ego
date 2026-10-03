import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/shift_cubit.dart';
import '../cubit/shift_state.dart';
import 'close_shift_dialog.dart';
import 'open_shift_dialog.dart';
import 'shift_cash_entry_dialog.dart';
import 'today_movement_dialog.dart';

class ActiveShiftBanner extends StatelessWidget {
  const ActiveShiftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        final shift = state.activeShift;

        if (shift == null || !shift.isOpen) {
          // No active shift warning banner
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('no_active_shift_warning'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => OpenShiftDialog.show(context),
                  icon: const Icon(Icons.access_time_filled_rounded, size: 14),
                  label: Text(AppLocalizations.of(context).translate('open_shift_btn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        // Active shift status bar
        final expCash = shift.calculatedExpectedCash;
        final durationHours = shift.duration.inHours;
        final durationMinutes = shift.duration.inMinutes % 60;
        final durationStr = '${durationHours}h ${durationMinutes}m';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : AppColor.lightCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              // Active Indicator Pulse
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Branch & Cashier
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        shift.branchName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shift.cashierName,
                          style: const TextStyle(fontSize: 10.5, color: AppColor.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${AppLocalizations.of(context).translate('shift_duration')}: $durationStr',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Sales Summary Chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatBadge(
                    label: AppLocalizations.of(context).translate('expected_drawer_cash'),
                    value: AppFormatters.formatEGP(expCash),
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildStatBadge(
                    label: AppLocalizations.of(context).translate('total_sales'),
                    value: AppFormatters.formatEGP(shift.totalSales),
                    color: AppColor.primary,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Today's Movement Modal Trigger
                  OutlinedButton.icon(
                    onPressed: () => TodayMovementDialog.show(context, shift: shift),
                    icon: const Icon(Icons.analytics_outlined, size: 14, color: AppColor.primary),
                    label: Text(
                      AppLocalizations.of(context).translate('btn_today_movement'),
                      style: const TextStyle(color: AppColor.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      side: BorderSide(color: AppColor.primary.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () => ShiftCashEntryDialog.show(context, shift: shift, isCashIn: true),
                    icon: const Icon(Icons.swap_vert_rounded, size: 14),
                    label: Text(AppLocalizations.of(context).translate('cash_in_out_btn')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => CloseShiftDialog.show(context, shift),
                    icon: const Icon(Icons.lock_rounded, size: 14),
                    label: Text(AppLocalizations.of(context).translate('close_shift_btn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
