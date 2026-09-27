import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/widgets/order_details_drawer.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/dashboard_date_filter_bar.dart';

class ProductSalesReportScreen extends StatefulWidget {
  final DashboardAnalyticsModel initialAnalytics;

  const ProductSalesReportScreen({super.key, required this.initialAnalytics});

  static Future<void> show(BuildContext context, DashboardAnalyticsModel analytics) {
    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: ProductSalesReportScreen(initialAnalytics: analytics),
      ),
    );
  }

  @override
  State<ProductSalesReportScreen> createState() => _ProductSalesReportScreenState();
}

class _ProductSalesReportScreenState extends State<ProductSalesReportScreen> {
  String _searchQuery = '';
  String _channelFilter = 'ALL'; // ALL, ONLINE, POS

  void _showProductOrdersList(
    BuildContext context,
    ProductSalesItemMetrics product,
    List<OrderModel> allOrders,
  ) {
    final isDark = HelperFun.isDarkMode(context);
    final matchingOrders = allOrders
        .where((o) => product.orderIds.contains(o.id) || o.items.any((i) => i.productId == product.productId))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلبات وفواتير: ${product.productTitle}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'إجمالي ${matchingOrders.length} طلب / فاتورة',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      if (Navigator.of(ctx).canPop()) {
                        Navigator.of(ctx).pop();
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: matchingOrders.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد طلبات مسجلة',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: matchingOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ord = matchingOrders[index];
                          final item = ord.items.where((i) => i.productId == product.productId).firstOrNull;
                          final qty = item?.quantity ?? 1;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                              border: Border.all(
                                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (ord.isPosSale ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    ord.isPosSale ? Icons.storefront_rounded : Icons.phone_android_rounded,
                                    color: ord.isPosSale ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'طلب #${ord.id}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        '${ord.sourceDisplayLabel} • ${AppFormatters.formatDateTime(ord.orderDate)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'الكمية: $qty قطعة',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatEGP(ord.totalAmount),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  onPressed: () {
                                    OrderDetailsDrawer.show(
                                      context,
                                      ord,
                                      onStatusChanged: (newStatus) {
                                        context.read<OrderCubit>().updateStatus(ord.id, newStatus);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColor.darkSurface : AppColor.lightSurface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColor.darkCard : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_rounded, size: 20, color: AppColor.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقرير تفاصيل مبيعات المنتجات والأصناف',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  'تفاصيل الكميات المباعة، التكلفة، وصافي الربح لكل منتج',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'close'.tr,
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final analytics = state is DashboardLoaded ? state.analytics : widget.initialAnalytics;
          final allProductSales = analytics.productSales;

          // Filter by search query & channel
          final filteredSales = allProductSales.where((p) {
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchesTitle = p.productTitle.toLowerCase().contains(q);
              final matchesSku = p.sku.toLowerCase().contains(q);
              final matchesBrand = p.brandName.toLowerCase().contains(q);
              if (!matchesTitle && !matchesSku && !matchesBrand) return false;
            }

            if (_channelFilter == 'ONLINE' && p.onlineQuantity <= 0) return false;
            if (_channelFilter == 'POS' && p.posQuantity <= 0) return false;

            return true;
          }).toList();

          final int totalUnitsSold = filteredSales.fold(0, (acc, p) => acc + p.totalQuantity);
          final double totalRevenue = filteredSales.fold(0.0, (acc, p) => acc + p.totalRevenue);
          final double totalCost = filteredSales.fold(0.0, (acc, p) => acc + p.totalCost);
          final double totalNetProfit = filteredSales.fold(0.0, (acc, p) => acc + p.netProfit);

          return BlocBuilder<OrderCubit, OrderState>(
            builder: (context, orderState) {
              final allOrders = orderState is OrderLoaded ? orderState.orders : <OrderModel>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Date Range Filter Bar
                    DashboardDateFilterBar(analytics: analytics),
                    const SizedBox(height: AppSizes.md),

                    // 2. Summary KPI Metrics
                    _buildKpiMetricsRow(
                      isDark: isDark,
                      totalUnitsSold: totalUnitsSold,
                      totalRevenue: totalRevenue,
                      totalCost: totalCost,
                      totalNetProfit: totalNetProfit,
                      uniqueProductsCount: filteredSales.length,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // 3. Search Bar and Channel Filter Pills
                    _buildSearchAndFilterControls(isDark: isDark),
                    const SizedBox(height: AppSizes.md),

                    // 4. Products Sales Items Table / List
                    if (filteredSales.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      _buildProductSalesList(
                        context: context,
                        isDark: isDark,
                        products: filteredSales,
                        allOrders: allOrders,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKpiMetricsRow({
    required bool isDark,
    required int totalUnitsSold,
    required double totalRevenue,
    required double totalCost,
    required double totalNetProfit,
    required int uniqueProductsCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final card1 = _buildKpiBox(
          isDark: isDark,
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'إجمالي القطع المباعة',
          value: '$totalUnitsSold قطعة',
          subtitle: 'من $uniqueProductsCount منتج مختلف',
        );

        final card2 = _buildKpiBox(
          isDark: isDark,
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'إجمالي مبيعات المنتجات',
          value: AppFormatters.formatEGP(totalRevenue),
          subtitle: 'التكلفة: ${AppFormatters.formatEGP(totalCost)}',
        );

        final card3 = _buildKpiBox(
          isDark: isDark,
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'صافي أرباح المنتجات',
          value: AppFormatters.formatEGP(totalNetProfit),
          subtitle: 'هامش الربح: ${totalRevenue > 0 ? ((totalNetProfit / totalRevenue) * 100).toStringAsFixed(1) : '0'}%',
          isProfit: true,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: AppSizes.md),
              Expanded(child: card2),
              const SizedBox(width: AppSizes.md),
              Expanded(child: card3),
            ],
          );
        }

        return Column(
          children: [
            card1,
            const SizedBox(height: AppSizes.sm),
            card2,
            const SizedBox(height: AppSizes.sm),
            card3,
          ],
        );
      },
    );
  }

  Widget _buildKpiBox({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    bool isProfit = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isProfit ? iconColor.withValues(alpha: 0.4) : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isProfit ? iconColor : (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterControls({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Search Input
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج، البراند أو الـ SKU...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Channel Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterChip(
                  label: 'كافة القنوات',
                  isSelected: _channelFilter == 'ALL',
                  isDark: isDark,
                  onTap: () => setState(() => _channelFilter = 'ALL'),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: '📱 أونلاين فقط',
                  isSelected: _channelFilter == 'ONLINE',
                  isDark: isDark,
                  onTap: () => setState(() => _channelFilter = 'ONLINE'),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: '🏪 كاشير الفرع فقط',
                  isSelected: _channelFilter == 'POS',
                  isDark: isDark,
                  onTap: () => setState(() => _channelFilter = 'POS'),
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSalesList({
    required BuildContext context,
    required bool isDark,
    required List<ProductSalesItemMetrics> products,
    required List<OrderModel> allOrders,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
        itemBuilder: (context, index) {
          final prod = products[index];

          return Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                final leadingInfo = Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index < 3 ? const Color(0xFFF59E0B) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: index < 3 ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        child: prod.productImage.isNotEmpty
                            ? Image.network(
                                prod.productImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_outlined, size: 20),
                              )
                            : const Icon(Icons.inventory_2_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Title, Brand, SKU
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.productTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (prod.brandName.isNotEmpty) ...[
                                Text(
                                  prod.brandName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.primary),
                                ),
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 6),
                              ],
                              if (prod.sku.isNotEmpty)
                                Text(
                                  'SKU: ${prod.sku}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final channelPills = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prod.onlineQuantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '📱 أونلاين: ${prod.onlineQuantity}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                        ),
                      ),
                    if (prod.posQuantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🏪 الفرع: ${prod.posQuantity}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                  ],
                );

                final financialMetrics = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Sold Quantity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'إجمالي المباع',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          '${prod.totalQuantity} قطعة',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Total Revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'إجمالي المبيعات',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          AppFormatters.formatEGP(prod.totalRevenue),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Net Profit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'صافي الربح',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Text(
                              AppFormatters.formatEGP(prod.netProfit),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: prod.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: (prod.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${prod.profitMargin.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: prod.netProfit >= 0 ? const Color(0xFF10B981) : AppColor.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // View Orders Button
                    OutlinedButton(
                      onPressed: () => _showProductOrdersList(context, prod, allOrders),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        side: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'الطلبات (${prod.ordersCount})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 5, child: leadingInfo),
                      const SizedBox(width: 10),
                      channelPills,
                      const SizedBox(width: 14),
                      financialMetrics,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leadingInfo,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        channelPills,
                        financialMetrics,
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            'لا توجد منتجات مباعة في الفترة المحددة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جرّب تغيير الفترة الزمنية بالتقويم أو إزالة الفلاتر',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
