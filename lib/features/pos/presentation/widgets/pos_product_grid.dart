import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../roles/domain/models/admin_role.dart';
import '../../../roles/presentation/cubit/auth_role_cubit.dart';
import '../../data/models/pos_catalog_item.dart';
import '../cubit/pos_cubit.dart';
import '../cubit/pos_state.dart';

/// Product & Variation Catalog View with slim horizontal cards listed vertically under each other.
/// Every variation (e.g. 49 variations of Frisky) is an individual slim horizontal card
/// showing image on the left, brand, flavor, nicotine, size, style, stock icon,
/// cost price (Admin permission controlled), regular price, sale price, and add button side-by-side.
class PosProductGrid extends StatefulWidget {
  const PosProductGrid({super.key});

  static const List<ProductCategoryType> posCategories = [
    ProductCategoryType.liquid,
    ProductCategoryType.disposable,
    ProductCategoryType.device,
    ProductCategoryType.pod,
    ProductCategoryType.coil,
    ProductCategoryType.accessory,
  ];

  @override
  State<PosProductGrid> createState() => _PosProductGridState();
}

class _PosProductGridState extends State<PosProductGrid> {
  bool _inStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        final showCostPrice = authState.hasPermission(
          AdminPermission.viewCostPrice,
        );

        return BlocBuilder<PosCubit, PosState>(
          builder: (context, state) {
            // Retrieve flattened variation items matching active search & category
            var catalogItems = state.filteredCatalogItems;

            if (_inStockOnly) {
              catalogItems = catalogItems
                  .where((item) => item.stock > 0)
                  .toList();
            }

            final allItems = state.allCatalogItems;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Category Filter Pills & Control Sub-bar
                _buildControlBar(
                  context,
                  state,
                  allItems,
                  catalogItems.length,
                  isDark,
                ),
                const SizedBox(height: 8),

                // 2. Direct Variation Structured Table View
                Expanded(
                  child: catalogItems.isEmpty
                      ? _buildEmptyState(
                          context,
                          isDark,
                          state.searchQuery.isNotEmpty ||
                              state.selectedCategory != null,
                        )
                      : _buildTableView(
                          context,
                          catalogItems,
                          isDark,
                          showCostPrice: showCostPrice,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    PosState state,
    List<PosCatalogItem> allItems,
    int filteredCount,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Pills
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            children: [
              _buildCategoryChip(
                context: context,
                label: 'all_categories_filter'.trParams({
                  'count': '${allItems.length}',
                }),
                isSelected: state.selectedCategory == null,
                onTap: () => context.read<PosCubit>().filterProducts(
                  clearCategory: true,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              ...PosProductGrid.posCategories.map((cat) {
                final isSelected = state.selectedCategory == cat;
                final count = allItems
                    .where((i) => i.categoryType == cat)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCategoryChip(
                    context: context,
                    label: '${_getCategoryLabel(cat)} ($count)',
                    isSelected: isSelected,
                    onTap: () =>
                        context.read<PosCubit>().filterProducts(category: cat),
                    isDark: isDark,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Sub-bar: Item Count, In-Stock Filter, and Reset
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Available items count & in-stock toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColor.darkSubCard
                        : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? AppColor.darkBorder
                          : AppColor.lightBorder,
                    ),
                  ),
                  child: Text(
                    'items_available_count'.trParams({
                      'count': '$filteredCount',
                    }),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColor.textSecondaryDark
                          : AppColor.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // In-stock only toggle chip
                InkWell(
                  onTap: () => setState(() => _inStockOnly = !_inStockOnly),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: _inStockOnly
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : (isDark
                                ? AppColor.darkSubCard
                                : AppColor.lightSubCard),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _inStockOnly
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _inStockOnly
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 13,
                          color: _inStockOnly
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'in_stock_only'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _inStockOnly
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _inStockOnly
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? AppColor.textSecondaryDark
                                      : AppColor.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Quick reset indicator if filtered
            if (state.searchQuery.isNotEmpty ||
                state.selectedCategory != null ||
                _inStockOnly)
              InkWell(
                onTap: () {
                  context.read<PosCubit>().filterProducts(
                    query: '',
                    clearCategory: true,
                  );
                  setState(() => _inStockOnly = false);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 13,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'reset_filters'.tr,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColor.primary,
      backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected
              ? AppColor.primary
              : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  /// Clean, elegant Table View container with sticky header and scrollable rows
  Widget _buildTableView(
    BuildContext context,
    List<PosCatalogItem> items,
    bool isDark, {
    required bool showCostPrice,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const minThreshold = 440.0;
            final isNarrow = constraints.maxWidth < minThreshold;

            Widget tableContent = SizedBox(
              width: isNarrow ? minThreshold : constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Sticky Table Header
                  _buildTableHeader(isDark, showCostPrice, isArabic: isArabic),

                  // 2. Table Rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            (isDark
                                    ? AppColor.darkBorder
                                    : AppColor.lightBorder)
                                .withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildTableRow(
                          context,
                          item,
                          isDark,
                          isArabic: isArabic,
                          showCostPrice: showCostPrice,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );

            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: tableContent,
              );
            }
            return tableContent;
          },
        ),
      ),
    );
  }

  /// Sticky table header bar with clear distinct column names distributed proportionally
  Widget _buildTableHeader(bool isDark, bool showCostPrice, {required bool isArabic}) {
    final headerChildren = <Widget>[
      // 1. Product & Specs Column
      Expanded(
        flex: showCostPrice ? 4 : 5,
        child: Text(
          isArabic ? 'الصنف والمواصفات' : 'Item & Specs',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
      ),
      const SizedBox(width: 8),

      // 2. Stock Column
      Expanded(
        flex: 2,
        child: Center(
          child: Text(
            isArabic ? 'المخزون' : 'Stock',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
    ];

    if (showCostPrice) {
      headerChildren.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              isArabic ? 'سعر التكلفة' : 'Cost',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
      );
      headerChildren.add(const SizedBox(width: 8));
    }

    headerChildren.addAll([
      // 4. Selling Price Column
      Expanded(
        flex: 2,
        child: Center(
          child: Text(
            isArabic ? 'سعر البيع' : 'Price',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),

      // 5. Action Column
      Expanded(
        flex: 2,
        child: Center(
          child: Text(
            isArabic ? 'إضافة' : 'Action',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            ),
          ),
        ),
      ),
    ]);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            width: 1.2,
          ),
        ),
      ),
      child: Row(children: headerChildren),
    );
  }

  /// Interactive table row for a single catalog variation item
  Widget _buildTableRow(
    BuildContext context,
    PosCatalogItem item,
    bool isDark, {
    required bool isArabic,
    required bool showCostPrice,
  }) {
    final isOutOfStock = item.isOutOfStock;

    return Opacity(
      opacity: isOutOfStock ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOutOfStock
              ? () {
                  HelperFun.showNotificationAlert(
                    title: 'out_of_stock'.tr,
                    message: isArabic
                        ? '⚠️ الصنف "${item.displayHeadline}" نفذ من المخزون بالكامل!'
                        : '⚠️ Item "${item.displayHeadline}" is out of stock!',
                  );
                }
              : () {
                  context.read<PosCubit>().addToCart(
                    item.product,
                    variation: item.variation,
                  );
                  try {
                    HapticFeedback.lightImpact();
                  } catch (_) {}
                },
          hoverColor: isDark
              ? AppColor.primary.withValues(alpha: 0.08)
              : AppColor.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // 1. Product & Variation Spec Column
                Expanded(
                  flex: showCostPrice ? 4 : 5,
                  child: Row(
                    children: [
                      // Thumbnail Image
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? AppColor.darkBorder
                                : AppColor.lightBorder,
                          ),
                        ),
                        child: item.thumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  item.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildFallbackIcon(
                                    item.categoryType,
                                    size: 16,
                                  ),
                                ),
                              )
                            : _buildFallbackIcon(item.categoryType, size: 16),
                      ),
                      const SizedBox(width: 8),

                      // Brand Tag, Headline & Localized Specs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                if (item.brandName.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      item.brandName,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: Text(
                                    item.displayHeadline,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.5),
                            // Spec badges (Nicotine, Size, Style/MTL/DL, Resistance, Color) - Standard Vape Specs
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Nicotine (e.g. 30mg, 50mg, 3mg)
                                  if (item.nicotine != null &&
                                      item.nicotine!.isNotEmpty) ...[
                                    _buildSpecPill(
                                      label: item.nicotine!,
                                      bgColor: isDark
                                          ? const Color(
                                              0xFF312E81,
                                            ).withValues(alpha: 0.6)
                                          : const Color(0xFFEEF2FF),
                                      borderColor: isDark
                                          ? const Color(
                                              0xFF4F46E5,
                                            ).withValues(alpha: 0.5)
                                          : const Color(0xFFC7D2FE),
                                      textColor: isDark
                                          ? const Color(0xFFA5B4FC)
                                          : const Color(0xFF4338CA),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],

                                  // Size / Volume (e.g. 30ml, 60ml)
                                  if (item.size != null &&
                                      item.size!.isNotEmpty) ...[
                                    _buildSpecPill(
                                      label: item.size!,
                                      bgColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      borderColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFCBD5E1),
                                      textColor: isDark
                                          ? AppColor.textSecondaryDark
                                          : AppColor.textSecondaryLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],

                                  // Style (e.g. MTL, DL, Salt Nic, Freebase)
                                  if (item.style != null &&
                                      item.style!.isNotEmpty) ...[
                                    _buildSpecPill(
                                      label: item.style!,
                                      bgColor: isDark
                                          ? const Color(
                                              0xFF064E3B,
                                            ).withValues(alpha: 0.6)
                                          : const Color(0xFFECFDF5),
                                      borderColor: isDark
                                          ? const Color(
                                              0xFF059669,
                                            ).withValues(alpha: 0.5)
                                          : const Color(0xFFA7F3D0),
                                      textColor: isDark
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF047857),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],

                                  // Resistance (e.g. 0.8Ω, 1.2Ω)
                                  if (item.resistance != null &&
                                      item.resistance!.isNotEmpty) ...[
                                    _buildSpecPill(
                                      label: item.resistance!,
                                      bgColor: isDark
                                          ? const Color(
                                              0xFF78350F,
                                            ).withValues(alpha: 0.5)
                                          : const Color(0xFFFEF3C7),
                                      borderColor: isDark
                                          ? const Color(
                                              0xFFD97706,
                                            ).withValues(alpha: 0.4)
                                          : const Color(0xFFFDE68A),
                                      textColor: isDark
                                          ? const Color(0xFFFDE047)
                                          : const Color(0xFFB45309),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    const SizedBox(width: 3.5),
                                  ],

                                  // Color
                                  if (item.color != null &&
                                      item.color!.isNotEmpty) ...[
                                    _buildColorBadge(item.color!, isDark),
                                    const SizedBox(width: 3.5),
                                  ],

                                  // Other attributes
                                  ...item.attributeValues.entries
                                      .where((e) {
                                        final k = e.key.toLowerCase();
                                        return !k.contains('flav') &&
                                            !k.contains('nic') &&
                                            !k.contains('size') &&
                                            !k.contains('res') &&
                                            !k.contains('color') &&
                                            !k.contains('style') &&
                                            !k.contains('نكهة') &&
                                            !k.contains('نيكوتين') &&
                                            !k.contains('حجم') &&
                                            !k.contains('لون') &&
                                            !k.contains('مقاومة');
                                      })
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            left: 3.5,
                                          ),
                                          child: _buildSpecPill(
                                            label: '${e.key}: ${e.value}',
                                            bgColor: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF1F5F9),
                                            borderColor: isDark
                                                ? AppColor.darkBorder
                                                : AppColor.lightBorder,
                                            textColor: isDark
                                                ? AppColor.textSecondaryDark
                                                : AppColor.textSecondaryLight,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Stock Column
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _buildMinimalStockIndicator(item, isDark, isArabic),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Cost Price Column (if permitted)
                if (showCostPrice)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _buildCostPriceCell(item, isDark),
                    ),
                  ),
                if (showCostPrice) const SizedBox(width: 8),

                // 4. Selling Price Column (Without "Sale" tag as requested)
                Expanded(
                  flex: 2,
                  child: Center(child: _buildPriceCell(item, isDark)),
                ),
                const SizedBox(width: 8),

                // 5. Add Button Column
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _buildAddButton(
                      context,
                      item,
                      isOutOfStock,
                      isArabic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cost price cell formatted neatly with currency
  Widget _buildCostPriceCell(PosCatalogItem item, bool isDark) {
    if (item.costPrice <= 0) {
      return Text(
        '-',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B1A45).withValues(alpha: 0.4) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.4) : const Color(0xFFDDD6FE),
        ),
      ),
      child: Text(
        AppFormatters.formatEGP(item.costPrice),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8B5CF6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Price cell showing original price struck-through if discounted, without "Sale" badge
  Widget _buildPriceCell(PosCatalogItem item, bool isDark) {
    final hasDiscount = item.hasDiscount;

    if (hasDiscount) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppFormatters.formatEGP(item.originalPrice),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
          Text(
            AppFormatters.formatEGP(item.price),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColor.primary,
            ),
          ),
        ],
      );
    }

    return Text(
      AppFormatters.formatEGP(item.price),
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        color: AppColor.primary,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Compact Add Button for table cell
  Widget _buildAddButton(
    BuildContext context,
    PosCatalogItem item,
    bool isOutOfStock,
    bool isArabic,
  ) {
    final label = isOutOfStock
        ? (isArabic ? 'نفذ' : 'Out')
        : (isArabic ? 'إضافة' : 'Add');

    return Container(
      height: 28,
      constraints: const BoxConstraints(maxWidth: 84),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? Colors.grey.withValues(alpha: 0.2)
            : AppColor.primary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isOutOfStock
            ? null
            : [
                BoxShadow(
                  color: AppColor.primary.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: InkWell(
        onTap: isOutOfStock
            ? () {
                HelperFun.showNotificationAlert(
                  title: 'out_of_stock'.tr,
                  message: isArabic
                      ? '⚠️ الصنف "${item.displayHeadline}" نفذ من المخزون بالكامل!'
                      : '⚠️ Item "${item.displayHeadline}" is out of stock!',
                );
              }
            : () {
                context.read<PosCubit>().addToCart(
                  item.product,
                  variation: item.variation,
                );
                try {
                  HapticFeedback.lightImpact();
                } catch (_) {}
              },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOutOfStock ? Icons.block_rounded : Icons.add_rounded,
                    size: 13,
                    color: isOutOfStock ? Colors.grey.shade500 : Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isOutOfStock ? Colors.grey.shade500 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Minimalist stock indicator with clear icon and count
  Widget _buildMinimalStockIndicator(
    PosCatalogItem item,
    bool isDark,
    bool isArabic,
  ) {
    final isOutOfStock = item.isOutOfStock;
    final isLow = item.isLowStock;

    final color = isOutOfStock
        ? AppColor.error
        : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    final icon = isOutOfStock
        ? Icons.remove_circle_outline_rounded
        : (isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded);

    final tooltip = isOutOfStock
        ? (isArabic ? 'نفذ من المخزون (0)' : 'Out of stock (0)')
        : (isLow
              ? (isArabic
                    ? 'مخزون منخفض: ${item.stock}'
                    : 'Low stock: ${item.stock}')
              : (isArabic
                    ? 'المتاح في المخزون: ${item.stock}'
                    : 'In stock: ${item.stock}'));

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 11.5, color: color),
              const SizedBox(width: 3),
              Text(
                '${item.stock}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Color badge with color circle and clean readable color name
  Widget _buildColorBadge(String colorText, bool isDark) {
    final colors = ColorUtils.parseColorsFromText(colorText);
    final label = ColorUtils.getReadableColorName(colorText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (colors.isNotEmpty) ...[
            Container(
              width: 7.5,
              height: 7.5,
              decoration: BoxDecoration(
                color: colors.first,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0.5),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecPill({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: fontWeight,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ProductCategoryType type, {double size = 20}) {
    IconData icon = switch (type) {
      ProductCategoryType.liquid => Icons.water_drop_outlined,
      ProductCategoryType.disposable => Icons.battery_charging_full_rounded,
      ProductCategoryType.device => Icons.vaping_rooms_outlined,
      ProductCategoryType.pod => Icons.extension_outlined,
      ProductCategoryType.coil => Icons.flash_on_outlined,
      ProductCategoryType.accessory => Icons.cable_outlined,
    };
    return Center(
      child: Icon(icon, size: size, color: Colors.grey.withValues(alpha: 0.45)),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'no_matching_products'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'no_matching_products_desc'.tr,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColor.textMutedDark
                    : AppColor.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<PosCubit>().filterProducts(
                    query: '',
                    clearCategory: true,
                  );
                  setState(() => _inStockOnly = false);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('reset_filters'.tr),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(ProductCategoryType type) {
    return switch (type) {
      ProductCategoryType.liquid => 'category_liquids'.tr,
      ProductCategoryType.disposable => 'category_disposable'.tr,
      ProductCategoryType.device => 'category_devices'.tr,
      ProductCategoryType.pod => 'category_pods'.tr,
      ProductCategoryType.coil => 'category_coils'.tr,
      ProductCategoryType.accessory => 'category_accessories'.tr,
    };
  }
}
