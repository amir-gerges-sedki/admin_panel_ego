import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';

/// Top Barcode & Search Bar with hardware barcode scanner integration and manual typing support
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
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppColor.primary
                  : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
              width: _isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isFocused ? 0.04 : 0.02),
                      blurRadius: _isFocused ? 6 : 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Scanner & Search Status Badge (Clickable to focus)
              InkWell(
                onTap: () => widget.focusNode.requestFocus(),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isFocused
                        ? AppColor.primary.withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: _isFocused
                          ? AppColor.primary.withValues(alpha: 0.4)
                          : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _searchController.text.isNotEmpty
                          ? Icons.search_rounded
                          : Icons.qr_code_scanner_rounded,
                      size: 23,
                      color: _isFocused
                          ? AppColor.primary
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Large Search & Barcode TextField
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'امسح الباركود، أو اكتب للبحث بالاسم / النكهة / الـ SKU...'
                        : 'Scan barcode, or search by item / flavor / SKU...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    context.read<PosCubit>().filterProducts(query: val);
                  },
                  onSubmitted: _onSubmitted,
                ),
              ),

              // Clear Button
              if (_searchController.text.isNotEmpty) ...[
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    context.read<PosCubit>().filterProducts(query: '');
                    widget.focusNode.requestFocus();
                  },
                  icon: const Icon(Icons.cancel_rounded, size: 21),
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'clear_search'.tr,
                ),
                const SizedBox(width: 4),
              ],

              const SizedBox(width: 14),

              // Action Submit Button
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _onSubmitted(_searchController.text),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text(
                    isArabic ? 'إدخال (Enter)' : 'Enter',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

