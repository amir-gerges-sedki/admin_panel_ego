import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/product_model.dart';
import '../../utils/product_barcode_label_printer.dart';

class ProductBarcodePrintDialog extends StatefulWidget {
  final ProductModel product;
  final ProductVariationModel? initialVariation;

  const ProductBarcodePrintDialog({
    super.key,
    required this.product,
    this.initialVariation,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    ProductVariationModel? variation,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProductBarcodePrintDialog(
        product: product,
        initialVariation: variation,
      ),
    );
  }

  @override
  State<ProductBarcodePrintDialog> createState() => _ProductBarcodePrintDialogState();
}

class _ProductBarcodePrintDialogState extends State<ProductBarcodePrintDialog> {
  BarcodeLabelSize _selectedSize = BarcodeLabelSize.standardRoll50x30;
  late final Map<String, int> _variationQuantities;
  late final Map<String, bool> _variationSelected;
  int _simpleProductQuantity = 1;
  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    _variationQuantities = {};
    _variationSelected = {};

    if (widget.product.productVariations.isNotEmpty) {
      for (final v in widget.product.productVariations) {
        final key = v.id.isNotEmpty ? v.id : v.sku;
        final isSelected = widget.initialVariation == null ||
            widget.initialVariation!.id == v.id ||
            widget.initialVariation!.sku == v.sku;
        _variationSelected[key] = isSelected;
        _variationQuantities[key] = 1;
      }
    }
  }

  int get _totalStickersCount {
    if (widget.product.productVariations.isEmpty) {
      return _simpleProductQuantity;
    }
    int total = 0;
    for (final v in widget.product.productVariations) {
      final key = v.id.isNotEmpty ? v.id : v.sku;
      if (_variationSelected[key] == true) {
        total += _variationQuantities[key] ?? 1;
      }
    }
    return total;
  }

  List<BarcodeLabelItem> _buildLabelItems() {
    final List<BarcodeLabelItem> items = [];

    if (widget.product.productVariations.isEmpty) {
      if (_simpleProductQuantity > 0) {
        items.add(BarcodeLabelItem.fromProduct(
          widget.product,
          copies: _simpleProductQuantity,
        ));
      }
    } else {
      for (final v in widget.product.productVariations) {
        final key = v.id.isNotEmpty ? v.id : v.sku;
        if (_variationSelected[key] == true) {
          final qty = _variationQuantities[key] ?? 1;
          if (qty > 0) {
            items.add(BarcodeLabelItem.fromProduct(
              widget.product,
              variation: v,
              copies: qty,
            ));
          }
        }
      }
    }

    return items;
  }

  void _handlePrint() {
    final items = _buildLabelItems();
    if (items.isEmpty) {
      HelperFun.showNotificationAlert(
        title: 'alert'.tr,
        message: 'please_select_at_least_one_item'.tr,
      );
      return;
    }

    ProductBarcodeLabelPrinter.printLabels(
      items: items,
      size: _selectedSize,
    );

    Navigator.of(context).pop();
    HelperFun.showNotificationAlert(
      title: 'print_command_sent_title'.tr,
      message: 'print_command_sent_msg'.trParams({
        'count': '$_totalStickersCount',
        'size': _selectedSize.label,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final hasVariations = widget.product.productVariations.isNotEmpty;

    return Dialog(
      backgroundColor: isDark ? AppColor.darkDialog : AppColor.lightDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFF97316), size: 24),
                  ),
                  const SizedBox(width: AppSizes.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'print_barcode_stickers'.tr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'print_barcode_stickers_desc'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 2. Main Content (Two Columns on Wide, Single on Mobile)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 650;

                    final leftConfigColumn = _buildConfigurationSection(isDark, hasVariations);
                    final rightPreviewColumn = _buildLivePreviewSection(isDark, hasVariations);

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: leftConfigColumn),
                          const SizedBox(width: AppSizes.lg),
                          Expanded(flex: 5, child: rightPreviewColumn),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          leftConfigColumn,
                          const SizedBox(height: AppSizes.md),
                          rightPreviewColumn,
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 24),

              // 3. Footer Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total_requested_labels'.trParams({'count': '$_totalStickersCount'}),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFF97316)),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      ElevatedButton.icon(
                        onPressed: _totalStickersCount > 0 ? _handlePrint : null,
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: Text('print_labels_count_btn'.trParams({'count': '$_totalStickersCount'})),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection(bool isDark, bool hasVariations) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Paper Size Selector
          Text(
            'label_paper_size'.tr,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BarcodeLabelSize>(
                value: _selectedSize,
                isExpanded: true,
                dropdownColor: isDark ? AppColor.darkCard : AppColor.lightCard,
                items: BarcodeLabelSize.values.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Row(
                      children: [
                        Icon(
                          size.isThermalRoll ? Icons.receipt_long_rounded : Icons.grid_view_rounded,
                          size: 18,
                          color: const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          size.label,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSize = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Product / Variations Quantity Selector
          if (!hasVariations) ...[
            Text(
              'number_of_copies'.tr,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildQuantityStepper(
              quantity: _simpleProductQuantity,
              onChanged: (q) => setState(() => _simpleProductQuantity = q),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'variations_and_quantities'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          for (final v in widget.product.productVariations) {
                            final key = v.id.isNotEmpty ? v.id : v.sku;
                            _variationSelected[key] = true;
                          }
                        });
                      },
                      child: Text('select_all'.tr, style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          for (final v in widget.product.productVariations) {
                            final key = v.id.isNotEmpty ? v.id : v.sku;
                            _variationQuantities[key] = v.stock > 0 ? v.stock : 1;
                          }
                        });
                      },
                      child: Text('by_stock_level'.tr, style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: widget.product.productVariations.length,
                separatorBuilder: (_, _) => const Divider(height: 8),
                itemBuilder: (context, idx) {
                  final v = widget.product.productVariations[idx];
                  final key = v.id.isNotEmpty ? v.id : v.sku;
                  final isSelected = _variationSelected[key] == true;
                  final qty = _variationQuantities[key] ?? 1;

                  final varAttrs = v.attributeValues.entries
                      .where((e) => e.key.toLowerCase() != 'type' && e.key.toLowerCase() != 'liquidtype')
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' | ');

                  return Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFFF97316),
                        onChanged: (val) {
                          setState(() {
                            _variationSelected[key] = val ?? false;
                            if (val == true) _previewIndex = idx;
                          });
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _previewIndex = idx),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.sku.isNotEmpty ? v.sku : widget.product.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              if (varAttrs.isNotEmpty)
                                Text(
                                  varAttrs,
                                  style: TextStyle(fontSize: 10.5, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                                ),
                              Text(
                                'stock_and_price_label'.trParams({
                                  'stock': '${v.stock}',
                                  'price': AppFormatters.formatEGP(v.salePrice > 0 ? v.salePrice : v.price),
                                }),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isSelected)
                        _buildQuantityStepper(
                          quantity: qty,
                          isCompact: true,
                          onChanged: (newQ) => setState(() => _variationQuantities[key] = newQ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLivePreviewSection(bool isDark, bool hasVariations) {
    ProductVariationModel? currentVar;
    if (hasVariations && widget.product.productVariations.isNotEmpty) {
      final safeIdx = _previewIndex.clamp(0, widget.product.productVariations.length - 1);
      currentVar = widget.product.productVariations[safeIdx];
    }

    final item = BarcodeLabelItem.fromProduct(widget.product, variation: currentVar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'live_sticker_preview'.tr,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_selectedSize.widthMm}mm x ${_selectedSize.heightMm}mm',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Sticker Preview Container Card
        Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black45, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store Name & Brand
                Text(
                  '${item.brandName.isNotEmpty ? "${item.brandName} • " : ""}${'store_brand_tag'.tr}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Product Title
                Text(
                  item.productTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Variation Badge
                if (item.variationSummary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      item.variationSummary,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Barcode Bars Graphic
                _buildBarcodePreviewGraphic(item.sku),

                const SizedBox(height: 6),

                // Price Tag
                Text(
                  AppFormatters.formatEGP(item.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'barcode_compatible_note'.tr,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodePreviewGraphic(String sku) {
    // Generate alternating bar graphic for live UI preview
    return Column(
      children: [
        Container(
          height: 38,
          width: 200,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(35, (index) {
              final isBar = (index % 3 != 0) || (index % 5 == 0);
              final width = (index % 4 == 0) ? 3.0 : ((index % 2 == 0) ? 2.0 : 1.0);
              return Container(
                width: width,
                color: isBar ? Colors.black : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              );
            }),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sku,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper({
    required int quantity,
    required ValueChanged<int> onChanged,
    bool isCompact = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Container(
          constraints: BoxConstraints(minWidth: isCompact ? 30 : 40),
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFFF97316)),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}
