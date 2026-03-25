# CureSync

A production-ready Android medical application built with Flutter, designed to help patients monitor health vitals, connect with caregivers, and manage medications — all in one place.

## Features

- **Patient Health Monitoring** — Track heart rate, blood pressure, and other vitals
- **Caregiver Connect** — Seamlessly sync updates between patients and caregivers
- **Smart Reminders** — Medication schedules, appointments, and health check-ups
- **Secure Auth** — Email/password and Google Sign-In via Firebase
- **Real-time Sync** — Cloud Firestore for instant data synchronization

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+ (Android-only) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore) |
| Code Generation | Freezed + json_serializable |
| Responsive UI | flutter_screenutil (375x812 design) |
| Typography | Google Fonts (Inter) |

## Architecture

Clean Architecture with feature-based organization:

```
lib/
├── main.dart
├── core/
│   ├── constants/          # Colors, strings, sizes, asset paths
│   ├── router/             # GoRouter configuration
│   ├── theme/              # Material 3 theme (Teal + Coral palette)
│   └── utils/              # Validators, extensions
├── features/
│   ├── auth/               # Splash, onboarding, login, signup, forgot password
│   │   ├── data/           # Repositories, data sources
│   │   ├── domain/         # Entities, use cases
│   │   └── presentation/   # Screens, widgets
│   ├── patient/            # Patient dashboard, vitals, records
│   └── caregiver/          # Caregiver dashboard, patient management
└── shared/
    └── widgets/            # CustomButton, CustomTextField, CustomCard, etc.
```

## Design System

**Color Palette:**

| Role | Color | Hex |
|---|---|---|
| Primary | Teal | `#0D9488` |
| Primary Dark | Deep Teal | `#115E59` |
| Accent | Coral | `#FF6B6B` |
| Scaffold | Mint White | `#F0FDFA` |
| Text Primary | Slate 900 | `#0F172A` |

**Medical Status Colors:**
- Critical: `#EF4444` (Red)
- Stable: `#22C55E` (Green)
- Monitoring: `#F59E0B` (Amber)

## Shared Widgets

| Widget | Description |
|---|---|
| `CustomButton` | Elevated/outlined with loading state |
| `CustomTextField` | Built-in validators (email, password, phone, name) + password toggle |
| `CustomCard` | Composable card with optional left border accent |
| `CustomAppBar` | Back button with GoRouter, action buttons |
| `CustomBottomNavBar` | Animated pill-shaped nav with optional FAB |
| `CustomBottomSheet` | Draggable modal bottom sheet |
| `LoadingOverlay` | Stack-based loading indicator |
| `StatusBadge` | Color-coded patient status pill (Critical/Stable/Monitoring) |

## Auth Flow

```
Splash (3s) → Onboarding (3 pages) → Login Option
                                        ├── Login → Home
                                        ├── Sign Up → Home
                                        └── Google Sign-In → Home
                                        └── Forgot Password (bottom sheet)
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.10.4`
- Android Studio / VS Code
- Firebase project configured

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd cure_sync

# Install dependencies
flutter pub get

# Generate Freezed/JSON models (when needed)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Firebase Configuration

1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Configure: `flutterfire configure --project=curesync-ec9fc`
3. This generates `firebase_options.dart` and `google-services.json` automatically
4. In Firebase Console, enable **Email/Password** and **Google** sign-in methods
5. Create a Firestore database in production mode

**Package name:** `com.armatrix.curesync`

### Firestore Schema

```
users/
  └── {uid}
      ├── name: string
      ├── email: string
      ├── role: "patient" | "caregiver" | null
      ├── photoUrl: string?
      └── createdAt: timestamp

patients/
  └── {patientId}
      ├── managerId: string (uid of the person who added them)
      ├── name: string
      ├── age: number
      ├── relation: string
      ├── accessCode: string (5-digit)
      ├── caregiverId: string? (null by default)
      └── createdAt: timestamp
```

### Auth Flow (Production)

```
App Launch
  ├── User logged in + has role → /dashboard
  ├── User logged in + no role → /role-selection
  └── No user → /onboarding → /login-option
                                  ├── Sign Up (email) → /role-selection → /dashboard
                                  ├── Login (email) → /dashboard
                                  └── Google Sign-In
                                        ├── New user → /role-selection → /dashboard
                                        └── Existing → /dashboard
```

### Assets

Place your assets in the `res/` directory:

```
res/
├── icons/          # SVG navigation & action icons
├── filled_icons/   # Filled icon variants
├── 3d_icons/       # 3D illustration icons
├── images/         # PNG/SVG images (logo, illustrations, google_icon.svg)
└── fonts/          # Custom font files (if any)
```

## Roadmap

- [x] Project structure & clean architecture setup
- [x] Design system (theme, colors, typography)
- [x] Shared widget library
- [x] Auth UI (splash, onboarding, login, signup, forgot password)
- [x] GoRouter navigation with auth guards
- [x] Firebase Auth (Email/Password + Google Sign-In)
- [x] Firestore schema (users + patients collections)
- [x] Riverpod auth state management (authStateChanges stream)
- [x] Role selection (Patient/Caregiver) persisted to Firestore
- [ ] Patient feature (dashboard, vitals, records)
- [ ] Caregiver feature (patient management, notifications)
- [ ] Push notifications
- [ ] Offline support

## License

This project is private and not published to pub.dev.
