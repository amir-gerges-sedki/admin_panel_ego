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
import '../widgets/pos_barcode_search_bar.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_checkout_dialog.dart';
import '../widgets/pos_product_grid.dart';
import '../widgets/pos_return_dialog.dart';

/// Point of Sale (POS) Cashier Screen for fast in-store sales and barcode scanning
class PosScreen extends StatefulWidget {
  final bool autoFocusScanner;

  const PosScreen({super.key, this.autoFocusScanner = true});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FocusNode _scannerFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus scanner on entry if requested
    if (widget.autoFocusScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scannerFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scannerFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _scannerFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.f4) {
        final state = context.read<PosCubit>().state;
        if (state.hasItems) {
          PosCheckoutDialog.show(context);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        PosReturnDialog.show(context);
      } else if (event.logicalKey == LogicalKeyboardKey.f9) {
        context.read<PosCubit>().clearCart();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isDark ? AppColor.darkSurface : AppColor.lightSurface,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. POS Top Status Bar
              _buildTopHeader(isDark),
              const SizedBox(height: AppSizes.sm),

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
                    : const Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: PosProductGrid(),
                          ),
                          SizedBox(height: AppSizes.md),
                          Expanded(
                            flex: 5,
                            child: PosCartPanel(),
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

  Widget _buildTopHeader(bool isDark) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: AppColor.primary, size: 20),
                ),
                const SizedBox(width: AppSizes.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pos_register_title'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'pos_register_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Keyboard Shortcuts & Return Action Pills
            Row(
              children: [
                _buildShortcutBadge('F2', 'shortcut_f2_scan'.tr, isDark),
                const SizedBox(width: 6),
                _buildShortcutBadge('F4', 'shortcut_f4_pay'.tr, isDark),
                const SizedBox(width: 6),
                _buildShortcutBadge(
                  'F8',
                  'shortcut_f8_returns'.tr,
                  isDark,
                  color: const Color(0xFFF97316),
                  onTap: () => PosReturnDialog.show(context),
                ),
                const SizedBox(width: 6),
                _buildShortcutBadge('F9', 'shortcut_f9_clear'.tr, isDark),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildShortcutBadge(
    String keyText,
    String label,
    bool isDark, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final effectiveColor = color ?? AppColor.primary;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keyText,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color ?? (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
          ),
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
