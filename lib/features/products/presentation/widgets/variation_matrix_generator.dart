import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../data/models/product_model.dart';
import 'color_palette_picker_dialog.dart';

class VariationMatrixGenerator extends StatefulWidget {
  final String baseSku;
  final double basePrice;
  final List<ProductVariationModel> initialVariations;
  final ValueChanged<List<ProductVariationModel>> onVariationsGenerated;

  const VariationMatrixGenerator({
    super.key,
    required this.baseSku,
    required this.basePrice,
    this.initialVariations = const [],
    required this.onVariationsGenerated,
  });

  @override
  State<VariationMatrixGenerator> createState() => _VariationMatrixGeneratorState();
}

class _VariationMatrixGeneratorState extends State<VariationMatrixGenerator> {
  // Mode: 'LIQUID', 'DEVICE', 'COIL'
  String _selectedTemplate = 'LIQUID';

  // 1. E-Liquid Per-Flavor Configuration State
  final List<String> _availableFlavors = [
    'Mango Ice',
    'Lush Watermelon',
    'Cubano Tobacco',
    'Blue Razz Ice',
    'Strawberry Kiwi',
    'Grape Ice',
    'Double Apple',
    'Spearmint',
    'Vanilla Custard',
    'Peach Ice',
    'Berry Mix',
  ];
  String _activeFlavor = 'Mango Ice';
  final TextEditingController _customFlavorController = TextEditingController();

  // Vaping style for the active flavor: 'MTL', 'DL', 'RDL', 'BOTH'
  String _activeVapeStyle = 'MTL';

  // Nicotines for active flavor
  final List<String> _availableNicotines = [
    '3mg',
    '6mg',
    '9mg',
    '12mg',
    '18mg',
    '20mg',
    '25mg',
    '30mg',
    '50mg',
  ];
  final List<String> _selectedNicotines = ['6mg', '9mg', '12mg', '50mg'];
  final TextEditingController _customNicotineController = TextEditingController();

  // Bottle sizes for active flavor
  final List<String> _availableSizes = ['15ml', '30ml', '60ml', '100ml', '120ml'];
  final List<String> _selectedSizes = ['30ml', '60ml'];
  final TextEditingController _customSizeController = TextEditingController();

  late TextEditingController _batchPriceController;
  late TextEditingController _batchStockController;

  // 2. Device Attributes State
  final List<String> _availableColors = [
    'Carbon Black',
    'Silver Chrome',
    'Gunmetal Grey',
    'Midnight Blue',
    'Aurora Purple',
    'Emerald Green',
    'Leather Brown',
    'Rose Gold',
    'Sunset Red',
  ];
  final List<String> _selectedColors = ['Carbon Black', 'Silver Chrome', 'Gunmetal Grey'];
  final TextEditingController _customColorController = TextEditingController();

  // 3. Coil Attributes State
  final List<String> _availableResistances = [
    '0.15Ω Mesh',
    '0.2Ω Mesh',
    '0.4Ω Mesh',
    '0.6Ω Mesh',
    '0.8Ω Mesh',
    '1.0Ω Regular',
    '1.2Ω MTL',
  ];
  final List<String> _selectedResistances = ['0.6Ω Mesh', '0.8Ω Mesh', '1.2Ω MTL'];
  final List<String> _selectedPackSizes = ['Pack of 4', 'Pack of 5'];

  late List<ProductVariationModel> _currentVariations;

  @override
  void initState() {
    super.initState();
    _currentVariations = List.from(widget.initialVariations);
    _batchPriceController = TextEditingController(text: widget.basePrice > 0 ? widget.basePrice.toStringAsFixed(0) : '350');
    _batchStockController = TextEditingController(text: '20');
  }

  @override
  void dispose() {
    _customFlavorController.dispose();
    _customNicotineController.dispose();
    _customSizeController.dispose();
    _customColorController.dispose();
    _batchPriceController.dispose();
    _batchStockController.dispose();
    super.dispose();
  }

