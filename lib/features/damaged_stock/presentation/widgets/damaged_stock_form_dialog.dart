import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../roles/presentation/cubit/auth_role_cubit.dart';
import '../../data/models/damaged_stock_model.dart';
import '../cubit/damaged_stock_cubit.dart';

class DamagedStockFormDialog extends StatefulWidget {
  const DamagedStockFormDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DamagedStockFormDialog(),
    );
  }

  @override
  State<DamagedStockFormDialog> createState() => _DamagedStockFormDialogState();
}

class _DamagedStockFormDialogState extends State<DamagedStockFormDialog> {
  final _formKey = GlobalKey<FormState>();

  ProductModel? _selectedProduct;
  ProductVariationModel? _selectedVariation;

  final _productSearchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _costPriceController = TextEditingController();
  final _notesController = TextEditingController();

  DamagedReason _selectedReason = DamagedReason.expired;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Ensure products are loaded
    final productState = context.read<ProductCubit>().state;
    if (productState is! ProductLoaded) {
      context.read<ProductCubit>().loadProducts();
    }
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _availableStock {
    if (_selectedProduct == null) return 0;
    if (_selectedVariation != null) return _selectedVariation!.stock;
    return _selectedProduct!.stock;
  }

  double get _currentCostPrice {
    final parsed = double.tryParse(_costPriceController.text.trim());
    if (parsed != null && parsed >= 0) return parsed;
    if (_selectedVariation != null) return _selectedVariation!.costPrice;
    if (_selectedProduct != null) return _selectedProduct!.costPrice;
    return 0.0;
  }

  int get _currentQuantity {
    return int.tryParse(_quantityController.text.trim()) ?? 0;
  }

  double get _totalLossCalculated => _currentQuantity * _currentCostPrice;

