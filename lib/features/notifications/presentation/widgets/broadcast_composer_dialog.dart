import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/broadcast_model.dart';

class BroadcastComposerDialog extends StatefulWidget {
  final ValueChanged<BroadcastModel> onSend;

  const BroadcastComposerDialog({super.key, required this.onSend});

  static void show(BuildContext context, {required ValueChanged<BroadcastModel> onSend}) {
    UnifiedModalSheet.show(
      context: context,
      title: 'compose_broadcast'.tr,
      subtitle: 'broadcasts_subtitle'.tr,
      icon: Icons.campaign_outlined,
      maxWidth: 680,
      content: BroadcastComposerDialog(onSend: onSend),
    );
  }

  @override
  State<BroadcastComposerDialog> createState() => _BroadcastComposerDialogState();
}

class _BroadcastComposerDialogState extends State<BroadcastComposerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetScreenController = TextEditingController(text: '/shop');
  String _targetAudience = 'All Users';

  final List<String> _audiences = [
    'All Users',
    'SaltNic Vapers',
    'Hardware Deals Seekers',
    'Inactive Users (30+ Days)',
  ];

  final List<Map<String, String>> _quickTemplates = [
    {
      'name': '🔥 Flash Sale',
      'title': '🔥 Weekend Flash Sale: 25% Off All Liquids!',
      'body': 'Stock up on your favorite salt nic & freebase flavors before midnight with code VAPE25.',
      'route': '/category/CAT_SALT_NIC',
      'image': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=600&q=80',
    },
    {
      'name': '⚡ New Arrivals',
      'title': '⚡ New In Stock: Vaporesso & GeekVape Devices!',
      'body': 'Explore the newest pod systems and replacement coils now in stock at EGO Store.',
      'route': '/category/CAT_DEVICES',
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&q=80',
    },
    {
      'name': '🚚 Free Shipping',
      'title': '🚚 Free Express Shipping on Orders Over 2000 EGP!',
      'body': 'Fast same-day dispatch across Greater Cairo and express delivery to all governorates.',
      'route': '/shop',
      'image': '',
    },
    {
      'name': '🔄 Restock Alert',
      'title': '🔄 Popular Flavors & Pods Restocked!',
      'body': 'VGOD, Nasty Juice, and XROS 0.4 ohm cartridges are back in stock now.',
      'route': '/shop',
      'image': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshState);
    _bodyController.addListener(_refreshState);
    _imageUrlController.addListener(_refreshState);
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshState);
    _bodyController.removeListener(_refreshState);
    _imageUrlController.removeListener(_refreshState);
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _targetScreenController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, String> t) {
    setState(() {
      _titleController.text = t['title'] ?? '';
      _bodyController.text = t['body'] ?? '';
      _targetScreenController.text = t['route'] ?? '/shop';
      _imageUrlController.text = t['image'] ?? '';
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bcast = BroadcastModel(
      id: 'BCAST_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      targetAudience: _targetAudience,
      imageUrl: _imageUrlController.text.trim(),
      targetScreen: _targetScreenController.text.trim().isNotEmpty
          ? _targetScreenController.text.trim()
          : '/shop',
      topic: _targetAudience == 'All Users' ? 'all_users' : _targetAudience.toLowerCase().replaceAll(' ', '_'),
      sentAt: DateTime.now(),
      successCount: 1890,
    );
    final currentContext = context;
    widget.onSend(bcast);
    Navigator.of(context).pop();
    HelperFun.showNotificationAlert(
      context: currentContext,
      title: '🔔 ${bcast.title}',
      message: bcast.body,
      imageUrl: bcast.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Template Pills
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Message Templates:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickTemplates.map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(t['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        onPressed: () => _applyTemplate(t),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Target Audience
          DropdownButtonFormField<String>(
            initialValue: _targetAudience,
            decoration: InputDecoration(
              labelText: 'target_audience'.tr,
              prefixIcon: const Icon(Icons.people_alt_outlined, size: 18),
            ),
            items: _audiences
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (val) => setState(() => _targetAudience = val!),
          ),
          const SizedBox(height: AppSizes.md),

          // Notification Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '${'broadcast_title'.tr} *',
              hintText: 'e.g. 🔥 Flash Sale: 25% Off All SaltNic Juices!',
              prefixIcon: const Icon(Icons.title_rounded, size: 18),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),

          // Message Body
          TextFormField(
            controller: _bodyController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${'notification_body_col'.tr} *',
              hintText: 'e.g. Stock up on your favorite liquids before midnight with promo code VAPE25.',
              prefixIcon: const Icon(Icons.message_outlined, size: 18),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizes.md),

          // Optional Image URL & Target Route Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Promo Image URL (Optional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _targetScreenController,
                  decoration: const InputDecoration(
                    labelText: 'Target App Screen / Route',
                    hintText: 'e.g. /shop, /category/CAT_SALT_NIC',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Live Push Notification Mobile Preview
          _buildMobilePushPreview(isDark),
          const SizedBox(height: AppSizes.lg),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text('cancel'.tr)),
              const SizedBox(width: AppSizes.md),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Push to All Users', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm + 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePushPreview(bool isDark) {
    final title = _titleController.text.isNotEmpty ? _titleController.text : 'EGO Store Announcement';
    final body = _bodyController.text.isNotEmpty
        ? _bodyController.text
        : 'Push notification message will display here on user lock screens...';
    final imageUrl = _imageUrlController.text.trim();

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
              const Icon(Icons.phone_iphone_rounded, size: 16, color: AppColor.primary),
              const SizedBox(width: 6),
              Text(
                'Live Device Push Preview',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EGO STORE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          Text(
                            'now',
                            style: TextStyle(fontSize: 10, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
