import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/stock_movement_model.dart';
import '../cubit/stock_movement_cubit.dart';
import '../cubit/stock_movement_state.dart';

class StockMovementsDialog extends StatefulWidget {
  final String? initialProductId;

  const StockMovementsDialog({super.key, this.initialProductId});

  static void show(BuildContext context, {String? initialProductId}) {
    UnifiedModalSheet.show(
      context: context,
      title: 'stock_movements_dialog_title'.tr,
      subtitle: 'stock_movements_dialog_subtitle'.tr,
      icon: Icons.history_edu_rounded,
      maxWidth: 1000,
      content: StockMovementsDialog(initialProductId: initialProductId),
    );
  }

  @override
  State<StockMovementsDialog> createState() => _StockMovementsDialogState();
}

class _StockMovementsDialogState extends State<StockMovementsDialog> {
  late TextEditingController _searchController;
  StockMovementType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockMovementCubit>().loadStockMovements(
            productId: widget.initialProductId,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getTypeColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.restock:
        return const Color(0xFF10B981);
      case StockMovementType.sale:
        return const Color(0xFF6366F1);
      case StockMovementType.damage:
        return const Color(0xFFEF4444);
      case StockMovementType.adjustment:
        return const Color(0xFFF59E0B);
      case StockMovementType.returnItem:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData _getTypeIcon(StockMovementType type) {
    switch (type) {
      case StockMovementType.restock:
        return Icons.arrow_downward_rounded;
      case StockMovementType.sale:
        return Icons.shopping_bag_outlined;
      case StockMovementType.damage:
        return Icons.delete_sweep_outlined;
      case StockMovementType.adjustment:
        return Icons.tune_rounded;
      case StockMovementType.returnItem:
        return Icons.replay_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<StockMovementCubit, StockMovementState>(
      builder: (context, state) {
        if (state is StockMovementLoading) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is StockMovementError) {
          return SizedBox(
            height: 250,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 36, color: AppColor.error),
                  const SizedBox(height: 8),
                  Text(state.message, style: const TextStyle(color: AppColor.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<StockMovementCubit>().loadStockMovements(),
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final movements = state is StockMovementLoaded ? state.filteredMovements : <StockMovementModel>[];
        final totalInflow = state is StockMovementLoaded ? state.totalInflowCount : 0;
        final totalInflowVal = state is StockMovementLoaded ? state.totalInflowValue : 0.0;
        final totalOutflow = state is StockMovementLoaded ? state.totalOutflowCount : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Summary Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;

                final kpis = [
                  _buildSummaryCard(
                    title: 'total_restocked_units'.tr,
                    value: 'units_count'.trParams({'count': totalInflow.toString()}),
                    icon: Icons.inventory_rounded,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  _buildSummaryCard(
                    title: 'total_restock_capital'.tr,
                    value: AppFormatters.formatEGP(totalInflowVal),
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF0EA5E9),
                    isDark: isDark,
                  ),
                  _buildSummaryCard(
                    title: 'total_outflow_units'.tr,
                    value: 'units_count'.trParams({'count': totalOutflow.toString()}),
                    icon: Icons.outbox_rounded,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ];

                if (isCompact) {
                  return Column(
                    children: kpis
                        .map((card) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: card,
                            ))
                        .toList(),
                  );
                }

                return Row(
                  children: kpis
                      .map((card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: card,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Filter Bar & Search
            Container(
              padding: const EdgeInsets.all(AppSizes.sm + 4),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'search_stock_movements_hint'.tr,
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<StockMovementCubit>().filterMovements(query: '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            context.read<StockMovementCubit>().filterMovements(query: val.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'refresh_log_tooltip'.tr,
                        onPressed: () => context.read<StockMovementCubit>().loadStockMovements(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Filter Chips by Type
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'all_filter'.tr,
                          isSelected: _selectedTypeFilter == null,
                          onSelected: () {
                            setState(() => _selectedTypeFilter = null);
                            context.read<StockMovementCubit>().filterMovements(clearType: true);
                          },
                          color: AppColor.primary,
                          isDark: isDark,
                        ),
                        ...StockMovementType.values.map((type) {
                          final isSelected = _selectedTypeFilter == type;
                          final typeColor = _getTypeColor(type);
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildFilterChip(
                              label: isArabic ? type.arabicName : type.displayName,
                              isSelected: isSelected,
                              onSelected: () {
                                setState(() => _selectedTypeFilter = type);
                                context.read<StockMovementCubit>().filterMovements(type: type);
                              },
                              color: typeColor,
                              isDark: isDark,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Movements Table / List
            if (movements.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_stock_movements_title'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'no_stock_movements_desc'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: movements.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final m = movements[idx];
                    final typeColor = _getTypeColor(m.type);
                    final isPositive = m.quantity > 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Type Icon & Badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getTypeIcon(m.type), size: 18, color: typeColor),
                          ),
                          const SizedBox(width: 12),

                          // Product & SKU Info
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.productTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (m.variationSku.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                                          ),
                                        ),
                                        child: Text(
                                          m.variationSku,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      isArabic ? m.type.arabicName : m.type.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: typeColor,
                                      ),
                                    ),
                                    if (m.supplierName.isNotEmpty) ...[
                                      const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        m.supplierName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                        ),
                                      ),
                                    ],
                                    if (m.invoiceNumber.isNotEmpty) ...[
                                      const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        '#${m.invoiceNumber}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Movement Flow & Cost
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isPositive ? "+" : ""}${m.quantity}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'units_short'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${m.previousStock} ➔ ${m.newStock}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                ),
                              ),
                              if (m.totalCost > 0)
                                Text(
                                  AppFormatters.formatEGP(m.totalCost),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color color,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (_) => onSelected(),
    );
  }
}
