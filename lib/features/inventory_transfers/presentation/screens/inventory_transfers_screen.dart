import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/stock_transfer_model.dart';
import '../cubit/stock_transfer_cubit.dart';
import '../cubit/stock_transfer_state.dart';
import '../widgets/stock_transfer_hub_dialog.dart';

class InventoryTransfersScreen extends StatefulWidget {
  const InventoryTransfersScreen({super.key});

  @override
  State<InventoryTransfersScreen> createState() => _InventoryTransfersScreenState();
}

class _InventoryTransfersScreenState extends State<InventoryTransfersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd • hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockTransferCubit>().loadTransfers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColor.darkSurface : AppColor.lightSurface,
      body: BlocConsumer<StockTransferCubit, StockTransferState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            HelperFun.showNotificationAlert(
              title: 'transfer_dialog_title'.tr,
              message: state.errorMessage!,
            );
            context.read<StockTransferCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            HelperFun.showNotificationAlert(
              title: 'transfer_dialog_title'.tr,
              message: state.successMessage!,
            );
            context.read<StockTransferCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header & Action Controls
                _buildHeader(isDark, state),
                const SizedBox(height: AppSizes.md),

                // 2. Summary KPI Metric Cards
                _buildSummaryKpis(isDark, state),
                const SizedBox(height: AppSizes.md),

                // 3. Search Bar & Status Chips Filter
                _buildFiltersBar(isDark, state),
                const SizedBox(height: AppSizes.md),

                // 4. Main Transfers Table / List
                Expanded(
                  child: state.isLoading && state.transfers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.filteredTransfers.isEmpty
                          ? _buildEmptyView(isDark)
                          : _buildTransfersTable(context, state, isDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, StockTransferState state) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF06B6D4), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'transfer_screen_title'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                'transfer_screen_subtitle'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
              ),
            ],
          ),
        ),

        // Branch Filter Dropdown
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            List<StoreBranchModel> branches = [];
            if (settingsState is SettingsLoaded) {
              branches = settingsState.settings.branches;
            }

            return Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.selectedBranchId,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('all_branches_warehouses'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                    ...branches.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        )),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      context.read<StockTransferCubit>().filterByBranch(val);
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),

        // Refresh Button
        IconButton(
          onPressed: () => context.read<StockTransferCubit>().loadTransfers(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'reload'.tr,
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // New Transfer Request Button
        ElevatedButton.icon(
          onPressed: () => StockTransferHubDialog.show(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('transfer_create_new_btn'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryKpis(bool isDark, StockTransferState state) {
    final total = state.transfers.length;
    final pending = state.transfers.where((t) => t.status == StockTransferStatus.pending).length;
    final inTransit = state.transfers.where((t) => t.status == StockTransferStatus.inTransit).length;
    final received = state.transfers.where((t) => t.status == StockTransferStatus.received).length;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'transfer_kpi_total'.tr,
            value: '$total',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _buildKpiCard(
            title: 'transfer_kpi_pending'.tr,
            value: '$pending',
            icon: Icons.schedule_rounded,
            color: const Color(0xFFEAB308),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _buildKpiCard(
            title: 'transfer_kpi_in_transit'.tr,
            value: '$inTransit',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _buildKpiCard(
            title: 'transfer_kpi_received'.tr,
            value: '$received',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(bool isDark, StockTransferState state) {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => context.read<StockTransferCubit>().setSearchQuery(val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'transfer_search_hint'.tr,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  borderSide: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  borderSide: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),

        // Status Tabs / Filter Chips
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(null, 'all'.tr, isDark, state.statusFilter == null),
                ...StockTransferStatus.values.map((status) {
                  return _buildStatusFilterChip(
                    status,
                    status.labelKey.tr,
                    isDark,
                    state.statusFilter == status,
                    color: status.color,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChip(
    StockTransferStatus? status,
    String label,
    bool isDark,
    bool isSelected, {
    Color? color,
  }) {
    final effectiveColor = color ?? AppColor.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => context.read<StockTransferCubit>().filterByStatus(status),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor.withValues(alpha: 0.15) : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: Border.all(
              color: isSelected ? effectiveColor : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? effectiveColor : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransfersTable(BuildContext context, StockTransferState state, bool isDark) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (!isDesktop) {
      return ListView.separated(
        itemCount: state.filteredTransfers.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          final transfer = state.filteredTransfers[index];
          return _buildMobileCard(context, transfer, isDark);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: SingleChildScrollView(
          child: DataTable(
            horizontalMargin: 16,
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(
              isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            ),
            columns: [
              DataColumn(label: Text('transfer_col_number'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_from'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_to'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_items'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_priority'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_status'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_date'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('transfer_col_actions'.tr, style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
            rows: state.filteredTransfers.map((t) => _buildDataRow(context, t, isDark)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, StockTransferModel t, bool isDark) {
    return DataRow(
      cells: [
        // 1. Transfer Number
        DataCell(
          Text(
            t.transferNumber,
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColor.primary),
          ),
        ),

        // 2. From Branch
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(t.fromBranchName, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        // 3. To Branch
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppColor.primary),
              const SizedBox(width: 6),
              Text(t.toBranchName, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),

        // 4. Items Count
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${t.items.length} ${'items'.tr} (${t.totalRequestedItems} pcs)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColor.primary),
            ),
          ),
        ),

        // 5. Priority
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.priority.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              t.priority.labelKey.tr,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.priority.color),
            ),
          ),
        ),

        // 6. Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: t.status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.status.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.status.icon, size: 14, color: t.status.color),
                const SizedBox(width: 4),
                Text(
                  t.status.labelKey.tr,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.status.color),
                ),
              ],
            ),
          ),
        ),

        // 7. Date
        DataCell(
          Text(
            _dateFormat.format(t.createdAt),
            style: TextStyle(fontSize: 11.5, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
          ),
        ),

        // 8. Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Details Button
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                tooltip: 'details'.tr,
                onPressed: () => _showTransferDetailsDialog(context, t),
              ),

              // Approve Action (if pending)
              if (t.status == StockTransferStatus.pending)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF3B82F6)),
                  tooltip: 'transfer_action_approve'.tr,
                  onPressed: () => _handleApprove(context, t),
                ),

              // Dispatch Action (if approved)
              if (t.status == StockTransferStatus.approved)
                IconButton(
                  icon: const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF8B5CF6)),
                  tooltip: 'transfer_action_dispatch'.tr,
                  onPressed: () => _handleDispatch(context, t),
                ),

              // Receive Action (if in transit)
              if (t.status == StockTransferStatus.inTransit)
                IconButton(
                  icon: const Icon(Icons.task_alt_rounded, size: 18, color: Color(0xFF10B981)),
                  tooltip: 'transfer_confirm_receipt_btn'.tr,
                  onPressed: () => _handleReceive(context, t),
                ),

              // Cancel / Reject Action (if pending)
              if (t.status == StockTransferStatus.pending)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColor.error),
                  tooltip: 'transfer_action_reject'.tr,
                  onPressed: () => _handleReject(context, t),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCard(BuildContext context, StockTransferModel t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.transferNumber, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColor.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(t.status.labelKey.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.status.color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${t.fromBranchName} ➔ ${t.toBranchName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${t.items.length} ${'items'.tr} (${t.totalRequestedItems} pcs)', style: const TextStyle(fontSize: 11.5)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dateFormat.format(t.createdAt), style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
              TextButton.icon(
                onPressed: () => _showTransferDetailsDialog(context, t),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text('details'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
          const SizedBox(height: 12),
          Text(
            'transfer_no_records'.tr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, StockTransferModel t) async {
    final cubit = context.read<StockTransferCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_action_approve'.tr),
        content: Text('transfer_approve_confirm_msg'.tr.replaceAll('{num}', t.transferNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
            child: Text('transfer_action_approve'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      await cubit.approveTransfer(t.id, performedBy: 'Admin');
    }
  }

  Future<void> _handleDispatch(BuildContext context, StockTransferModel t) async {
    final cubit = context.read<StockTransferCubit>();
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_action_dispatch'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('transfer_dispatch_confirm_msg'.tr.replaceAll('{num}', t.transferNumber)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                hintText: 'transfer_courier_notes_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            child: Text('transfer_action_dispatch'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      await cubit.dispatchTransfer(t.id, performedBy: 'Admin', notes: notesCtrl.text.trim());
    }
    notesCtrl.dispose();
  }

  Future<void> _handleReceive(BuildContext context, StockTransferModel t) async {
    final cubit = context.read<StockTransferCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_confirm_receipt_title'.tr),
        content: Text('transfer_confirm_receipt_msg'.tr.replaceAll('{num}', t.transferNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: Text('transfer_confirm_btn'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      await cubit.receiveTransfer(t.id, performedBy: 'Admin');
    }
  }

  Future<void> _handleReject(BuildContext context, StockTransferModel t) async {
    final cubit = context.read<StockTransferCubit>();
    final reasonCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_action_reject'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('transfer_reject_confirm_msg'.tr),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'transfer_reject_reason_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('transfer_action_reject'.tr),
          ),
        ],
      ),
    );

    if (ok == true) {
      await cubit.rejectTransfer(t.id, performedBy: 'Admin', reason: reasonCtrl.text.trim());
    }
    reasonCtrl.dispose();
  }

  void _showTransferDetailsDialog(BuildContext context, StockTransferModel t) {
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        child: Container(
          width: 640,
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.transferNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColor.primary),
                      ),
                      Text(
                        '${t.fromBranchName} ➔ ${t.toBranchName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t.status.labelKey.tr,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.status.color),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Requested Items List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: t.items.length,
                  separatorBuilder: (c, idx) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = t.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: item.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.image,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (c, err, stack) => const Icon(Icons.inventory_2_outlined),
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined, color: AppColor.primary),
                      title: Text(item.productTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        item.variationAttributes.isNotEmpty
                            ? item.variationAttributes.entries.map((e) => '${e.key}: ${e.value}').join(' | ')
                            : (item.variationSku.isNotEmpty ? 'SKU: ${item.variationSku}' : ''),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.requestedQuantity} pcs',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColor.primary),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (t.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${'notes'.tr}: ${t.notes}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'requested_by'.tr}: ${t.requestedBy}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
