import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../inventory_transfers/presentation/widgets/stock_transfer_hub_dialog.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/stock_movement_cubit.dart';

/// Modal Dialog for Super Admin & Store Managers to inspect and adjust stock across all branches & warehouses.
class BranchStockMatrixDialog extends StatefulWidget {
  final ProductModel product;

  const BranchStockMatrixDialog({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BranchStockMatrixDialog(product: product),
    );
  }

  @override
  State<BranchStockMatrixDialog> createState() => _BranchStockMatrixDialogState();
}

class _BranchStockMatrixDialogState extends State<BranchStockMatrixDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProductModel _product;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    final tabCount = _product.productVariations.isNotEmpty ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStock({
    required String branchId,
    required String branchName,
    String? variationSku,
    required int newQuantity,
  }) async {
    if (newQuantity < 0) return;
    setState(() => _isUpdating = true);

    try {
      final oldQuantity = variationSku != null && variationSku.isNotEmpty
          ? (_product.productVariations.firstWhere((v) => v.sku == variationSku).getStockForBranch(branchId))
          : _product.getStockForBranch(branchId);

      await context.read<ProductCubit>().updateBranchStock(
            productId: _product.id,
            variationSku: variationSku,
            branchId: branchId,
            newQuantity: newQuantity,
          );

      // Record Stock Movement audit
      if (mounted) {
        try {
          await context.read<StockMovementCubit>().recordMovement(
                StockMovementModel(
                  id: '',
                  productId: _product.id,
                  productTitle: _product.displayTitle,
                  productCategory: _product.categoryId,
                  variationSku: variationSku ?? '',
                  type: newQuantity >= oldQuantity ? StockMovementType.restock : StockMovementType.adjustment,
                  quantity: newQuantity - oldQuantity,
                  previousStock: oldQuantity,
                  newStock: newQuantity,
                  costPricePerUnit: _product.costPrice,
                  totalCost: (newQuantity - oldQuantity).abs() * _product.costPrice,
                  notes: 'تعديل رصيد فرع: $branchName',
                  performedBy: 'Super Admin',
                  branchId: branchId,
                  branchName: branchName,
                  createdAt: DateTime.now(),
                ),
              );
        } catch (_) {}
      }

      // Refresh local product instance from cubit
      if (mounted) {
        final productState = context.read<ProductCubit>().state;
        if (productState is ProductLoaded) {
          final updated = productState.products.firstWhere(
            (p) => p.id == _product.id,
            orElse: () => _product,
          );
          setState(() {
            _product = updated;
          });
        }
      }

      if (mounted) {
        HelperFun.showNotificationAlert(
          title: 'branch_stock_title'.tr,
          message: 'branch_stock_updated_success'.trParams({
            'branch': branchName,
            'qty': '$newQuantity',
          }),
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFun.showNotificationAlert(
          title: 'branch_stock_title'.tr,
          message: 'حدث خطأ أثناء تعديل المخزون: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSetStockPrompt({
    required BuildContext context,
    required StoreBranchModel branch,
    ProductVariationModel? variation,
  }) {
    final currentQty = variation != null
        ? variation.getStockForBranch(branch.id)
        : _product.getStockForBranch(branch.id);

    final controller = TextEditingController(text: '$currentQty');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = HelperFun.isDarkMode(ctx);
        return AlertDialog(
          backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
          title: Text(
            'set_branch_stock_title'.tr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'branch'.tr}: ${branch.name}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.primary),
              ),
              if (variation != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${'variation'.tr}: ${variation.attributeValues.values.join(" / ")} (SKU: ${variation.sku})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'new_stock_quantity'.tr,
                  suffixText: 'pcs'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(controller.text.trim());
                if (qty != null && qty >= 0) {
                  Navigator.pop(ctx);
                  _updateStock(
                    branchId: branch.id,
                    branchName: branch.name,
                    variationSku: variation?.sku,
                    newQuantity: qty,
                  );
                }
              },
              child: Text('save'.tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final size = MediaQuery.of(context).size;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        List<StoreBranchModel> branches = [];
        if (settingsState is SettingsLoaded) {
          branches = settingsState.settings.branches;
        }

        if (branches.isEmpty) {
          branches = [
            const StoreBranchModel(
              id: 'main_branch',
              name: 'الفرع الرئيسي (Main Branch)',
              isPrimary: true,
              isWarehouse: false,
            ),
          ];
        }

        final totalStock = _product.getStockForBranch('all');
        final totalInventoryCost = totalStock * _product.costPrice;
        final totalInventoryRetail = totalStock * _product.effectivePrice;

        return Dialog(
          backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 860,
            height: size.height * 0.85,
            constraints: const BoxConstraints(maxHeight: 780),
            child: Column(
              children: [
                // 1. Header with Product Preview & Global KPIs
                _buildHeader(isDark, totalStock, totalInventoryCost, totalInventoryRetail),

                // 2. Tab Bar (if variable)
                if (_product.productVariations.isNotEmpty) _buildTabBar(isDark),

                // 3. Tab Views / Content
                Expanded(
                  child: _product.productVariations.isNotEmpty
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBranchesOverviewTab(isDark, branches),
                            _buildVariationsMatrixTab(isDark, branches),
                          ],
                        )
                      : _buildBranchesOverviewTab(isDark, branches),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    bool isDark,
    int totalStock,
    double totalCost,
    double totalRetail,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md + 4),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusLg)),
        border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          if (_product.thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _product.thumbnail,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_outlined, size: 36),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 32, color: AppColor.primary),
            ),
          const SizedBox(width: 14),

          // Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _product.displayTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'branch_stock_matrix_badge'.tr,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColor.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_product.brand.name} • ${_product.categoryType.displayName} • ${'price'.tr}: ${AppFormatters.formatEGP(_product.effectivePrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Total Stock KPI Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'total_all_branches_stock'.tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.primary),
                ),
                Text(
                  '$totalStock pcs',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColor.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColor.primary,
        indicatorWeight: 3,
        labelColor: AppColor.primary,
        unselectedLabelColor: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store_mall_directory_rounded, size: 18),
                const SizedBox(width: 6),
                Text('branches_stock_overview_tab'.tr),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune_rounded, size: 18),
                const SizedBox(width: 6),
                Text('variations_stock_matrix_tab'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesOverviewTab(bool isDark, List<StoreBranchModel> branches) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: branches.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final branch = branches[index];
        final stockAtBranch = _product.getStockForBranch(branch.id);
        final isLowStock = stockAtBranch <= (_product.lowStockThreshold ?? 5);

        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isLowStock
                  ? AppColor.warning.withValues(alpha: 0.5)
                  : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
          ),
          child: Row(
            children: [
              // Store / Warehouse Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (branch.isWarehouse ? const Color(0xFF06B6D4) : AppColor.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  branch.isWarehouse ? Icons.warehouse_rounded : Icons.storefront_rounded,
                  color: branch.isWarehouse ? const Color(0xFF06B6D4) : AppColor.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Branch Info & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        if (branch.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'primary_branch_badge'.tr,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (branch.isWarehouse ? const Color(0xFF06B6D4) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            branch.isWarehouse ? 'warehouse_type_label'.tr : 'retail_store_label'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: branch.isWarehouse ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (branch.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        branch.address,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Stock Counter & Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColor.darkChip : AppColor.lightChip,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 16),
                          onPressed: _isUpdating || stockAtBranch <= 0
                              ? null
                              : () => _updateStock(
                                    branchId: branch.id,
                                    branchName: branch.name,
                                    newQuantity: stockAtBranch - 1,
                                  ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'decrement_1'.tr,
                        ),
                        InkWell(
                          onTap: () => _showSetStockPrompt(context: context, branch: branch),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              '$stockAtBranch',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isLowStock ? AppColor.warning : AppColor.primary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          onPressed: _isUpdating
                              ? null
                              : () => _updateStock(
                                    branchId: branch.id,
                                    branchName: branch.name,
                                    newQuantity: stockAtBranch + 1,
                                  ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'increment_1'.tr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Direct Set Button
                  OutlinedButton.icon(
                    onPressed: () => _showSetStockPrompt(context: context, branch: branch),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: Text('edit_qty_btn'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Transfer Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      StockTransferHubDialog.show(context);
                    },
                    icon: const Icon(Icons.sync_alt_rounded, size: 14),
                    label: Text('transfer_to_branch_btn'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVariationsMatrixTab(bool isDark, List<StoreBranchModel> branches) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _product.productVariations.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final variation = _product.productVariations[index];
        final totalVarStock = variation.getStockForBranch('all');

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Variation Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusMd - 1)),
                ),
                child: Row(
                  children: [
                    if (variation.image.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          variation.image,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                      )
                    else
                      const Icon(Icons.tune_rounded, size: 20, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        variation.attributeValues.values.isNotEmpty
                            ? variation.attributeValues.values.join(' / ')
                            : 'Variation #${index + 1}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      'SKU: ${variation.sku.isNotEmpty ? variation.sku : "N/A"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${'total'.tr}: $totalVarStock pcs',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColor.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // Variation Stock per Branch Grid/Chips
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm + 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: branches.map((branch) {
                    final branchQty = variation.getStockForBranch(branch.id);
                    return InkWell(
                      onTap: () => _showSetStockPrompt(
                        context: context,
                        branch: branch,
                        variation: variation,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkChip : AppColor.lightChip,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: branchQty > 0
                                ? AppColor.primary.withValues(alpha: 0.4)
                                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              branch.isWarehouse ? Icons.warehouse_rounded : Icons.storefront_rounded,
                              size: 14,
                              color: branch.isWarehouse ? const Color(0xFF06B6D4) : AppColor.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              branch.name,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: branchQty > 0
                                    ? AppColor.primary
                                    : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$branchQty',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: branchQty > 0 ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
