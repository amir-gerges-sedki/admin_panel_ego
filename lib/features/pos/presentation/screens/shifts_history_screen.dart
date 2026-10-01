import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/shift_cubit.dart';
import '../cubit/shift_state.dart';
import '../widgets/open_shift_dialog.dart';

class ShiftsHistoryScreen extends StatefulWidget {
  const ShiftsHistoryScreen({super.key});

  @override
  State<ShiftsHistoryScreen> createState() => _ShiftsHistoryScreenState();
}

class _ShiftsHistoryScreenState extends State<ShiftsHistoryScreen> {
  String _selectedBranch = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ShiftCubit>().loadShiftsHistory();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        final shifts = state.historyShifts.where((s) {
          if (_selectedBranch != 'ALL' && s.branchId != _selectedBranch) {
            return false;
          }
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            final matchesCashier = s.cashierName.toLowerCase().contains(q);
            final matchesBranch = s.branchName.toLowerCase().contains(q);
            final matchesId = s.id.toLowerCase().contains(q);
            if (!matchesCashier && !matchesBranch && !matchesId) return false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: CustomDataTable(
            title: AppLocalizations.of(context).translate('cashier_shifts_title'),
            subtitle: AppLocalizations.of(context).translate('cashier_shifts_subtitle'),
            searchHint: AppLocalizations.of(context).translate('search_shifts_hint'),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            filterWidget: _buildBranchFilter(isDark),
            trailingHeaderAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && context.mounted) {
                      context.read<ShiftCubit>().loadShiftsHistory(
                            startDate: picked.start,
                            endDate: picked.end,
                          );
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(AppLocalizations.of(context).translate('filter_date_range')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: AppSizes.sm),
                  ),
                ),
                const SizedBox(width: 8),
                if (!state.hasActiveShift)
                  ElevatedButton.icon(
                    onPressed: () => OpenShiftDialog.show(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(AppLocalizations.of(context).translate('open_shift_btn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                  ),
              ],
            ),
            columns: [
              DataTableColumn(label: AppLocalizations.of(context).translate('branch_name')),
              DataTableColumn(label: AppLocalizations.of(context).translate('cashier_name')),
              DataTableColumn(label: AppLocalizations.of(context).translate('shift_start_time')),
              DataTableColumn(label: AppLocalizations.of(context).translate('opening_drawer_cash')),
              DataTableColumn(label: AppLocalizations.of(context).translate('pos_cash_sales')),
              DataTableColumn(label: AppLocalizations.of(context).translate('total_sales')),
              DataTableColumn(label: AppLocalizations.of(context).translate('difference_reconciliation')),
              DataTableColumn(label: AppLocalizations.of(context).translate('shift_status')),
            ],
            rows: shifts.map((s) {
              final diff = s.difference ?? 0.0;
              final isClosed = s.isClosed;

              return DataRow(
                cells: [
                  // Branch
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_rounded, size: 15, color: AppColor.primary),
                        const SizedBox(width: 6),
                        Text(s.branchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                  ),

                  // Cashier
                  DataCell(Text(s.cashierName, style: const TextStyle(fontSize: 12))),

                  // Start Time
                  DataCell(
                    Text(
                      '${s.openedAt.day}/${s.openedAt.month} ${s.openedAt.hour.toString().padLeft(2, '0')}:${s.openedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),

                  // Opening Cash
                  DataCell(Text(AppFormatters.formatEGP(s.openingCash), style: const TextStyle(fontSize: 12))),

                  // Cash Sales
                  DataCell(Text(AppFormatters.formatEGP(s.cashSales), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),

                  // Total Sales
                  DataCell(
                    Text(
                      AppFormatters.formatEGP(s.totalSales),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary),
                    ),
                  ),

                  // Difference Reconciliation
                  DataCell(
                    !isClosed
                        ? Text(
                            AppLocalizations.of(context).translate('shift_in_progress'),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: diff.abs() < 0.01
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : (diff > 0
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              diff.abs() < 0.01
                                  ? AppLocalizations.of(context).translate('drawer_balanced')
                                  : '${diff > 0 ? '+' : ''}${AppFormatters.formatEGP(diff)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: diff.abs() < 0.01
                                    ? const Color(0xFF10B981)
                                    : (diff > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                              ),
                            ),
                          ),
                  ),

                  // Status Chip
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.isOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.isOpen
                            ? AppLocalizations.of(context).translate('shift_open')
                            : AppLocalizations.of(context).translate('shift_closed'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: s.isOpen ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBranchFilter(bool isDark) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        List<StoreBranchModel> branches = [];
        if (settingsState is SettingsLoaded) {
          branches = settingsState.settings.branches;
        }

        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBranch,
              dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColor.textPrimaryLight,
              ),
              items: [
                DropdownMenuItem(
                  value: 'ALL',
                  child: Text(AppLocalizations.of(context).translate('all_branches')),
                ),
                ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedBranch = val);
              },
            ),
          ),
        );
      },
    );
  }
}
