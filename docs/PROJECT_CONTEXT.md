# 🏢 Project Context & Scope — EGO Store

## 1. Executive Summary & Domain Vision
**EGO Store** (Package: `master_store`) is an enterprise-grade e-commerce application specialized in the **Vaping & Smoking lifestyle domain** (Vape Kits & Box Mods, E-Liquids, Salt Nicotine, Pod Systems, Replacement Coils & Pods, Disposables, and Vaping Accessories).

The application is engineered in Flutter to deliver a high-performance, aesthetically refined shopping experience across mobile (Android & iOS) and responsive desktop/web platforms, strictly adhering to **Clean Architecture** (Feature-First), **BLoC/Cubit** state management, **GetIt** dependency injection, and **Firebase Cloud Infrastructure**.

---

## 2. Target Platforms & Environment
- **Mobile**: Android (minSdkVersion 21, targetSdkVersion 34) & iOS (iOS 13+).
- **Web & Desktop**: Fully responsive layouts adaptable across Mobile (<600px), Tablet (600px - 1024px), and Desktop (>1024px) screen viewports.
- **Dart & Flutter SDK**: SDK `^3.1.5` to `<4.0.0` with full null-safety and Material 3 design tokens.

---

## 3. Core Functional Capabilities & Domain Features

### A. Catalog & Product Discovery (Vape & Smoking Specifics)
- **Specialized Taxonomy**:
  - *Hardware & Kits*: Starter Pods, Advanced Box Mods, Squonk & Mech Mods.
  - *E-Liquids & Juices*: Salt Nicotine (20mg - 50mg), Freebase E-Liquids (3mg - 18mg), Shortfills.
  - *Coils, Cartridges & Tanks*: Sub-Ohm Coils, RTA/RDA Rebuildable Atomizers, Replacement Pods.
  - *Disposables & Accessories*: High-puff Disposables, 18650/21700 Batteries, Cotton, Chargers, Drip Tips.
- **Product Variations Engine**:
  - *Nicotine Strengths*: 0mg, 3mg, 6mg, 12mg, 20mg, 30mg, 50mg.
  - *Flavors & Profiles*: Fruity, Iced / Menthol, Classic Tobacco, Dessert & Bakery, Beverages.
  - *Bottle Volumes*: 30ml, 60ml, 100ml, 120ml.
  - *Coil Resistances*: 0.15Ω, 0.2Ω, 0.4Ω, 0.6Ω, 0.8Ω, 1.0Ω, 1.2Ω.
- **Search & Brand Filtering**: Instant search across brands (e.g., *Vaporesso*, *GeekVape*, *Voopoo*, *SMOK*, *VGOD*, *Nasty Juice*, *Uwell*, *Dinner Lady*, *Rincoe*, *Oxva*).
- **Wishlist & Favorites**: Instant toggle with optimistic UI updates.

### B. Authentication & User Verification
- **Email & Password Authentication**: Full signup, login, password recovery, and email verification.
- **Social Sign-In**: Google Sign-In (`google_sign_in`) & Facebook Login (`flutter_facebook_auth`) integration.

### C. Cart & Checkout Engine
- **Cart Management**: Subtotal calculation, item quantity adjustment, and live stock validation.
- **Coupons & Promo Codes**: Percentage discounts with promo code verification.
- **Shipping Rules**: Configurable flat delivery fee (`60 EGP`) with free shipping progress threshold (`2000 EGP`).
- **Payment Processing Channels**:
  1. *Cash on Delivery (COD)*: Secure delivery order placement.
  2. *Credit / Debit Cards (Visa, MasterCard)*: Paymob/Card integration with CVV validation.
  3. *Egyptian Mobile Wallets*: Instant validation for **Vodafone Cash (010)**, **Orange Money (012)**, **Etisalat Cash (011)**, and **WE Pay (015)**.

### D. Order Fulfillment & Live Tracking
- **Order Lifecycle States**: `Pending` ➔ `Processing` ➔ `Shipped` ➔ `Delivered` (or `Cancelled`).
- **Real-Time Tracking**: Snapshot listener on Firestore triggering push notifications and local heads-up alerts upon status change.

### E. Notifications & Badging
- **FCM System**: Push token synchronization, background/foreground message handling, and order status updates.
- **App Icon Badge**: Unread notification counter via `app_badge_plus`.

### F. Personalization & Omnichannel Support
- **Address Book**: Geolocation picker with Google Maps integration + manual address entries.
- **Bilingual Experience**: Arabic (RTL) & English (LTR) language toggle without app restart.
- **Adaptive Dark Mode**: Curated dark palette (`0xFF141417`, `0xFF1A1A1A`) and light mode.
- **Customer Support**: Direct WhatsApp customer care launcher, phone dialer, and email support.

---

## 4. Current Stability & Health Status
- **Static Analysis**: `dart analyze lib` is **100% clean** (0 errors, 0 warnings, 0 hints).
- **Architecture**: Complete Feature-First modularization (all legacy `lib/view/` and `lib/data/` folders completely removed).
- **Code Quality**: SOLID & Single Responsibility separation across all services, repositories, blocs, and UI components.

---

## 5. 📌 TODOs & Items for Business Review

- [ ] **TODO: Regulatory Age Verification (18+/21+)**: Determine whether to enforce a mandatory age-gate modal at initial app launch or require birthdate validation during signup to comply with local e-cigarette sales regulations.
- [ ] **TODO: Server-Side Payment Webhook Handlers**: Confirm whether card payment processing relies entirely on client-side status returns or requires Firebase Cloud Functions to verify Paymob HMAC signatures for order finalization.
- [ ] **TODO: Health Warning Disclaimers**: Decide if a permanent statutory nicotine warning header (e.g., *"Warning: This product contains nicotine. Nicotine is an addictive chemical."*) should be displayed in the product details screen.
