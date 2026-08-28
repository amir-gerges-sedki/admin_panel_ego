# 📂 Project Folder Structure & Directory Map

## 1. Directory Tree Overview

```
lib/
├── app.dart                                # Root MaterialApp.router with MultiBlocProvider & Themes
├── main.dart                               # App entry point, Firebase init & DI bootstrap
│
├── common/                                 # Shared Reusable UI Components
│   └── widgets/
│       ├── appBar/                         # Custom app bars & responsive headers
│       ├── dialogs/                        # Unified bottom sheets & alert popups
│       ├── images/                         # Network image cache & circular avatars
│       ├── layouts/                        # Responsive grid & list layouts
│       ├── loaders/                        # Shimmer skeletons & loading spinners
│       ├── products/                       # Generic product cards & tiles
│       └── text/                           # Section headings & price texts
│
├── core/                                   # Global Infrastructure & Framework Code
│   ├── constant/                           # Constants (AppColor, AppAsset, AppRoute, AppSizes)
│   ├── di/                                 # Service locator setup (injection_container.dart)
│   ├── errors/                             # Failure definitions & exception handlers
│   ├── formatters/                         # Phone number, currency, & date formatting
│   ├── helper/                             # Helper utilities, snackbars, & dark mode detector
│   ├── localization/                       # Translations (ar.dart, en.dart) & LocaleBloc
│   ├── routing/                            # GoRouter routing tree & page transitions
│   ├── services/                           # Low-level system services
│   │   ├── notifications/                  # FCM tokens, badges, local alerts, & banner suite
│   │   ├── location_service.dart           # Geolocator & GPS coordinates resolver
│   │   └── network_service.dart            # Connectivity & internet checker
│   ├── theme/                              # Material 3 theme definitions & ThemeCubit
│   └── validators/                         # Input validation logic (AppValidator)
│
└── features/                               # Business Domain Features (Feature-First)
    ├── auth/                               # Authentication Feature
    │   ├── data/
    │   │   ├── models/                     # Auth payload & credentials models
    │   │   └── repositories/               # AuthenticationRepository (Firebase Auth & Social Sign-In)
    │   └── presentation/
    │       ├── bloc/                       # Login & Register Blocs / States / Events
    │       ├── screens/                    # Login, Signup, VerifyEmail, ForgetPassword, ResetPassword
    │       └── widgets/                    # Social login buttons & auth headers
    │
    ├── personalization/                    # User Profile, Addresses, Settings & Privacy
    │   ├── data/
    │   │   ├── models/                     # UserModel, AddressModel, ContactInfoModel
    │   │   └── repositories/               # UserRepository, AddressRepository, ContactRepository
    │   └── presentation/
    │       ├── bloc/                       # UserBloc, AddressBloc, ContactCubit
    │       └── screens/
    │           ├── address/                # Address list & Add/Edit address screen
    │           ├── privacy/                # AccountPrivacyScreen & privacy/widgets/
    │           ├── profile/                # EditProfileScreen & avatar selector
    │           └── setting/                # SettingScreen & setting/widgets/
    │
    ├── shop/                               # Store, Products, Categories, Brands & Search
    │   ├── data/
    │   │   ├── models/                     # ProductModel, CategoryModel, BrandModel, BannerModel
    │   │   └── repositories/               # ProductRepository, CategoryRepository, BrandRepository
    │   └── presentation/
    │       ├── bloc/                       # ProductBloc, CategoryBloc, BrandBloc, SearchBloc
    │       └── screens/
    │           ├── all_products/           # All products grid screen
    │           ├── bottom_nav_bar/         # Responsive navigation shell & drawer
    │           ├── brand/                  # Brand showcase & brand products
    │           ├── home/                   # Home screen with search, categories, banners & grid
    │           ├── product_details/        # Product details, image gallery, & variations
    │           ├── store/                  # Shop / Category tabs & brand grid
    │           └── sub_category/           # Subcategory filtering screen
    │
    ├── cart/                               # Cart & Checkout System
    │   ├── data/
    │   │   ├── models/                     # CartItemModel, CartModel
    │   │   └── repositories/               # CartRepository (Local & Firestore sync)
    │   └── presentation/
    │       ├── bloc/                       # CartBloc, CartEvents, CartStates
    │       └── screens/
    │           ├── cart/                   # Cart screen & quantity modifiers
    │           └── checkout/               # CheckoutScreen & checkout/Widgets/
    │
    ├── orders/                             # Orders & Real-time Tracking
    │   ├── data/
    │   │   ├── models/                     # OrderModel, OrderItemModel
    │   │   └── repositories/               # OrderRepository
    │   └── presentation/
    │       ├── bloc/                       # OrderBloc, OrderEvents, OrderStates
    │       └── screens/
    │           ├── order_details/          # Order invoice, item list, & shipping breakdown
    │           └── orders/                 # User orders list with status filters
    │
    ├── notifications/                      # In-App Notification Center & Streams
    │   ├── data/
    │   │   ├── models/                     # NotificationModel
    │   │   └── repositories/               # NotificationRepository
    │   └── presentation/
    │       ├── bloc/                       # NotificationBloc, NotificationEvents, NotificationStates
    │       └── screens/
    │           └── notification/           # NotificationScreen & notification modal sheets
    │
    ├── wishlist/                           # Wishlist & Favourites
    │   ├── data/
    │   │   └── repositories/               # WishlistRepository
    │   └── presentation/
    │       ├── bloc/                       # WishlistBloc
    │       └── screens/
    │           └── wishlist/               # Wishlist grid screen
    │
    ├── coupons/                            # Coupons & Promo Codes
    │   ├── data/
    │   │   ├── models/                     # CouponModel
    │   │   └── repositories/               # CouponRepository
    │   └── presentation/
    │       └── bloc/                       # CouponBloc
    │
    └── splash/                             # Animated App Splash
        └── presentation/
            └── screens/                    # SplashScreen with logo animations
```

---

## 2. Directory Separation Rules

1. **No Circular Feature Dependencies**: A feature must never directly import internal presentation widgets from another feature. Shared widgets belong in `lib/common/` or `lib/core/`.
2. **Data Model Encapsulation**: Models must have `fromJson` / `toJson` / `fromSnapshot` factory methods and `empty()` defaults.
3. **No Direct UI Database Calls**: UI widgets must communicate solely through BLoC events or injected repository abstractions.
