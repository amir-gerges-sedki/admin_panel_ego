import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
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

  final List<String> _commonPresets = ['SALE', 'NEW', 'POPULAR', 'HOT DEAL', 'LIMITED', 'BEST SELLER'];

  @override
  void initState() {
    super.initState();
    final b = widget.initialBadge;
    _nameController = TextEditingController(text: b?.name ?? '');
    _nameArController = TextEditingController(text: b?.nameAr ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final nameClean = _nameController.text.trim().toUpperCase();
      final id = widget.initialBadge?.id.isNotEmpty == true
          ? widget.initialBadge!.id
          : 'BADGE_${nameClean.replaceAll(' ', '_')}';

      final model = BadgeModel(
        id: id,
        name: nameClean,
        nameAr: _nameArController.text.trim(),
        colorHex: '#F59E0B',
        textColorHex: '#FFFFFF',
        isActive: true,
      );

      widget.onSave(model);
      Navigator.of(context).pop();
      HelperFun.successSnackbar(
        'تم إضافة الباتش',
        'تم حفظ الباتش "$nameClean" بنجاح في قاعدة البيانات.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return AlertDialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            widget.initialBadge != null ? 'تعديل الباتش' : 'إضافة نوع باتش جديد (Badge)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر من الأنواع الشائعة أو اكتب اسماً مخصصاً:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      backgroundColor: isSelected ? const Color(0xFFF59E0B) : (isDark ? AppColor.darkSubCard : AppColor.lightSubCard),
                      onPressed: () {
                        setState(() {
                          _nameController.text = preset;
                          if (preset == 'SALE') _nameArController.text = 'تخفيض';
                          if (preset == 'NEW') _nameArController.text = 'جديد';
                          if (preset == 'POPULAR') _nameArController.text = 'شائع';
                          if (preset == 'HOT DEAL') _nameArController.text = 'عرض ساخن';
                          if (preset == 'LIMITED') _nameArController.text = 'إصدار محدود';
                          if (preset == 'BEST SELLER') _nameArController.text = 'الأكثر مبيعاً';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.md),

                // Name (English)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الباتش (مثل: SALE / NEW / POPULAR) *',
                    hintText: 'e.g. SALE',
                    prefixIcon: Icon(Icons.label_outline, size: 18),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الباتش' : null,
                ),
                const SizedBox(height: AppSizes.sm),

                // Name (Arabic)
                TextFormField(
                  controller: _nameArController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالعربية (اختياري)',
                    hintText: 'e.g. تخفيض / جديد / الأكثر طلباً',
                    prefixIcon: Icon(Icons.translate_rounded, size: 18),
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
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
          ),
          child: const Text('حفظ في فايربيس'),
        ),
      ],
    );
  }
}
