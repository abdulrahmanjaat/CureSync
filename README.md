# CureSync

A production-ready Android medical application built with Flutter, designed to help patients monitor health vitals, connect with caregivers, and manage medications — all in one place.

## Features

- **Multi-Profile Manager** — Create and manage health profiles for yourself and family members
- **Medication Tracking** — Add medications with dosage, duration, and multiple daily reminders
- **Smart Alarms** — Recurring local notifications for every medication schedule
- **5-Digit Access Code** — Each patient gets a unique code to share with caregivers
- **Caregiver Connect** — Seamlessly sync updates between patients and caregivers
- **Secure Auth** — Email/password and Google Sign-In via Firebase
- **Real-time Sync** — Cloud Firestore with offline persistence
- **Role-Based UI** — Patient and Caregiver see different dashboards

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+ (Android-only) |
| State Management | Riverpod (StreamProvider, StateNotifier) |
| Navigation | GoRouter with `refreshListenable` auth guards |
| Backend | Firebase (Auth, Firestore) |
| Notifications | flutter_local_notifications + timezone |
| Secure Storage | flutter_secure_storage (AES encrypted) |
| Preferences | shared_preferences |
| Responsive UI | flutter_screenutil (375x812 design) |
| Typography | Google Fonts (Inter) |

## Architecture

Clean Architecture with feature-based organization:

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/             # Colors, strings, sizes, asset paths
│   ├── router/                # GoRouter with auth + role guards
│   ├── services/              # Notifications, secure storage, preferences
│   ├── theme/                 # Material 3 theme (Teal + Coral)
│   └── utils/                 # Validators, extensions, snackbar service
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/        # UserModel, PatientModel
│   │   │   └── repositories/  # AuthRepository (Firebase Auth + Firestore)
│   │   └── presentation/
│   │       ├── providers/     # authStateProvider, authController, roleProvider
│   │       ├── screens/       # Splash, onboarding, login, signup, role selection
│   │       └── widgets/       # Auth header illustration
│   ├── patient/
│   │   ├── data/
│   │   │   ├── models/        # MedicationModel
│   │   │   └── repositories/  # PatientRepository, MedicationRepository
│   │   └── presentation/
│   │       ├── providers/     # patientsStream, medicationsStream
│   │       ├── screens/       # Home, patient details, add medication, meds, profile
│   │       └── widgets/       # Greeting, access code card, health snapshot, patient tiles
│   └── caregiver/             # (Planned)
└── shared/
    ├── navigation/            # MainWrapper with bottom nav bar
    └── widgets/               # CustomButton, CustomTextField, CustomCard, etc.
```

## Screens

### Auth Flow
| Screen | Description |
|---|---|
| Splash | Animated logo, auto-routes based on auth state |
| Onboarding | 3-page walkthrough with code-based illustrations |
| Login Option | Hero landing with Sign Up / Login / Google |
| Login | Email + password, remember me, forgot password |
| Signup | Name, email, password, terms, Google sign-in |
| Role Selection | Circular orbit graphic — Patient / Caregiver / Family / Doctor / Pharmacy |

### Patient Dashboard
| Screen | Description |
|---|---|
| Home | 2-column grid of patient cards + "Add Family Member" |
| Patient Details | Vitals grid + active medications with alarm chips |
| Add Medication | Form + multiple time picker → schedules local notifications |
| Medications | All meds across all patients, grouped by name |
| Profile | User info, settings, sign out, delete account (danger zone) |

## Navigation

```
/                           → Splash (auto-routes)
/onboarding                 → Onboarding (3 pages)
/login-option               → Landing screen
/login                      → Login
/signup                     → Signup
/role-selection             → Role picker (circular orbit UI)
/dashboard                  → MainWrapper (bottom nav: Home | Meds | Profile)
/patient/:id                → Patient details (vitals + medications)
/patient/:id/add-med        → Add medication (form + time picker + notifications)
```

### Router Guards

```
authStateChanges() ─┐
                     ├─→ _RouterNotifier → GoRouter.refreshListenable
userDataStream() ───┘

Redirect logic:
  Not logged in             → /login-option or /onboarding
  Logged in, no role        → /role-selection
  Logged in, has role       → /dashboard
  Logged in on auth page    → /dashboard (skip)
```

## Design System

**Color Palette:**

| Role | Color | Hex |
|---|---|---|
| Primary | Teal | `#0D9488` |
| Primary Dark | Deep Teal | `#115E59` |
| Primary Light | Mint | `#5EEAD4` |
| Accent | Coral | `#FF6B6B` |
| Scaffold | Mint White | `#F0FDFA` |
| Text Primary | Slate 900 | `#0F172A` |

**Medical Status:** Critical `#EF4444` · Stable `#22C55E` · Monitoring `#F59E0B`

## Firestore Schema

```
users/{uid}
  ├── name, email, role, photoUrl, createdAt

patients/{patientId}
  ├── managerId, name, age, relation, accessCode, caregiverId, createdAt
  └── medications/{medId}
        ├── patientId, name, dosage, durationDays
        ├── reminderTimes: ["08:00", "14:00", "21:00"]
        ├── startDate, isActive
```

## Security & Persistence

| Layer | Implementation |
|---|---|
| Auth tokens | Firebase Auth SDK (internal persistence) |
| Credentials | `flutter_secure_storage` (AES / EncryptedSharedPreferences) |
| UI settings | `shared_preferences` (onboarding seen, theme) |
| Firestore | `persistenceEnabled: true`, unlimited cache |
| Notifications | `flutter_local_notifications` with `zonedSchedule` (daily recurring) |

## Getting Started

### Prerequisites

- Flutter SDK `^3.10.4`
- Android Studio / VS Code
- Firebase project with Auth + Firestore enabled

### Setup

```bash
git clone <repo-url>
cd cure_sync
flutter pub get

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure --project=curesync-ec9fc

# Run
flutter run
```

### Firebase Setup

1. Package name: `com.armatrix.curesync`
2. Enable **Email/Password** and **Google** sign-in in Firebase Console
3. Add SHA-1 and SHA-256 fingerprints for Google Sign-In
4. Create Firestore database and set security rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /patients/{patientId} {
      allow create: if request.auth != null;
      allow read, update: if request.auth != null && (
        resource.data.managerId == request.auth.uid ||
        resource.data.caregiverId == request.auth.uid
      );
      allow delete: if request.auth != null && resource.data.managerId == request.auth.uid;
    }
    match /patients/{patientId}/medications/{medId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Roadmap

- [x] Clean architecture setup
- [x] Design system (Teal + Coral theme)
- [x] Shared widget library (12 components)
- [x] Auth UI (splash, onboarding, login, signup, forgot password)
- [x] GoRouter with auth + role guards
- [x] Firebase Auth (Email/Password + Google Sign-In)
- [x] Role selection (5-node circular orbit UI)
- [x] Multi-profile patient manager (CRUD + access codes)
- [x] Medication tracking with Firestore sub-collections
- [x] Local notification alarms (recurring daily schedules)
- [x] Bottom navigation (Home / Meds / Profile)
- [x] Account management (settings, sign out, delete account)
- [x] Security (secure storage, offline persistence, navigation guards)
- [ ] Caregiver dashboard (link via access code, alerts)
- [ ] Vitals data entry and charting
- [ ] Push notifications (FCM)
- [ ] Health report export (PDF)

## License

This project is private and not published to pub.dev.
