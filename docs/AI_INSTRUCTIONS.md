# 🤖 AI Agent Engineering Guidelines & Guardrails — EGO Store

This document establishes the **strict, mandatory operational constraints**, engineering rules, and architectural guidelines that **ANY AI coding assistant or software engineer** MUST strictly follow when modifying, maintaining, or extending the **EGO Store** (`master_store`) codebase.

---

## 1. 🛡️ Prime Directives & Mindset

1. **You Are a Senior Flutter Software Architect**:
   - Write robust, clean, null-safe, and self-documenting Dart code.
   - Adhere strictly to **Clean Architecture**, **Feature-First Organization**, **BLoC / Cubit State Management**, **SOLID Principles**, and **Material 3**.

2. **CRITICAL: NEVER Alter Business Logic or Backend Integrations Without Explicit Request**:
   - **DO NOT** modify, refactor, or rewrite existing repository query logic, Firebase Firestore data paths, Firebase Auth flows, or BLoC state transitions unless the user explicitly and directly asks you to change that specific business logic.
   - **DO NOT** replace real Firebase backend calls with mock or dummy data.
   - **DO NOT** alter payment handling (COD, Cards, Mobile Wallets) or price/discount calculations without explicit authorization.

3. **CRITICAL: NEVER Modify UI Aesthetics or Theme Tokens Without Permission**:
   - Preserve existing layouts, animations, widget aesthetics, and spacing.
   - Always use defined `AppColor.*` tokens and `HelperFun.isDarkMode(context)` for adaptive dark/light rendering. **Never hardcode random colors or raw shades of grey**.
   - Use `AppSizes.*` for consistent padding, margins, and border radius.

4. **Domain Ground Truth**:
   - The store is strictly an enterprise **Vaping & Smoking lifestyle store** (Vape Kits & Mods, E-Liquids, Salt Nicotine, Pod Systems, Replacement Coils & Pods, Disposables, and Accessories).
   - Never inject generic apparel, footwear, or non-vape domain placeholders.

---

## 2. 🏗️ Structural & Architectural Constraints

1. **Strict Feature-First Structure**:
   - Every feature must reside exclusively inside `lib/features/<feature_name>/` split into:
     - `data/` (`models/`, `repositories/`, `datasources/`)
     - `presentation/` (`bloc/`, `screens/`, `widgets/`)
   - **NEVER** re-introduce legacy monolithic folders like `lib/view/` or top-level `lib/data/`.
   - Shared components across multiple features belong in `lib/common/` or `lib/core/`.

2. **Single Responsibility Principle & Sub-Widget Decomposition**:
   - Keep screen files (`*_screen.dart`) concise and focused (ideally **under 300 lines**).
   - Bottom sheets, modal dialogs, complex cards, and progress steppers must be extracted into dedicated files in a `widgets/` sub-folder within that feature.
   - Every widget must have exactly one clear reason to change.

3. **State Management Protocol**:
   - Use `flutter_bloc` exclusively (`Bloc` or `Cubit`).
   - State objects must be **immutable** and extend `Equatable`.
   - Global application-level states (Theme, Locale, User session, Cart items) are registered in `main.dart` via `MultiBlocProvider`.
   - Feature-specific workflows (Auth, Verify Email, Forget Password, Contact Us) must be scoped appropriately.
   - **NEVER** perform direct database queries inside UI `build()` methods; always dispatch events through BLoC or use injected repositories.

4. **Dependency Injection Protocol**:
   - All repositories, data sources, system services, and BLoCs must be registered in:
     [`lib/core/di/injection_container.dart`](file:///c:/projects/ecommerce_app-main/lib/core/di/injection_container.dart)
   - Use `registerLazySingleton` for stateless repositories and services.
   - Use `registerFactory` for transient BLoCs/Cubits.
   - Use `registerSingleton` for eager startup instances (`MyServices`, `SharedPreferences`).

5. **Error Handling & User Feedback**:
   - Never show raw `ScaffoldMessenger.of(context).showSnackBar`.
   - Always use the unified `HelperFun` methods:
     - `HelperFun.successnackbar(title, message, duration)`
     - `HelperFun.warningSnackbar(title: ..., message: ...)`
     - `HelperFun.errorSnackbar(title: ..., message: ...)`
   - Always verify `if (!context.mounted) return;` before using `BuildContext` across asynchronous gaps.

---

## 3. 🚦 Mandatory Verification & QA Checklist

Before completing any task or delivering code to the user, you **MUST**:
1. Run `dart analyze lib` in the terminal.
2. Ensure **0 errors**, **0 warnings**, and **0 hints**.
3. Verify that no unused imports or broken package paths exist.
4. Ensure all newly created files follow `snake_case.dart` naming and are properly registered in DI if applicable.
