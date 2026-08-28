# 🏛️ System Architecture & Engineering Principles

## 1. Architectural Philosophy
**EGO Store** strictly follows **Layered Clean Architecture** organized with a **Feature-First** packaging strategy. This guarantees separation of concerns, high maintainability, testability, and zero circular dependencies.

```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│  Screens ──► Modular Sub-Widgets ──► BLoC / Cubit       │
└───────────────────────────┬────────────────────────────┘
                            │ (Dispatches Events / Calls Methods)
                            ▼
┌────────────────────────────────────────────────────────┐
│                      DATA LAYER                        │
│  Repositories ──► Models (fromJson/toJson) ──► Sources  │
└───────────────────────────┬────────────────────────────┘
                            │ (Queries & Streams)
                            ▼
┌────────────────────────────────────────────────────────┐
│            INFRASTRUCTURE & EXTERNAL SERVICES          │
│  Firebase (Firestore / Auth / Messaging) + Device APIs │
└────────────────────────────────────────────────────────┘
```

---

## 2. Feature-First Structure

Each business domain is an independent, self-contained feature residing under `lib/features/<feature_name>/`. A feature is split into layers:

```
lib/features/<feature_name>/
├── data/
│   ├── models/            # Data transfer objects with serialization/deserialization
│   └── repositories/      # Firestore/API query operations & data mapping
├── presentation/
│   ├── bloc/              # BLoC / Cubit state management (Events & States)
│   ├── screens/           # Main screen pages & routing destinations
│   │   └── <screen>/
│   │       └── widgets/   # Small, reusable, single-responsibility sub-widgets
│   └── widgets/           # Feature-level shared UI components
```

---

## 3. The `core/` & `common/` Packages

### A. `lib/core/`
Contains global infrastructure code, third-party adapters, and framework-wide utilities that do not belong to any single feature:
- `constant/`: Application colors, assets, routes, sizes, strings.
- `di/`: Dependency injection setup (`injection_container.dart` via `GetIt`).
- `errors/`: Exception hierarchy (`Failure`, `FirebaseFailure`, `ValidationException`).
- `formatters/`: Phone formatting, currency, and date formatters.
- `helper/`: Snackbar utilities, dark mode detector, responsive sizing.
- `localization/`: Translation files (`ar.dart`, `en.dart`) and language `LocaleBloc`.
- `routing/`: Declarative GoRouter configuration (`app_router.dart`).
- `services/`: Low-level system services (Notification modular suite, Location service, Network listener).
- `theme/`: Material 3 theme definitions, typography, and `ThemeCubit`.
- `validators/`: Input validation logic (`AppValidator`).

### B. `lib/common/`
Contains reusable UI widgets used across multiple features:
- `widgets/appBar/`: Reusable custom app bar.
- `widgets/dialogs/`: Standard modal sheets (`UnifiedBottomSheet`), alert dialogs, snackbars.
- `widgets/images/`: Cached image loader, circular and rounded image avatars.
- `widgets/products/`: Global product cards, grids, and horizontal lists.
- `widgets/loaders/`: Shimmer loading skeletons and animations.

---

## 4. SOLID Principles in EGO Store

### 1. Single Responsibility Principle (SRP)
Every class has exactly one reason to change:
- *Notification System*: Rather than a monolithic 1400-line notification class, responsibilities are cleanly decoupled:
  - `FCMTokenManager`: Only handles token fetching, local caching, and Firestore synchronization.
  - `FCMBackgroundHandler`: Only executes isolated top-level background FCM messages.
  - `NotificationBadgeManager`: Only sets and increments app icon badges.
  - `LocalNotificationHelper`: Only creates channels and shows heads-up notification dialogs.
  - `InAppNotificationBanner`: Only shows floating top banners for foreground alerts.
  - `PushNotificationService`: Acts as a pure coordinator Facade.

### 2. Open/Closed Principle (OCP)
Modules are open for extension but closed for modification. For instance, payment methods and wallet providers are modeled as standalone polymorphic classes (`PaymentMethodModel`, `WalletProviderModel`), allowing new providers (like Apple Pay, Fawry) to be added without breaking existing checkout logic.

### 3. Liskov Substitution Principle (LSP)
BLoC states and events extend polymorphic base classes with `Equatable` support (`UserEvent`, `OrderEvent`, `CartEvent`), allowing seamless substitution and type-safe state transitions.

### 4. Interface Segregation Principle (ISP)
Repositories expose focused methods specific to their feature domain rather than unified monolithic data interfaces.

### 5. Dependency Inversion Principle (DIP)
High-level presentation screens do not instantiate database connections directly. They depend on injected repositories and BLoCs supplied via the `GetIt` service locator container.