  int? _parseNicotine(String nic) {
    final clean = nic.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean);
  }

  bool _isDlNic(String nic) {
    final val = _parseNicotine(nic);
    if (val != null) return val == 3 || val == 6;
    final lower = nic.trim().toLowerCase();
    return lower == '3mg' || lower == '6mg' || lower == '3' || lower == '6';
  }

  bool _isMtlNic(String nic) {
    final val = _parseNicotine(nic);
    if (val != null) return val >= 6 && val <= 50;
    final lower = nic.trim().toLowerCase();
    return lower != '3mg' && lower != '3';
  }

  List<String> _getNicotinesForStyle(String style, List<String> selected) {
    if (style == 'DL' || style == 'RDL') {
      final list = selected.where(_isDlNic).toList();
      return list.isNotEmpty ? list : const ['3mg', '6mg'];
    } else if (style == 'MTL') {
      final list = selected.where(_isMtlNic).toList();
      return list.isNotEmpty ? list : const ['6mg', '9mg', '12mg', '18mg', '20mg', '25mg', '30mg', '50mg'];
    } else {
      return selected.isNotEmpty
          ? selected
          : const ['3mg', '6mg', '9mg', '12mg', '18mg', '20mg', '25mg', '30mg', '50mg'];
    }
  }

  void _onVapeStyleChanged(String newStyle) {
    setState(() {
      _activeVapeStyle = newStyle;
      if (newStyle == 'DL' || newStyle == 'RDL') {
        _availableNicotines.clear();
        _availableNicotines.addAll(['3mg', '6mg']);
        _selectedNicotines.clear();
        _selectedNicotines.addAll(['3mg', '6mg']);
      } else if (newStyle == 'MTL') {
        _availableNicotines.clear();
        _availableNicotines.addAll(['6mg', '9mg', '12mg', '18mg', '20mg', '25mg', '30mg', '50mg']);
        _selectedNicotines.clear();
        _selectedNicotines.addAll(['6mg', '9mg', '12mg', '50mg']);
      } else {
        _availableNicotines.clear();
        _availableNicotines.addAll(['3mg', '6mg', '9mg', '12mg', '18mg', '20mg', '25mg', '30mg', '50mg']);
        _selectedNicotines.clear();
        _selectedNicotines.addAll(['3mg', '6mg', '20mg', '50mg']);
      }
    });
  }

  void _addLiquidFlavorVariations() {
    if (_selectedNicotines.isEmpty || _selectedSizes.isEmpty) {
      HelperFun.errorSnackbar(
        title: 'Selection Required',
        message: 'Please select at least one Nicotine strength and one Bottle size for $_activeFlavor.',
      );
      return;
    }

    final price = double.tryParse(_batchPriceController.text) ?? widget.basePrice;
    final stock = int.tryParse(_batchStockController.text) ?? 20;
    final prefix = widget.baseSku.isNotEmpty ? widget.baseSku.toUpperCase() : 'EGO';
    final flavorCode = _activeFlavor.replaceAll(' ', '').toUpperCase();

    final List<String> styles = _activeVapeStyle == 'BOTH'
        ? ['MTL', 'DL']
        : [_activeVapeStyle];

    final newVariations = <ProductVariationModel>[];

    for (final style in styles) {
      final styleNics = _getNicotinesForStyle(style, _selectedNicotines);
      for (final nic in styleNics) {
        for (final size in _selectedSizes) {
          final sku = '$prefix-$flavorCode-$style-$size-$nic'.toUpperCase();

          // Avoid duplicate SKU
          if (_currentVariations.any((v) => v.sku == sku)) continue;

          newVariations.add(
            ProductVariationModel(
              id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${_currentVariations.length + newVariations.length}',
              sku: sku,
              price: price,
              salePrice: price,
              stock: stock,
              attributeValues: {
                'Flavour': _activeFlavor,
                'Style': style,
                'Type': style,
                'Nicotine': nic,
                'Size': size,
              },
            ),
          );
        }
      }
    }

    if (newVariations.isEmpty) {
      HelperFun.infoSnackbar(
        title: 'Variations Exist',
        message: 'All selected combinations for $_activeFlavor already exist in the list.',
      );
      return;
    }

    setState(() {
      _currentVariations.addAll(newVariations);
    });
    widget.onVariationsGenerated(_currentVariations);
    HelperFun.successSnackbar(
      'Variations Added',
      'Added ${newVariations.length} variations for flavor "$_activeFlavor" ($styles, $_selectedNicotines, $_selectedSizes).',
    );
  }

  void _addDeviceVariations() {
    if (_selectedColors.isEmpty) return;
    final price = double.tryParse(_batchPriceController.text) ?? widget.basePrice;
    final stock = int.tryParse(_batchStockController.text) ?? 15;
    final prefix = widget.baseSku.isNotEmpty ? widget.baseSku.toUpperCase() : 'DEV';

    final newVars = <ProductVariationModel>[];
    for (final color in _selectedColors) {
      final colorCode = color.replaceAll(' ', '').toUpperCase();
      final sku = '$prefix-$colorCode'.toUpperCase();
      if (_currentVariations.any((v) => v.sku == sku)) continue;

      newVars.add(
        ProductVariationModel(
          id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${_currentVariations.length + newVars.length}',
          sku: sku,
          price: price,
          salePrice: price,
          stock: stock,
          attributeValues: {'Color': color},
        ),
      );
    }

    setState(() {
      _currentVariations.addAll(newVars);
    });
    widget.onVariationsGenerated(_currentVariations);
    HelperFun.successSnackbar(
      'Colors Added',
      'Added ${newVars.length} device color variations.',
    );
  }

  void _addCoilVariations() {
    if (_selectedResistances.isEmpty || _selectedPackSizes.isEmpty) return;
    final price = double.tryParse(_batchPriceController.text) ?? widget.basePrice;
    final stock = int.tryParse(_batchStockController.text) ?? 30;
    final prefix = widget.baseSku.isNotEmpty ? widget.baseSku.toUpperCase() : 'COIL';

    final newVars = <ProductVariationModel>[];
    for (final res in _selectedResistances) {
      for (final pack in _selectedPackSizes) {
        final resCode = res.split(' ').first.replaceAll('Ω', '').replaceAll('.', '');
        final packCode = pack.replaceAll(' ', '').toUpperCase();
        final sku = '$prefix-R$resCode-$packCode'.toUpperCase();
        if (_currentVariations.any((v) => v.sku == sku)) continue;

        newVars.add(
          ProductVariationModel(
            id: 'VAR_${DateTime.now().millisecondsSinceEpoch}_${_currentVariations.length + newVars.length}',
            sku: sku,
            price: price,
            salePrice: price,
            stock: stock,
            attributeValues: {
              'Resistance': res,
              'Pack Size': pack,
            },
          ),
        );
      }
    }

    setState(() {
      _currentVariations.addAll(newVars);
    });
    widget.onVariationsGenerated(_currentVariations);
    HelperFun.successSnackbar(
      'Coil Variations Added',
      'Added ${newVars.length} coil resistance variations.',
    );
  }

  int _calculatePotentialCombinations() {
    if (_selectedTemplate == 'LIQUID') {
      final stylesCount = _activeVapeStyle == 'BOTH' ? 2 : 1;
      return stylesCount * _selectedNicotines.length * _selectedSizes.length;
    } else if (_selectedTemplate == 'DEVICE') {
      return _selectedColors.length;
    } else {
      return _selectedResistances.length * _selectedPackSizes.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Category Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vape Custom Variations & SKU Matrix',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'Build specific variations per flavor (e.g. Mango Ice MTL with 6,9,12,50mg & 30,60ml)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                  ),
                ],
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'LIQUID',
                    icon: Icon(Icons.water_drop_outlined, size: 16),
                    label: Text('E-Liquids'),
                  ),
                  ButtonSegment(
                    value: 'DEVICE',
                    icon: Icon(Icons.vape_free_rounded, size: 16),
                    label: Text('Devices'),
                  ),
                  ButtonSegment(
                    value: 'COIL',
                    icon: Icon(Icons.flash_on_outlined, size: 16),
                    label: Text('Coils & Pods'),
                  ),
                ],
                selected: {_selectedTemplate},
                onSelectionChanged: (val) {
                  setState(() => _selectedTemplate = val.first);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.md),

          // 1. LIQUID PER-FLAVOR BUILDER
          if (_selectedTemplate == 'LIQUID') ...[
            // Flavor Selector Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1️⃣ Target Flavour',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _availableFlavors.contains(_activeFlavor) ? _activeFlavor : _availableFlavors.first,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: _availableFlavors
                            .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) => setState(() => _activeFlavor = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Or Add New Custom Flavour',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customFlavorController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Energy Drink Ice...',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              final text = _customFlavorController.text.trim();
                              if (text.isNotEmpty) {
                                setState(() {
                                  if (!_availableFlavors.contains(text)) {
                                    _availableFlavors.add(text);
                                  }
                                  _activeFlavor = text;
                                  _customFlavorController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Set'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Vaping Style for this Flavor (DL vs MTL)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('2️⃣ Vaping Style for ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      '"$_activeFlavor"',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColor.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'MTL', label: Text('MTL (Mouth To Lung) only')),
                    ButtonSegment(value: 'DL', label: Text('DL (Direct Lung) only')),
                    ButtonSegment(value: 'RDL', label: Text('RDL (Restricted DL)')),
                    ButtonSegment(value: 'BOTH', label: Text('Both MTL & DL')),
                  ],
                  selected: {_activeVapeStyle},
                  onSelectionChanged: (val) => _onVapeStyleChanged(val.first),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        _activeVapeStyle == 'DL' || _activeVapeStyle == 'RDL'
                            ? 'نمط DL (سحبة شيشة): نيكوتين 3mg و 6mg فقط (Freebase)'
                            : _activeVapeStyle == 'MTL'
                                ? 'نمط MTL (سحبة سيجارة): نيكوتين من 6mg إلى 50mg (Salt Nic)'
                                : 'كلاهما: يتم توليد DL لـ (3mg, 6mg) و MTL لـ (6mg إلى 50mg) تلقائياً',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Nicotines & Sizes for this Flavor
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nicotines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3️⃣ Nicotine Strengths',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _availableNicotines.map((nic) {
                          final isSel = _selectedNicotines.contains(nic);
                          return FilterChip(
                            label: Text(nic, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                            selected: isSel,
                            selectedColor: AppColor.primary,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedNicotines.add(nic);
                                } else {
                                  _selectedNicotines.remove(nic);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customNicotineController,
                              decoration: const InputDecoration(
                                hintText: 'Custom nic (e.g. 35mg)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColor.primary, size: 22),
                            onPressed: () {
                              final txt = _customNicotineController.text.trim();
                              if (txt.isNotEmpty) {
                                setState(() {
                                  if (!_availableNicotines.contains(txt)) _availableNicotines.add(txt);
                                  if (!_selectedNicotines.contains(txt)) _selectedNicotines.add(txt);
                                  _customNicotineController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),

                // Sizes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '4️⃣ Bottle Sizes',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _availableSizes.map((sz) {
                          final isSel = _selectedSizes.contains(sz);
                          return FilterChip(
                            label: Text(sz, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                            selected: isSel,
                            selectedColor: AppColor.primary,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedSizes.add(sz);
                                } else {
                                  _selectedSizes.remove(sz);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customSizeController,
                              decoration: const InputDecoration(
                                hintText: 'Custom size (e.g. 150ml)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColor.primary, size: 22),
                            onPressed: () {
                              final txt = _customSizeController.text.trim();
                              if (txt.isNotEmpty) {
                                setState(() {
                                  if (!_availableSizes.contains(txt)) _availableSizes.add(txt);
                                  if (!_selectedSizes.contains(txt)) _selectedSizes.add(txt);
                                  _customSizeController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Batch Pricing & Add Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (EGP)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: _batchStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                ElevatedButton.icon(
                  onPressed: _addLiquidFlavorVariations,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: Text('Add ${_calculatePotentialCombinations()} Variations for "$_activeFlavor"'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  ),
                ),
              ],
            ),
          ]

          // 2. DEVICE TEMPLATE
          else if (_selectedTemplate == 'DEVICE') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🎨 Select Device & Packaging Colors', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: () {
                    ColorPalettePickerDialog.show(
                      context,
                      onColorSelected: (c) {
                        setState(() {
                          if (!_availableColors.contains(c)) _availableColors.add(c);
                          if (!_selectedColors.contains(c)) _selectedColors.add(c);
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.palette_rounded, size: 14),
                  label: const Text('Palette & Mix Picker', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _availableColors.map((opt) {
                final isSel = _selectedColors.contains(opt);
                return FilterChip(
                  avatar: ColorUtils.buildColorIndicator(opt, size: 12),
                  label: Text(opt, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                  selected: isSel,
                  selectedColor: AppColor.primary,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedColors.add(opt);
                      } else {
                        _selectedColors.remove(opt);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customColorController,
                    decoration: const InputDecoration(
                      hintText: 'Add custom device color (e.g. Titanium Grey)...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final text = _customColorController.text.trim();
                    if (text.isNotEmpty && !_availableColors.contains(text)) {
                      setState(() {
                        _availableColors.add(text);
                        _selectedColors.add(text);
                        _customColorController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Color'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (EGP)', isDense: true),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: _batchStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Initial Stock', isDense: true),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                ElevatedButton.icon(
                  onPressed: _addDeviceVariations,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: Text('Add ${_selectedColors.length} Device Colors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  ),
                ),
              ],
            ),
          ]

          // 3. COIL & POD TEMPLATE
          else ...[
            _buildChipSelector('⚡ Select Coil Resistances (Ω)', _availableResistances, _selectedResistances),
            const SizedBox(height: AppSizes.md),
            _buildChipSelector('📦 Packaging Options', ['Single Pod (1 pc)', 'Pack of 3', 'Pack of 4', 'Pack of 5'], _selectedPackSizes),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (EGP)', isDense: true),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: _batchStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Initial Stock', isDense: true),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                ElevatedButton.icon(
                  onPressed: _addCoilVariations,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: Text('Add ${_selectedResistances.length * _selectedPackSizes.length} Coil Variations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSizes.lg),

          // Total Variations Summary & Interactive Table
          if (_currentVariations.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configured Variations Matrix (${_currentVariations.length} Active SKUs)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentVariations.clear();
                    });
                    widget.onVariationsGenerated([]);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColor.error),
                  label: const Text('Clear All', style: TextStyle(color: AppColor.error, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkCard : AppColor.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentVariations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final v = _currentVariations[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: Row(
                      children: [
                        // Image Thumbnail / Picker
                        InkWell(
                          onTap: () => _editVariationImage(i, v),
                          borderRadius: BorderRadius.circular(6),
                          child: Tooltip(
                            message: v.image.isNotEmpty ? 'Edit variation image' : 'Add variation image',
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: v.image.isNotEmpty
                                      ? AppColor.primary
                                      : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                                ),
                              ),
                              child: v.image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.network(
                                        v.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.broken_image,
                                          size: 16,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColor.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // SKU & Attributes
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.sku,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: v.attributeValues.entries.map((e) {
                                  Color badgeColor = AppColor.primary;
                                  final key = e.key.toLowerCase();
                                  final isColor = key.contains('color');
                                  if (key.contains('flavor') || key.contains('flavour')) {
                                    badgeColor = const Color(0xFF10B981); // emerald green
                                  } else if (key.contains('type') || key.contains('dl') || key.contains('mtl')) {
                                    badgeColor = const Color(0xFF8B5CF6); // purple
                                  } else if (isColor) {
                                    badgeColor = const Color(0xFF06B6D4); // cyan
                                  } else if (key.contains('resistance') || key.contains('ohm')) {
                                    badgeColor = const Color(0xFFF59E0B); // amber
                                  } else if (key.contains('nicotine')) {
                                    badgeColor = const Color(0xFFEC4899); // pink
                                  } else if (key.contains('size')) {
                                    badgeColor = const Color(0xFF3B82F6); // blue
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isColor) ...[
                                          ColorUtils.buildColorIndicator(e.value, size: 10),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          '${e.key}: ${e.value}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // Editable Price
                        SizedBox(
                          width: 85,
                          child: TextFormField(
                            initialValue: v.salePrice.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'EGP',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            ),
                            onChanged: (val) {
                              final p = double.tryParse(val) ?? v.salePrice;
                              _currentVariations[i] = ProductVariationModel(
                                id: v.id,
                                sku: v.sku,
                                price: p,
                                salePrice: p,
                                stock: v.stock,
                                image: v.image,
                                attributeValues: v.attributeValues,
                              );
                              widget.onVariationsGenerated(_currentVariations);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),

                        // Editable Stock
                        SizedBox(
                          width: 75,
                          child: TextFormField(
                            initialValue: v.stock.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            ),
                            onChanged: (val) {
                              final newStock = int.tryParse(val) ?? v.stock;
                              _currentVariations[i] = ProductVariationModel(
                                id: v.id,
                                sku: v.sku,
                                price: v.price,
                                salePrice: v.salePrice,
                                stock: newStock,
                                image: v.image,
                                attributeValues: v.attributeValues,
                              );
                              widget.onVariationsGenerated(_currentVariations);
                            },
                          ),
                        ),

                        // Delete Single Variation
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColor.error),
                          tooltip: 'Remove variation',
                          onPressed: () {
                            setState(() {
                              _currentVariations.removeAt(i);
                            });
                            widget.onVariationsGenerated(_currentVariations);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editVariationImage(int index, ProductVariationModel v) {
    final controller = TextEditingController(text: v.image);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Variation Image (${v.sku})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://example.com/image.png',
                prefixIcon: Icon(Icons.link),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentVariations[index] = v.copyWith(image: controller.text.trim());
              });
              widget.onVariationsGenerated(_currentVariations);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelector(String label, List<String> allOptions, List<String> selected) {
    final isColor = label.toLowerCase().contains('color');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: allOptions.map((opt) {
            final isSel = selected.contains(opt);
            return FilterChip(
              avatar: isColor ? ColorUtils.buildColorIndicator(opt, size: 12) : null,
              label: Text(opt, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
              selected: isSel,
              selectedColor: AppColor.primary,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selected.add(opt);
                  } else {
                    selected.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