  void _onProductSelected(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      if (product.productVariations.isNotEmpty) {
        _selectedVariation = product.productVariations.first;
        _costPriceController.text = _selectedVariation!.costPrice.toStringAsFixed(2);
      } else {
        _selectedVariation = null;
        _costPriceController.text = product.costPrice.toStringAsFixed(2);
      }
      _quantityController.text = '1';
    });
  }

  void _onVariationSelected(ProductVariationModel variation) {
    setState(() {
      _selectedVariation = variation;
      _costPriceController.text = variation.costPrice.toStringAsFixed(2);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'damage_select_product_required'.tr,
      );
      return;
    }

    final qty = _currentQuantity;
    if (qty <= 0) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'damage_qty_min_error'.tr,
      );
      return;
    }

    if (qty > _availableStock) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: '${"damage_qty_exceeds_stock".tr} ($_availableStock)',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = context.read<AuthRoleCubit>().state;
      final recordedBy = authState.activeAdminEmail.isNotEmpty
          ? authState.activeAdminEmail
          : authState.activeAdminName;

      await context.read<DamagedStockCubit>().recordDamage(
            product: _selectedProduct!,
            variationSku: _selectedVariation?.sku,
            quantity: qty,
            reason: _selectedReason,
            customCostPrice: _currentCostPrice,
            notes: _notesController.text.trim(),
            recordedBy: recordedBy,
          );

      if (mounted) {
        Navigator.of(context).pop();
        HelperFun.showNotificationAlert(
          title: 'success'.tr,
          message: 'damage_recorded_success'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        HelperFun.showNotificationAlert(
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm + 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'log_damage_title'.tr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'log_damage_subtitle'.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.md),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Product Autocomplete / Search Selector
                      _buildProductSelector(isDark),
                      const SizedBox(height: AppSizes.md),

                      // 2. Variation Selector (if variable product)
                      if (_selectedProduct != null && _selectedProduct!.productVariations.isNotEmpty) ...[
                        _buildVariationSelector(isDark),
                        const SizedBox(height: AppSizes.md),
                      ],

                      // 3. Current Stock Status Badge
                      if (_selectedProduct != null) ...[
                        _buildStockInfoCard(isDark),
                        const SizedBox(height: AppSizes.md),
                      ],

                      // 4. Damage Reason Selector
                      _buildReasonSelector(isDark),
                      const SizedBox(height: AppSizes.md),

                      // 5. Quantity & Unit Cost Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity Field
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'damage_quantity'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'required_field'.tr;
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n <= 0) return 'damage_qty_min_error'.tr;
                                    if (n > _availableStock) return '${"damage_qty_exceeds_stock".tr} ($_availableStock)';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                                    suffixText: 'قطع',
                                    hintText: '1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),

                          // Unit Cost Field
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'cost_price_per_unit'.tr,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _costPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'required_field'.tr;
                                    final n = double.tryParse(v.trim());
                                    if (n == null || n < 0) return 'invalid_amount'.tr;
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                    suffixText: 'ج.م',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 6. Calculated Total Loss Preview Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calculate_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'total_damage_financial_loss'.tr,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              AppFormatters.formatEGP(_totalLossCalculated),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // 7. Notes Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'notes_and_explanation'.tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'damage_notes_hint'.tr,
                              prefixIcon: const Padding(
                                padding: EdgeInsetsDirectional.only(bottom: 24),
                                child: Icon(Icons.notes_rounded, size: 18),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.md),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'confirm_log_damage'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelector(bool isDark) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final products = state is ProductLoaded ? state.products : <ProductModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_product_to_damage'.tr,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Autocomplete<ProductModel>(
              displayStringForOption: (product) => product.displayTitle,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return products.take(15);
                }
                final q = textEditingValue.text.toLowerCase().trim();
                return products.where((p) {
                  final title = p.displayTitle.toLowerCase();
                  final brand = p.brand.name.toLowerCase();
                  final id = p.id.toLowerCase();
                  final hasMatchingSku = p.productVariations.any((v) => v.sku.toLowerCase().contains(q));
                  return title.contains(q) || brand.contains(q) || id.contains(q) || hasMatchingSku;
                });
              },
              onSelected: _onProductSelected,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'search_product_barcode_hint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _selectedProduct != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() {
                                _selectedProduct = null;
                                _selectedVariation = null;
                                _quantityController.text = '1';
                                _costPriceController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    color: isDark ? AppColor.darkCard : Colors.white,
                    child: Container(
                      width: 580,
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (ctx, idx) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            leading: product.thumbnail.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      product.thumbnail,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_rounded, size: 24),
                                    ),
                                  )
                                : const Icon(Icons.inventory_2_rounded, size: 24),
                            title: Text(
                              product.displayTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${product.brand.name} • ${product.categoryType.displayName} • ${"stock".tr}: ${product.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                            trailing: Text(
                              AppFormatters.formatEGP(product.costPrice),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            onTap: () => onSelected(product),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVariationSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_variation'.tr,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductVariationModel>(
              value: _selectedVariation,
              isExpanded: true,
              items: _selectedProduct!.productVariations.map((v) {
                final attrStr = v.attributeValues.entries.map((e) => '${e.key}: ${e.value}').join(', ');
                return DropdownMenuItem<ProductVariationModel>(
                  value: v,
                  child: Text(
                    '${v.sku.isNotEmpty ? "[${v.sku}] " : ""}$attrStr (${"stock".tr}: ${v.stock})',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _onVariationSelected(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfoCard(bool isDark) {
    final stock = _availableStock;
    final isZero = stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isZero ? AppColor.error : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(
          color: (isZero ? AppColor.error : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isZero ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                size: 18,
                color: isZero ? AppColor.error : const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Text(
                'available_stock_in_warehouse'.tr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            '$stock ${"units".tr}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isZero ? AppColor.error : const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'damage_reason'.tr,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: DamagedReason.values.map((reason) {
            final isSelected = _selectedReason == reason;
            return ChoiceChip(
              avatar: Icon(
                reason.icon,
                size: 16,
                color: isSelected ? Colors.white : reason.color,
              ),
              label: Text(
                reason.labelKey.tr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              selectedColor: reason.color,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedReason = reason);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
