import 'package:get_it/get_it.dart';
import '../../features/accounting/data/datasources/accounting_remote_data_source.dart';
import '../../features/accounting/data/repositories/accounting_repository.dart';
import '../../features/accounting/presentation/cubit/accounting_cubit.dart';
import '../../features/badges/data/datasources/badge_remote_data_source.dart';
import '../../features/badges/data/repositories/badge_repository.dart';
import '../../features/badges/presentation/cubit/badge_cubit.dart';
import '../../features/banners/data/datasources/banner_remote_data_source.dart';
import '../../features/banners/data/repositories/banner_repository.dart';
import '../../features/banners/presentation/cubit/banner_cubit.dart';
import '../../features/brands/data/datasources/brand_remote_data_source.dart';
import '../../features/brands/data/repositories/brand_repository.dart';
import '../../features/brands/presentation/cubit/brand_cubit.dart';
import '../../features/coupons/data/datasources/coupon_remote_data_source.dart';
import '../../features/coupons/data/repositories/coupon_repository.dart';
import '../../features/coupons/presentation/cubit/coupon_cubit.dart';
import '../../features/customers/data/datasources/customer_remote_data_source.dart';
import '../../features/customers/data/repositories/customer_repository.dart';
import '../../features/customers/presentation/cubit/customer_cubit.dart';
import '../../features/damaged_stock/data/datasources/damaged_stock_remote_data_source.dart';
import '../../features/damaged_stock/data/repositories/damaged_stock_repository.dart';
import '../../features/damaged_stock/presentation/cubit/damaged_stock_cubit.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/employees/data/datasources/employees_remote_data_source.dart';
import '../../features/employees/data/repositories/employees_repository.dart';
import '../../features/employees/presentation/cubit/employee_cubit.dart';
import '../../features/expenses/data/datasources/expense_remote_data_source.dart';
import '../../features/expenses/data/repositories/expense_repository.dart';
import '../../features/expenses/presentation/cubit/expense_cubit.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../../features/pos/data/datasources/pos_remote_data_source.dart';
import '../../features/pos/data/datasources/shift_remote_data_source.dart';
import '../../features/pos/data/repositories/pos_repository.dart';
import '../../features/pos/data/repositories/shift_repository.dart';
import '../../features/pos/presentation/cubit/pos_cubit.dart';
import '../../features/pos/presentation/cubit/shift_cubit.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/datasources/stock_movement_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/products/data/repositories/stock_movement_repository.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../../features/products/presentation/cubit/product_form_cubit.dart';
import '../../features/products/presentation/cubit/stock_movement_cubit.dart';
import '../../features/reports/data/datasources/reports_remote_data_source.dart';
import '../../features/reports/data/repositories/reports_repository.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/roles/data/datasources/roles_remote_data_source.dart';
import '../../features/roles/data/repositories/roles_repository.dart';
import '../../features/inventory_transfers/data/datasources/stock_transfer_remote_data_source.dart';
import '../../features/inventory_transfers/data/repositories/stock_transfer_repository.dart';
import '../../features/inventory_transfers/presentation/cubit/stock_transfer_cubit.dart';
import '../../features/roles/presentation/cubit/auth_role_cubit.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/suppliers/data/datasources/purchase_invoice_data_source.dart';
import '../../features/suppliers/data/datasources/supplier_payment_data_source.dart';
import '../../features/suppliers/data/datasources/supplier_remote_data_source.dart';
import '../../features/suppliers/data/repositories/purchase_invoice_repository.dart';
import '../../features/suppliers/data/repositories/supplier_payment_repository.dart';
import '../../features/suppliers/data/repositories/supplier_repository.dart';
import '../../features/suppliers/presentation/cubit/supplier_cubit.dart';
import '../../features/inventory_audit/data/datasources/inventory_audit_remote_data_source.dart';
import '../../features/inventory_audit/data/repositories/inventory_audit_repository.dart';
import '../../features/inventory_audit/presentation/cubit/inventory_audit_cubit.dart';
import '../localization/locale_bloc.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Global Bloc / Cubit Singletons
  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
  sl.registerLazySingleton<LocaleBloc>(LocaleBloc.new);

  // Data Sources
  sl.registerLazySingleton<BannerRemoteDataSource>(
      BannerRemoteDataSourceImpl.new);
  sl.registerLazySingleton<BadgeRemoteDataSource>(
      BadgeRemoteDataSourceImpl.new);
  sl.registerLazySingleton<BrandRemoteDataSource>(
      BrandRemoteDataSourceImpl.new);
  sl.registerLazySingleton<CouponRemoteDataSource>(
      CouponRemoteDataSourceImpl.new);
  sl.registerLazySingleton<CustomerRemoteDataSource>(
      CustomerRemoteDataSourceImpl.new);
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      NotificationRemoteDataSourceImpl.new);
  sl.registerLazySingleton<OrderRemoteDataSource>(
      OrderRemoteDataSourceImpl.new);
  sl.registerLazySingleton<PosRemoteDataSource>(
      PosRemoteDataSourceImpl.new);
  sl.registerLazySingleton<ShiftRemoteDataSource>(
      ShiftRemoteDataSourceImpl.new);
  sl.registerLazySingleton<StockTransferRemoteDataSource>(
      StockTransferRemoteDataSourceImpl.new);
  sl.registerLazySingleton<InventoryAuditRemoteDataSource>(
      InventoryAuditRemoteDataSourceImpl.new);
  sl.registerLazySingleton<ProductRemoteDataSource>(
      ProductRemoteDataSourceImpl.new);
  sl.registerLazySingleton<StockMovementRemoteDataSource>(
      StockMovementRemoteDataSourceImpl.new);
  sl.registerLazySingleton<SupplierRemoteDataSource>(
      SupplierRemoteDataSourceImpl.new);
  sl.registerLazySingleton<PurchaseInvoiceDataSource>(
      PurchaseInvoiceDataSourceImpl.new);
  sl.registerLazySingleton<SupplierPaymentDataSource>(
      SupplierPaymentDataSourceImpl.new);
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
      ExpenseRemoteDataSourceImpl.new);
  sl.registerLazySingleton<AccountingRemoteDataSource>(
      AccountingRemoteDataSourceImpl.new);
  sl.registerLazySingleton<ReportsRemoteDataSource>(
      ReportsRemoteDataSourceImpl.new);
  sl.registerLazySingleton<DamagedStockRemoteDataSource>(
      DamagedStockRemoteDataSourceImpl.new);
  sl.registerLazySingleton<EmployeesRemoteDataSource>(
      EmployeesRemoteDataSourceImpl.new);
  sl.registerLazySingleton<SettingsRemoteDataSource>(
      SettingsRemoteDataSourceImpl.new);
  sl.registerLazySingleton<RolesRemoteDataSource>(
      RolesRemoteDataSourceImpl.new);

  // Repositories
  sl.registerLazySingleton<BrandRepository>(
      () => BrandRepositoryImpl(remoteDataSource: sl<BrandRemoteDataSource>()));
  sl.registerLazySingleton<PosRepository>(
      () => PosRepositoryImpl(remoteDataSource: sl<PosRemoteDataSource>()));
  sl.registerLazySingleton<ShiftRepository>(
      () => ShiftRepositoryImpl(remoteDataSource: sl<ShiftRemoteDataSource>()));
  sl.registerLazySingleton<StockTransferRepository>(
      () => StockTransferRepositoryImpl(remoteDataSource: sl<StockTransferRemoteDataSource>()));
  sl.registerLazySingleton<InventoryAuditRepository>(
      () => InventoryAuditRepositoryImpl(dataSource: sl<InventoryAuditRemoteDataSource>()));
  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
            remoteDataSource: sl<ProductRemoteDataSource>(),
            brandRepository: sl<BrandRepository>(),
          ));
  sl.registerLazySingleton<StockMovementRepository>(
      () => StockMovementRepositoryImpl(
            remoteDataSource: sl<StockMovementRemoteDataSource>(),
            productRepository: sl<ProductRepository>(),
          ));
  sl.registerLazySingleton<SupplierRepository>(
      () => SupplierRepositoryImpl(remoteDataSource: sl<SupplierRemoteDataSource>()));
  sl.registerLazySingleton<PurchaseInvoiceRepository>(
      () => PurchaseInvoiceRepositoryImpl(dataSource: sl<PurchaseInvoiceDataSource>()));
  sl.registerLazySingleton<SupplierPaymentRepository>(
      () => SupplierPaymentRepositoryImpl(dataSource: sl<SupplierPaymentDataSource>()));
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(remoteDataSource: sl<ExpenseRemoteDataSource>()));
  sl.registerLazySingleton<AccountingRepository>(
      () => AccountingRepositoryImpl(remoteDataSource: sl<AccountingRemoteDataSource>()));
  sl.registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(remoteDataSource: sl<ReportsRemoteDataSource>()));
  sl.registerLazySingleton<DamagedStockRepository>(
      () => DamagedStockRepositoryImpl(
            remoteDataSource: sl<DamagedStockRemoteDataSource>(),
            productRepository: sl<ProductRepository>(),
            movementDataSource: sl<StockMovementRemoteDataSource>(),
          ));
  sl.registerLazySingleton<EmployeesRepository>(
      () => EmployeesRepositoryImpl(
            remoteDataSource: sl<EmployeesRemoteDataSource>(),
            expenseRepository: sl<ExpenseRepository>(),
          ));
  sl.registerLazySingleton<BadgeRepository>(
      () => BadgeRepositoryImpl(remoteDataSource: sl<BadgeRemoteDataSource>()));
  sl.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(remoteDataSource: sl<OrderRemoteDataSource>()));
  sl.registerLazySingleton<BannerRepository>(
      () => BannerRepositoryImpl(remoteDataSource: sl<BannerRemoteDataSource>()));
  sl.registerLazySingleton<CouponRepository>(
      () => CouponRepositoryImpl(remoteDataSource: sl<CouponRemoteDataSource>()));
  sl.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(remoteDataSource: sl<CustomerRemoteDataSource>()));
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl<NotificationRemoteDataSource>()));
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(remoteDataSource: sl<SettingsRemoteDataSource>()));
  sl.registerLazySingleton<RolesRepository>(
      () => RolesRepositoryImpl(remoteDataSource: sl<RolesRemoteDataSource>()));
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(
            orderRepository: sl<OrderRepository>(),
            customerRepository: sl<CustomerRepository>(),
            productRepository: sl<ProductRepository>(),
            supplierRepository: sl<SupplierRepository>(),
            expenseRepository: sl<ExpenseRepository>(),
            damagedStockRepository: sl<DamagedStockRepository>(),
            employeesRepository: sl<EmployeesRepository>(),
            settingsRepository: sl<SettingsRepository>(),
          ));

  // Auth & Roles State (Lazy Singleton)
  sl.registerLazySingleton<AuthRoleCubit>(() => AuthRoleCubit(sl<RolesRepository>()));

  // Feature Cubits (Lazy singletons / factories for Admin Panel Shell)
  sl.registerFactory<DashboardCubit>(() => DashboardCubit(sl<DashboardRepository>()));
  sl.registerFactory<PosCubit>(() => PosCubit(repository: sl<PosRepository>()));
  sl.registerFactory<ShiftCubit>(() => ShiftCubit(repository: sl<ShiftRepository>()));
  sl.registerFactory<StockTransferCubit>(() => StockTransferCubit(repository: sl<StockTransferRepository>()));
  sl.registerFactory<InventoryAuditCubit>(() => InventoryAuditCubit(repository: sl<InventoryAuditRepository>()));
  sl.registerFactory<ProductCubit>(() => ProductCubit(sl<ProductRepository>()));
  sl.registerFactory<ProductFormCubit>(() => ProductFormCubit(sl<ProductRepository>()));
  sl.registerFactory<StockMovementCubit>(() => StockMovementCubit(sl<StockMovementRepository>()));
  sl.registerFactory<SupplierCubit>(() => SupplierCubit(
        supplierRepository: sl<SupplierRepository>(),
        invoiceRepository: sl<PurchaseInvoiceRepository>(),
        paymentRepository: sl<SupplierPaymentRepository>(),
      ));
  sl.registerFactory<ExpenseCubit>(() => ExpenseCubit(sl<ExpenseRepository>()));
  sl.registerFactory<AccountingCubit>(() => AccountingCubit(repository: sl<AccountingRepository>()));
  sl.registerFactory<ReportsCubit>(() => ReportsCubit(repository: sl<ReportsRepository>()));
  sl.registerFactory<DamagedStockCubit>(() => DamagedStockCubit(sl<DamagedStockRepository>()));
  sl.registerFactory<EmployeeCubit>(() => EmployeeCubit(sl<EmployeesRepository>()));
  sl.registerFactory<BrandCubit>(() => BrandCubit(sl<BrandRepository>()));
  sl.registerFactory<BadgeCubit>(() => BadgeCubit(sl<BadgeRepository>()));
  sl.registerFactory<OrderCubit>(() => OrderCubit(sl<OrderRepository>()));
  sl.registerFactory<BannerCubit>(() => BannerCubit(sl<BannerRepository>()));
  sl.registerFactory<CouponCubit>(() => CouponCubit(sl<CouponRepository>()));
  sl.registerFactory<CustomerCubit>(() => CustomerCubit(sl<CustomerRepository>()));
  sl.registerFactory<NotificationCubit>(() => NotificationCubit(sl<NotificationRepository>()));
  sl.registerFactory<SettingsCubit>(() => SettingsCubit(sl<SettingsRepository>()));
}
