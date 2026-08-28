# 🎨 UI Design System & Material 3 Tokens

## 1. Design Tokens & Color System (`AppColor`)

EGO Store employs a curated, unified design palette supporting high-contrast Dark Mode and crisp Light Mode with harmonious surface tokens.

### A. Primary & Accent Tokens
- **Primary Brand**: `#4B68FF` (Deep Royal Blue)
- **Secondary**: `#FFE24B` (Vibrant Sun Yellow)
- **Accent**: `#B0C7FF` (Soft Sky Blue)

### B. Adaptive Surface & Card Tokens
| Surface Token | Dark Mode (`dark = true`) | Light Mode (`dark = false`) |
|---|---|---|
| **Card Background** | `0xFF141417` | `0xFFFFFFFF` |
| **Surface Background** | `0xFF1A1A1A` | `0xFFF7F7FA` |
| **Sub-Card / Nested Card**| `0xFF1C1C22` | `0xFFF9FAFB` |
| **Chip Background** | `0xFF222228` | `0xFFF3F4F6` |
| **Dialog Background** | `0xFF16161A` | `0xFFFFFFFF` |
| **Drag Handle** | `0xFF3F3F46` | `0xFFD1D5DB` |
| **Border Outline** | `0x14FFFFFF` (8% White) | `0x14000000` (8% Black) |

### C. Order Status Semantic Tokens
- **Pending**: `#F97316` (Warm Orange)
- **Processing**: `#A855F7` (Royal Purple)
- **Shipped**: `#3B82F6` (Electric Blue)
- **Out for Delivery**: `#F59E0B` (Amber)
- **Delivered**: `#10B981` (Emerald Green)
- **Cancelled**: `#EF4444` (Crimson Red)

---

## 2. Spacing & Radius Tokens (`AppSizes`)

```dart
abstract class AppSizes {
  // Padding and Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Spacing Between Elements
  static const double defaultSpace = 24.0;
  static const double spaceBtwItems = 16.0;
  static const double spaceBtwSections = 32.0;

  // Border Radius
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;
  static const double cardRadiusLg = 16.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusSm = 10.0;
}
```

---

## 3. Typography & Fonts

1. **Primary Body & Headings**: `Urbanist` (Modern Geometric Sans-Serif) with weights `w400` (Regular), `w600` (SemiBold), `w700` (Bold), and `w800` (ExtraBold).
2. **Branded Elements & Accents**: `Poppins` font family configured in `pubspec.yaml`.

---

## 4. Modal Bottom Sheet Standards (`UnifiedBottomSheet`)
All interactive modal bottom sheets across the application (Addresses, Contact Us, Help Center, FAQs, Filter Sheets) use the standardized `UnifiedBottomSheet.show` presentation:
- Smooth slide-up transition (`SlideTransition` on mobile, `ScaleTransition` on desktop).
- Sticky pinned header containing title, icon, trailing action, and close button.
- Smooth native vertical drag-down-to-dismiss gesture.
- Keyboard bottom-inset adaptation for active form fields.
