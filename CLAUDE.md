# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Final Year Project (FYP) called **Smart Sauda** — a smart grocery shopping system. It consists of two parts:

- `Smart_sauda1/` — Flutter mobile app (the primary codebase)
- `sketch_esp01/` — Arduino/ESP-01 firmware for a physical NFC reader hardware component
- `arduino.IDE/` — Arduino IDE files

---

## Flutter App (`Smart_sauda1/`)

### Common Commands

Run from within the `Smart_sauda1/` directory:

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze for lints
flutter analyze

# Build Android APK
flutter build apk

# Generate launcher icons (after changing assets/images/app_icon.png)
flutter pub run flutter_launcher_icons
```

### Architecture

The app follows **Clean Architecture** with the Provider pattern for state management.

**Layer structure inside `lib/`:**

```
lib/
├── main.dart              # App entry point — wires all DI manually
├── firebase_options.dart  # Auto-generated Firebase config
├── core/                  # Shared UI primitives (theme, router, colors, styles, validators, reusable widgets)
├── domain/                # Shared domain layer (entities, repository interfaces, use cases for orders/products/audits)
├── data/                  # Shared data layer (FirestoreDataSource, model implementations, repository impls)
└── features/              # Feature modules
    ├── auth/              # Full Clean Architecture slice (data/domain/presentation)
    ├── admin/             # Admin role feature
    ├── auditor/           # Auditor role feature
    └── customer/          # Customer role feature
```

Each feature under `features/` contains its own `data/`, `domain/`, and `presentation/` layers where needed. Auth is the most complete example of this pattern.

### Dependency Injection

All dependencies are wired in `main.dart` inside `MyApp.build()` — there is no DI framework. The instantiation order is: DataSources → Repositories → UseCases → Providers. `MultiProvider` at the root exposes everything to the widget tree.

### State Management

Uses `provider` package with `ChangeNotifier`:
- `AuthProvider` — auth state, current user, role enforcement
- `CheckoutProvider` — active cart session, product scanning, payment
- `AdminProvider` — admin statistics and order management
- `AuditorProvider` — cart audit stream, item verification

### Routing

Named routes via `AppRouter.generateRoute()` in `lib/core/app_router.dart`. All route name constants are defined as static strings in `AppRouter`. The login/signup routes accept a `role` argument (either `Map{'role': '...'}` or a plain `String`).

### Firebase / Firestore

- **Auth**: Firebase Authentication (email/password)
- **Database**: Cloud Firestore with these collections:
  - `users` — user profiles with `role` field (`customer`, `admin`, `auditor`)
  - `productA` / `productB` — two separate product collections, both queried simultaneously
  - `orders` — completed purchase records
  - `carts` — real-time shared cart sessions (used for customer ↔ auditor live sync)
  - `audits` — audit records

**Key architectural detail**: The `carts` collection is the live sync channel between the Customer app and the Auditor app. When a customer pairs a cart (`CheckoutProvider.startNewCartSession`), a Firestore document is created and populated with all products. The auditor listens to this document in real-time via `AuditorProvider.listenToCart`. This replaces actual NFC/hardware integration in the current simulation.

### Roles & Access Control

Three roles: `customer`, `admin`, `auditor`. Role is stored in Firestore `users/{uid}.role`. Login enforces role matching — a user trying to log in via the wrong portal is rejected. Role selection happens on `RoleSelectionScreen` before login/signup.

### Hardware Integration (Simulation State)

The NFC and QR scanning screens (`nfc_scan_screen.dart`, `qr_pairing_screen.dart`, `barcode_scan_screen.dart`, `auditor_qr_pairing_screen.dart`) are currently **simulated** — buttons trigger simulated scans instead of real hardware. The physical hardware (ESP-01 + PN532 NFC reader in `sketch_esp01/`) is a separate component that would provide real NFC tag UIDs over HTTP; the app integration for that is not yet wired.

### Key Design Decisions

- Products are split across `productA` and `productB` collections — `FirestoreDataSource.getProducts()` always fetches both in parallel with `Future.wait`.
- `flutter_screenutil` is used for responsive sizing with a base design size of 375×812.
- The `CheckoutProvider.startNewCartSession` pre-populates the Firestore cart with all products from the DB upon pairing (simulating items already in a physical smart cart).
- Barcode scan falls back to mock data if the barcode is not found in Firestore — this is intentional for testing.

---

## Arduino Firmware (`sketch_esp01/`)

`sketch_esp01.ino` runs on an Arduino connected to:
- An **Adafruit PN532** NFC module via I2C (SDA=A4, SCL=A5)
- An **ESP-01** WiFi module via SoftwareSerial (pins 2, 3)

It reads NFC tag UIDs and serves them over HTTP on port 80. The ESP-01 connects to a WiFi network (currently hardcoded SSID `iPhone`, password `12345678`) and acts as a simple HTTP server returning the UID as an HTML page.
