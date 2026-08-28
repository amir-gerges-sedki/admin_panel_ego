# 📚 EGO Store — Architectural & Engineering Documentation Suite

Welcome to the official technical documentation for **EGO Store** (Package: `master_store`). This documentation suite serves as the single source of truth for software engineers, architects, AI agents, and product managers working on or extending the project.

---

## 📑 Table of Contents

| Document | Description | Target Audience |
|---|---|---|
| [**1. PROJECT_CONTEXT.md**](file:///c:/projects/ecommerce_app-main/docs/PROJECT_CONTEXT.md) | Business domain, technical scope, capabilities, platforms, and current stability status. | All Developers & Stakeholders |
| [**2. ARCHITECTURE.md**](file:///c:/projects/ecommerce_app-main/docs/ARCHITECTURE.md) | Layered Clean Architecture & Feature-First design patterns, SOLID principles, and data flow. | Senior Engineers & Architects |
| [**3. FOLDER_STRUCTURE.md**](file:///c:/projects/ecommerce_app-main/docs/FOLDER_STRUCTURE.md) | Comprehensive tree map of `lib/` and directory categorization rules. | Developers & AI Agents |
| [**4. FIREBASE_STRUCTURE.md**](file:///c:/projects/ecommerce_app-main/docs/FIREBASE_STRUCTURE.md) | Schema schemas, Firestore collections, Realtime DB, Storage paths, and Security rules. | Backend & Cloud Developers |
| [**5. STATE_MANAGEMENT.md**](file:///c:/projects/ecommerce_app-main/docs/STATE_MANAGEMENT.md) | BLoC / Cubit patterns, state immutability with Equatable, and global vs local scopes. | Flutter Engineers |
| [**6. DEPENDENCY_INJECTION.md**](file:///c:/projects/ecommerce_app-main/docs/DEPENDENCY_INJECTION.md) | Service locator setup using `GetIt`, lifecycle rules, and lazy singletons vs factories. | Flutter Engineers |
| [**7. UI_DESIGN_SYSTEM.md**](file:///c:/projects/ecommerce_app-main/docs/UI_DESIGN_SYSTEM.md) | Material 3 themes, color palettes, typography (`Urbanist` & `Poppins`), and responsiveness. | UI/UX & Frontend Engineers |
| [**8. CODING_GUIDELINES.md**](file:///c:/projects/ecommerce_app-main/docs/CODING_GUIDELINES.md) | Code quality standards, error handling, clean widget composition, and performance rules. | All Developers |
| [**9. NAMING_CONVENTIONS.md**](file:///c:/projects/ecommerce_app-main/docs/NAMING_CONVENTIONS.md) | Uniform naming standards for files, classes, blocs, routes, assets, and localization keys. | All Developers & Reviewers |
| [**10. AI_INSTRUCTIONS.md**](file:///c:/projects/ecommerce_app-main/docs/AI_INSTRUCTIONS.md) | Precise ground rules, constraints, and instructions for AI coding assistants. | AI Agents & Maintainers |
| [**11. ADMIN_PANEL_PLAN.md**](file:///c:/projects/ecommerce_app-main/docs/ADMIN_PANEL_PLAN.md) | Technical blueprint for the Flutter Web / Dashboard admin portal to manage the store. | Architects & Fullstack Devs |
| [**12. CHANGELOG.md**](file:///c:/projects/ecommerce_app-main/docs/CHANGELOG.md) | Chronological log of architectural migrations, refactoring milestones, and version history. | All Stakeholders |

---

## ⚡ Core Tech Stack at a Glance

```
Flutter SDK:      >= 3.1.5 < 4.0.0
Architecture:     Clean Architecture (Feature-First)
Design System:    Material 3 (Dark / Light Theme + Custom Design Tokens)
State Mgmt:       flutter_bloc (BLoC & Cubit) + Equatable
Dependency Inj:   get_it (Service Locator)
Navigation:       go_router (Declarative Routing & Deep Linking)
Backend & Cloud:  Firebase (Auth, Firestore, Cloud Messaging, Realtime DB, Storage)
Local Storage:    shared_preferences
Localization:     Bilingual (Arabic [RTL] & English [LTR])
Notifications:    firebase_messaging + flutter_local_notifications + app_badge_plus
```
