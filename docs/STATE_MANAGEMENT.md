# ⚡ State Management Architecture (BLoC & Cubit)

## 1. Overview
EGO Store uses **`flutter_bloc`** as the exclusive state management solution. State objects are strictly **immutable** and implement `Equatable` for deterministic equality comparisons and optimal UI rebuilds.

```
┌─────────────────────────────────────────────────────────────┐
│                          UI WIDGET                          │
│   context.read<Bloc>().add(Event)  /  context.watch<Bloc>() │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Dispatches Event)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         BLOC / CUBIT                        │
│   Transforms events into states via Repositories            │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Emits New State)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    BLOCBUILDER / CONSUMER                   │
│   Rebuilds widget subtree based on state changes            │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Global vs Scoped State Management

### A. Global MultiBlocProvider (in `main.dart`)
Services, sessions, cart, and core catalog data that must persist across app-wide navigation are injected at the root level:

| BLoC / Cubit | Type | Purpose |
|---|---|---|
| `ThemeCubit` | Global Cubit | Toggles light / dark / system theme modes |
| `LocaleBloc` | Global BLoC | Controls Arabic (RTL) / English (LTR) language switching |
| `UserBloc` | Global BLoC | Holds authenticated user profile and emits updates |
| `CartBloc` | Global BLoC | Maintains cart items, total counts, and checkout state |
| `FavouriteCubit` | Global Cubit | Syncs wishlist favorites optimistically |
| `ProductsCubit` | Global Cubit | Loads featured and general catalog products |
| `BannerBloc` | Global BLoC | Loads home banners and promotional slides |
| `CouponsCubit` | Global Cubit | Manages active discount promo codes |
| `AddressesBloc` | Global BLoC | Manages delivery addresses and selected shipping address |
| `BottomNavCubit` | Global Cubit | Controls bottom navigation tab index |
| `SearchBloc` | Global BLoC | Handles real-time search queries and filters |

### B. Locally Scoped BLoCs & Cubits
Transient workflows (like Login, Signup, Email Verification, Reset Password, and Contact Info) are created on-demand or scoped to their respective screen routes to avoid memory leaks.

---

## 3. Standard BLoC Implementation Blueprint

### 1. Events Definition
```dart
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final CartItemModel item;
  const AddToCart(this.item);
  @override
  List<Object?> get props => [item];
}

class LoadCartItems extends CartEvent {}
```

### 2. State Definition
```dart
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}
class CartLoading extends CartState {}
class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final double subtotal;
  final double total;

  const CartLoaded({required this.items, required this.subtotal, required this.total});

  @override
  List<Object?> get props => [items, subtotal, total];
}
class CartError extends CartState {
  final String message;
  const CartError(this.message);
  @override
  List<Object?> get props => [message];
}
```

### 3. BLoC Business Logic
```dart
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;

  CartBloc({required this.cartRepository}) : super(CartInitial()) {
    on<LoadCartItems>(_onLoadCartItems);
    on<AddToCart>(_onAddToCart);
  }

  Future<void> _onLoadCartItems(LoadCartItems event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final items = await cartRepository.getCartItems();
      final subtotal = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
      emit(CartLoaded(items: items, subtotal: subtotal, total: subtotal));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}
```

---

## 4. UI Consumption Patterns

### A. `BlocBuilder` (Pure Rendering)
Use when only rebuilding UI without side-effects:
```dart
BlocBuilder<CartBloc, CartState>(
  builder: (context, state) {
    if (state is CartLoading) return const Center(child: CircularProgressIndicator());
    if (state is CartLoaded) return CartListView(items: state.items);
    return const SizedBox.shrink();
  },
);
```

### B. `BlocListener` (Side-Effects only)
Use when triggering navigation, snackbars, or dialogs:
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) context.go(AppRoute.home);
    if (state is AuthError) HelperFun.errorSnackbar(title: 'error'.tr, message: state.message);
  },
  child: const LoginForm(),
);
```

### C. `BlocConsumer` (Both Rendering and Side-Effects)
Use when a widget requires both UI rebuilds and navigation/alerts.
