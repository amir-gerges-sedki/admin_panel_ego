import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../common/widgets/image_picker/dual_image_picker_field.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_bloc.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../data/models/banner_model.dart';
import '../cubit/banner_cubit.dart';

class BannerFormDialog extends StatefulWidget {
  final BannerModel? initialBanner;
  final ValueChanged<BannerModel> onSave;

  const BannerFormDialog({super.key, this.initialBanner, required this.onSave});

  static void show(
    BuildContext context, {
    BannerModel? initialBanner,
    required ValueChanged<BannerModel> onSave,
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: initialBanner == null ? 'add_banner'.tr : 'edit_banner'.tr,
      icon: Icons.view_carousel_outlined,
      maxWidth: 580,
      content: BannerFormDialog(initialBanner: initialBanner, onSave: onSave),
    );
  }

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageController;
  late TextEditingController _targetController;
  bool _active = true;

  // Destination & Product Sponsorship
  String _destinationType = 'product'; // 'product' or 'custom'
  String? _selectedProductId;
  String? _selectedProductTitle;
  String? _selectedProductThumbnail;
  String? _selectedProductBrand;
  double? _selectedProductPrice;

  @override
  void initState() {
    super.initState();
    final banner = widget.initialBanner;
    _titleController = TextEditingController(text: banner?.title ?? '');
    _imageController = TextEditingController(text: banner?.imageUrl ?? '');
    _targetController = TextEditingController(
      text: banner?.targetScreen ?? (banner?.isProductTarget == true ? '/productDetailsScreen' : '/shop'),
    );
    _active = banner?.active ?? true;

    if (banner != null) {
      if (banner.isProductTarget) {
        _destinationType = 'product';
        _selectedProductId = banner.productId;
        _selectedProductTitle = banner.productTitle;
      } else {
        final t = (banner.targetType ?? banner.targetScreen).toLowerCase();
        if (t.contains('new')) {
          _destinationType = 'newArrivals';
        } else if (t.contains('popular') || t.contains('best')) {
          _destinationType = 'popular';
        } else {
          _destinationType = 'sale';
        }
      }
    }

    _imageController.addListener(_onImageChanged);

    // Ensure products are loaded for picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productCubit = context.read<ProductCubit>();
      if (productCubit.state is! ProductLoaded) {
        productCubit.loadProducts();
      } else if (_selectedProductId != null && _selectedProductTitle == null) {
        _resolveInitialProductDetails((productCubit.state as ProductLoaded).products);
      }
    });
  }

  void _onImageChanged() {
    if (mounted) setState(() {});
  }

  void _resolveInitialProductDetails(List<ProductModel> products) {
    if (_selectedProductId == null) return;
    final match = products.where((p) => p.id == _selectedProductId).firstOrNull;
    if (match != null && mounted) {
      setState(() {
        _selectedProductTitle = match.displayTitle;
        _selectedProductThumbnail = match.thumbnail;
        _selectedProductBrand = match.brand.name;
        _selectedProductPrice = match.price;
      });
    }
  }

  @override
  void dispose() {
    _imageController.removeListener(_onImageChanged);
    _titleController.dispose();
    _imageController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProductId = product.id;
      _selectedProductTitle = product.displayTitle;
      _selectedProductThumbnail = product.thumbnail;
      _selectedProductBrand = product.brand.name;
      _selectedProductPrice = product.price;
      _targetController.text = '/productDetailsScreen';

      // Smart autofill if banner title / image are currently empty
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = product.displayTitle;
      }
      if (_imageController.text.trim().isEmpty && product.thumbnail.isNotEmpty) {
        _imageController.text = product.thumbnail;
      }
    });
  }

  void _clearSelectedProduct() {
    setState(() {
      _selectedProductId = null;
      _selectedProductTitle = null;
      _selectedProductThumbnail = null;
      _selectedProductBrand = null;
      _selectedProductPrice = null;
    });
  }

  void _autofillFromProduct() {
    if (_selectedProductTitle != null && _selectedProductTitle!.isNotEmpty) {
      _titleController.text = _selectedProductTitle!;
    }
    if (_selectedProductThumbnail != null && _selectedProductThumbnail!.isNotEmpty) {
      _imageController.text = _selectedProductThumbnail!;
    }
  }

  void _openProductPickerModal(BuildContext context) {
    final productCubit = context.read<ProductCubit>();
    if (productCubit.state is! ProductLoaded) {
      productCubit.loadProducts();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return _ProductPickerSheet(
          initialSelectedId: _selectedProductId,
          onProductPicked: (product) {
            _selectProduct(product);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_imageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('required'.tr),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }

    if (_destinationType == 'product' && (_selectedProductId == null || _selectedProductId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_product_selected'.tr),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }

    String targetScreen;
    if (_destinationType == 'product') {
      targetScreen = '/productDetailsScreen';
    } else if (_destinationType == 'newArrivals') {
      targetScreen = '/new-arrivals';
    } else if (_destinationType == 'popular') {
      targetScreen = '/popular';
    } else {
      targetScreen = '/deals';
    }

    final banner = BannerModel(
      id: widget.initialBanner?.id ?? 'BANNER_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      imageUrl: _imageController.text.trim(),
      targetScreen: targetScreen,
      productId: _destinationType == 'product' ? _selectedProductId : null,
      productTitle: _destinationType == 'product' ? _selectedProductTitle : null,
      targetType: _destinationType,
      active: _active,
    );

    widget.onSave(banner);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, localeState) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Destination Type Selector
              Text(
                'target_type'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      isSelected: _destinationType == 'product',
                      icon: Icons.shopping_bag_outlined,
                      title: 'target_product_short'.tr,
                      onTap: () {
                        setState(() {
                          _destinationType = 'product';
                          _targetController.text = '/productDetailsScreen';
                        });
                      },
                      isDark: isDark,
                    ),
                  ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTypeOption(
                  isSelected: _destinationType == 'sale',
                  icon: Icons.local_offer_outlined,
                  title: 'target_sale'.tr,
                  onTap: () {
                    setState(() {
                      _destinationType = 'sale';
                      _targetController.text = '/deals';
                    });
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  isSelected: _destinationType == 'newArrivals',
                  icon: Icons.auto_awesome_outlined,
                  title: 'target_new_arrivals'.tr,
                  onTap: () {
                    setState(() {
                      _destinationType = 'newArrivals';
                      _targetController.text = '/new-arrivals';
                    });
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTypeOption(
                  isSelected: _destinationType == 'popular',
                  icon: Icons.star_outline_rounded,
                  title: 'target_popular'.tr,
                  onTap: () {
                    setState(() {
                      _destinationType = 'popular';
                      _targetController.text = '/popular';
                    });
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Conditional Product Picker or Target Preview
          if (_destinationType == 'product') ...[
            _buildProductSponsorSection(isDark),
            const SizedBox(height: AppSizes.md),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _destinationType == 'sale'
                        ? Icons.local_offer_outlined
                        : (_destinationType == 'newArrivals'
                            ? Icons.auto_awesome_outlined
                            : Icons.star_outline_rounded),
                    size: 18,
                    color: AppColor.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _destinationType == 'sale'
                        ? 'target_sale'.tr
                        : (_destinationType == 'newArrivals'
                            ? 'target_new_arrivals'.tr
                            : 'target_popular'.tr),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],

          // Banner Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '${'banner_title_col'.tr} *',
              hintText: 'banner_title_hint'.tr,
              prefixIcon: const Icon(Icons.title_rounded, size: 18),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
          ),
          const SizedBox(height: AppSizes.md),

          // Banner Image (URL or Firebase Storage Upload)
          DualImagePickerField(
            initialUrl: _imageController.text,
            label: 'banner_image',
            storageFolder: 'banners',
            customFileName: _titleController.text.trim().isNotEmpty
                ? 'banner_${_titleController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}'
                : null,
            previewWidth: 140,
            previewHeight: 80,
            isRequired: true,
            onImageChanged: (url) {
              setState(() {
                _imageController.text = url;
              });
            },
          ),
          const SizedBox(height: AppSizes.md),

          // Active Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Switch(
                  value: _active,
                  activeThumbColor: AppColor.primary,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(width: 8),
                Text('active'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Action Buttons
          Row(
            children: [
              if (widget.initialBanner != null) ...[
                TextButton.icon(
                  onPressed: () => _confirmDeleteFromDialog(context, widget.initialBanner!),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColor.error),
                  label: Text(
                    'delete_banner'.tr,
                    style: const TextStyle(color: AppColor.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr),
              ),
              const SizedBox(width: AppSizes.md),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                label: Text('save'.tr),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  void _confirmDeleteFromDialog(BuildContext context, BannerModel banner) {
    final isDark = HelperFun.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_banner_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          banner.title.trim().isNotEmpty
              ? 'delete_banner_confirm_with_title'.trParams({'title': banner.title})
              : 'delete_banner_confirm'.tr,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BannerCubit>().deleteBanner(banner.id);
              Navigator.of(context).pop();
              HelperFun.successSnackbar('success'.tr, 'item_deleted'.tr);
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required bool isSelected,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary.withValues(alpha: 0.12)
              : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColor.primary
                  : (isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColor.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSponsorSection(bool isDark) {
    if (_selectedProductId != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    child: (_selectedProductThumbnail != null && _selectedProductThumbnail!.isNotEmpty)
                        ? Image.network(
                            _selectedProductThumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag_outlined, size: 20),
                          )
                        : const Icon(Icons.shopping_bag_outlined, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProductTitle ?? _selectedProductId!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (_selectedProductBrand != null) ...[
                            Text(
                              _selectedProductBrand!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_selectedProductPrice != null) ...[
                            Text(
                              AppFormatters.formatEGP(_selectedProductPrice!),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColor.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  tooltip: 'change_product'.tr,
                  onPressed: () => _openProductPickerModal(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColor.error),
                  tooltip: 'remove'.tr,
                  onPressed: _clearSelectedProduct,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _autofillFromProduct,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high_rounded, size: 14, color: AppColor.primary),
                  const SizedBox(width: 6),
                  Text(
                    'fill_from_product'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openProductPickerModal(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_shopping_cart_rounded, color: AppColor.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'select_product'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }}

class _ProductPickerSheet extends StatefulWidget {
  final String? initialSelectedId;
  final ValueChanged<ProductModel> onProductPicked;

  const _ProductPickerSheet({
    this.initialSelectedId,
    required this.onProductPicked,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppColor.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'select_product'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'close'.tr,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Search Bar
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'search_products_hint'.tr,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),

              // Product List
              Expanded(
                child: BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductLoaded) {
                      final products = state.products.where((p) {
                        if (_searchQuery.isEmpty) return true;
                        return p.displayTitle.toLowerCase().contains(_searchQuery) ||
                            p.brand.name.toLowerCase().contains(_searchQuery) ||
                            p.id.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            'no_products_found'.tr,
                            style: TextStyle(
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final isSelected = p.id == widget.initialSelectedId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 42,
                                height: 42,
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                child: p.thumbnail.isNotEmpty
                                    ? Image.network(
                                        p.thumbnail,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.shopping_bag_outlined, size: 18),
                                      )
                                    : const Icon(Icons.shopping_bag_outlined, size: 18),
                              ),
                            ),
                            title: Text(
                              p.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColor.primary : null,
                              ),
                            ),
                            subtitle: Text(
                              '${p.brand.name} • ${AppFormatters.formatEGP(p.price)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColor.primary, size: 20)
                                : const Icon(Icons.chevron_right_rounded, size: 18),
                            onTap: () => widget.onProductPicked(p),
                          );
                        },
                      );
                    }

                    return Center(
                      child: ElevatedButton(
                        onPressed: () => context.read<ProductCubit>().loadProducts(),
                        child: Text('reload'.tr),
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
}
