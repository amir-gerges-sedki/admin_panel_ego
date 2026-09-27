import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductSelectorDialog extends StatefulWidget {
  final List<String> initialSelectedIds;
  final ValueChanged<List<ProductModel>> onSelected;
  final String? title;
  final String? subtitle;

  const ProductSelectorDialog({
    super.key,
    required this.initialSelectedIds,
    required this.onSelected,
    this.title,
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> initialSelectedIds,
    required ValueChanged<List<ProductModel>> onSelected,
    String? title,
    String? subtitle,
  }) {
    return UnifiedModalSheet.show(
      context: context,
      title: title ?? 'اختيار الأجهزة والتانكات المتوافقة (Compatible Products)',
      subtitle: subtitle ??
          'ابحث واختر الأجهزة والتانكات من المتجر لربطها كمنتجات متوافقة مع هذا المنتج',
      icon: Icons.link_rounded,
      maxWidth: 780,
      content: ProductSelectorDialog(
        initialSelectedIds: initialSelectedIds,
        onSelected: onSelected,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<ProductSelectorDialog> {
  late final TextEditingController _searchController;
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  ProductCategoryType? _selectedCategoryFilter;
  final Map<String, ProductModel> _selectedProductsMap = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = sl<ProductRepository>();
      final products = await repo.getProducts();

      if (!mounted) return;

      // Map previously selected items
      final initialMap = <String, ProductModel>{};
      for (final p in products) {
        if (widget.initialSelectedIds.contains(p.id)) {
          initialMap[p.id] = p;
        }
      }

      setState(() {
        _allProducts = products;
        _selectedProductsMap.addAll(initialMap);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل المنتجات: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleProduct(ProductModel product) {
    setState(() {
      if (_selectedProductsMap.containsKey(product.id)) {
        _selectedProductsMap.remove(product.id);
      } else {
        _selectedProductsMap[product.id] = product;
      }
    });
  }

  List<ProductModel> get _filteredProducts {
    return _allProducts.where((product) {
      // 1. Category Filter
      if (_selectedCategoryFilter != null &&
          product.categoryType != _selectedCategoryFilter) {
        return false;
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = product.displayTitle.toLowerCase().contains(q);
        final matchBrand = product.brand.name.toLowerCase().contains(q);
        final matchCategory =
            product.categoryType.displayName.toLowerCase().contains(q) ||
            product.categoryType.arabicName.toLowerCase().contains(q);
        final matchSku = product.productVariations
            .any((v) => v.sku.toLowerCase().contains(q));

        if (!matchTitle && !matchBrand && !matchCategory && !matchSku) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المنتجات من قاعدة البيانات...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColor.error),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColor.error)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final displayed = _filteredProducts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search & Filter Bar ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الجهاز، الموديل، الماركة، أو الـ SKU...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Quick Category Filter Chips ──────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(
                label: 'الكل (All)',
                isSelected: _selectedCategoryFilter == null,
                onTap: () => setState(() => _selectedCategoryFilter = null),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                label: 'أجهزة وسحبات (Devices)',
                icon: Icons.phone_android_rounded,
                isSelected:
                    _selectedCategoryFilter == ProductCategoryType.device,
                onTap: () => setState(
                  () => _selectedCategoryFilter = ProductCategoryType.device,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                label: 'بودات وخرطوشات (Pods)',
                icon: Icons.view_carousel_rounded,
                isSelected: _selectedCategoryFilter == ProductCategoryType.pod,
                onTap: () => setState(
                  () => _selectedCategoryFilter = ProductCategoryType.pod,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                label: 'كويلات (Coils)',
                icon: Icons.bolt_rounded,
                isSelected: _selectedCategoryFilter == ProductCategoryType.coil,
                onTap: () => setState(
                  () => _selectedCategoryFilter = ProductCategoryType.coil,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                label: 'ملحقات (Accessories)',
                icon: Icons.handyman_rounded,
                isSelected:
                    _selectedCategoryFilter == ProductCategoryType.accessory,
                onTap: () => setState(
                  () => _selectedCategoryFilter = ProductCategoryType.accessory,
                ),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Products List View ───────────────────────────────────────────
        Container(
          height: 360,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: displayed.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 38,
                        color: isDark
                            ? AppColor.textMutedDark
                            : AppColor.textMutedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد منتجات مطابقة لخيارات البحث',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColor.textMutedDark
                              : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: displayed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final product = displayed[index];
                    final isSelected =
                        _selectedProductsMap.containsKey(product.id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleProduct(product),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                                : (isDark
                                    ? AppColor.darkSubCard
                                    : AppColor.lightSubCard),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark
                                      ? AppColor.darkBorder
                                      : AppColor.lightBorder),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) => _toggleProduct(product),
                              ),
                              const SizedBox(width: 8),

                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade100,
                                  child: product.thumbnail.isNotEmpty
                                      ? Image.network(
                                          product.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_not_supported_rounded,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.category_rounded,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Title & Brand
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.displayTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (product.brand.name.isNotEmpty) ...[
                                          Text(
                                            product.brand.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product.categoryType.arabicName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Price & Stock
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${product.price.toStringAsFixed(0)} EGP',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  Text(
                                    'مخزون: ${product.stock}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: product.stock > 0
                                          ? Colors.grey
                                          : AppColor.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),

        // ── Action Buttons Footer ────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Selected Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'تم تحديد ${_selectedProductsMap.length} منتج',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),

            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onSelected(_selectedProductsMap.values.toList());
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('تأكيد واختيار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
