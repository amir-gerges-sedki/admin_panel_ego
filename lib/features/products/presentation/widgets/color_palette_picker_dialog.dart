import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/color_utils.dart';
import '../../../../core/helper/helper_fun.dart';

class ColorPalettePickerDialog extends StatefulWidget {
  final ValueChanged<String> onColorSelected;

  const ColorPalettePickerDialog({super.key, required this.onColorSelected});

  static void show(
    BuildContext context, {
    required ValueChanged<String> onColorSelected,
  }) {
    UnifiedModalSheet.show(
      context: context,
      title: 'Pick Color - منتقي ألوان الأجهزة والباكجينج',
      subtitle:
          'اختر لوناً موحداً أو تدرج مكس للعلب والباكجينج عبر (Sampler | Spectrum | Image)',
      icon: Icons.palette_outlined,
      maxWidth: 780,
      content: ColorPalettePickerDialog(onColorSelected: onColorSelected),
    );
  }

  @override
  State<ColorPalettePickerDialog> createState() =>
      _ColorPalettePickerDialogState();
}

enum ColorPickerSource { sampler, spectrum, image }

class _ColorPalettePickerDialogState extends State<ColorPalettePickerDialog> {
  // Mode: 0 = Solid Color, 1 = Mix / Gradient for Packaging & Boxes
  int _selectedMode = 0;

  // Active target when in Mix mode: 0 = Primary, 1 = Secondary
  int _activeMixTarget = 0;

  // Current Active Source Tab: Sampler, Spectrum, Image
  ColorPickerSource _currentSource = ColorPickerSource.sampler;

  // Color State
  Color _solidColor = const Color(0xFF5F3FD1); // Default Purple from reference
  Color _primaryMixColor = const Color(0xFF8B5CF6);
  Color _secondaryMixColor = const Color(0xFFEC4899);

  // Spectrum HSV State
  double _hue = 260.0; // 0 to 360
  double _saturation = 0.70; // 0 to 1
  double _value = 0.82; // 0 to 1

  // Text Controllers
  late TextEditingController _hexController;
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  String _sampledImageUrl = '';

  // 14 Rows x 12 Columns Palette Matrix
  static final List<List<Color>> _samplerMatrix = _generateSamplerMatrix();

  static List<List<Color>> _generateSamplerMatrix() {
    final List<List<Color>> matrix = [];

    // Row 0: Grayscale (White to Black)
    matrix.add([
      const Color(0xFFFFFFFF),
      const Color(0xFFF3F4F6),
      const Color(0xFFE5E7EB),
      const Color(0xFFD1D5DB),
      const Color(0xFF9CA3AF),
      const Color(0xFF6B7280),
      const Color(0xFF4B5563),
      const Color(0xFF374151),
      const Color(0xFF1F2937),
      const Color(0xFF111827),
      const Color(0xFF09090B),
      const Color(0xFF000000),
    ]);

    // Hues for remaining rows: 13 distinct chromatic rows
    final hues = [
      0.0, // Red
      340.0, // Crimson / Pink
      300.0, // Magenta
      280.0, // Purple
      260.0, // Deep Violet / Indigo
      220.0, // Royal Blue
      195.0, // Cyan / Sky
      175.0, // Teal
      150.0, // Emerald Green
      110.0, // Lime
      55.0, // Yellow / Gold
      30.0, // Orange
      18.0, // Coral / Terracotta
    ];

    for (final h in hues) {
      final List<Color> row = [];
      // 12 gradations from very light tint (low sat, high val) to deep shade (high sat, low val)
      for (int i = 0; i < 12; i++) {
        double sat;
        double val;
        if (i < 4) {
          sat = 0.15 + (i * 0.18);
          val = 0.98 - (i * 0.05);
        } else if (i < 8) {
          sat = 0.75 + ((i - 4) * 0.06);
          val = 0.85 - ((i - 4) * 0.10);
        } else {
          sat = 0.95;
          val = 0.45 - ((i - 8) * 0.09);
        }
        sat = sat.clamp(0.0, 1.0);
        val = val.clamp(0.08, 1.0);
        row.add(HSVColor.fromAHSV(1.0, h, sat, val).toColor());
      }
      matrix.add(row);
    }

    return matrix;
  }

