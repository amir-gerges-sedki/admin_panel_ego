import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/stock_transfer_model.dart';
import '../cubit/stock_transfer_cubit.dart';
import '../cubit/stock_transfer_state.dart';

class StockTransferHistoryTab extends StatefulWidget {
  final String currentBranchId;
  final String currentBranchName;

  const StockTransferHistoryTab({
    super.key,
    required this.currentBranchId,
    required this.currentBranchName,
  });

  @override
  State<StockTransferHistoryTab> createState() => _StockTransferHistoryTabState();
}

class _StockTransferHistoryTabState extends State<StockTransferHistoryTab> {
  int _directionFilter = 0; // 0 = Incoming to this branch, 1 = Outgoing from this branch, 2 = All

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<StockTransferCubit, StockTransferState>(
      builder: (context, state) {
        if (state.isLoading && state.transfers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        List<StockTransferModel> displayedTransfers;
        if (_directionFilter == 0) {
          displayedTransfers = state.incomingTransfers(widget.currentBranchId);
        } else if (_directionFilter == 1) {
          displayedTransfers = state.outgoingTransfers(widget.currentBranchId);
        } else {
          displayedTransfers = state.filteredTransfers;
        }

        return Column(
          children: [
            // Direction & Status Filter Header
            _buildFiltersHeader(isDark, state),
            const Divider(height: 1),

            // Transfers List
            Expanded(
              child: displayedTransfers.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: () => context.read<StockTransferCubit>().loadTransfers(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount: displayedTransfers.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: AppSizes.md),
                        itemBuilder: (context, index) {
                          final transfer = displayedTransfers[index];
                          return _buildTransferCard(context, transfer, isDark);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersHeader(bool isDark, StockTransferState state) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      child: Column(
        children: [
          // Direction Filter (Incoming / Outgoing / All)
          Row(
            children: [
              _buildDirectionChip(0, 'transfer_filter_incoming'.tr, Icons.call_received_rounded, isDark),
              const SizedBox(width: 8),
              _buildDirectionChip(1, 'transfer_filter_outgoing'.tr, Icons.call_made_rounded, isDark),
              const SizedBox(width: 8),
              _buildDirectionChip(2, 'all'.tr, Icons.sync_alt_rounded, isDark),
            ],
          ),
          const SizedBox(height: 8),

          // Status Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(null, 'all'.tr, isDark, isSelected: state.statusFilter == null),
                ...StockTransferStatus.values.map((status) {
                  return _buildStatusChip(
                    status,
                    status.labelKey.tr,
                    isDark,
                    isSelected: state.statusFilter == status,
                    color: status.color,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionChip(int index, String label, IconData icon, bool isDark) {
    final isSelected = _directionFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _directionFilter = index),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary
                : (isDark ? AppColor.darkChip : AppColor.lightChip),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: Border.all(
              color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    StockTransferStatus? status,
    String label,
    bool isDark, {
    required bool isSelected,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColor.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => context.read<StockTransferCubit>().filterByStatus(status),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
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
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? effectiveColor : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, StockTransferModel transfer, bool isDark) {
    final isIncoming = transfer.toBranchId == widget.currentBranchId;
    final isAwaitingReceipt = isIncoming &&
        (transfer.status == StockTransferStatus.inTransit || transfer.status == StockTransferStatus.approved);

    final dateFormat = DateFormat('yyyy-MM-dd • hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isAwaitingReceipt
              ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.25)
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          width: 1.0,
        ),
        boxShadow: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkCard : AppColor.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusMd - 1)),
            ),
            child: Row(
              children: [
                // Transfer Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transfer.transferNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColor.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transfer.priority.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transfer.priority.labelKey.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: transfer.priority.color,
                    ),
                  ),
                ),

                const Spacer(),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: transfer.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: transfer.status.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(transfer.status.icon, size: 14, color: transfer.status.color),
                      const SizedBox(width: 4),
                      Text(
                        transfer.status.labelKey.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: transfer.status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Routing Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm + 4, AppSizes.md, AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 16,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'transfer_from'.tr}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          transfer.fromBranchName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColor.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'transfer_to'.tr}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          transfer.toBranchName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items Preview List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkCard : AppColor.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${'items'.tr} (${transfer.items.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${'transfer_total_qty'.tr}: ${transfer.totalRequestedItems}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColor.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...transfer.items.take(3).map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${it.productTitle} ${it.variationAttributes.isNotEmpty ? "(${it.variationAttributes.values.join(' / ')})" : ""}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${it.requestedQuantity}x',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      )),
                  if (transfer.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${transfer.items.length - 3} ${'more_items'.tr}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Notes if present
          if (transfer.notes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, 6, AppSizes.md, 0),
              child: Text(
                '${'notes'.tr}: ${transfer.notes}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Footer Actions & Timestamp
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Text(
                  dateFormat.format(transfer.createdAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                const Spacer(),

                // View Details Button
                TextButton.icon(
                  onPressed: () => _showTransferDetailsDialog(context, transfer),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: Text('details'.tr, style: const TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),

                // Confirm Receipt Action Button (for incoming shipments)
                if (isAwaitingReceipt) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _confirmReceipt(context, transfer),
                    icon: const Icon(Icons.task_alt_rounded, size: 15),
                    label: Text('transfer_confirm_receipt_btn'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                    ),
                  ),
                ],

                // Cancel Request (if pending by requester)
                if (transfer.status == StockTransferStatus.pending && isIncoming) ...[
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _cancelTransfer(context, transfer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.error,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColor.error),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text('cancel'.tr, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 50, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
            const SizedBox(height: 12),
            Text(
              'transfer_no_records'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReceipt(BuildContext context, StockTransferModel transfer) async {
    final cubit = context.read<StockTransferCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_confirm_receipt_title'.tr),
        content: Text('transfer_confirm_receipt_msg'.tr.replaceAll('{num}', transfer.transferNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: Text('transfer_confirm_btn'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.receiveTransfer(
        transfer.id,
        performedBy: 'Cashier (${widget.currentBranchName})',
      );
    }
  }

  Future<void> _cancelTransfer(BuildContext context, StockTransferModel transfer) async {
    final cubit = context.read<StockTransferCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('transfer_cancel_title'.tr),
        content: Text('transfer_cancel_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('no'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            child: Text('yes'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.cancelTransfer(
        transfer.id,
        performedBy: 'Cashier (${widget.currentBranchName})',
      );
    }
  }

  void _showTransferDetailsDialog(BuildContext context, StockTransferModel transfer) {
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
        child: Container(
          width: 580,
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
                        transfer.transferNumber,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColor.primary),
                      ),
                      Text(
                        '${transfer.fromBranchName} ➔ ${transfer.toBranchName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Items Table
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: transfer.items.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final it = transfer.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: it.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                it.image,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_outlined),
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined, color: AppColor.primary),
                      title: Text(it.productTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        it.variationAttributes.isNotEmpty
                            ? it.variationAttributes.entries.map((e) => '${e.key}: ${e.value}').join(' | ')
                            : (it.variationSku.isNotEmpty ? 'SKU: ${it.variationSku}' : ''),
                        style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${it.requestedQuantity}x',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColor.primary),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSizes.md),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('close'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
