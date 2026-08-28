# 🖥️ EGO Store (Vape & Smoking) — Admin Dashboard Blueprint & Implementation Plan

## 1. Vision & Architecture
The **EGO Store Admin Panel** is a specialized **Flutter Web / Desktop** dashboard sharing the exact same Cloud Firestore database, Firebase Storage buckets, and Authentication infrastructure. It is customized specifically for managing a **Vape & E-Cigarette / Smoking** business (devices, e-liquids, pods, coils, disposables, and accessories).

```
┌────────────────────────────────────────────────────────────┐
│              EGO STORE VAPE ADMIN PANEL                    │
│                  (Flutter Web / Desktop)                   │
└─────────────────────────────┬──────────────────────────────┘
                              │
               (Shared Firestore & Storage Buckets)
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│                    FIREBASE BACKEND                        │
│  Collections: /Products, /Orders, /Categories, /Users...   │
└─────────────────────────────▲──────────────────────────────┘
                              │
                              │
┌─────────────────────────────┴──────────────────────────────┐
│              EGO STORE MOBILE & WEB APP                    │
│                  (Android / iOS / Web)                     │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Core Admin Modules (Vape & Smoking Domain)

### Module 1: Dashboard Analytics & Real-Time Overview
- **Vape Business KPIs**: Total Revenue (EGP), Today's Orders, Best-Selling E-Liquids, Top Hardware Brands.
- **Low Stock Inventory Alerts**: Instant warnings for low coil packs (<10 units), trending pod kits, or expiring liquid batches.
- **Live Orders Stream**: Incoming real-time orders feed with instant sound alerts.

### Module 2: Vape Catalog & Variations Matrix Manager
- **Product Creator & Editor**:
  - Image uploader (Liquid bottles, Pod device angles, packaging) to Firebase Storage (`/Products/{id}/`).
  - Title, Arabic & English descriptions, Category & Brand selectors.
  - **Dynamic Vape Variation Matrix Generator**:
    - *For E-Liquids*: Matrix by Nicotine Strength (`20mg`, `30mg`, `50mg` or `3mg`, `6mg`, `12mg`) & Flavor / Bottle Size (`30ml`, `60ml`, `100ml`).
    - *For Hardware / Pods*: Matrix by Color (`Black`, `Gunmetal`, `Silver`, `Blue`) & Coil Resistance (`0.4Ω`, `0.6Ω`, `0.8Ω`, `1.2Ω`).
    - Individual stock counters and SKU generators per variation (e.g. `XROS4-BLK-06`).
- **Category & Sub-Category Tree**:
  - Hardware / Kits, Pod Systems, Salt Nicotine, Freebase, Replacement Coils, Disposables, Accessories.
- **Brand Showcase Manager**: Manage official vape manufacturers (*Vaporesso, GeekVape, Voopoo, SMOK, VGOD, Nasty Juice, Uwell, Dinner Lady, Rincoe*).
- **Hero Promotional Banners**: Upload promotional banners (e.g. *New SaltNic Arrivals*, *Weekend Coil Deals*).

### Module 3: Order Fulfillment & Dispatcher
- **Orders Table**: Status filters (`Pending`, `Processing`, `Shipped`, `Delivered`, `Cancelled`).
- **Order Details Drawer**: View customer delivery address, phone dialer, chosen flavor/nicotine variations, and payment method (Cash on Delivery, Visa, Vodafone Cash / Orange / Etisalat / WE).
- **Live Status Dispatcher**: Advancing an order to `Shipped` automatically updates Firestore and pushes an instant FCM delivery notification to the customer's phone.

### Module 4: Marketing, Coupons & Push Broadcasts
- **Vape Promo Code Generator**: Create flash-sale coupons (e.g. `VAPE20`, `FREESHIP2000`) with percentage discounts, minimum cart values, and expiration dates.
- **FCM Push Notification Broadcaster**: Send targeted announcements (e.g. *"New VGOD Flavors in Stock!"*) to all users or topic subscribers.

### Module 5: Customer CRM & Store Contact Setup
- **Customer Directory**: View customer profiles, lifetime order history, and saved shipping addresses.
- **Store Contact Info Editor**: Update the official WhatsApp support line, customer service phone, and email in `/ContactInfo/support`.

---

## 3. Recommended Admin Project Structure (Flutter Web)

```
admin_panel/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/
│   │   ├── router/
│   │   └── services/
│   └── features/
│       ├── auth/               # Admin Role Authentication & Guard
│       ├── dashboard/          # Analytics & KPI counters
│       ├── products/           # Vape Product CRUD & Variation Matrix
│       ├── categories/         # Vape Category & Brand manager
│       ├── orders/             # Order fulfillment & status updater
│       ├── banners/            # Banner slider uploader
│       ├── coupons/            # Promo code generator
│       └── notifications/      # FCM broadcast dispatcher
```
