import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/badge_model.dart';
import '../cubit/badge_cubit.dart';
import '../cubit/badge_state.dart';
import 'badge_form_dialog.dart';

class BadgesManagementDialog extends StatefulWidget {
  const BadgesManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    context.read<BadgeCubit>().loadBadges();

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const BadgesManagementDialog(),
    );
  }

  @override
  State<BadgesManagementDialog> createState() => _BadgesManagementDialogState();
}

class _BadgesManagementDialogState extends State<BadgesManagementDialog> {
  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFF59E0B);
    }
  }

  void _confirmDelete(BuildContext context, BadgeModel badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_badge'.tr),
        content: Text('${'delete_badge_confirm'.tr} (${badge.name})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BadgeCubit>().deleteBadge(badge.id);
              HelperFun.successSnackbar('success'.tr, 'item_deleted'.tr);
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'badges'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'badges_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'reload'.tr,
                    onPressed: () => context.read<BadgeCubit>().loadBadges(),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () {
                      BadgeFormDialog.show(
                        context,
                        onSave: (badge) {
                          context.read<BadgeCubit>().addBadge(badge);
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('add_badge'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm + 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content List
            Expanded(
              child: BlocBuilder<BadgeCubit, BadgeState>(
                builder: (context, state) {
                  if (state is BadgeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is BadgeError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColor.error, size: 40),
                          const SizedBox(height: 8),
                          Text(state.message, style: const TextStyle(color: AppColor.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<BadgeCubit>().loadBadges(),
                            child: Text('reload'.tr),
                          ),
                        ],
                      ),
                    );
                  }

                  final badges = (state is BadgeLoaded) ? state.badges : <BadgeModel>[];

                  if (badges.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, size: 48, color: Color(0xFFF59E0B)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'no_badges_found'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'no_badges_desc'.tr,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              BadgeFormDialog.show(
                                context,
                                onSave: (b) => context.read<BadgeCubit>().addBadge(b),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text('add_badge'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    itemCount: badges.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final badge = badges[i];
                      final badgeColor = _parseColor(badge.colorHex);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                          border: Border.all(
                            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Badge preview chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withValues(alpha: 0.35),
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
                                    badge.nameAr.isNotEmpty
                                        ? '${badge.name} (${badge.nameAr})'
                                        : badge.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        badge.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (badge.nameAr.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${badge.nameAr}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColor.darkChip : AppColor.lightChip,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ID: ${badge.id}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        badge.colorHex,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Active Switch
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  badge.isActive
                                      ? 'badge_active'.tr
                                      : 'badge_inactive'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badge.isActive ? AppColor.success : AppColor.textMutedLight,
                                  ),
                                ),
                                Switch(
                                  value: badge.isActive,
                                  activeThumbColor: const Color(0xFFF59E0B),
                                  onChanged: (val) {
                                    context.read<BadgeCubit>().updateBadge(
                                      badge.copyWith(isActive: val),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),

                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFF59E0B)),
                              tooltip: 'edit_badge'.tr,
                              onPressed: () {
                                BadgeFormDialog.show(
                                  context,
                                  initialBadge: badge,
                                  onSave: (updated) {
                                    context.read<BadgeCubit>().updateBadge(updated);
                                  },
                                );
                              },
                            ),

                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColor.error),
                              tooltip: 'delete_badge'.tr,
                              onPressed: () => _confirmDelete(context, badge),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
