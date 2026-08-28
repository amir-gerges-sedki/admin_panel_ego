# 🏷️ Naming Conventions & Code Standards

Consistent naming conventions maintain predictable navigation and seamless readability across the entire codebase.

---

## 1. Files & Directories

| Entity | Convention | Example |
|---|---|---|
| **Dart Files** | `snake_case.dart` | `product_card_vertical.dart`, `checkout_summary_card.dart` |
| **Feature Directories** | `snake_case` | `personalization/`, `all_products/`, `sub_category/` |
| **Asset Files** | `snake_case` | `google.png`, `shop_logo_animation.gif`, `signup.json` |

---

## 2. Classes, Interfaces, Mixins & Enums

| Entity | Convention | Example |
|---|---|---|
| **Classes & Enums** | `PascalCase` | `UserModel`, `PaymentMethodModel`, `OrderRepository` |
| **Screens** | `<Name>Screen` | `HomeScreen`, `ShopScreen`, `SettingScreen` |
| **BLoCs** | `<Feature>Bloc` | `CartBloc`, `ProductBloc`, `AuthBloc` |
| **Cubits** | `<Feature>Cubit` | `ThemeCubit`, `ContactCubit` |
| **Repositories** | `<Feature>Repository` | `UserRepository`, `ProductRepository` |
| **Data Models** | `<Feature>Model` | `CartItemModel`, `OrderModel`, `BrandModel` |

---

## 3. BLoC Events & States

### A. Events
Events must be named clearly as past actions or direct commands in `PascalCase`:
```dart
// Commands / Actions
abstract class CartEvent extends Equatable {
  const CartEvent();
}

class AddToCart extends CartEvent {
  final CartItemModel item;
  const AddToCart(this.item);
  @override
  List<Object?> get props => [item];
}

class RemoveFromCart extends CartEvent {
  final String cartItemId;
  const RemoveFromCart(this.cartItemId);
  @override
  List<Object?> get props => [cartItemId];
}

class ClearCart extends CartEvent {}
```

### B. States
States must clearly reflect the lifecycle status: `<Feature><Initial | Loading | Loaded | Error | ActionDone>`:
```dart
abstract class ProductState extends Equatable {
  const ProductState();
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  const ProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}
```

---

## 4. Routes & Constants

### A. Routes (`AppRoute`)
Route constants are static properties in `camelCase` pointing to URL route paths:
```dart
class AppRoute {
  static const String splash = '/';
  static const String onBoarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String shop = '/shop';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetails = '/orderDetails';
  static const String notifications = '/notifications';
  static const String setting = '/setting';
  static const String privacy = '/privacy';
}
```

---

## 5. Localization Translation Keys
All localization strings use `snake_case` as the dictionary key and are resolved using the `.tr` extension:
```dart
// ✅ Correct
Text('welcome_back'.tr)
Text('edit_profile'.tr)
Text('order_history'.tr)

// ❌ Incorrect
Text('WelcomeBack'.tr)
Text('editProfile'.tr)
```
