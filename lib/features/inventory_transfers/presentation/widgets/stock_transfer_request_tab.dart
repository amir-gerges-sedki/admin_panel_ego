import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/data/models/store_branch_model.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/stock_transfer_model.dart';
import '../cubit/stock_transfer_cubit.dart';
import '../cubit/stock_transfer_state.dart';

class StockTransferRequestTab extends StatefulWidget {
  final String currentBranchId;
  final String currentBranchName;
  final String currentShiftId;
  final VoidCallback onSuccess;

  const StockTransferRequestTab({
    super.key,
    required this.currentBranchId,
    required this.currentBranchName,
    required this.currentShiftId,
    required this.onSuccess,
  });

  @override
  State<StockTransferRequestTab> createState() => _StockTransferRequestTabState();
}

class _StockTransferRequestTabState extends State<StockTransferRequestTab> {
  String? _selectedSourceBranchId;
  String _selectedSourceBranchName = '';
  StockTransferPriority _selectedPriority = StockTransferPriority.normal;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  final List<StockTransferItemModel> _selectedItems = [];

  // Active product selection state
  ProductModel? _currentPickedProduct;
  ProductVariationModel? _currentPickedVariation;
  int _itemQuantityToAdd = 1;

  String? _localValidationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initSourceBranch();
  }

  void _initSourceBranch() {
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      final branches = settingsState.settings.branches;
      final otherBranches = branches.where((b) => b.id != widget.currentBranchId).toList();
      if (otherBranches.isNotEmpty) {
        _selectedSourceBranchId = otherBranches.first.id;
        _selectedSourceBranchName = otherBranches.first.name;
      } else if (branches.isNotEmpty) {
        _selectedSourceBranchId = branches.first.id;
        _selectedSourceBranchName = branches.first.name;
      } else {
        _selectedSourceBranchId = 'main_warehouse';
        _selectedSourceBranchName = 'transfer_main_warehouse'.tr;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  void _addItemToRequest() {
    if (_currentPickedProduct == null) return;

    final p = _currentPickedProduct!;
    final v = _currentPickedVariation;

    final sku = v != null && v.sku.isNotEmpty
        ? v.sku
        : (p.productVariations.isNotEmpty ? p.productVariations.first.sku : p.id);

    final attrs = v?.attributeValues ?? {};
    final cost = v?.costPrice ?? p.costPrice;
    final selling = v?.salePrice ?? (v?.price ?? (p.salePrice > 0 ? p.salePrice : p.price));
    final img = v != null && v.image.isNotEmpty ? v.image : p.thumbnail;

    final existingIndex = _selectedItems.indexWhere(
      (it) => it.productId == p.id && it.variationSku == sku,
    );

    setState(() {
      _localValidationError = null;
      if (existingIndex >= 0) {
        final existing = _selectedItems[existingIndex];
        _selectedItems[existingIndex] = existing.copyWith(
          requestedQuantity: existing.requestedQuantity + _itemQuantityToAdd,
        );
      } else {
        _selectedItems.add(
          StockTransferItemModel(
            productId: p.id,
            productTitle: p.displayTitle,
            productCategory: p.categoryId,
            variationSku: sku,
            variationAttributes: attrs,
            requestedQuantity: _itemQuantityToAdd,
            costPrice: cost,
            sellingPrice: selling,
            image: img,
          ),
        );
      }

      // Reset picked product
      _currentPickedProduct = null;
      _currentPickedVariation = null;
      _itemQuantityToAdd = 1;
      _productSearchController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _submitRequest() async {
    setState(() {
      _localValidationError = null;
    });

    // 1. Auto-resolve source branch if not set
    if (_selectedSourceBranchId == null || _selectedSourceBranchId!.isEmpty) {
      final settingsState = context.read<SettingsCubit>().state;
      if (settingsState is SettingsLoaded && settingsState.settings.branches.isNotEmpty) {
        final other = settingsState.settings.branches.where((b) => b.id != widget.currentBranchId).toList();
        if (other.isNotEmpty) {
          _selectedSourceBranchId = other.first.id;
          _selectedSourceBranchName = other.first.name;
        } else {
          _selectedSourceBranchId = settingsState.settings.branches.first.id;
          _selectedSourceBranchName = settingsState.settings.branches.first.name;
        }
      } else {
        _selectedSourceBranchId = 'main_warehouse';
        _selectedSourceBranchName = 'transfer_main_warehouse'.tr;
      }
    }

    // 2. If user selected a product in the autocomplete but didn't click "Add", auto-add it!
    if (_selectedItems.isEmpty && _currentPickedProduct != null) {
      _addItemToRequest();
    }

    // 3. Check if still empty
    if (_selectedItems.isEmpty) {
      const msg = 'يرجى البحث عن صنف وإضافته لقائمة الطلب أولاً';
      setState(() {
        _localValidationError = msg;
      });
      HelperFun.showNotificationAlert(
        title: 'transfer_dialog_title'.tr,
        message: msg,
        context: context,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await context.read<StockTransferCubit>().createTransferRequest(
            fromBranchId: _selectedSourceBranchId!,
            fromBranchName: _selectedSourceBranchName,
            toBranchId: widget.currentBranchId.isNotEmpty ? widget.currentBranchId : 'main_branch',
            toBranchName: widget.currentBranchName.isNotEmpty ? widget.currentBranchName : 'الفرع الحالي',
            items: List.from(_selectedItems),
            priority: _selectedPriority,
            notes: _notesController.text.trim(),
            shiftId: widget.currentShiftId,
            requestedBy: 'Cashier (${widget.currentBranchName.isNotEmpty ? widget.currentBranchName : "الفرع"})',
          );

      if (success && mounted) {
        setState(() {
          _selectedItems.clear();
          _currentPickedProduct = null;
          _currentPickedVariation = null;
          _notesController.clear();
          _productSearchController.clear();
          _localValidationError = null;
        });
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localValidationError = 'حدث خطأ أثناء الإرسال: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        List<StoreBranchModel> availableBranches = [];
        if (settingsState is SettingsLoaded) {
          availableBranches = settingsState.settings.branches;
        }

        final otherBranches = availableBranches
            .where((b) => b.id != widget.currentBranchId)
            .toList();

        // Ensure source branch is never null
        if (_selectedSourceBranchId == null) {
          if (otherBranches.isNotEmpty) {
            _selectedSourceBranchId = otherBranches.first.id;
            _selectedSourceBranchName = otherBranches.first.name;
          } else if (availableBranches.isNotEmpty) {
            _selectedSourceBranchId = availableBranches.first.id;
            _selectedSourceBranchName = availableBranches.first.name;
          } else {
            _selectedSourceBranchId = 'main_warehouse';
            _selectedSourceBranchName = 'transfer_main_warehouse'.tr;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Source & Destination Branch Routing
              _buildBranchRoutingSection(isDark, otherBranches, availableBranches),
              const SizedBox(height: AppSizes.md),

              // 2. Priority Selection
              _buildPrioritySelector(isDark),
              const SizedBox(height: AppSizes.md),

              // 3. Product Search & Add Section
              _buildProductSearchAndAddCard(isDark),
              const SizedBox(height: AppSizes.md),

              // 4. Requested Items List
              _buildSelectedItemsList(isDark),
              const SizedBox(height: AppSizes.md),

              // 5. Validation Alert (if any)
              if (_localValidationError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    border: Border.all(color: AppColor.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localValidationError!,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColor.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],

              // 6. Notes & Submit Button
              _buildNotesAndSubmitSection(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchRoutingSection(
    bool isDark,
    List<StoreBranchModel> otherBranches,
    List<StoreBranchModel> allBranches,
  ) {
    final branchChoices = otherBranches.isNotEmpty ? otherBranches : allBranches;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, color: AppColor.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'transfer_route_title'.tr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              // Source Branch (Where goods will come from)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transfer_from_branch'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkChip : AppColor.lightChip,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSourceBranchId,
                          isExpanded: true,
                          hint: Text('transfer_select_source_hint'.tr, style: const TextStyle(fontSize: 13)),
                          items: [
                            if (branchChoices.isEmpty)
                              DropdownMenuItem(
                                value: 'main_warehouse',
                                child: Text('transfer_main_warehouse'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              )
                            else
                              ...branchChoices.map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  )),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedSourceBranchId = val;
                              final found = branchChoices.where((b) => b.id == val);
                              if (found.isNotEmpty) {
                                _selectedSourceBranchName = found.first.name;
                              } else {
                                _selectedSourceBranchName = 'transfer_main_warehouse'.tr;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.md),
              const Icon(Icons.arrow_forward_rounded, color: AppColor.primary, size: 22),
              const SizedBox(width: AppSizes.md),

              // Destination Branch (Current requesting branch)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transfer_to_branch'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppColor.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.currentBranchName.isNotEmpty
                                   ? widget.currentBranchName
                                  : 'transfer_current_branch'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return Row(
      children: [
        Text(
          'transfer_priority_label'.tr,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        ...StockTransferPriority.values.map((priority) {
          final isSelected = _selectedPriority == priority;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedPriority = priority),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? priority.color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  border: Border.all(
                    color: isSelected ? priority.color : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priority.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      priority.labelKey.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? priority.color : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductSearchAndAddCard(bool isDark) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, productState) {
        final products = productState is ProductLoaded ? productState.products : <ProductModel>[];

        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart_rounded, color: AppColor.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'transfer_add_products_title'.tr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Product Autocomplete Search Field
              Autocomplete<ProductModel>(
                displayStringForOption: (ProductModel p) => p.displayTitle,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.trim().isEmpty) {
                    return const Iterable<ProductModel>.empty();
                  }
                  final q = textEditingValue.text.toLowerCase().trim();
                  return products.where((p) {
                    final matchTitle = p.displayTitle.toLowerCase().contains(q);
                    final matchBrand = p.brand.name.toLowerCase().contains(q);
                    final matchSku = p.productVariations.any((v) => v.sku.toLowerCase().contains(q));
                    return matchTitle || matchBrand || matchSku;
                  }).take(10);
                },
                onSelected: (ProductModel selection) {
                  setState(() {
                    _currentPickedProduct = selection;
                    _currentPickedVariation = selection.productVariations.isNotEmpty
                        ? selection.productVariations.first
                        : null;
                    _localValidationError = null;
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'transfer_search_product_hint'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? AppColor.darkChip : AppColor.lightChip,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                        borderSide: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                      ),
                    ),
                  );
                },
              ),

              // Variation & Quantity Selectors (if product picked)
              if (_currentPickedProduct != null) ...[
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkCard : AppColor.lightCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      // Product Thumbnail
                      if (_currentPickedProduct!.thumbnail.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _currentPickedProduct!.thumbnail,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_outlined, size: 28),
                          ),
                        )
                      else
                        const Icon(Icons.inventory_2_outlined, size: 36, color: AppColor.primary),
                      const SizedBox(width: 10),

                      // Product Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPickedProduct!.displayTitle,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_currentPickedProduct!.brand.name} • ${_currentPickedProduct!.categoryType.displayName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Variation Dropdown (if variable)
                      if (_currentPickedProduct!.productVariations.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColor.darkChip : AppColor.lightChip,
                            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ProductVariationModel>(
                              value: _currentPickedVariation ?? _currentPickedProduct!.productVariations.first,
                              isDense: true,
                              items: _currentPickedProduct!.productVariations.map((v) {
                                final label = v.attributeValues.values.isNotEmpty
                                    ? v.attributeValues.values.join(' / ')
                                    : (v.sku.isNotEmpty ? v.sku : 'Default');
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _currentPickedVariation = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 12),

                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkChip : AppColor.lightChip,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 16),
                              onPressed: _itemQuantityToAdd > 1
                                  ? () => setState(() => _itemQuantityToAdd--)
                                  : null,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$_itemQuantityToAdd',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              onPressed: () => setState(() => _itemQuantityToAdd++),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Add Button
                      ElevatedButton.icon(
                        onPressed: _addItemToRequest,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('add'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedItemsList(bool isDark) {
    if (_selectedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
            const SizedBox(height: 8),
            Text(
              'transfer_no_items_selected'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'transfer_requested_items'.tr} (${_selectedItems.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${'transfer_total_qty'.tr}: ${_selectedItems.fold<int>(0, (sum, i) => sum + i.requestedQuantity)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColor.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedItems.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _selectedItems[index];
              return ListTile(
                leading: item.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2_outlined),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: AppColor.primary),
                title: Text(
                  item.productTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  item.variationAttributes.isNotEmpty
                      ? item.variationAttributes.entries.map((e) => '${e.key}: ${e.value}').join(' | ')
                      : (item.variationSku.isNotEmpty ? 'SKU: ${item.variationSku}' : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Text(
                        '${item.requestedQuantity}x',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColor.error, size: 20),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesAndSubmitSection(bool isDark) {
    return BlocBuilder<StockTransferCubit, StockTransferState>(
      builder: (context, transferState) {
        final isLoading = _isSubmitting || transferState.isCreating;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'transfer_notes_hint'.tr,
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                filled: true,
                fillColor: isDark ? AppColor.darkChip : AppColor.lightChip,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  borderSide: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _submitRequest,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  isLoading ? 'جاري إرسال الطلب...' : 'transfer_submit_btn'.tr,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