  // Presets for Packaging Mix & Devices
  final List<Map<String, dynamic>> _packagingMixPresets = [
    {
      'name': 'Nebula Purple & Pink',
      'c1': const Color(0xFF8B5CF6),
      'c2': const Color(0xFFEC4899),
    },
    {
      'name': 'Aurora Cyan & Blue',
      'c1': const Color(0xFF06B6D4),
      'c2': const Color(0xFF3B82F6),
    },
    {
      'name': 'Sunset Flame',
      'c1': const Color(0xFFF59E0B),
      'c2': const Color(0xFFEF4444),
    },
    {
      'name': 'Cyberpunk Neon',
      'c1': const Color(0xFF10B981),
      'c2': const Color(0xFF06B6D4),
    },
    {
      'name': 'Carbon Black & Gold',
      'c1': const Color(0xFF18181B),
      'c2': const Color(0xFFD97706),
    },
    {
      'name': 'Royal Violet & Teal',
      'c1': const Color(0xFF7C3AED),
      'c2': const Color(0xFF14B8A6),
    },
    {
      'name': 'Rose Gold & Platinum',
      'c1': const Color(0xFFFB7185),
      'c2': const Color(0xFFE2E8F0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: ColorUtils.toHex(_solidColor));
    _nameController = TextEditingController(text: 'Obsidian Purple');
    _imageUrlController = TextEditingController();
    _updateHsvFromColor(_solidColor);
  }

  @override
  void dispose() {
    _hexController.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    if (_selectedMode == 0) return _solidColor;
    return _activeMixTarget == 0 ? _primaryMixColor : _secondaryMixColor;
  }

  void _updateCurrentColor(Color color) {
    setState(() {
      if (_selectedMode == 0) {
        _solidColor = color;
      } else {
        if (_activeMixTarget == 0) {
          _primaryMixColor = color;
        } else {
          _secondaryMixColor = color;
        }
      }
      _hexController.text = ColorUtils.toHex(color);
      _updateHsvFromColor(color);
    });
  }

  void _updateHsvFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _onHexInputChanged(String val) {
    final parsed = ColorUtils.parseHex(val);
    if (parsed != null) {
      _updateCurrentColor(parsed);
    }
  }

  void _onSpectrumTap(Offset localPos, Size size) {
    final sat = (localPos.dx / size.width).clamp(0.0, 1.0);
    final val = (1.0 - (localPos.dy / size.height)).clamp(0.0, 1.0);
    setState(() {
      _saturation = sat;
      _value = val;
      final newColor = HSVColor.fromAHSV(
        1.0,
        _hue,
        _saturation,
        _value,
      ).toColor();
      if (_selectedMode == 0) {
        _solidColor = newColor;
      } else {
        if (_activeMixTarget == 0) {
          _primaryMixColor = newColor;
        } else {
          _secondaryMixColor = newColor;
        }
      }
      _hexController.text = ColorUtils.toHex(newColor);
    });
  }

  void _onHueChanged(double newHue) {
    setState(() {
      _hue = newHue;
      final newColor = HSVColor.fromAHSV(
        1.0,
        _hue,
        _saturation,
        _value,
      ).toColor();
      if (_selectedMode == 0) {
        _solidColor = newColor;
      } else {
        if (_activeMixTarget == 0) {
          _primaryMixColor = newColor;
        } else {
          _secondaryMixColor = newColor;
        }
      }
      _hexController.text = ColorUtils.toHex(newColor);
    });
  }

  void _submit() {
    String finalColorString;

    if (_selectedMode == 0) {
      finalColorString = ColorUtils.toHex(_solidColor);
    } else {
      final hex1 = ColorUtils.toHex(_primaryMixColor);
      final hex2 = ColorUtils.toHex(_secondaryMixColor);
      finalColorString = '$hex1/$hex2';
    }

    widget.onColorSelected(finalColorString);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector: Solid Color vs Mix / Gradient for Boxes
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeTab(
                  title: 'لون أحادي للأجهزة (Solid Color)',
                  icon: Icons.circle_rounded,
                  isSelected: _selectedMode == 0,
                  onTap: () => setState(() => _selectedMode = 0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildModeTab(
                  title: 'مكس ألوان وتدرج للعلب والباكجينج (Mix / Boxes)',
                  icon: Icons.gradient_rounded,
                  isSelected: _selectedMode == 1,
                  onTap: () => setState(() => _selectedMode = 1),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // If in Mix mode: Dual Color Selector Tabs (Color 1 vs Color 2)
        if (_selectedMode == 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkCard : AppColor.lightCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: Row(
              children: [
                // Live 3D Box Packaging Gradient Mockup
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryMixColor, _secondaryMixColor],
                    ),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryMixColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تعديل:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _primaryMixColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                  ),
                  label: Text(
                    'اللون الأساسي (${ColorUtils.toHex(_primaryMixColor)})',
                  ),
                  selected: _activeMixTarget == 0,
                  selectedColor: AppColor.primary.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() {
                      _activeMixTarget = 0;
                      _hexController.text = ColorUtils.toHex(_primaryMixColor);
                      _updateHsvFromColor(_primaryMixColor);
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _secondaryMixColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                  ),
                  label: Text(
                    'لون المكس/العلبة (${ColorUtils.toHex(_secondaryMixColor)})',
                  ),
                  selected: _activeMixTarget == 1,
                  selectedColor: AppColor.primary.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() {
                      _activeMixTarget = 1;
                      _hexController.text = ColorUtils.toHex(
                        _secondaryMixColor,
                      );
                      _updateHsvFromColor(_secondaryMixColor);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Source Switcher: Sampler | Spectrum | Image (As in user's UI)
        Row(
          children: [
            const Text(
              'Source',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: AppSizes.md),
            _buildSourceButton(
              title: 'Sampler',
              icon: Icons.color_lens_outlined,
              source: ColorPickerSource.sampler,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            _buildSourceButton(
              title: 'Spectrum',
              icon: Icons.grid_view_rounded,
              source: ColorPickerSource.spectrum,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            _buildSourceButton(
              title: 'Image',
              icon: Icons.image_outlined,
              source: ColorPickerSource.image,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Main Visual Color Workspace (Sampler Grid + 2D Spectrum)
        _buildMainColorWorkspace(isDark),
        const SizedBox(height: AppSizes.md),

        // Bottom Controls: Pixel Color + Hex + Coordinates
        _buildBottomControls(isDark),
        const SizedBox(height: AppSizes.lg),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_selectedMode == 1)
              PopupMenuButton<Map<String, dynamic>>(
                tooltip: 'اختر من التدرجات الجاهزة',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColor.darkSubCard
                        : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColor.darkBorder
                          : AppColor.lightBorder,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'تدرجات علب وأجهزة جاهزة ▾',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (preset) {
                  setState(() {
                    _primaryMixColor = preset['c1'] as Color;
                    _secondaryMixColor = preset['c2'] as Color;
                    _nameController.text = preset['name'] as String;
                    _hexController.text = ColorUtils.toHex(_primaryMixColor);
                    _updateHsvFromColor(_primaryMixColor);
                  });
                },
                itemBuilder: (context) {
                  return _packagingMixPresets.map((p) {
                    return PopupMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [p['c1'] as Color, p['c2'] as Color],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p['name'] as String,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              )
            else
              const SizedBox.shrink(),

            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: AppSizes.md),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('حفظ واختيار اللون (Save Color)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColor.textPrimaryDark
                            : AppColor.textPrimaryLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required String title,
    required IconData icon,
    required ColorPickerSource source,
    required bool isDark,
  }) {
    final isSelected = _currentSource == source;

    return InkWell(
      onTap: () => setState(() => _currentSource = source),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColor.darkBorder : Colors.grey.shade200)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColor.primary
                  : (isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColor.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MAIN WORKSPACE (Sampler 14x12 Grid + 2D Spectrum Canvas)
  // ----------------------------------------------------------------------
  Widget _buildMainColorWorkspace(bool isDark) {
    if (_currentSource == ColorPickerSource.image) {
      return _buildImagePickerWorkspace(isDark);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side: 14 Rows x 12 Columns Swatches Matrix (Sampler)
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : AppColor.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _samplerMatrix.map((row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((swatch) {
                  final isSelected =
                      _currentColor.toARGB32() == swatch.toARGB32();

                  return GestureDetector(
                    onTap: () => _updateCurrentColor(swatch),
                    child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : (swatch.computeLuminance() > 0.8
                                    ? Colors.grey.shade400
                                    : Colors.transparent),
                          width: isSelected ? 2 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: AppSizes.md),

        // Right Side: 2D HSV Spectrum Canvas + Hue Slider
        Expanded(
          child: Column(
            children: [
              // 2D Gradient Canvas
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 230,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return GestureDetector(
                        onPanDown: (d) => _onSpectrumTap(d.localPosition, size),
                        onPanUpdate: (d) =>
                            _onSpectrumTap(d.localPosition, size),
                        child: CustomPaint(
                          size: size,
                          painter: _SpectrumCanvasPainter(
                            hue: _hue,
                            saturation: _saturation,
                            value: _value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Rainbow Hue Slider Bar
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000), // 0
                      Color(0xFFFFFF00), // 60
                      Color(0xFF00FF00), // 120
                      Color(0xFF00FFFF), // 180
                      Color(0xFF0000FF), // 240
                      Color(0xFFFF00FF), // 300
                      Color(0xFFFF0000), // 360
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 16,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _hue,
                    min: 0.0,
                    max: 360.0,
                    onChanged: _onHueChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // IMAGE COLOR PICKER WORKSPACE (Image Eyedropper)
  // ----------------------------------------------------------------------
  Widget _buildImagePickerWorkspace(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText:
                        'رابط صورة الجهاز أو العلبة لاستخراج اللون (Image URL)',
                    hintText: 'https://example.com/device_packaging_box.jpg',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _sampledImageUrl = _imageUrlController.text.trim();
                  });
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('تحميل الصورة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (_sampledImageUrl.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Image.network(
                    _sampledImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('فشل تحميل الصورة. يرجى التأكد من الرابط.'),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'أدخل رابط صورة العلبة أو الجهاز لاستخراج وتحديد الألوان بدقة',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BOTTOM CONTROLS (Pixel Color + Hex + Coordinates)
  // ----------------------------------------------------------------------
  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Pixel Color & Swatch
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Pixel Color',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _currentColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _currentColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _hexController,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _onHexInputChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: AppSizes.md),

          // Name Input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اسم اللون / الفينش (Color Name)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Nebula Purple, Matte Obsidian',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Coordinates Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Coordinates',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Sat: ${(_saturation * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Val: ${(_value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}

// ----------------------------------------------------------------------
// 2D SPECTRUM CANVAS PAINTER
// ----------------------------------------------------------------------
class _SpectrumCanvasPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _SpectrumCanvasPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Horizontal Hue / Saturation Gradient (White to Pure Hue)
    final pureHueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final horizontalPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, pureHueColor],
      ).createShader(rect);

    canvas.drawRect(rect, horizontalPaint);

    // 2. Vertical Brightness Gradient (Transparent to Solid Black)
    final verticalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
      ).createShader(rect);

    canvas.drawRect(rect, verticalPaint);

    // 3. Draw Selector Circle Crosshair
    final cursorX = saturation * size.width;
    final cursorY = (1.0 - value) * size.height;

    final cursorCenter = Offset(cursorX, cursorY);

    // Outer Shadow / Border Ring
    canvas.drawCircle(
      cursorCenter,
      7,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Inner White Ring
    canvas.drawCircle(
      cursorCenter,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpectrumCanvasPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.value != value;
  }
}
