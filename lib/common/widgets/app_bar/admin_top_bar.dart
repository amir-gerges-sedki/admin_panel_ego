import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/helper/responsive_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_bloc.dart';
import '../../../core/theme/theme_cubit.dart';

import '../../../features/orders/presentation/cubit/order_cubit.dart';

/// Top Application Bar for EGO Admin Panel
class AdminTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String>? onGlobalSearch;
  final VoidCallback? onNotificationPressed;

  const AdminTopBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onGlobalSearch,
    this.onNotificationPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<AdminTopBar> createState() => _AdminTopBarState();
}

class _AdminTopBarState extends State<AdminTopBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
  }

  void _onSearchInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile Menu Trigger
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: widget.onMenuPressed,
            ),
            const SizedBox(width: AppSizes.sm),
          ],

          // Title & Breadcrumb
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text.rich(
                  TextSpan(
                    text: '${'app_name'.tr} / ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    ),
                    children: [
                      TextSpan(
                        text: widget.title.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Search Bar on Desktop (only if wide enough)
          if (isDesktop && MediaQuery.sizeOf(context).width > 1100 && widget.onGlobalSearch != null) ...[
            SizedBox(
              width: 220,
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: widget.onGlobalSearch,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          splashRadius: 16,
                          tooltip: 'clear_search'.tr,
                          onPressed: () {
                            _searchController.clear();
                            widget.onGlobalSearch?.call('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
          ],

          // Live System Badge (only on very wide screens)
          if (MediaQuery.sizeOf(context).width > 1280) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm + 2, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: AppColor.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColor.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'live_store_status'.tr,
                    style: const TextStyle(
                      color: AppColor.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
          ],

          // Language Switcher Button
          BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, state) {
              final isArabic = state.locale.languageCode == 'ar';
              return IconButton(
                tooltip: isArabic ? 'switch_to_english'.tr : 'switch_to_arabic'.tr,
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    border: Border.all(
                      color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                    ),
                  ),
                  child: Text(
                    isArabic ? 'EN' : 'عربي',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                ),
                onPressed: () => context.read<LocaleBloc>().toggleLocale(),
              );
            },
          ),
          const SizedBox(width: 4),

          // Theme Toggle Button
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return IconButton(
                tooltip: state.isDarkMode ? 'light_theme'.tr : 'dark_theme'.tr,
                icon: Icon(
                  state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                  color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          const SizedBox(width: 4),

          // Notifications Bell with Dynamic Badge from Firestore
          BlocBuilder<OrderCubit, OrderState>(
            builder: (context, orderState) {
              int pendingCount = 0;
              if (orderState is OrderLoaded) {
                pendingCount = orderState.orders
                    .where((o) => o.status.toLowerCase() == 'pending')
                    .length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: pendingCount > 0
                        ? 'notifications'.trParams({'count': '$pendingCount'})
                        : 'notifications'.tr,
                    icon: Icon(
                      pendingCount > 0 ? Icons.notifications_active_outlined : Icons.notifications_outlined,
                      size: 20,
                      color: pendingCount > 0 ? AppColor.primary : (isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                    ),
                    onPressed: () {
                      if (widget.onNotificationPressed != null) {
                        widget.onNotificationPressed!();
                      } else {
                        HelperFun.infoSnackbar(
                          title: 'notifications'.tr,
                          message: pendingCount > 0
                              ? '$pendingCount pending orders waiting for dispatch.'
                              : 'All orders processed. No pending notifications.',
                        );
                      }
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColor.statusPending,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: AppSizes.sm),

          // Admin Profile Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColor.primary,
                  child: Text(
                    'EG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: AppSizes.sm),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'admin_email'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
