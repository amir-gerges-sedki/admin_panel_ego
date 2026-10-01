import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../pos/presentation/cubit/shift_cubit.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/stock_transfer_cubit.dart';
import '../cubit/stock_transfer_state.dart';
import 'stock_transfer_history_tab.dart';
import 'stock_transfer_request_tab.dart';

/// Modal dialog for requesting stock from other branches & tracking branch transfers directly in POS
class StockTransferHubDialog extends StatefulWidget {
  const StockTransferHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const StockTransferHubDialog(),
    );
  }

  @override
  State<StockTransferHubDialog> createState() => _StockTransferHubDialogState();
}

class _StockTransferHubDialogState extends State<StockTransferHubDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Pre-load required data on dialog open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.read<ProductCubit>().state is! ProductLoaded) {
          context.read<ProductCubit>().loadProducts();
        }
        if (context.read<SettingsCubit>().state is! SettingsLoaded) {
          context.read<SettingsCubit>().loadSettings();
        }
        context.read<StockTransferCubit>().loadTransfers();
        context.read<StockTransferCubit>().startWatchingTransfers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final size = MediaQuery.of(context).size;

    // Resolve current shift branch or primary branch
    final shiftState = context.watch<ShiftCubit>().state;
    final activeShift = shiftState.activeShift;

    String currentBranchId = activeShift?.branchId ?? '';
    String currentBranchName = activeShift?.branchName ?? '';
    final currentShiftId = activeShift?.id ?? '';

    if (currentBranchId.isEmpty) {
      final settingsState = context.watch<SettingsCubit>().state;
      if (settingsState is SettingsLoaded && settingsState.settings.branches.isNotEmpty) {
        final primary = settingsState.settings.branches.firstWhere(
          (b) => b.isPrimary,
          orElse: () => settingsState.settings.branches.first,
        );
        currentBranchId = primary.id;
        currentBranchName = primary.name;
      } else {
        currentBranchId = 'main_branch';
        currentBranchName = 'transfer_current_branch'.tr;
      }
    }

    return BlocListener<StockTransferCubit, StockTransferState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          HelperFun.showNotificationAlert(
            title: 'transfer_dialog_title'.tr,
            message: state.errorMessage!,
            context: context,
          );
        }
      },
      child: Dialog(
        backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 880,
          height: size.height * 0.88,
          constraints: const BoxConstraints(maxHeight: 820),
          child: Column(
            children: [
              // 1. Dialog Top Header
              _buildHeader(isDark, currentBranchName),

              // 2. Tab Bar
              _buildTabBar(isDark, currentBranchId),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: New Request Form
                    StockTransferRequestTab(
                      currentBranchId: currentBranchId,
                      currentBranchName: currentBranchName,
                      currentShiftId: currentShiftId,
                      onSuccess: () {
                        if (mounted) {
                          _tabController.animateTo(1);
                          context.read<StockTransferCubit>().loadTransfers();
                          HelperFun.showNotificationAlert(
                            title: 'transfer_dialog_title'.tr,
                            message: 'transfer_request_success_msg'.tr,
                            context: context,
                          );
                        }
                      },
                    ),

                    // Tab 1: History & Incoming Shipments
                    StockTransferHistoryTab(
                      currentBranchId: currentBranchId,
                      currentBranchName: currentBranchName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String currentBranchName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusLg)),
        border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: const Icon(Icons.sync_alt_rounded, color: Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'transfer_dialog_title'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'F7',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${'transfer_current_branch_label'.tr}: $currentBranchName',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, String currentBranchId) {
    return BlocBuilder<StockTransferCubit, StockTransferState>(
      builder: (context, state) {
        final incomingCount = state.awaitingReceiptCount(currentBranchId);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF06B6D4),
            indicatorWeight: 3,
            labelColor: const Color(0xFF06B6D4),
            unselectedLabelColor: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_business_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('transfer_tab_new_request'.tr),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('transfer_tab_history'.tr),
                    if (incomingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Green alert badge
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$incomingCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
