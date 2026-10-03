import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/firebase_storage_service.dart';

enum ImageInputMode { url, upload }

/// A unified dual-source image picker supporting both direct network URLs
/// and direct device file upload to Firebase Storage with live progress.
class DualImagePickerField extends StatefulWidget {
  final String? initialUrl;
  final ValueChanged<String> onImageChanged;
  final String label;
  final String storageFolder;
  final String? customFileName;
  final double previewWidth;
  final double previewHeight;
  final String? helperText;
  final bool isRequired;

  const DualImagePickerField({
    super.key,
    this.initialUrl,
    required this.onImageChanged,
    this.label = 'image',
    this.storageFolder = 'general',
    this.customFileName,
    this.previewWidth = 120,
    this.previewHeight = 120,
    this.helperText,
    this.isRequired = false,
  });

  @override
  State<DualImagePickerField> createState() => _DualImagePickerFieldState();
}

class _DualImagePickerFieldState extends State<DualImagePickerField> {
  late TextEditingController _urlController;
  late ImageInputMode _currentMode;
  String _currentImageUrl = '';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialUrl?.trim() ?? '';
    _urlController = TextEditingController(text: _currentImageUrl);
    _currentMode = ImageInputMode.url;
  }

  @override
  void didUpdateWidget(covariant DualImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl) {
      final newUrl = widget.initialUrl?.trim() ?? '';
      if (newUrl != _currentImageUrl) {
        setState(() {
          _currentImageUrl = newUrl;
          _urlController.text = newUrl;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlInputChanged(String val) {
    final trimmed = val.trim();
    setState(() {
      _currentImageUrl = trimmed;
      _uploadError = null;
    });
    widget.onImageChanged(trimmed);
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      final downloadUrl = await FirebaseStorageService.pickAndUploadImage(
        folder: widget.storageFolder,
        customFileName: widget.customFileName,
        onProgress: (prog) {
          if (mounted) setState(() => _uploadProgress = prog);
        },
      );

      if (downloadUrl != null && mounted) {
        setState(() {
          _currentImageUrl = downloadUrl;
          _urlController.text = downloadUrl;
          _isUploading = false;
        });
        widget.onImageChanged(downloadUrl);
        HelperFun.showNotificationAlert(
          title: 'upload_success_title'.tr,
          message: 'upload_success_msg'.tr,
        );
      } else {
        if (mounted) setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _currentImageUrl = '';
      _urlController.clear();
      _uploadError = null;
    });
    widget.onImageChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & Mode Switcher Row (Responsive Wrap)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              '${widget.label.tr}${widget.isRequired ? ' *' : ''}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
              ),
            ),
            _buildModeSwitcher(isDark),
          ],
        ),
        const SizedBox(height: 8),

        // Main Container with Preview and Input controls
        Container(
          padding: const EdgeInsets.all(AppSizes.sm + 4),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Preview Card
              _buildLivePreview(isDark),
              const SizedBox(width: 12),

              // 2. Input / Dropzone Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentMode == ImageInputMode.url) ...[
                      // URL Text Field
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'image_url_hint'.tr,
                          prefixIcon: const Icon(Icons.link_rounded, size: 18),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: _clearImage,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12.5),
                        onChanged: _onUrlInputChanged,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'paste_direct_image_url_desc'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ] else ...[
                      // Upload from Device Dropzone Button
                      _buildUploadDropzone(isDark),
                    ],

                    if (_uploadError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _uploadError!,
                        style: const TextStyle(fontSize: 11, color: AppColor.error, fontWeight: FontWeight.w600),
                      ),
                    ],

                    if (widget.helperText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.helperText!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillButton(
            label: 'network_url_tab'.tr,
            icon: Icons.link_rounded,
            isSelected: _currentMode == ImageInputMode.url,
            onTap: () => setState(() => _currentMode = ImageInputMode.url),
            isDark: isDark,
          ),
          _buildPillButton(
            label: 'upload_file_tab'.tr,
            icon: Icons.cloud_upload_outlined,
            isSelected: _currentMode == ImageInputMode.upload,
            onTap: () => setState(() => _currentMode = ImageInputMode.upload),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(bool isDark) {
    final hasImage = _currentImageUrl.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: widget.previewWidth,
          height: widget.previewHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(
              color: hasImage ? AppColor.primary.withValues(alpha: 0.6) : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
              width: hasImage ? 1.5 : 1,
            ),
          ),
          child: _isUploading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        strokeWidth: 2.5,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColor.primary),
                    ),
                  ],
                )
              : hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd - 1.5),
                      child: Image.network(
                        _currentImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_rounded, size: 28, color: AppColor.error),
                            const SizedBox(height: 4),
                            Text(
                              'invalid_image_url'.tr,
                              style: const TextStyle(fontSize: 9.5, color: AppColor.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 30,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'no_image'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
        ),
        if (hasImage && !_isUploading)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: _clearImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadDropzone(bool isDark) {
    return InkWell(
      onTap: _isUploading ? null : _pickAndUpload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'uploading_to_firebase'.tr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary),
              ),
            ] else ...[
              const Icon(Icons.add_photo_alternate_rounded, size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Text(
                'pick_and_upload_device_btn'.tr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
