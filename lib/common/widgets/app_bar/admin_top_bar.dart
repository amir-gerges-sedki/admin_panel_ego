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
import '../../../features/roles/domain/models/admin_role.dart';
import '../../../features/roles/presentation/cubit/auth_role_cubit.dart';

/// Top Application Bar for EGO Admin Panel with PIN-Protected Role Elevation
class AdminTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String>? onGlobalSearch;
  final VoidCallback? onNotificationPressed;
  final ValueChanged<int>? onNavigateTab;

  const AdminTopBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onGlobalSearch,
    this.onNotificationPressed,
    this.onNavigateTab,
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

  void _showRoleSecurityDialog(BuildContext context, AuthRoleState authState, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: authState.activeRole.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(authState.activeRole.icon, color: authState.activeRole.color, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'current_active_role'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Role Status Card
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: authState.activeRole.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  border: Border.all(color: authState.activeRole.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: authState.activeRole.color,
                      child: Icon(authState.activeRole.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.activeRole.labelKey.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: authState.activeRole.color,
                            ),
                          ),
                          Text(
                            authState.activeRole.descriptionKey.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // If currently elevated (Super Admin or Admin), allow Locking session back to Staff
              if (authState.isElevated) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  title: Text(
                    'lock_to_staff'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    'staff_role_desc'.tr,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                  ),
                  onTap: () {
                    context.read<AuthRoleCubit>().lockToStaff();
                    Navigator.of(dialogCtx).pop();
                    HelperFun.infoSnackbar(
                      title: 'lock_to_staff'.tr,
                      message: 'session_locked'.tr,
                    );
                  },
                ),
                const Divider(height: 1),
              ],

              // Role Elevation Options with PIN protection
              if (authState.activeRole != AdminRole.superAdmin) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'super_admin'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                  subtitle: Text(
                    'super_admin_desc'.tr,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                  ),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    _promptPinDialog(context, AdminRole.superAdmin, isDark);
                  },
                ),
              ],

              if (authState.activeRole != AdminRole.admin) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'admin_role'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                  subtitle: Text(
                    'admin_role_desc'.tr,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
                  ),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    _promptPinDialog(context, AdminRole.admin, isDark);
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  void _promptPinDialog(BuildContext context, AdminRole targetRole, bool isDark) {
    final pinController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (pinCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: targetRole.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Icon(Icons.lock_outline_rounded, color: targetRole.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'enter_passcode_title'.tr,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'enter_passcode_prompt'.tr.replaceAll('{role}', targetRole.labelKey.tr),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: pinController,
                  obscureText: obscure,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'passcode_hint'.tr,
                    prefixIcon: Icon(Icons.password_rounded, color: targetRole.color, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _submitPin(context, pinCtx, targetRole, pinController.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(pinCtx).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: targetRole.color,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _submitPin(context, pinCtx, targetRole, pinController.text),
              child: Text('unlock_elevate'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _submitPin(BuildContext context, BuildContext pinCtx, AdminRole targetRole, String pin) {
    final cubit = context.read<AuthRoleCubit>();
    final success = cubit.elevateRole(targetRole, pin);

    if (success) {
      Navigator.of(pinCtx).pop();
      HelperFun.successSnackbar(
        'role_elevated_success'.tr.replaceAll('{role}', targetRole.labelKey.tr),
        'app_name'.tr,
      );
    } else {
      HelperFun.errorSnackbar(
        title: 'error'.tr,
        message: 'invalid_passcode'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
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
              // Mobile Menu Trigger & Logo
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: widget.onMenuPressed,
                ),
                const SizedBox(width: AppSizes.xs),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, size: 20),
                    ),
                  ),
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

              // Search Bar on Desktop (Enlarged)
              if (isDesktop && MediaQuery.sizeOf(context).width > 960 && widget.onGlobalSearch != null) ...[
                SizedBox(
                  width: MediaQuery.sizeOf(context).width > 1400
                      ? 360
                      : (MediaQuery.sizeOf(context).width > 1200 ? 300 : 250),
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onGlobalSearch,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'search'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
              ],


              // Notifications Bell
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
              const SizedBox(width: 4),

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
              const SizedBox(width: AppSizes.sm),

              // Interactive Active Role / User Profile Pill
              InkWell(
                onTap: () => _showRoleSecurityDialog(context, authState, isDark),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 5),
                  decoration: BoxDecoration(
                    color: authState.activeRole.color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: authState.activeRole.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: authState.activeRole.color,
                        child: Icon(authState.activeRole.icon, size: 14, color: Colors.white),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: AppSizes.sm),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authState.activeRole.labelKey.tr,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: authState.activeRole.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  authState.isElevated ? Icons.lock_open_rounded : Icons.lock_rounded,
                                  size: 11,
                                  color: authState.activeRole.color,
                                ),
                              ],
                            ),
                            Text(
                              authState.activeAdminEmail,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: authState.activeRole.color,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
