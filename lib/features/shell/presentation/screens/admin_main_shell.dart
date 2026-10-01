import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/app_bar/admin_top_bar.dart';
import '../../../../common/widgets/sidebar/admin_sidebar.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_bloc.dart';
import '../../../accounting/presentation/screens/accounting_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../banners/presentation/cubit/banner_cubit.dart';
import '../../../banners/presentation/screens/banners_screen.dart';
import '../../../brands/presentation/cubit/brand_cubit.dart';
import '../../../brands/presentation/screens/brands_screen.dart';
import '../../../coupons/presentation/cubit/coupon_cubit.dart';
import '../../../coupons/presentation/screens/coupons_screen.dart';
import '../../../customers/presentation/cubit/customer_cubit.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../damaged_stock/presentation/cubit/damaged_stock_cubit.dart';
import '../../../damaged_stock/presentation/screens/damaged_stock_screen.dart';
import '../../../employees/presentation/cubit/employee_cubit.dart';
import '../../../employees/presentation/screens/employees_screen.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import '../../../inventory_transfers/presentation/cubit/stock_transfer_cubit.dart';
import '../../../inventory_transfers/presentation/cubit/stock_transfer_state.dart';
import '../../../inventory_transfers/data/models/stock_transfer_model.dart';
import '../../../inventory_transfers/presentation/screens/inventory_transfers_screen.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../notifications/presentation/screens/broadcast_screen.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../pos/presentation/screens/pos_screen.dart';
import '../../../pos/presentation/screens/shifts_history_screen.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../roles/domain/models/admin_role.dart';
import '../../../roles/presentation/cubit/auth_role_cubit.dart';
import '../../../roles/presentation/screens/roles_management_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../suppliers/presentation/cubit/supplier_cubit.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _selectedTabIndex = 0;
  bool _isSidebarCollapsed = false;
  AdminWorkspaceMode _workspaceMode = AdminWorkspaceMode.all;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _tabTitles = [
    'dashboard',
    'pos_cashier',
    'products',
    'brands',
    'orders',
    'suppliers',
    'expenses',
    'accounting',
    'reports',
    'cashier_shifts',
    'inventory_transfers',
    'damaged_stock',
    'employees',
    'banners',
    'coupons',
    'customers',
    'notifications',
    'settings',
    'roles_permissions',
  ];

  final Map<int, AdminPermission> _tabPermissions = {
    0: AdminPermission.dashboard,
    1: AdminPermission.pos,
    2: AdminPermission.products,
    3: AdminPermission.brands,
    4: AdminPermission.orders,
    5: AdminPermission.suppliers,
    6: AdminPermission.expenses,
    7: AdminPermission.accounting,
    8: AdminPermission.reports,
    9: AdminPermission.shifts,
    10: AdminPermission.transfers,
    11: AdminPermission.damagedStock,
    12: AdminPermission.employees,
    13: AdminPermission.banners,
    14: AdminPermission.coupons,
    15: AdminPermission.customers,
    16: AdminPermission.notifications,
    17: AdminPermission.settings,
    18: AdminPermission.roles,
  };

  void _handleGlobalSearch(String query) {
    switch (_selectedTabIndex) {
      case 2:
        context.read<ProductCubit>().filterProducts(query: query);
        break;
      case 3:
        context.read<BrandCubit>().filterBrands(query);
        break;
      case 4:
        context.read<OrderCubit>().filterOrders(query: query);
        break;
      case 5:
        context.read<SupplierCubit>().filterSuppliers(query);
        break;
      case 6:
        context.read<ExpenseCubit>().filterExpenses(query: query);
        break;
      case 10:
        context.read<StockTransferCubit>().setSearchQuery(query);
        break;
      case 11:
        context.read<DamagedStockCubit>().filterDamagedStock(query: query);
        break;
      case 12:
        context.read<EmployeeCubit>().filterEmployees(query: query);
        break;
      case 13:
        context.read<BannerCubit>().filterBanners(query);
        break;
      case 14:
        context.read<CouponCubit>().filterCoupons(query);
        break;
      case 15:
        context.read<CustomerCubit>().filterCustomers(query);
        break;
      case 16:
        context.read<NotificationCubit>().filterBroadcasts(query);
        break;
      default:
        if (query.trim().isNotEmpty) {
          setState(() => _selectedTabIndex = 2);
          context.read<ProductCubit>().filterProducts(query: query);
        }
        break;
    }
  }

  int _getFirstPermittedTab(AuthRoleState authState) {
    for (int i = 0; i < _tabTitles.length; i++) {
      final perm = _tabPermissions[i];
      if (perm != null && authState.hasPermission(perm)) {
        return i;
      }
    }
    return 1; // Fallback to POS or Orders
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocBuilder<AuthRoleCubit, AuthRoleState>(
      builder: (context, authState) {
        // Ensure the active tab is permitted for the current role
        final currentPerm = _tabPermissions[_selectedTabIndex];
        final isCurrentTabAllowed = currentPerm != null && authState.hasPermission(currentPerm);

        if (!isCurrentTabAllowed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedTabIndex = _getFirstPermittedTab(authState);
              });
            }
          });
        }

        final allowedCount = _tabPermissions.values.where((p) => authState.hasPermission(p)).length;
        final bool isSingleModuleMode = allowedCount <= 1;
        final bool showDesktopSidebar = isDesktop && !isSingleModuleMode;
        final bool showMobileDrawer = !isDesktop && !isSingleModuleMode;

        return BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, localeState) {
            final screens = [
              DashboardScreen(onNavigateTab: (index) => setState(() => _selectedTabIndex = index)),
              const PosScreen(),
              const ProductsScreen(),
              const BrandsScreen(),
              const OrdersScreen(),
              const SuppliersScreen(),
              const ExpensesScreen(),
              const AccountingScreen(),
              const ReportsScreen(),
              const ShiftsHistoryScreen(),
              const InventoryTransfersScreen(),
              const DamagedStockScreen(),
              const EmployeesScreen(),
              const BannersScreen(),
              const CouponsScreen(),
              const CustomersScreen(),
              const BroadcastScreen(),
              const SettingsScreen(),
              const RolesManagementScreen(),
            ];

            return BlocBuilder<OrderCubit, OrderState>(
              builder: (context, orderState) {
                int pendingOrdersCount = 0;
                if (orderState is OrderLoaded) {
                  pendingOrdersCount = orderState.orders
                      .where((o) => o.status.toLowerCase() == 'pending')
                      .length;
                }

                return BlocBuilder<StockTransferCubit, StockTransferState>(
                  builder: (context, transferState) {
                    final pendingTransfersCount = transferState.transfers
                        .where((t) => t.status == StockTransferStatus.pending || t.status == StockTransferStatus.inTransit)
                        .length;

                    return PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, result) {
                        if (didPop) return;
                        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                          _scaffoldKey.currentState?.closeDrawer();
                        }
                      },
                      child: Scaffold(
                        key: _scaffoldKey,
                        drawer: showMobileDrawer
                            ? Drawer(
                                child: AdminSidebar(
                                  selectedIndex: _selectedTabIndex,
                                  onItemSelected: (index) {
                                    setState(() => _selectedTabIndex = index);
                                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                                      _scaffoldKey.currentState?.closeDrawer();
                                    }
                                  },
                                  isCollapsed: false,
                                  onToggleCollapse: () {},
                                  pendingOrdersCount: pendingOrdersCount,
                                  pendingTransfersCount: pendingTransfersCount,
                                  workspaceMode: _workspaceMode,
                                ),
                              )
                            : null,
                        body: Row(
                          children: [
                            if (showDesktopSidebar)
                              AdminSidebar(
                                selectedIndex: _selectedTabIndex,
                                onItemSelected: (index) => setState(() => _selectedTabIndex = index),
                                isCollapsed: _isSidebarCollapsed,
                                onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                                pendingOrdersCount: pendingOrdersCount,
                                pendingTransfersCount: pendingTransfersCount,
                                workspaceMode: _workspaceMode,
                              ),
                            Expanded(
                              child: Column(
                                children: [
                                  AdminTopBar(
                                    title: _selectedTabIndex < _tabTitles.length
                                        ? _tabTitles[_selectedTabIndex]
                                        : 'dashboard',
                                    onMenuPressed: showMobileDrawer
                                        ? () => _scaffoldKey.currentState?.openDrawer()
                                        : null,
                                    onGlobalSearch: _handleGlobalSearch,
                                    onNotificationPressed: () {
                                      setState(() => _selectedTabIndex = 4);
                                      context.read<OrderCubit>().filterOrders(status: 'Pending', query: '');
                                    },
                                    onNavigateTab: (index) => setState(() => _selectedTabIndex = index),
                                    workspaceMode: _workspaceMode,
                                    onWorkspaceModeChanged: (mode) => setState(() => _workspaceMode = mode),
                                  ),

                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: KeyedSubtree(
                                        key: ValueKey('${localeState.locale.languageCode}_$_selectedTabIndex'),
                                        child: isCurrentTabAllowed
                                            ? screens[_selectedTabIndex]
                                            : _buildAccessDeniedView(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAccessDeniedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColor.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 48, color: AppColor.error),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'access_denied_title'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'access_denied_desc'.tr,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
