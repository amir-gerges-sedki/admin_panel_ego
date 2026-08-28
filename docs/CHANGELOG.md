# 📜 Architectural & Engineering Changelog

All notable changes, architectural refactorings, and feature migrations for **EGO Store** are documented in this file.

---

## [1.2.0] — 2026-08-22
### 🏗️ Architecture & Single Responsibility Decomposition
- **Feature-First Migration Complete**: Fully migrated all business domains into `lib/features/{auth, personalization, shop, cart, orders, notifications, wishlist, coupons, splash}/` and removed legacy `lib/view/` and `lib/data/` directories.
- **Push Notification Modularization**: Decomposed monolithic 1331-line `push_notification_service.dart` into discrete, single-responsibility modules:
  - `notification_badge_manager.dart` (App icon badge counting via `AppBadgePlus`)
  - `fcm_background_handler.dart` (Isolated background FCM message receiver)
  - `fcm_token_manager.dart` (Token retrieval, local caching, Firestore synchronization)
  - `local_notification_helper.dart` (Local notification channels and order heads-up alerts)
  - `in_app_notification_banner.dart` (In-app foreground notification snackbars)
  - `push_notification_service.dart` (Clean Facade coordinator)
- **UI Screen Decomposition**:
  - `lib/features/cart/presentation/screens/checkout/Widgets/`:
    - Extracted `checkout_progress_stepper.dart` (4-step animated timeline)
    - Extracted `checkout_summary_card.dart` (Price totals, tax, shipping calculations)
    - Extracted `payment_method_tile.dart` (Selectable payment method card)
    - Extracted `payment_models.dart` (Payment and wallet models)
  - `lib/features/personalization/presentation/screens/setting/widgets/`:
    - Extracted `setting_user_card.dart` (User avatar & profile status)
    - Extracted `setting_contact_sheet.dart` (Contact modal sheet with dialer, WhatsApp, & email actions)
    - Extracted `setting_faqs_sheet.dart` (Expandable FAQs accordion)
    - Extracted `setting_help_sheet.dart` (App feature guide)
    - Extracted `setting_logout_dialog.dart` (Logout confirmation dialog)
  - `lib/features/personalization/presentation/screens/privacy/widgets/`:
    - Extracted `change_password_sheet.dart` (Validated password change form & reset link)
    - Extracted `delete_account_dialog.dart` (Account deletion confirmation dialog)
    - Extracted `privacy_policy_sheet.dart` (Privacy terms modal)
    - Extracted `terms_of_service_sheet.dart` (Terms of service modal)
- **Verification**: Ran `dart analyze lib` confirming **0 errors, 0 warnings, 0 hints**.

---

## [1.1.0] — 2026-08-20
### 🌟 Feature Enhancements & Performance
- Implemented responsive desktop navigation and adaptive drawer navigation.
- Integrated unified bottom sheet design standard (`UnifiedBottomSheet`) across all feature modals.
- Enhanced coupon system with real-time validation and percentage discount calculations.
- Integrated live order status snapshot listener with instant push and heads-up notifications.

---

## [1.0.0] — Initial Release
### 🚀 Core E-Commerce Launch
- Complete user authentication (Email/Password, Google OAuth, Facebook Auth).
- Product catalog, category taxonomy, brand showcase, and dynamic promotional banners.
- Full shopping cart, coupon codes, and multi-payment checkout (COD, Credit/Debit Cards, Egyptian Mobile Wallets).
- Profile management, address book with geocoding, dark/light theme toggle, and Arabic/English bilingual localization.
