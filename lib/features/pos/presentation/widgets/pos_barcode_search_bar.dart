import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';

/// Top Barcode & Search Bar with hardware barcode scanner integration
class PosBarcodeSearchBar extends StatefulWidget {
  final FocusNode focusNode;
  final bool autofocus;

  const PosBarcodeSearchBar({
    super.key,
    required this.focusNode,
    this.autofocus = true,
  });

  @override
  State<PosBarcodeSearchBar> createState() => _PosBarcodeSearchBarState();
}

class _PosBarcodeSearchBarState extends State<PosBarcodeSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSubmitted(String val) async {
    final clean = val.trim();
    if (clean.isEmpty) return;

    final cubit = context.read<PosCubit>();

    // 1. Check if it is an exact barcode or SKU match
    final matchedProduct = cubit.handleBarcodeScanned(clean, showErrorIfNotFound: false);

    if (matchedProduct != null && mounted) {
      // If a multi-variant product was scanned by its parent barcode or title,
      // filter the catalog directly to show all its variations immediately in the list/grid!
      cubit.filterProducts(query: matchedProduct.title);
      widget.focusNode.requestFocus();
      return;
    }

    // If an item was directly added by barcode scanner
    if (cubit.state.barcodeFeedbackMessage != null &&
        (cubit.state.barcodeFeedbackMessage!.contains('تمت') ||
            cubit.state.barcodeFeedbackMessage!.contains('✅'))) {
      _searchController.clear();
      cubit.filterProducts(query: '');
      widget.focusNode.requestFocus();
      return;
    }

    // 2. Otherwise, treat as manual keyword search and keep results filtered
    cubit.filterProducts(query: clean);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocConsumer<PosCubit, PosState>(
      listener: (context, state) {
        if (state.barcodeFeedbackMessage != null) {
          final isSuccess = state.barcodeFeedbackMessage!.contains('تمت') || state.barcodeFeedbackMessage!.contains('✅');
          HelperFun.showNotificationAlert(
            title: isSuccess ? 'barcode_scanned_title'.tr : 'barcode_scan_alert'.tr,
            message: state.barcodeFeedbackMessage!,
          );
          context.read<PosCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Scanner Status Indicator Icon
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),

              // Search & Barcode TextField
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'pos_barcode_search_bar_hint'.tr,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    context.read<PosCubit>().filterProducts(query: val);
                  },
                  onSubmitted: _onSubmitted,
                ),
              ),

              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<PosCubit>().filterProducts(query: '');
                    widget.focusNode.requestFocus();
                  },
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'clear_search'.tr,
                ),
              const SizedBox(width: 10),

              // Enter submit button
              ElevatedButton.icon(
                onPressed: () => _onSubmitted(_searchController.text),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
                label: Text(
                  'enter_key_submit'.tr,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

