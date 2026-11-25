import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../badges/data/models/badge_model.dart';
import '../../../../badges/presentation/cubit/badge_cubit.dart';
import '../../../../badges/presentation/cubit/badge_state.dart';
import '../../../../badges/presentation/widgets/badges_management_dialog.dart';
import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/constant/app_sizes.dart';
import '../../../../../core/localization/app_localizations.dart';

/// Settings card for homepage product badges management and previews
class BadgesSettingsCard extends StatelessWidget {
  final bool isDark;

  const BadgesSettingsCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'badges'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'badges_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColor.textSecondaryDark
                            : AppColor.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'badges_card_desc'.tr,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColor.textSecondaryDark
                  : AppColor.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          BlocBuilder<BadgeCubit, BadgeState>(
            builder: (context, state) {
              final badges = state is BadgeLoaded ? state.badges : <BadgeModel>[];

              Color parseColor(String hex, Color fallback) {
                try {
                  final clean = hex.replaceAll('#', '').trim();
                  return Color(int.parse('FF$clean', radix: 16));
                } catch (_) {
                  return fallback;
                }
              }

              if (badges.isNotEmpty) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges.map((badge) {
                    final color = parseColor(badge.colorHex, const Color(0xFFF59E0B));
                    final textColor = parseColor(badge.textColorHex, Colors.white);
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    final label = (isAr && badge.nameAr.trim().isNotEmpty) ? badge.nameAr : badge.name;
                    return _buildSampleBadgeChip(label, color, textColor: textColor);
                  }).toList(),
                );
              }

              Color getColorFor(String defaultName, Color fallback) {
                final match = badges.where((b) => b.name.trim().toUpperCase() == defaultName.toUpperCase()).firstOrNull;
                return match != null ? parseColor(match.colorHex, fallback) : fallback;
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSampleBadgeChip('SALE', getColorFor('SALE', const Color(0xFFEF4444))),
                  _buildSampleBadgeChip('NEW', getColorFor('NEW', const Color(0xFF10B981))),
                  _buildSampleBadgeChip('HOT DEAL', getColorFor('HOT DEAL', const Color(0xFFF59E0B))),
                  _buildSampleBadgeChip('LIMITED', getColorFor('LIMITED', const Color(0xFF0EA5E9))),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton.icon(
            onPressed: () async {
              await BadgesManagementDialog.show(context);
              if (context.mounted) {
                context.read<BadgeCubit>().loadBadges();
              }
            },
            icon: const Icon(Icons.stars_rounded, size: 18),
            label: Text('manage_badges'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md - 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleBadgeChip(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
