import 'package:get_it/get_it.dart';
import '../../features/badges/data/repositories/badge_repository.dart';
import '../../features/badges/presentation/cubit/badge_cubit.dart';
import '../../features/banners/data/repositories/banner_repository.dart';
import '../../features/banners/presentation/cubit/banner_cubit.dart';
import '../../features/categories/data/repositories/category_repository.dart';
import '../../features/categories/presentation/cubit/category_cubit.dart';
import '../../features/coupons/data/repositories/coupon_repository.dart';
import '../../features/coupons/presentation/cubit/coupon_cubit.dart';
import '../../features/customers/data/repositories/customer_repository.dart';
import '../../features/customers/presentation/cubit/customer_cubit.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../../features/products/presentation/cubit/product_form_cubit.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../localization/locale_bloc.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Global Bloc / Cubit Singletons
  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
  sl.registerLazySingleton<LocaleBloc>(LocaleBloc.new);

  // Repositories
  sl.registerLazySingleton<DashboardRepository>(DashboardRepositoryImpl.new);
  sl.registerLazySingleton<ProductRepository>(ProductRepositoryImpl.new);
  sl.registerLazySingleton<CategoryRepository>(CategoryRepositoryImpl.new);
  sl.registerLazySingleton<BadgeRepository>(BadgeRepositoryImpl.new);
  sl.registerLazySingleton<OrderRepository>(OrderRepositoryImpl.new);
  sl.registerLazySingleton<BannerRepository>(BannerRepositoryImpl.new);
  sl.registerLazySingleton<CouponRepository>(CouponRepositoryImpl.new);
  sl.registerLazySingleton<CustomerRepository>(CustomerRepositoryImpl.new);
  sl.registerLazySingleton<NotificationRepository>(NotificationRepositoryImpl.new);
  sl.registerLazySingleton<SettingsRepository>(SettingsRepositoryImpl.new);

  // Feature Cubits (Lazy singletons / factories for Admin Panel Shell)
  sl.registerFactory<DashboardCubit>(() => DashboardCubit(sl<DashboardRepository>()));
  sl.registerFactory<ProductCubit>(() => ProductCubit(sl<ProductRepository>()));
  sl.registerFactory<ProductFormCubit>(() => ProductFormCubit(sl<ProductRepository>()));
  sl.registerFactory<CategoryCubit>(() => CategoryCubit(sl<CategoryRepository>()));
  sl.registerFactory<BadgeCubit>(() => BadgeCubit(sl<BadgeRepository>()));
  sl.registerFactory<OrderCubit>(() => OrderCubit(sl<OrderRepository>()));
  sl.registerFactory<BannerCubit>(() => BannerCubit(sl<BannerRepository>()));
  sl.registerFactory<CouponCubit>(() => CouponCubit(sl<CouponRepository>()));
  sl.registerFactory<CustomerCubit>(() => CustomerCubit(sl<CustomerRepository>()));
  sl.registerFactory<NotificationCubit>(() => NotificationCubit(sl<NotificationRepository>()));
  sl.registerFactory<SettingsCubit>(() => SettingsCubit(sl<SettingsRepository>()));
}
