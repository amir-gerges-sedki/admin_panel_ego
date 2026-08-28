# 💉 Dependency Injection Guide (`GetIt`)

## 1. Overview & Service Locator Pattern
**EGO Store** utilizes **`get_it`** as a central Service Locator (`sl`) to manage the lifecycle, instantiation, and decoupling of all repositories, datasources, system services, and state management BLoCs.

All registrations are centralized in:
[`lib/core/di/injection_container.dart`](file:///c:/projects/ecommerce_app-main/lib/core/di/injection_container.dart)

---

## 2. Injection Lifecycle Rules

### A. `registerLazySingleton<T>`
Used for **stateless repositories**, **core services**, and **global singletons** where only one instance should exist across the entire application lifecycle and is instantiated upon first request:
```dart
sl.registerLazySingleton<AuthenticationRepository>(
  AuthenticationRepository.new,
);

sl.registerLazySingleton<UserRepository>(
  () => UserRepository(authRepository: sl<AuthenticationRepository>()),
);

sl.registerLazySingleton<ProductsRepository>(
  ProductsRepository.new,
);

sl.registerLazySingleton<PushNotificationService>(
  () => PushNotificationService.instance,
);
```

### B. `registerFactory<T>`
Used for **transient BLoCs and Cubits** that should create a brand-new instance every time they are requested (e.g., within route builders or screen widgets):
```dart
sl.registerFactory<SignUpBloc>(
  () => SignUpBloc(
    authRepository: sl<AuthenticationRepository>(),
    userRepository: sl<UserRepository>(),
  ),
);

sl.registerFactory<ProductsCubit>(
  () => ProductsCubit(sl<ProductsRepository>()),
);
```

### C. `registerSingleton<T>`
Used for **eager singletons** initialized immediately at startup (e.g. `MyServices`, `SharedPreferences`, `NotificationRepository`, `SearchBloc`):
```dart
sl.registerSingleton<MyServices>(myServices);
sl.registerSingleton<SharedPreferences>(myServices.sharedPref);
```

---

## 3. Dependency Graph Resolution

When a class requires dependencies, resolve them using `sl<T>()` or shorthand `sl()`:

```
                  ┌──────────────────────┐
                  │ FirebaseFirestore /  │
                  │   FirebaseAuth       │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │ AuthenticationRepo / │
                  │     UserRepo         │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   UserBloc / AuthBloc │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  Presentation Screen │
                  └──────────────────────┘
```

---

## 4. How to Register a New Feature

When introducing a new feature (e.g. `Reviews`):
1. Register the Remote Data Source:
   ```dart
   sl.registerLazySingleton<ReviewRemoteDataSource>(() => ReviewRemoteDataSourceImpl());
   ```
2. Register the Repository:
   ```dart
   sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
   ```
3. Register the BLoC / Cubit:
   ```dart
   sl.registerFactory<ReviewCubit>(() => ReviewCubit(reviewRepository: sl()));
   ```
