import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/app_bar/admin_top_bar.dart';
import '../../../../common/widgets/sidebar/admin_sidebar.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../banners/presentation/cubit/banner_cubit.dart';
import '../../../banners/presentation/screens/banners_screen.dart';
import '../../../categories/presentation/cubit/category_cubit.dart';
import '../../../categories/presentation/screens/categories_brands_screen.dart';
import '../../../coupons/presentation/cubit/coupon_cubit.dart';
import '../../../coupons/presentation/screens/coupons_screen.dart';
import '../../../customers/presentation/cubit/customer_cubit.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../notifications/presentation/screens/broadcast_screen.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _selectedTabIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _tabTitles = [
    'dashboard',
    'products',
    'categories',
    'orders',
    'banners',
    'coupons',
    'customers',
    'notifications',
    'settings',
  ];

  void _handleGlobalSearch(String query) {
    switch (_selectedTabIndex) {
      case 1:
        context.read<ProductCubit>().filterProducts(query: query);
        break;
      case 2:
        context.read<CategoryCubit>().filterCategories(query);
        context.read<CategoryCubit>().filterBrands(query);
        break;
      case 3:
        context.read<OrderCubit>().filterOrders(query: query);
        break;
      case 4:
        context.read<BannerCubit>().filterBanners(query);
        break;
      case 5:
        context.read<CouponCubit>().filterCoupons(query);
        break;
      case 6:
        context.read<CustomerCubit>().filterCustomers(query);
        break;
      case 7:
        context.read<NotificationCubit>().filterBroadcasts(query);
        break;
      default:
        if (query.trim().isNotEmpty) {
          setState(() => _selectedTabIndex = 1);
          context.read<ProductCubit>().filterProducts(query: query);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final screens = [
      DashboardScreen(onNavigateTab: (index) => setState(() => _selectedTabIndex = index)),
      const ProductsScreen(),
      const CategoriesBrandsScreen(),
      const OrdersScreen(),
      const BannersScreen(),
      const CouponsScreen(),
      const CustomersScreen(),
      const BroadcastScreen(),
      const SettingsScreen(),
    ];

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, orderState) {
        int pendingOrdersCount = 0;
        if (orderState is OrderLoaded) {
          pendingOrdersCount = orderState.orders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length;
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: !isDesktop
              ? Drawer(
                  child: AdminSidebar(
                    selectedIndex: _selectedTabIndex,
                    onItemSelected: (index) {
                      setState(() => _selectedTabIndex = index);
                      Navigator.of(context).pop();
                    },
                    isCollapsed: false,
                    onToggleCollapse: () {},
                    pendingOrdersCount: pendingOrdersCount,
                  ),
                )
              : null,
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  selectedIndex: _selectedTabIndex,
                  onItemSelected: (index) => setState(() => _selectedTabIndex = index),
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  pendingOrdersCount: pendingOrdersCount,
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      title: _tabTitles[_selectedTabIndex],
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      onGlobalSearch: _handleGlobalSearch,
                      onNotificationPressed: () => setState(() => _selectedTabIndex = 7),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: screens[_selectedTabIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
