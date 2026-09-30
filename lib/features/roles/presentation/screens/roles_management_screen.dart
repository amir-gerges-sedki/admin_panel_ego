import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/cubit/customer_cubit.dart';
import '../../domain/models/admin_role.dart';
import '../cubit/auth_role_cubit.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<AdminPermission> _adminPerms;
  late Set<AdminPermission> _staffPerms;
  late TextEditingController _superAdminPasscodeCtrl;
  late TextEditingController _adminPasscodeCtrl;
  bool _defaultToStaff = true;
  bool _isSaving = false;
  String _userSearchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final state = context.read<AuthRoleCubit>().state;
    _adminPerms = Set<AdminPermission>.from(
      state.permissionsConfig.permissions[AdminRole.admin] ??
          RolePermissionsModel.defaultPermissions().permissions[AdminRole.admin]!,
    );
    _staffPerms = Set<AdminPermission>.from(
      state.permissionsConfig.permissions[AdminRole.staff] ??
          RolePermissionsModel.defaultPermissions().permissions[AdminRole.staff]!,
    );
    _superAdminPasscodeCtrl = TextEditingController(text: state.passcodesConfig.superAdminPasscode);
    _adminPasscodeCtrl = TextEditingController(text: state.passcodesConfig.adminPasscode);
    _defaultToStaff = state.passcodesConfig.defaultToStaff;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _superAdminPasscodeCtrl.dispose();
    _adminPasscodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    final cubit = context.read<AuthRoleCubit>();
    try {
      await cubit.updateRolePermissions(AdminRole.admin, _adminPerms);
      await cubit.updateRolePermissions(AdminRole.staff, _staffPerms);
      if (mounted) {
        HelperFun.successSnackbar(
          'role_assigned_success'.tr,
          'permissions_saved_desc'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFun.errorSnackbar(title: 'error'.tr, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePasscodes() async {
    final superPass = _superAdminPasscodeCtrl.text.trim();
    final adminPass = _adminPasscodeCtrl.text.trim();

    if (superPass.isEmpty || adminPass.isEmpty) {
      HelperFun.warningSnackbar(
        title: 'warning'.tr,
        message: 'passcodes_cannot_be_empty'.tr,
      );
      return;
    }

    setState(() => _isSaving = true);
    final cubit = context.read<AuthRoleCubit>();
    try {
      final newPasscodes = SecurityPasscodesModel(
        superAdminPasscode: superPass,
        adminPasscode: adminPass,
        defaultToStaff: _defaultToStaff,
      );
      await cubit.updateSecurityPasscodes(newPasscodes);
      if (mounted) {
        HelperFun.successSnackbar(
          'passcodes_saved_success'.tr,
          'security_passcodes_title'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFun.errorSnackbar(title: 'error'.tr, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefaults() {
    final defaults = RolePermissionsModel.defaultPermissions();
    setState(() {
      _adminPerms = Set<AdminPermission>.from(defaults.permissions[AdminRole.admin]!);
      _staffPerms = Set<AdminPermission>.from(defaults.permissions[AdminRole.staff]!);
    });
    HelperFun.infoSnackbar(
      title: 'info'.tr,
      message: 'permissions_reset_desc'.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: isDark ? AppColor.darkSurface : AppColor.lightSurface,
          body: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar with Role Switcher Indicator
                _buildHeader(context, authState, isDark, isDesktop),
                const SizedBox(height: AppSizes.md),

                // Tab Selector (3 Tabs)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkCard : AppColor.lightCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColor.primary,
                    indicatorWeight: 3,
                    labelColor: AppColor.primary,
                    unselectedLabelColor: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.security_rounded, size: 18),
                        text: 'permissions_matrix'.tr,
                      ),
                      Tab(
                        icon: const Icon(Icons.people_alt_rounded, size: 18),
                        text: 'team_members_roles'.tr,
                      ),
                      Tab(
                        icon: const Icon(Icons.pin_rounded, size: 18),
                        text: 'security_passcodes_tab'.tr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Permissions Matrix
                      _buildPermissionsMatrixTab(context, isDark, isDesktop),
                      // Tab 2: Team Members & Role Assignment
                      _buildTeamMembersTab(context, isDark, isDesktop),
                      // Tab 3: Security Passcodes Management
                      _buildSecurityPasscodesTab(context, isDark, isDesktop),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthRoleState authState, bool isDark, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColor.primary, size: 28),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'roles_permissions'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'roles_management_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: authState.activeRole.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: authState.activeRole.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(authState.activeRole.icon, size: 16, color: authState.activeRole.color),
                  const SizedBox(width: 6),
                  Text(
                    '${'current_active_role'.tr}: ${authState.activeRole.labelKey.tr}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: authState.activeRole.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsMatrixTab(BuildContext context, bool isDark, bool isDesktop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Explanations Banner
          Row(
            children: [
              Expanded(
                child: _buildRoleInfoBadge(
                  title: 'super_admin'.tr,
                  subtitle: 'super_admin_desc'.tr,
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildRoleInfoBadge(
                  title: 'admin_role'.tr,
                  subtitle: 'admin_role_desc'.tr,
                  icon: Icons.admin_panel_settings_rounded,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildRoleInfoBadge(
                  title: 'staff_role'.tr,
                  subtitle: 'staff_role_desc'.tr,
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Matrix Table Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkCard : AppColor.lightCard,
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.cardRadiusMd)),
                    border: Border(bottom: BorderSide(color: isDark ? AppColor.darkBorder : AppColor.lightBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'module_permission'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'super_admin'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'admin_role'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'staff_role'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Matrix Rows
                ...AdminPermission.values.map((perm) {
                  final isAdminEnabled = _adminPerms.contains(perm);
                  final isStaffEnabled = _staffPerms.contains(perm);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (isDark ? AppColor.darkBorder : AppColor.lightBorder).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Module name & icon
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(perm.icon, size: 18, color: AppColor.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  perm.labelKey.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Super Admin Column (Always Granted / Locked)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Tooltip(
                              message: 'super_admin_full_access'.tr,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 13, color: Color(0xFF8B5CF6)),
                                    SizedBox(width: 4),
                                    Text(
                                      'ALL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Admin Column (Interactive Switch)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Switch.adaptive(
                              value: isAdminEnabled,
                              activeThumbColor: const Color(0xFF3B82F6),
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    _adminPerms.add(perm);
                                  } else {
                                    _adminPerms.remove(perm);
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                        // Staff / Guest Column (Interactive Switch)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Switch.adaptive(
                              value: isStaffEnabled,
                              activeThumbColor: const Color(0xFF10B981),
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    _staffPerms.add(perm);
                                  } else {
                                    _staffPerms.remove(perm);
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: Text('reset_defaults'.tr),
                onPressed: _resetToDefaults,
              ),
              const SizedBox(width: AppSizes.md),
              ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text('save_changes'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _isSaving ? null : _savePermissions,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  Widget _buildRoleInfoBadge({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersTab(BuildContext context, bool isDark, bool isDesktop) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, custState) {
        if (custState is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<CustomerModel> customers = [];
        if (custState is CustomerLoaded) {
          customers = custState.customers;
        }

        var filtered = customers.where((c) {
          final q = _userSearchQuery.toLowerCase().trim();
          final matchesQuery = q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q);

          if (!matchesQuery) return false;

          if (_selectedRoleFilter == 'all') return true;
          if (_selectedRoleFilter == 'super_admin') return c.role == 'super_admin' || c.role == 'superadmin';
          if (_selectedRoleFilter == 'admin') return c.role == 'admin';
          if (_selectedRoleFilter == 'staff') return c.role == 'staff' || c.role == 'guest' || c.role == 'employee';
          if (_selectedRoleFilter == 'user') return c.role != 'admin' && c.role != 'super_admin' && c.role != 'staff';
          return true;
        }).toList();

        return Column(
          children: [
            // Search & Filter Header
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'search_staff_hint'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (q) => setState(() => _userSearchQuery = q),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildFilterChip('all', 'all_roles'.tr, isDark),
                    _buildFilterChip('super_admin', 'super_admin'.tr, isDark),
                    _buildFilterChip('admin', 'admin_role'.tr, isDark),
                    _buildFilterChip('staff', 'staff_role'.tr, isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Members Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkCard : AppColor.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
                  border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                ),
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'no_staff_found'.tr,
                          style: TextStyle(
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                        ),
                        itemBuilder: (context, i) {
                          final user = filtered[i];
                          final userRole = AdminRole.fromString(user.role);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: userRole.color.withValues(alpha: 0.2),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: userRole.color,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name.isNotEmpty ? user.name : 'Unknown User',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text('${user.email} • ${user.phone.isNotEmpty ? user.phone : '-'}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: userRole.color.withValues(alpha: 0.4)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AdminRole>(
                                  value: userRole,
                                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: userRole.color,
                                  ),
                                  items: AdminRole.values.map((r) {
                                    return DropdownMenuItem<AdminRole>(
                                      value: r,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(r.icon, size: 14, color: r.color),
                                          const SizedBox(width: 6),
                                          Text(r.labelKey.tr),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newRole) async {
                                    if (newRole != null && newRole != userRole) {
                                      await context.read<AuthRoleCubit>().assignUserRole(user.id, newRole);
                                      if (context.mounted) {
                                        context.read<CustomerCubit>().loadCustomers();
                                        HelperFun.successSnackbar(
                                          'role_assigned_success'.tr,
                                          '${user.name} ⬅ ${newRole.labelKey.tr}',
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedRoleFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColor.primary,
      backgroundColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (_) => setState(() => _selectedRoleFilter = key),
    );
  }

  // ── Tab 3: Security Passcodes Management ──
  Widget _buildSecurityPasscodesTab(BuildContext context, bool isDark, bool isDesktop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColor.darkCard : AppColor.lightCard,
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
              border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: const Icon(Icons.pin_rounded, color: Color(0xFF8B5CF6), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'security_passcodes_title'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'security_passcodes_subtitle'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // Super Admin PIN Field
                Text(
                  'super_admin_passcode_label'.tr,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'super_admin_passcode_desc'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _superAdminPasscodeCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'super_admin_passcode_hint'.tr,
                    prefixIcon: const Icon(Icons.verified_user_rounded, color: Color(0xFF8B5CF6), size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Admin Manager PIN Field
                Text(
                  'admin_passcode_label'.tr,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin_passcode_desc'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _adminPasscodeCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'admin_passcode_hint'.tr,
                    prefixIcon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF3B82F6), size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Default to Staff Switch
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'default_to_staff_label'.tr,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'default_to_staff_desc'.tr,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _defaultToStaff,
                        activeThumbColor: AppColor.primary,
                        onChanged: (v) => setState(() => _defaultToStaff = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Save Passcodes CTA Button
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text('save_changes'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _savePasscodes,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}
