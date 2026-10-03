import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/inventory_audit_model.dart';
import '../cubit/inventory_audit_cubit.dart';

class PhysicalStockAuditDialog extends StatefulWidget {
  final String initialBranchId;
  final String initialBranchName;

  const PhysicalStockAuditDialog({
    super.key,
    this.initialBranchId = 'main_branch',
    this.initialBranchName = 'المخزن الرئيسي / الفرع الرئيسي',
  });

  static Future<void> show(
    BuildContext context, {
    String initialBranchId = 'main_branch',
    String initialBranchName = 'المخزن الرئيسي / الفرع الرئيسي',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PhysicalStockAuditDialog(
        initialBranchId: initialBranchId,
        initialBranchName: initialBranchName,
      ),
    );
  }

  @override
  State<PhysicalStockAuditDialog> createState() => _PhysicalStockAuditDialogState();
}

class _PhysicalStockAuditDialogState extends State<PhysicalStockAuditDialog> {
  late String _selectedBranchId;
  late String _selectedBranchName;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  bool _varianceOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranchId;
    _selectedBranchName = widget.initialBranchName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAuditSession();
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _initAuditSession() {
    final prodState = context.read<ProductCubit>().state;
    final allProducts = prodState is ProductLoaded ? prodState.products : [];
    context.read<InventoryAuditCubit>().startNewAudit(
          branchId: _selectedBranchId,
          branchName: _selectedBranchName,
          allProducts: allProducts.cast(),
        );
  }

