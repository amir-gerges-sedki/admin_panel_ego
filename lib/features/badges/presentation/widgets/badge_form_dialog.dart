import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/badge_model.dart';

class BadgeFormDialog extends StatefulWidget {
  final BadgeModel? initialBadge;
  final ValueChanged<BadgeModel> onSave;

  const BadgeFormDialog({
    super.key,
    this.initialBadge,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    BadgeModel? initialBadge,
    required ValueChanged<BadgeModel> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BadgeFormDialog(
        initialBadge: initialBadge,
        onSave: onSave,
      ),
    );
  }

  @override
  State<BadgeFormDialog> createState() => _BadgeFormDialogState();
}

class _BadgeFormDialogState extends State<BadgeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late String _selectedColorHex;
  late bool _isActive;

  final List<String> _commonPresets = [
    'SALE',
    'NEW',
    'POPULAR',
    'HOT DEAL',
    'LIMITED',
    'BEST SELLER',
  ];

  static const List<Map<String, dynamic>> _colorPalette = [
    {'name': 'Amber', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'name': 'Red', 'hex': '#EF4444', 'color': Color(0xFFEF4444)},
    {'name': 'Emerald', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'Blue', 'hex': '#0EA5E9', 'color': Color(0xFF0EA5E9)},
    {'name': 'Purple', 'hex': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
    {'name': 'Pink', 'hex': '#EC4899', 'color': Color(0xFFEC4899)},
    {'name': 'Indigo', 'hex': '#4B68FF', 'color': Color(0xFF4B68FF)},
    {'name': 'Dark', 'hex': '#1E293B', 'color': Color(0xFF1E293B)},
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.initialBadge;
    _nameController = TextEditingController(text: b?.name ?? '');
    _nameArController = TextEditingController(text: b?.nameAr ?? '');
    _selectedColorHex = (b != null && b.colorHex.isNotEmpty) ? b.colorHex : '#F59E0B';
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFF59E0B);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final nameClean = _nameController.text.trim().toUpperCase();
      final id = widget.initialBadge?.id.isNotEmpty == true
          ? widget.initialBadge!.id
          : 'BADGE_${nameClean.replaceAll(' ', '_')}';

      final model = (widget.initialBadge ?? const BadgeModel(id: '', name: '')).copyWith(
        id: id,
        name: nameClean,
        nameAr: _nameArController.text.trim(),
        colorHex: _selectedColorHex,
        textColorHex: '#FFFFFF',
        isActive: _isActive,
      );

      widget.onSave(model);
      Navigator.of(context).pop();
      HelperFun.successSnackbar(
        widget.initialBadge != null ? 'item_updated'.tr : 'item_created'.tr,
        widget.initialBadge != null
            ? 'تم حفظ تعديلات الشارة "$nameClean" بنجاح.'
            : 'تم إضافة الشارة "$nameClean" بنجاح.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final currentColor = _parseColor(_selectedColorHex);
    final previewName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim().toUpperCase() : 'PREVIEW';
    final previewAr = _nameArController.text.trim();

    return AlertDialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: currentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.stars_rounded, color: currentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.initialBadge != null ? 'edit_badge'.tr : 'add_badge'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live preview
                Container(
                  width: double.infinity,
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
                      Text(
                        '${'badge_preview'.tr}:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              previewAr.isNotEmpty ? '$previewName ($previewAr)' : previewName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Presets
                Text(
                  'choose_preset_or_custom'.tr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonPresets.map((preset) {
                    final isSelected = _nameController.text.toUpperCase() == preset;
                    return ActionChip(
                      label: Text(
                        preset,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      backgroundColor: isSelected ? currentColor : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                      onPressed: () {
                        setState(() {
                          _nameController.text = preset;
                          if (preset == 'SALE') {
                            _nameArController.text = 'تخفيض';
                            _selectedColorHex = '#EF4444';
                          } else if (preset == 'NEW') {
                            _nameArController.text = 'جديد';
                            _selectedColorHex = '#10B981';
                          } else if (preset == 'POPULAR') {
                            _nameArController.text = 'شائع';
                            _selectedColorHex = '#8B5CF6';
                          } else if (preset == 'HOT DEAL') {
                            _nameArController.text = 'عرض ساخن';
                            _selectedColorHex = '#F59E0B';
                          } else if (preset == 'LIMITED') {
                            _nameArController.text = 'إصدار محدود';
                            _selectedColorHex = '#0EA5E9';
                          } else if (preset == 'BEST SELLER') {
                            _nameArController.text = 'الأكثر مبيعاً';
                            _selectedColorHex = '#4B68FF';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.md),

                // Name (English)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '${'badge_name_en'.tr} (e.g. SALE / NEW / POPULAR) *',
                    hintText: 'e.g. SALE',
                    prefixIcon: const Icon(Icons.label_outline, size: 18),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.trim().isEmpty ? 'badge_name_required'.tr : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSizes.sm),

                // Name (Arabic)
                TextFormField(
                  controller: _nameArController,
                  decoration: InputDecoration(
                    labelText: '${'badge_name_ar'.tr} (اختياري)',
                    hintText: 'e.g. تخفيض / جديد / الأكثر طلباً',
                    prefixIcon: const Icon(Icons.translate_rounded, size: 18),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSizes.md),

                // Color picker
                Text(
                  '${'badge_color'.tr}:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPalette.map((cp) {
                    final hex = cp['hex'] as String;
                    final color = cp['color'] as Color;
                    final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();

                    return InkWell(
                      onTap: () => setState(() => _selectedColorHex = hex),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.sm),

                // Active toggle
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'badge_status'.tr,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'badge_status_app_hint'.tr,
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _isActive,
                    activeThumbColor: AppColor.primary,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: currentColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.initialBadge != null ? 'save_badge_changes'.tr : 'add_badge'.tr),
        ),
      ],
    );
  }
}
