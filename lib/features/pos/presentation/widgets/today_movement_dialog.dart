import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/shift_transaction_model.dart';
import '../cubit/shift_cubit.dart';
import '../cubit/shift_state.dart';
import 'shift_cash_entry_dialog.dart';

class TodayMovementDialog extends StatefulWidget {
  final CashierShiftModel? shift;

  const TodayMovementDialog({super.key, this.shift});

  static void show(BuildContext context, {CashierShiftModel? shift}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<ShiftCubit>(),
        child: TodayMovementDialog(shift: shift),
      ),
    );
  }

  @override
  State<TodayMovementDialog> createState() => _TodayMovementDialogState();
}

class _TodayMovementDialogState extends State<TodayMovementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 900 ? 840.0 : width - 32;

    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, shiftState) {
        final activeShift = widget.shift ?? shiftState.activeShift;
        final currentBranchId = activeShift?.branchId ?? shiftState.filterBranchId ?? '';
        final now = DateTime.now();

        // Filter today's shifts for this branch from history + active shift
        final allTodayShifts = <CashierShiftModel>[];
        if (activeShift != null) {
          allTodayShifts.add(activeShift);
        }
        for (final s in shiftState.historyShifts) {
          if (s.id != activeShift?.id && _isSameDay(s.openedAt, now)) {
            if (currentBranchId.isEmpty || s.branchId == currentBranchId) {
              allTodayShifts.add(s);
            }
          }
        }

        // Aggregate Today's Totals for Branch
        double todayTotalSales = 0;
        double todayCashSales = 0;
        double todayCardSales = 0;
        double todayInstapaySales = 0;
        double todayVodafoneSales = 0;
        double todayCashIns = 0;
        double todayCashOuts = 0;
        double todayRefunds = 0;
        int todayOrdersCount = 0;
        double todayOpeningCash = 0;

        for (final s in allTodayShifts) {
          todayTotalSales += s.totalSales;
          todayCashSales += s.cashSales;
          todayCardSales += s.cardSales;
          todayInstapaySales += s.instapaySales;
          todayVodafoneSales += s.vodafoneCashSales;
          todayCashIns += s.cashIns;
          todayCashOuts += s.cashOuts;
          todayRefunds += s.cashRefunds;
          todayOrdersCount += s.ordersCount;
          todayOpeningCash += s.openingCash;
        }

        final todayExpectedCash = activeShift != null
            ? activeShift.calculatedExpectedCash
            : (todayOpeningCash + todayCashSales + todayCashIns - todayCashOuts - todayRefunds);

        return Dialog(
          backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            side: BorderSide(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 820),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                _buildHeader(context, isDark, activeShift),

                // 2. Tab Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkCard : AppColor.lightCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark
                              ? AppColor.textSecondaryDark
                              : AppColor.textSecondaryLight,
                          labelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 15),
                                  const SizedBox(width: 6),
                                  Text('active_shift_tab'.tr),
                                  if (activeShift != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                children: [
                                  const Icon(Icons.today_rounded, size: 15),
                                  const SizedBox(width: 6),
                                  Text('today_total_tab'.tr),
                                  if (allTodayShifts.length > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${allTodayShifts.length}',
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (activeShift != null)
                        OutlinedButton.icon(
                          onPressed: () => ShiftCashEntryDialog.show(
                            context,
                            shift: activeShift,
                            isCashIn: true,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.swap_vert_rounded, size: 14),
                          label: Text('cash_in_out_btn'.tr),
                        ),
                    ],
                  ),
                ),

                // 3. Tab Views Content
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Current Shift
                      activeShift != null
                          ? _buildShiftView(
                              context: context,
                              isDark: isDark,
                              shift: activeShift,
                              transactions:
                                  shiftState.activeShiftTransactions,
                            )
                          : _buildNoShiftPlaceholder(isDark),

                      // Tab 2: Full Today Aggregated Branch Total
                      _buildTodayBranchView(
                        isDark: isDark,
                        totalSales: todayTotalSales,
                        cashSales: todayCashSales,
                        cardSales: todayCardSales,
                        instapaySales: todayInstapaySales,
                        vodafoneSales: todayVodafoneSales,
                        cashIns: todayCashIns,
                        cashOuts: todayCashOuts,
                        refunds: todayRefunds,
                        ordersCount: todayOrdersCount,
                        openingCash: todayOpeningCash,
                        expectedCash: todayExpectedCash,
                        shiftsCount: allTodayShifts.length,
                        branchName: activeShift?.branchName ??
                            'active_branch_label'.tr,
                      ),
                    ],
                  ),
                ),

                // 4. Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSizes.cardRadiusLg),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColor.darkBorder
                            : AppColor.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: Text('close_btn'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, CashierShiftModel? shift) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.md - 2),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.cardRadiusLg)),
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.query_stats_rounded,
              color: AppColor.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'today_movement_title'.tr,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppFormatters.formatDate(now),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  shift != null
                      ? '${shift.branchName} • ${shift.cashierName}'
                      : 'today_movement_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftView({
    required BuildContext context,
    required bool isDark,
    required CashierShiftModel shift,
    required List<ShiftTransactionModel> transactions,
  }) {
    final avgTicket =
        shift.ordersCount > 0 ? (shift.totalSales / shift.ordersCount) : 0.0;
    final expCash = shift.calculatedExpectedCash;
    final durationHours = shift.duration.inHours;
    final durationMinutes = shift.duration.inMinutes % 60;
    final durationStr = '${durationHours}h ${durationMinutes}m';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Info Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_rounded,
                        size: 16, color: AppColor.primary),
                    const SizedBox(width: 6),
                    Text(
                      shift.branchName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      shift.cashierName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${'shift_duration'.tr}: $durationStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // 4 KPIs Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  label: 'total_sales'.tr,
                  value: AppFormatters.formatEGP(shift.totalSales),
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'kpi_today_orders'.tr,
                  value: '${shift.ordersCount}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColor.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'average_order_value'.tr,
                  value: AppFormatters.formatEGP(avgTicket),
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'expected_drawer_cash'.tr,
                  value: AppFormatters.formatEGP(expCash),
                  icon: Icons.point_of_sale_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Payment Methods & Cash Flow Cards Side-by-Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Methods Breakdown
              Expanded(
                child: _buildSectionContainer(
                  title: 'payment_methods_breakdown'.tr,
                  icon: Icons.pie_chart_outline_rounded,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildMethodRow(
                        title: 'payment_cash'.tr,
                        amount: shift.cashSales,
                        total: shift.totalSales,
                        color: const Color(0xFF10B981),
                        icon: Icons.attach_money_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'card_visa_sales'.tr,
                        amount: shift.cardSales,
                        total: shift.totalSales,
                        color: const Color(0xFF3B82F6),
                        icon: Icons.credit_card_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'instapay_sales'.tr,
                        amount: shift.instapaySales,
                        total: shift.totalSales,
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.bolt_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'vodafone_cash_sales'.tr,
                        amount: shift.vodafoneCashSales,
                        total: shift.totalSales,
                        color: const Color(0xFFEF4444),
                        icon: Icons.phone_android_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Drawer Cash Flow
              Expanded(
                child: _buildSectionContainer(
                  title: 'drawer_cash_flow'.tr,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildFlowItem('opening_float'.tr, shift.openingCash,
                          isDark, isNeutral: true),
                      const Divider(height: 12),
                      _buildFlowItem(
                          'payment_cash'.tr, shift.cashSales, isDark,
                          isPositive: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_inflow'.tr, shift.cashIns, isDark,
                          isPositive: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_outflow'.tr, shift.cashOuts, isDark,
                          isNegative: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_refunds'.tr, shift.cashRefunds, isDark,
                          isNegative: true),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'expected_drawer_cash'.tr,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            AppFormatters.formatEGP(expCash),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Recent Drawer Transactions Log
          _buildSectionContainer(
            title: 'recent_shift_txs'.tr,
            icon: Icons.history_rounded,
            isDark: isDark,
            child: transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'no_shift_txs_found'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColor.textMutedDark
                              : AppColor.textMutedLight,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final tx = transactions[idx];
                      final isCashIn = tx.type == ShiftTransactionType.cashIn;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCashIn
                                        ? const Color(0xFF10B981)
                                        : AppColor.error)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCashIn
                                    ? 'drawer_cash_in_btn'.tr
                                    : 'drawer_cash_out_btn'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isCashIn
                                      ? const Color(0xFF10B981)
                                      : AppColor.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tx.reason.isNotEmpty ? tx.reason : '---',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              AppFormatters.formatTime(tx.createdAt),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColor.textMutedDark
                                    : AppColor.textMutedLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${isCashIn ? '+' : '-'}${AppFormatters.formatEGP(tx.amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCashIn
                                    ? const Color(0xFF10B981)
                                    : AppColor.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBranchView({
    required bool isDark,
    required double totalSales,
    required double cashSales,
    required double cardSales,
    required double instapaySales,
    required double vodafoneSales,
    required double cashIns,
    required double cashOuts,
    required double refunds,
    required int ordersCount,
    required double openingCash,
    required double expectedCash,
    required int shiftsCount,
    required String branchName,
  }) {
    final avgTicket =
        ordersCount > 0 ? (totalSales / ordersCount) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 16, color: AppColor.primary),
                    const SizedBox(width: 6),
                    Text(
                      branchName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  'today_all_shifts_count'
                      .trParams({'count': '$shiftsCount'}),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // 4 KPIs Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  label: 'total_sales'.tr,
                  value: AppFormatters.formatEGP(totalSales),
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'kpi_today_orders'.tr,
                  value: '$ordersCount',
                  icon: Icons.receipt_long_rounded,
                  color: AppColor.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'average_order_value'.tr,
                  value: AppFormatters.formatEGP(avgTicket),
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  label: 'expected_drawer_cash'.tr,
                  value: AppFormatters.formatEGP(expectedCash),
                  icon: Icons.point_of_sale_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Payment Methods & Cash Flow Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Methods
              Expanded(
                child: _buildSectionContainer(
                  title: 'payment_methods_breakdown'.tr,
                  icon: Icons.pie_chart_outline_rounded,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildMethodRow(
                        title: 'payment_cash'.tr,
                        amount: cashSales,
                        total: totalSales,
                        color: const Color(0xFF10B981),
                        icon: Icons.attach_money_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'card_visa_sales'.tr,
                        amount: cardSales,
                        total: totalSales,
                        color: const Color(0xFF3B82F6),
                        icon: Icons.credit_card_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'instapay_sales'.tr,
                        amount: instapaySales,
                        total: totalSales,
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.bolt_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildMethodRow(
                        title: 'vodafone_cash_sales'.tr,
                        amount: vodafoneSales,
                        total: totalSales,
                        color: const Color(0xFFEF4444),
                        icon: Icons.phone_android_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Drawer Flow
              Expanded(
                child: _buildSectionContainer(
                  title: 'drawer_cash_flow'.tr,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildFlowItem('opening_float'.tr, openingCash, isDark,
                          isNeutral: true),
                      const Divider(height: 12),
                      _buildFlowItem(
                          'payment_cash'.tr, cashSales, isDark,
                          isPositive: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_inflow'.tr, cashIns, isDark,
                          isPositive: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_outflow'.tr, cashOuts, isDark,
                          isNegative: true),
                      const SizedBox(height: 4),
                      _buildFlowItem(
                          'drawer_total_refunds'.tr, refunds, isDark,
                          isNegative: true),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'expected_drawer_cash'.tr,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            AppFormatters.formatEGP(expectedCash),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNoShiftPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 48, color: Colors.grey.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'no_active_shift_warning'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColor.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildMethodRow({
    required String title,
    required double amount,
    required double total,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    final pct = total > 0 ? (amount / total) * 100 : 0.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColor.textMutedDark
                      : AppColor.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          AppFormatters.formatEGP(amount),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildFlowItem(
    String label,
    double amount,
    bool isDark, {
    bool isPositive = false,
    bool isNegative = false,
    bool isNeutral = false,
  }) {
    Color? color;
    String prefix = '';
    if (isPositive) {
      color = const Color(0xFF10B981);
      prefix = '+';
    } else if (isNegative) {
      color = AppColor.error;
      prefix = '-';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColor.textSecondaryDark
                : AppColor.textSecondaryLight,
          ),
        ),
        Text(
          '$prefix${AppFormatters.formatEGP(amount)}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
