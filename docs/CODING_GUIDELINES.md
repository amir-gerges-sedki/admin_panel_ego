# 📐 Coding Guidelines & Engineering Best Practices

## 1. Core Principles & Philosophy
Every piece of code in **EGO Store** must be:
1. **Readable & Self-Documenting**: Clear naming and zero ambiguous abbreviations.
2. **Immutable by Default**: Use `final`, `const`, and `Equatable` for state objects.
3. **Single-Responsibility**: Decompose UI widgets into discrete sub-components.
4. **Resilient**: Graceful error handling with localized feedback for network or auth errors.

---

## 2. Widget Construction & Decomposition

### A. File Size & Sub-Widget Extraction Rule
- Main screen files (`*_screen.dart`) should stay concise (ideally **under 300 lines**).
- Modals, complex cards, progress steppers, and dialogs must be extracted into dedicated files in a `widgets/` folder inside the respective feature.

### B. `const` Constructors Everywhere
Always mark immutable widgets with `const` to optimize Flutter element rebuilding:
```dart
// ✅ Correct
const SizedBox(height: AppSizes.spaceBtwItems);
const Icon(Icons.shopping_bag_outlined, color: AppColor.primary, size: 24);

// ❌ Incorrect
SizedBox(height: 16);
```

### C. Resource Cleanup in State Objects
Always clean up controllers, focus nodes, animations, and subscriptions in `dispose()`:
```dart
@override
void dispose() {
  _textController.dispose();
  _focusNode.dispose();
  _animationController.dispose();
  super.dispose();
}
```

---

## 3. Error Handling & Feedback

### A. Use `HelperFun` for User Feedback
Never use raw `ScaffoldMessenger.of(context).showSnackBar` directly. Always use the unified `HelperFun` methods:
```dart
// Success Alert
HelperFun.successnackbar('success_title'.tr, 'item_added_to_cart'.tr, 2);

// Warning Alert
HelperFun.warningSnackbar(title: 'warning'.tr, message: 'please_select_size'.tr);

// Error Alert
HelperFun.errorSnackbar(title: 'error'.tr, message: state.errorMessage);
```

### B. Failures & Exceptions Hierarchy
Repositories catch exceptions and return `Either<Failure, T>` or throw typed `Failure` subclasses defined in `lib/core/errors/`:
```dart
try {
  final snapshot = await _firestore.collection('Products').get();
  return snapshot.docs.map((d) => ProductModel.fromSnapshot(d)).toList();
} on FirebaseException catch (e) {
  throw FirebaseFailure.fromCode(e.code);
} catch (e) {
  throw const UnknownFailure('An unexpected error occurred.');
}
```

---

## 4. Null-Safety & Defensive Programming

1. **Avoid Forced Unwrapping (`!`)**: Unless null-safety is mathematically guaranteed, use null-aware operators (`?.`, `??`).
```dart
// ✅ Correct
final userName = user?.userName.isNotEmpty == true ? user!.userName : 'guest'.tr;

// ❌ Incorrect
final userName = user!.userName;
```
2. **Safe Model Parsers**: When parsing Firestore data maps, protect against unexpected types (integers vs strings for phone numbers or prices):
```dart
final rawPrice = (data['price'] ?? 0.0);
final price = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0.0;
```

---

## 5. Asynchronous Operations & Context Safety
Before invoking `BuildContext` across async gaps, verify `mounted`:
```dart
// ✅ Correct
final result = await authRepo.signIn(email, password);
if (!context.mounted) return;
context.go(AppRoute.home);

// ❌ Incorrect
await authRepo.signIn(email, password);
context.go(AppRoute.home); // Unsafe context access
```
