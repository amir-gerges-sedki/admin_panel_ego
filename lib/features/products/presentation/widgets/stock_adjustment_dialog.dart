import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/stock_movement_cubit.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final ProductModel product;
  final String? initialVariationSku;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
    this.initialVariationSku,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countedStockController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedVariationSku;
  StockMovementType _selectedType = StockMovementType.adjustment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedVariationSku = widget.initialVariationSku;
    if (_selectedVariationSku == null &&
        widget.product.productVariations.isNotEmpty) {
      _selectedVariationSku = widget.product.productVariations.first.sku;
    }
    _updateInitialCountField();
  }

  int get _currentSystemStock {
    if (_selectedVariationSku != null &&
        widget.product.productVariations.isNotEmpty) {
      final variation = widget.product.productVariations.firstWhere(
        (v) => v.sku == _selectedVariationSku,
        orElse: () => widget.product.productVariations.first,
      );
      return variation.stock;
    }
    return widget.product.stock;
  }

  void _updateInitialCountField() {
    _countedStockController.text = _currentSystemStock.toString();
  }

  @override
  void dispose() {
    _countedStockController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final countedStock = int.tryParse(_countedStockController.text.trim()) ?? 0;
    if (countedStock < 0) return;

    setState(() => _isSaving = true);

    try {
      final updatedProduct =
          await context.read<StockMovementCubit>().executeStockAdjustment(
                product: widget.product,
                variationSku: _selectedVariationSku,
                newExactStock: countedStock,
                type: _selectedType,
                reason: _reasonController.text.trim().isNotEmpty
                    ? _reasonController.text.trim()
                    : 'تسوية جردية - ${_selectedType.displayName}',
                notes: _notesController.text.trim(),
                performedBy: 'Admin / Inventory Manager',
              );

      if (mounted) {
        context.read<ProductCubit>().updateProduct(updatedProduct);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('stock_adjusted_successfully'),
            ),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error')}: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currentStock = _currentSystemStock;
    final countedStock = int.tryParse(_countedStockController.text.trim()) ?? currentStock;
    final variance = countedStock - currentStock;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColor.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).translate('stock_adjustment_audit'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product info header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, size: 18, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.product.displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Variation Selector if variations exist
              if (widget.product.productVariations.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context).translate('select_variation'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVariationSku,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                  decoration: _inputDecoration(isDark),
                  items: widget.product.productVariations.map((v) {
                    final attrs = v.attributeValues.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', ');
                    return DropdownMenuItem(
                      value: v.sku,
                      child: Text(
                        '${v.sku} ${attrs.isNotEmpty ? '($attrs)' : ''} [${v.stock} in stock]',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedVariationSku = val;
                        _updateInitialCountField();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Stock Comparison (System Stock vs Counted Stock)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('system_recorded_stock'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                            ),
                          ),
                          child: Text(
                            '$currentStock ${AppLocalizations.of(context).translate('units')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('physical_counted_stock'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _countedStockController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(isDark, hint: '0'),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return AppLocalizations.of(context).translate('field_required');
                            }
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed < 0) {
                              return AppLocalizations.of(context).translate('enter_valid_stock');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Variance Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: variance == 0
                      ? Colors.blue.withValues(alpha: 0.1)
                      : (variance > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('audit_variance'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${variance > 0 ? '+' : ''}$variance ${AppLocalizations.of(context).translate('units')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: variance == 0
                            ? AppColor.primary
                            : (variance > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Adjustment Reason / Type
              Text(
                AppLocalizations.of(context).translate('adjustment_reason_type'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<StockMovementType>(
                initialValue: _selectedType,
                isExpanded: true,
                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                decoration: _inputDecoration(isDark),
                items: [
                  StockMovementType.adjustment,
                  StockMovementType.damage,
                  StockMovementType.restock,
                  StockMovementType.returnItem,
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      AppLocalizations.of(context).isArabic ? type.arabicName : type.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 14),

              // Notes
              Text(
                AppLocalizations.of(context).translate('notes_optional'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(
                  isDark,
                  hint: AppLocalizations.of(context).translate('audit_notes_hint'),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.of(context).translate('cancel'),
                      style: TextStyle(
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submitAdjustment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context).translate('confirm_adjustment'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

  InputDecoration _inputDecoration(bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
    );
  }
}