  void _onBarcodeSubmitted(String code) {
    if (code.trim().isEmpty) return;
    final matched = context.read<InventoryAuditCubit>().handleBarcodeScanned(code.trim());
    if (matched) {
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    } else {
      HelperFun.showNotificationAlert(
        title: 'barcode'.tr,
        message: 'الصنف غير موجود في الجرد الحالي!',
      );
      _barcodeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _barcodeController.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 1100 ? 1040.0 : width - 32;

    return BlocConsumer<InventoryAuditCubit, InventoryAuditState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          HelperFun.showNotificationAlert(
            title: 'inventory_audit_title'.tr,
            message: state.successMessage!,
          );
          Navigator.of(context).pop();
        }
        if (state.errorMessage != null) {
          HelperFun.errorSnackbar(
            title: 'error'.tr,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        var filteredItems = state.currentAuditItems;

        if (_varianceOnly) {
          filteredItems = filteredItems.where((i) => i.variance != 0).toList();
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          filteredItems = filteredItems.where((i) {
            return i.productTitle.toLowerCase().contains(q) ||
                i.variationSku.toLowerCase().contains(q);
          }).toList();
        }

        return Dialog(
          backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            side: BorderSide(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header
                _buildHeader(context, isDark, state),

                // 2. Controls & Barcode Bar
                _buildControlsBar(isDark),

                // 3. Items Comparison Table
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildAuditTable(context, filteredItems, isDark),
                ),

                // 4. Financial Summary & Actions Footer
                _buildFooter(context, isDark, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, InventoryAuditState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.cardRadiusLg)),
        border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fact_check_rounded, color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'inventory_audit_title'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _selectedBranchName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'inventory_audit_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          // Branch Selector
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, setSnap) {
              final branches = setSnap is SettingsLoaded ? setSnap.settings.branches : <StoreBranchModel>[];
              if (branches.isEmpty) return const SizedBox.shrink();

              return Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: branches.any((b) => b.id == _selectedBranchId) ? _selectedBranchId : branches.first.id,
                    items: branches.map((b) {
                      return DropdownMenuItem<String>(
                        value: b.id,
                        child: Text(b.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (newBranchId) {
                      if (newBranchId == null) return;
                      final b = branches.firstWhere((br) => br.id == newBranchId);
                      setState(() {
                        _selectedBranchId = b.id;
                        _selectedBranchName = b.name;
                      });
                      _initAuditSession();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          // Barcode Scan Input
          Expanded(
            flex: 4,
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              onSubmitted: _onBarcodeSubmitted,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'scan_barcode_audit_hint'.tr,
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF6366F1)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  onPressed: () => _onBarcodeSubmitted(_barcodeController.text),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search Filter
          Expanded(
            flex: 4,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'search_product_hint'.tr,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Variance Only Toggle
          FilterChip(
            selected: _varianceOnly,
            label: Text(
              'show_variance_only'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _varianceOnly ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            selectedColor: AppColor.error,
            backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            onSelected: (val) => setState(() => _varianceOnly = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTable(
    BuildContext context,
    List<InventoryAuditItemModel> items,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            ),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            dataRowMinHeight: 44,
            dataRowMaxHeight: 52,
            columnSpacing: 14,
            horizontalMargin: 12,
            columns: [
              DataColumn(label: Text('product_name'.tr)),
              DataColumn(label: Text('sku'.tr)),
              DataColumn(label: Text('system_stock_label'.tr)),
              DataColumn(label: Text('physical_stock_counted'.tr)),
              DataColumn(label: Text('variance_difference'.tr)),
              DataColumn(label: Text('variance_cost_impact'.tr)),
            ],
            rows: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final hasVariance = item.variance != 0;
              final isDeficit = item.variance < 0;

              return DataRow(
                color: WidgetStateProperty.resolveWith((states) {
                  if (hasVariance) {
                    return (isDeficit ? AppColor.error : const Color(0xFF3B82F6)).withValues(alpha: 0.05);
                  }
                  return null;
                }),
                cells: [
                  // Product Title & Attributes
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.productTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variationAttributes.isNotEmpty)
                          Text(
                            item.variationAttributes.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // SKU
                  DataCell(
                    Text(
                      item.variationSku.isNotEmpty ? item.variationSku : '---',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),

                  // System Quantity
                  DataCell(
                    Text(
                      '${item.systemQuantity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Physical Count Stepper & Input
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<InventoryAuditCubit>().updatePhysicalQuantity(idx, item.physicalQuantity - 1);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.remove, size: 14),
                          ),
                        ),
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${item.physicalQuantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.read<InventoryAuditCubit>().updatePhysicalQuantity(idx, item.physicalQuantity + 1);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.add, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Variance Badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasVariance
                            ? (isDeficit ? AppColor.error : const Color(0xFF3B82F6)).withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasVariance
                              ? (isDeficit ? AppColor.error : const Color(0xFF3B82F6)).withValues(alpha: 0.4)
                              : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        hasVariance
                            ? '${item.variance > 0 ? "+" : ""}${item.variance}'
                            : 'مطابق (0)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: hasVariance
                              ? (isDeficit ? AppColor.error : const Color(0xFF3B82F6))
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),

                  // Financial Cost Impact
                  DataCell(
                    Text(
                      AppFormatters.formatEGP(item.varianceCost),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: item.varianceCost < 0
                            ? AppColor.error
                            : (item.varianceCost > 0 ? const Color(0xFF3B82F6) : null),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 8),
          Text(
            'no_items_match_audit'.tr,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    bool isDark,
    InventoryAuditState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSizes.cardRadiusLg)),
        border: Border(top: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          // KPI Badges
          _buildStatPill('إجمالي المجرود', '${state.totalCountedUnits} قطعة', AppColor.primary, isDark),
          const SizedBox(width: 8),
          _buildStatPill('عجز (-)', '${state.deficitUnits} قطعة', AppColor.error, isDark),
          const SizedBox(width: 8),
          _buildStatPill('زيادة (+)', '${state.surplusUnits} قطعة', const Color(0xFF3B82F6), isDark),
          const SizedBox(width: 8),
          _buildStatPill('صافي الفارق المالي', AppFormatters.formatEGP(state.totalVarianceCost), isDark ? Colors.white70 : Colors.black87, isDark),

          const Spacer(),

          // Save Draft Button
          OutlinedButton.icon(
            onPressed: state.isSubmitting
                ? null
                : () {
                    context.read<InventoryAuditCubit>().saveDraft(
                          auditedBy: 'Branch Staff',
                          notes: _notesController.text.trim(),
                        );
                  },
            icon: const Icon(Icons.save_outlined, size: 16),
            label: Text('save_audit_draft_btn'.tr),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),

          // Reconcile & Apply Button
          ElevatedButton.icon(
            onPressed: state.isSubmitting
                ? null
                : () {
                    _confirmReconcile(context, state);
                  },
            icon: state.isSubmitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 16),
            label: Text('reconcile_and_apply_btn'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String val, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
          Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  void _confirmReconcile(BuildContext context, InventoryAuditState state) {
    final varianceCount = state.currentAuditItems.where((i) => i.variance != 0).length;

    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text('confirm_audit_reconciliation_title'.tr),
          ],
        ),
        content: Text(
          'confirm_audit_reconciliation_msg'.trParams({
            'count': '$varianceCount',
            'branch': _selectedBranchName,
          }),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(confirmCtx).pop();
              context.read<InventoryAuditCubit>().reconcileAndComplete(
                    auditedBy: 'Branch Staff',
                    notes: _notesController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('confirm_and_apply'.tr),
          ),
        ],
      ),
    );
  }
}
