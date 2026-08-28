import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/helper/helper_fun.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/theme_cubit.dart';
import 'features/badges/presentation/cubit/badge_cubit.dart';
import 'features/banners/presentation/cubit/banner_cubit.dart';
import 'features/categories/presentation/cubit/category_cubit.dart';
import 'features/coupons/presentation/cubit/coupon_cubit.dart';
import 'features/customers/presentation/cubit/customer_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/notifications/presentation/cubit/notification_cubit.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';
import 'features/products/presentation/cubit/product_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/shell/presentation/screens/admin_main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.init();

  // Initialize Service Locator (GetIt)
  await initDependencies();

  runApp(const EgoAdminApp());
}

class EgoAdminApp extends StatelessWidget {
  const EgoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleBloc>(create: (_) => sl<LocaleBloc>()),
        BlocProvider<DashboardCubit>(
          create: (_) => sl<DashboardCubit>()..loadDashboard(),
        ),
        BlocProvider<ProductCubit>(
          create: (_) => sl<ProductCubit>()..loadProducts(),
        ),
        BlocProvider<CategoryCubit>(
          create: (_) => sl<CategoryCubit>()..loadData(),
        ),
        BlocProvider<BadgeCubit>(create: (_) => sl<BadgeCubit>()..loadBadges()),
        BlocProvider<OrderCubit>(create: (_) => sl<OrderCubit>()..loadOrders()),
        BlocProvider<BannerCubit>(
          create: (_) => sl<BannerCubit>()..loadBanners(),
        ),
        BlocProvider<CouponCubit>(
          create: (_) => sl<CouponCubit>()..loadCoupons(),
        ),
        BlocProvider<CustomerCubit>(
          create: (_) => sl<CustomerCubit>()..loadCustomers(),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => sl<NotificationCubit>()..loadBroadcasts(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..loadSettings(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
                title: 'EGO Store Admin Panel',
                debugShowCheckedModeBanner: false,
                navigatorKey: HelperFun.navigatorKey,
                scaffoldMessengerKey: HelperFun.messengerKey,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode,
                locale: localeState.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en', ''), Locale('ar', '')],
                home: const AdminMainShell(),
              );
            },
          );
        },
      ),
    );
  }
}
