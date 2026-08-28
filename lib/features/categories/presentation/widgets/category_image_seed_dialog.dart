import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/services/category_image_seeder.dart';

/// Dialog for seeding EGO-branded images into Firestore Categories.
///
/// Features a one-click "Seed All from Internet" button that automatically
/// downloads images from pre-configured URLs and saves them to Firestore.
class CategoryImageSeedDialog extends StatefulWidget {
  final VoidCallback? onComplete;

  const CategoryImageSeedDialog({super.key, this.onComplete});

  static void show(BuildContext context, {VoidCallback? onComplete}) {
    UnifiedModalSheet.show(
      context: context,
      title: 'صور الأقسام — EGO',
      icon: Icons.photo_library_outlined,
      maxWidth: 640,
      content: CategoryImageSeedDialog(onComplete: onComplete),
    );
  }

  @override
  State<CategoryImageSeedDialog> createState() =>
      _CategoryImageSeedDialogState();
}

class _CategoryImageSeedDialogState extends State<CategoryImageSeedDialog> {
  final Map<String, TextEditingController> _urlControllers = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _results = {};
  bool _batchLoading = false;

  @override
  void initState() {
    super.initState();
    for (final catId in CategoryImageSeeder.supportedCategoryIds) {
      // Pre-fill with default internet image URL
      _urlControllers[catId] = TextEditingController(
        text: CategoryImageSeeder.getDefaultImageUrl(catId),
      );
      _loading[catId] = false;
      _results[catId] = null;
    }
  }

  @override
  void dispose() {
    for (final c in _urlControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 🚀 One-click: Download all images from internet → save to Firestore
  Future<void> _seedAllFromInternet() async {
    setState(() {
      _batchLoading = true;
      for (final catId in CategoryImageSeeder.supportedCategoryIds) {
        _loading[catId] = true;
        _results[catId] = null;
      }
    });

    // Use the URLs from the text fields (pre-filled or user-modified)
    for (final catId in CategoryImageSeeder.supportedCategoryIds) {
      final url = _urlControllers[catId]?.text.trim() ?? '';
      if (url.isEmpty) continue;

      try {
        await CategoryImageSeeder.setCategoryImageUrl(
          categoryId: catId,
          imageUrl: url,
        );
        if (mounted) {
          setState(() {
            _results[catId] = '✅ تم حفظ الصورة بنجاح';
            _loading[catId] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results[catId] = '❌ $e';
            _loading[catId] = false;
          });
        }
      }
    }

    if (mounted) {
      setState(() => _batchLoading = false);
    }
    widget.onComplete?.call();
  }

  /// Upload to Firebase Storage (download from URL → upload → save Storage URL)
  Future<void> _seedAllToStorage() async {
    setState(() {
      _batchLoading = true;
      for (final catId in CategoryImageSeeder.supportedCategoryIds) {
        _loading[catId] = true;
        _results[catId] = null;
      }
    });

    for (final catId in CategoryImageSeeder.supportedCategoryIds) {
      final url = _urlControllers[catId]?.text.trim() ?? '';
      if (url.isEmpty) continue;

      try {
        final downloadUrl = await CategoryImageSeeder.seedCategoryImageFromUrl(
          categoryId: catId,
          sourceUrl: url,
        );
        if (mounted) {
          setState(() {
            _results[catId] = '✅ تم الرفع → $downloadUrl';
            _loading[catId] = false;
          });
        }
      } catch (e) {
        // Fallback to direct URL if upload fails
        try {
          await CategoryImageSeeder.setCategoryImageUrl(
            categoryId: catId,
            imageUrl: url,
          );
          if (mounted) {
            setState(() {
              _results[catId] = '⚠️ تم حفظ الرابط مباشرة (فشل الرفع)';
              _loading[catId] = false;
            });
          }
        } catch (e2) {
          if (mounted) {
            setState(() {
              _results[catId] = '❌ $e2';
              _loading[catId] = false;
            });
          }
        }
      }
    }

    if (mounted) {
      setState(() => _batchLoading = false);
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── One-click seed button ──
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primary.withValues(alpha: 0.15),
                AppColor.info.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColor.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColor.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              const Text(
                'إضافة صور من الإنترنت تلقائياً',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الصور جاهزة ومعبرة عن EGO — اضغط زر واحد وخلاص!',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColor.textSecondaryDark
                      : AppColor.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _batchLoading ? null : _seedAllFromInternet,
                      icon: _batchLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'حفظ صور الإنترنت مباشرة',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _batchLoading ? null : _seedAllToStorage,
                      icon: _batchLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: const Text(
                        'رفع إلى Firebase Storage',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.success,
                        side: const BorderSide(color: AppColor.success),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Category rows with preview + editable URL ──
        ...CategoryImageSeeder.supportedCategoryIds.map(
          (catId) => _buildCategoryRow(context, catId, isDark),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String categoryId,
    bool isDark,
  ) {
    final isLoading = _loading[categoryId] ?? false;
    final result = _results[categoryId];
    final name = CategoryImageSeeder.getCategoryName(categoryId);
    final previewUrl = _urlControllers[categoryId]?.text.trim() ?? '';

    // Category icon & color
    final IconData icon;
    final Color iconColor;
    switch (categoryId) {
      case 'CAT_LIQUIDS':
        icon = Icons.water_drop_rounded;
        iconColor = const Color(0xFF0EA5E9);
        break;
      case 'CAT_HARDWARE':
        icon = Icons.vape_free_rounded;
        iconColor = const Color(0xFF6366F1);
        break;
      case 'CAT_COILS_PODS':
        icon = Icons.flash_on_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'CAT_ACCESSORIES':
        icon = Icons.handyman_rounded;
        iconColor = const Color(0xFFEC4899);
        break;
      default:
        icon = Icons.category_outlined;
        iconColor = AppColor.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + name + image preview
            Row(
              children: [
                // Category icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),

                // Name + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        categoryId,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColor.textMutedDark
                              : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Image preview thumbnail
                if (previewUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      previewUrl,
                      width: 56,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 56,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColor.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 16,
                          color: AppColor.error,
                        ),
                      ),
                    ),
                  ),

                // Loading indicator
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Editable URL field
            TextFormField(
              controller: _urlControllers[categoryId],
              decoration: InputDecoration(
                hintText: 'رابط الصورة من الإنترنت',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColor.textMutedDark
                      : AppColor.textMutedLight,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link_rounded, size: 16),
              ),
              style: const TextStyle(fontSize: 11),
              onChanged: (_) => setState(() {}),
            ),

            // Result feedback
            if (result != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: result.startsWith('❌')
                      ? AppColor.error.withValues(alpha: 0.08)
                      : AppColor.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 11,
                    color: result.startsWith('❌')
                        ? AppColor.error
                        : AppColor.success,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
