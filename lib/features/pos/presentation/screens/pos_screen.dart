import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';
import '../cubit/shift_cubit.dart';
import '../cubit/shift_state.dart';
import '../widgets/active_shift_banner.dart';
import '../widgets/close_shift_dialog.dart';
import '../widgets/open_shift_dialog.dart';
import '../widgets/pos_barcode_search_bar.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_checkout_dialog.dart';
import '../widgets/pos_product_grid.dart';
import '../widgets/pos_return_dialog.dart';
import '../../../inventory_transfers/presentation/cubit/stock_transfer_cubit.dart';
import '../../../inventory_transfers/presentation/cubit/stock_transfer_state.dart';
import '../../../inventory_transfers/presentation/widgets/stock_transfer_hub_dialog.dart';

/// Point of Sale (POS) Cashier Screen for fast in-store sales and barcode scanning
class PosScreen extends StatefulWidget {
  final bool autoFocusScanner;

  const PosScreen({super.key, this.autoFocusScanner = true});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FocusNode _scannerFocusNode = FocusNode();
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // Register global hardware keyboard listener for instant F-keys response
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    // Auto-focus scanner on entry if requested
    if (widget.autoFocusScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scannerFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _scannerFocusNode.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _onF2Pressed();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f4) {
        _onF4Pressed();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f6) {
        _onF6Pressed();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f7) {
        _onF7Pressed();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        _onF8Pressed();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f9) {
        _onF9Pressed();
        return true;
      }
    }
    return false;
  }

  void _onF2Pressed() {
    if (_isDialogOpen) return;
    _scannerFocusNode.requestFocus();
  }

  Future<void> _onF4Pressed() async {
    if (_isDialogOpen) return;

    final state = context.read<PosCubit>().state;
    if (state.hasItems) {
      _isDialogOpen = true;
      try {
        await PosCheckoutDialog.show(context);
      } finally {
        if (mounted) {
          _isDialogOpen = false;
          _scannerFocusNode.requestFocus();
        }
      }
    } else {
      HelperFun.showNotificationAlert(
        title: 'pos_register_title'.tr,
        message: 'empty_cart_title'.tr,
      );
    }
  }

  Future<void> _onF6Pressed() async {
    if (_isDialogOpen) return;
    final shiftState = context.read<ShiftCubit>().state;
    _isDialogOpen = true;
    try {
      if (shiftState.hasActiveShift) {
        await CloseShiftDialog.show(context, shiftState.activeShift!);
      } else {
        await OpenShiftDialog.show(context);
      }
    } finally {
      if (mounted) {
        _isDialogOpen = false;
        _scannerFocusNode.requestFocus();
      }
    }
  }

  Future<void> _onF7Pressed() async {
    if (_isDialogOpen) return;

    _isDialogOpen = true;
    try {
      await StockTransferHubDialog.show(context);
    } finally {
      if (mounted) {
        _isDialogOpen = false;
        _scannerFocusNode.requestFocus();
      }
    }
  }

  Future<void> _onF8Pressed() async {
    if (_isDialogOpen) return;

    _isDialogOpen = true;
    try {
      await PosReturnDialog.show(context);
    } finally {
      if (mounted) {
        _isDialogOpen = false;
        _scannerFocusNode.requestFocus();
      }
    }
  }

  void _onF9Pressed() {
    if (_isDialogOpen) return;
    final state = context.read<PosCubit>().state;
    if (state.hasItems) {
      context.read<PosCubit>().clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: isDark ? AppColor.darkSurface : AppColor.lightSurface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. POS Top Status Bar
            _buildTopHeader(isDark),
            const SizedBox(height: AppSizes.sm),

            // Active Shift Status Banner
            const ActiveShiftBanner(),

            // 2. Barcode & Search Input Bar
            PosBarcodeSearchBar(
              focusNode: _scannerFocusNode,
              autofocus: widget.autoFocusScanner,
            ),
            const SizedBox(height: AppSizes.sm + 4),

            // 3. Main Working Area
            Expanded(
              child: isDesktop
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left 65%: Product Grid & Category Filters
                        Expanded(
                          flex: 7,
                          child: PosProductGrid(),
                        ),
                        SizedBox(width: AppSizes.md),

                        // Right 35%: Cart & Payment Register
                        Expanded(
                          flex: 5,
                          child: PosCartPanel(),
                        ),
                      ],
                    )
                  : _buildMobileTabletLayout(isDark),
            ),
          ],
        ),
      ),
    );
  }

  /// Responsive Tab-based layout for mobile and tablet to prevent vertical squashing
  Widget _buildMobileTabletLayout(bool isDark) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grid_view_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('pos_tab_catalog'.tr),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('pos_tab_cart'.tr),
                          if (state.hasItems) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${state.totalItemsCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    PosProductGrid(),
                    PosCartPanel(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(bool isDark) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 680;
            final isVeryCompact = constraints.maxWidth < 480;

            return Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: const Icon(Icons.point_of_sale_rounded, color: AppColor.primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'pos_register_title'.tr,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isCompact)
                              Text(
                                'pos_register_subtitle'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Keyboard Shortcuts & Action Pills
                BlocBuilder<ShiftCubit, ShiftState>(
                  builder: (context, shiftState) {
                    final currentBranchId = shiftState.activeShift?.branchId ?? '';

                    return BlocBuilder<StockTransferCubit, StockTransferState>(
                      builder: (context, transferState) {
                        final incomingCount = transferState.awaitingReceiptCount(currentBranchId);

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildShortcutBadge('F2', isVeryCompact ? null : 'shortcut_f2_scan'.tr, isDark, onTap: _onF2Pressed),
                              const SizedBox(width: 5),
                              _buildShortcutBadge('F4', isVeryCompact ? null : 'shortcut_f4_pay'.tr, isDark, onTap: _onF4Pressed),
                              const SizedBox(width: 5),
                              _buildShortcutBadge(
                                'F6',
                                isVeryCompact ? null : 'shortcut_f6_shift'.tr,
                                isDark,
                                color: const Color(0xFF10B981),
                                onTap: _onF6Pressed,
                              ),
                              const SizedBox(width: 5),
                              _buildShortcutBadge(
                                'F7',
                                isVeryCompact ? null : 'shortcut_f7_transfers'.tr,
                                isDark,
                                color: const Color(0xFF06B6D4),
                                count: incomingCount,
                                onTap: _onF7Pressed,
                              ),
                              const SizedBox(width: 5),
                              _buildShortcutBadge(
                                'F8',
                                isVeryCompact ? null : 'shortcut_f8_returns'.tr,
                                isDark,
                                color: const Color(0xFFF97316),
                                onTap: _onF8Pressed,
                              ),
                              const SizedBox(width: 5),
                              _buildShortcutBadge('F9', isVeryCompact ? null : 'shortcut_f9_clear'.tr, isDark, onTap: _onF9Pressed),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShortcutBadge(
    String keyText,
    String? label,
    bool isDark, {
    Color? color,
    int? count,
    VoidCallback? onTap,
  }) {
    final effectiveColor = color ?? AppColor.primary;
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: label != null ? 7 : 5, vertical: 3.5),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.12)
            : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color != null ? color.withValues(alpha: 0.4) : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(3.5),
            ),
            child: Text(
              keyText,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color ?? (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
              ),
            ),
          ],
          if (count != null && count > 0) ...[
            const SizedBox(width: 4.5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: badge,
      );
    }
    return badge;
  }
}
