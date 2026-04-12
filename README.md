# CureSync

A premium Android medical application built with Flutter — a personal health concierge for patients and professional caregivers. Track vitals, manage medications, coordinate care, and monitor assigned patients in real-time.

## Features

### Patient
- **Executive Bento Dashboard** — White bento-grid layout with adherence ring, pill timeline, vitals cards, lifestyle trackers, and SOS emergency slider
- **Multi-Patient Manager** — Create and manage health profiles for family members with unique 5-digit access codes
- **My Care Circle** — Home dashboard card showing connected caregivers with role badge and live "Connected" indicator
- **Medication Tracking** — Add medications with dosage, duration, and multiple daily reminders via Cupertino time picker
- **Smart Alarms** — Recurring local notifications scheduled per medication with `flutter_local_notifications`
- **Pill Timeline** — Visual horizontal tracker (teal = taken, coral = upcoming) for daily adherence

### Caregiver
- **Dual-Track Onboarding** — Family Caregiver (free, minimal setup) vs Pro Caregiver (bio, rates, specializations, certifications)
- **Access Code Linking** — Enter a patient's 5-digit code to instantly connect; atomic Firestore handshake updates both sides
- **Live Patient Grid** — Bento cards per assigned patient showing real-time MedStatus, heart rate, BP vitals, SOS flag
- **Quick Note** — Bottom sheet per patient to log care observations (Observation / Med Note / Vital Note / General)
- **Daily Duty List** — Chronological list of all medication times across all patients; highlights overdue and upcoming
- **Alerts Screen** — 3-tab screen: Emergency (SOS), Missed Meds, Hiring requests
- **SOS Overlay** — Full-screen pulsing red overlay + repeating `heavyImpact` haptic when any patient triggers emergency
- **Work Profile** — Hourly/daily rates (Cupertino wheel), work hours, certifications, specializations, Available-for-Hire toggle
- **Pending Deals** — Accept/reject hire requests from patient managers with atomic handshake transaction
- **PDF Health Summary** — 7-day report (meds + care logs + adherence) shared via system print/share sheet

### Shared
- **Discovery Hub** — 4-tab screen (Doctors / Caregivers / Hospitals / Pharmacy) backed by Firestore `pro_*` collections
- **Notification History** — Tabbed screen: Medication Alerts + System events
- **Secure Auth** — Email/password and Google Sign-In via Firebase with role-based routing
- **Real-time Sync** — Cloud Firestore with offline persistence and live streams throughout

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+ (Android-only) |
| State Management | Riverpod (`StreamProvider`, `StateNotifierProvider`, `Provider.family`) |
| Navigation | GoRouter with `refreshListenable` auth + role guards |
| Backend | Firebase Auth + Cloud Firestore |
| Notifications | flutter_local_notifications + timezone |
| PDF Export | pdf + printing (PdfGoogleFonts) |
| Animations | flutter_animate (cascade fadeIn + scale) |
| Secure Storage | flutter_secure_storage (AES encrypted) |
| Preferences | shared_preferences |
| Responsive UI | flutter_screenutil (375×812 design base) |
| Typography | Google Fonts (Poppins headings, Inter body) |

## Architecture

Clean Architecture with feature-based organization:

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/                 # Colors, strings, sizes, asset paths
│   ├── router/                    # GoRouter — auth + role guards + all routes
│   ├── services/
│   │   ├── notification_service   # flutter_local_notifications scheduler
│   │   ├── pdf_export_service     # 7-day health summary PDF builder
│   │   ├── secure_storage_service # AES-encrypted credential storage
│   │   └── preferences_service    # Onboarding seen, theme mode
│   ├── theme/                     # Material 3 theme (Teal + Coral)
│   └── utils/                     # Validators, extensions, snackbar service
├── features/
│   ├── auth/
│   │   ├── data/models/           # UserModel
│   │   ├── data/repositories/     # AuthRepository
│   │   └── presentation/
│   │       ├── providers/         # authState, currentUserData, authController, role
│   │       └── screens/           # Splash, onboarding, login, signup, role selection
│   ├── patient/
│   │   ├── data/models/           # MedicationModel, PatientModel
│   │   ├── data/repositories/     # PatientRepository, MedicationRepository
│   │   └── presentation/
│   │       ├── providers/         # patientsStream, resolvedActivePatientId, medicationsStream
│   │       └── screens/
│   │           ├── home_screen              # Executive Bento dashboard
│   │           ├── medications_screen       # All meds grouped by patient
│   │           ├── profile_screen           # Account, settings, sign out
│   │           ├── patients_tab_screen      # Patient list tab
│   │           ├── patient_details_screen   # Vitals + meds (readOnly flag for caregivers)
│   │           ├── add_medication_screen    # Form + Cupertino time picker
│   │           └── patient_management_screen
│   ├── caregiver/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── caregiver_profile_model  # caregiverType, bio, rates, isAvailableForHire
│   │   │   │   ├── assigned_patient_model
│   │   │   │   ├── deal_request_model       # DealStatus enum
│   │   │   │   └── care_log_model           # CareLogType enum
│   │   │   └── repositories/
│   │   │       └── caregiver_repository     # linkPatientByCode, acceptDeal, revokeAccess, SOS
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── caregiver_provider       # 13 providers incl. dailyDutyList, linkPatient, sosTrigger
│   │       └── screens/
│   │           ├── caregiver_onboarding_screen  # Dual-track: Family vs Pro setup
│   │           ├── caregiver_home_screen        # Greeting AppBar, Link Card, Grid, Duty List, SOS
│   │           ├── caregiver_alerts_screen      # Emergency | Missed Meds | Hiring tabs
│   │           ├── caregiver_work_profile_screen # Rates, hours, certs, Available toggle
│   │           └── pending_deals_screen
│   ├── discovery/
│   │   └── presentation/screens/
│   │       └── discovery_hub_screen         # 4-tab: Doctors/Caregivers/Hospitals/Pharmacy
│   └── notifications/
│       └── presentation/screens/
│           └── notification_history_screen  # Tabbed missed/upcoming/taken/system alerts
└── shared/
    ├── navigation/
    │   └── main_wrapper   # Role-aware floating nav (Patient: 4 tabs / Caregiver: 3 tabs)
    └── widgets/           # CustomButton, CustomTextField, CustomCard, etc.
```

## Screens

### Auth Flow
| Screen | Description |
|---|---|
| Splash | Animated logo, auto-routes based on auth + role state |
| Onboarding | 3-page walkthrough |
| Login Option | Animated hero with gradient background |
| Login | Email + password, remember me, forgot password |
| Signup | Name fields, Google sign-in |
| Role Selection | 5-node circular orbit (Patient/Caregiver/Family/Doctor/Pharmacy) |

### Caregiver Onboarding
| Step | Family | Pro |
|---|---|---|
| 1 — Type | Select "Family Caregiver" → instant setup | Select "Pro Caregiver" → proceed to details |
| 2 — Details | — | Bio, years of experience, Cupertino rate picker (hourly/daily), specializations |
| Save | Creates `caregivers/{uid}` doc | Creates full profile; `isAvailableForHire: true` |

### Patient Dashboard (Executive Bento)
| Screen | Description |
|---|---|
| Home | Bento grid: adherence ring, smart action card, pill timeline, lifestyle strip, vitals, SOS, My Care Circle card |
| Patient Details | Vitals grid + active medications; hides Add Med + access code when `readOnly` |
| Add Medication | Form + Cupertino time picker (Material-wrapped, haptic ticks) |
| Medications | All meds across patients, grouped with "+ Add" per patient |
| Profile | User info, settings, sign out, delete account |
| Patient Management | Family member admin cards |

### Caregiver Dashboard
| Screen | Description |
|---|---|
| Home | Greeting AppBar (bell + avatar), Link Patient card, stats row, patient bento grid, Quick Note sheets, Daily Duty List |
| Alerts | 3 tabs with live badge counts: Emergency (SOS), Missed Meds, Hiring Requests |
| Work Profile | Available-for-Hire toggle, rates pickers, work hours, specialization chips, certifications |
| Pending Deals | Accept/reject hire requests; accept triggers atomic handshake |

### Discovery Hub (4 tabs)
| Tab | Data Source |
|---|---|
| Doctors | `pro_doctors` Firestore collection |
| Caregivers | `pro_caregivers` Firestore collection |
| Hospitals | `pro_hospitals` Firestore collection |
| Pharmacy | `pro_pharmacies` Firestore collection |

### Notification History
| Tab | Content |
|---|---|
| Medication Alerts | Derived from `todayPillTimelineProvider` — missed (red), upcoming (blue), taken (green) |
| System | Static system events (welcome, data sync) |

## Navigation

```
/                             → Splash (auto-routes)
/onboarding                   → Onboarding (3 pages)
/login-option                 → Landing screen
/login                        → Login
/signup                       → Signup
/role-selection               → Role picker (circular orbit UI)
/caregiver/onboarding         → Caregiver profile setup (post role-selection)
/dashboard                    → MainWrapper (role-aware floating nav)
                                  Patient:   Home | Meds | Patients | Discover
                                  Caregiver: Home | Alerts | Profile
/patient/:id                  → Patient details (full edit for manager; readOnly for caregiver)
/patient/:id/add-med          → Add medication
/manage-patients              → Care Circle hub
/notifications                → Notification history (push route)
/profile                      → Profile / Account settings (push route)
/caregiver/alerts             → Caregiver alerts (push route)
/caregiver/deals              → Pending Deals screen
/caregiver/work-profile       → Caregiver Work Profile
/caregiver/patient/:id        → Patient details (readOnly=true)
```

### Router Guards

```
authStateChanges() ─┐
                     ├─→ _RouterNotifier → GoRouter.refreshListenable
userDataStream() ───┘

Redirect logic:
  Not logged in                        → /login-option or /onboarding
  Logged in, no role                   → /role-selection
  Logged in, no role, on /caregiver/onboarding  → allow (setup flow)
  Logged in, has role                  → /dashboard
  Logged in on auth/role page          → /dashboard (skip)
```

## Caregiver-Patient Handshake Protocol

Two ways a caregiver can link to a patient:

**Path A — Manager-initiated (via Discovery Hub / Deal Request):**
```
Manager creates deal_request → Caregiver sees it in Alerts → accepts → atomic transaction
```

**Path B — Caregiver-initiated (via Access Code):**
```
Caregiver enters 5-digit code → Firestore query finds patient → atomic transaction
```

Both paths execute the same atomic `runTransaction`:
1. Write to `caregivers/{uid}/assigned_patients/{patientId}` — `isActive: true`
2. Update `patients/{patientId}.caregiverId` = caregiver UID

### Collections Involved

| Collection | Purpose |
|---|---|
| `caregivers/{uid}` | Work profile — type, rates, availability |
| `caregivers/{uid}/deal_requests/{id}` | Pending/accepted/rejected hire requests |
| `caregivers/{uid}/assigned_patients/{id}` | Active patient roster |
| `caregivers/{uid}/care_logs/{id}` | Private caregiver notes |
| `patients/{id}` | `caregiverId` field set on link, cleared on revoke |

### Revoking Access

`revokeAccess()` runs an atomic transaction:
1. Sets `assigned_patient.isActive = false`
2. Removes `caregiverId` from the patient document

### Providers (Caregiver)

| Provider | Type | Purpose |
|---|---|---|
| `assignedPatientsProvider` | `StreamProvider` | Live list of active assigned patients |
| `patientLiveDataProvider` | `StreamProvider.family` | Live patient doc (SOS flag, vitals) |
| `assignedPatientMedsProvider` | `StreamProvider.family` | Read-only meds for a patient |
| `patientTakenKeysProvider` | `StreamProvider.family` | Today's dose log keys for overdue check |
| `patientMedStatusProvider` | `Provider.family` | `MedStatus` enum per patient |
| `sosTriggerProvider` | `Provider` | First patient with `isSosActive == true` |
| `dailyDutyListProvider` | `Provider` | Chronological `DutyItem` list across all patients |
| `linkPatientProvider` | `StateNotifierProvider` | Access code link flow with error handling |
| `totalMissedMedsProvider` | `Provider` | Count of patients with overdue status |
| `dealRequestsProvider` | `StreamProvider` | Live deal requests stream |
| `pendingDealCountProvider` | `Provider` | Pending deals badge count |
| `careLogsProvider` | `StreamProvider.family` | Care logs per patient |
| `caregiverProfileProvider` | `StreamProvider` | Own work profile |

## Multi-Patient Logic (Patient side)

`resolvedActivePatientIdProvider` resolves the active patient in priority order:

1. Explicitly selected patient via `activePatientIdProvider`
2. First patient in `patientsStreamProvider` (auto-select)
3. `null` → Add Med bento shows SnackBar + navigates to `/manage-patients`

## Role-Based Access Control

| Role | Can Do |
|---|---|
| Manager (`managerId`) | Full CRUD on patient profile + medications + dose logs |
| Caregiver (`caregiverId`) | Read + write medications + dose logs for assigned patients; read-only view in UI |
| Any authenticated user | Query patients by `accessCode` (limit 1) for linking; read `pro_*` collections |
| Admin (custom claim) | Write to `pro_hospitals` collection |

Access control enforced at both UI layer (Riverpod, `readOnly` flag) and Firestore security rules.

## Design System

**Executive Bento Style:**
- Background: `#F8FBFA` with faint teal radial gradient
- Cards: white, 20dp radius, dual soft shadows (teal tint + black)
- Status tags: `Active` (teal), `Ongoing` (amber), `Taken` (green), `Hold` (red), `Upcoming` (blue)

**Color Palette:**

| Token | Color | Hex |
|---|---|---|
| Primary | Teal | `#0D9488` |
| Primary Dark | Deep Teal | `#115E59` |
| Primary Light | Mint | `#5EEAD4` |
| Accent | Coral | `#FF6B6B` |
| Info | Cyan | `#0891B2` |
| Background | White | `#F8FBFA` |
| Text Primary | Slate 900 | `#0F172A` |
| Text Secondary | Slate 400 | `#94A3B8` |

**Typography:** Poppins (headings, numbers) + Inter (body, labels)

**Bottom Navigation:** Floating dark pill `#1A1A2E` at 95% opacity with `BackdropFilter` blur; teal active pill with label slide animation. Role-aware: 4 tabs for patients, 3 tabs for caregivers.

**Haptic System:**

| Feedback | Trigger |
|---|---|
| `lightImpact()` | Nav taps, button presses, back navigation |
| `selectionClick()` | Cupertino picker scroll ticks, chip toggles |
| `mediumImpact()` | Deal acceptance, care log save |
| `heavyImpact()` | SOS activation; repeating every 2s on SOS overlay |

## Firestore Schema

```
users/{uid}
  ├── name, email, role, photoUrl, createdAt
  └── notifications/{notifId}

patients/{patientId}
  ├── managerId, name, age, relation, accessCode, caregiverId, isSosActive, createdAt
  ├── medications/{medId}
  │     ├── patientId, name, dosage, durationDays, reminderTimes, startDate, isActive
  └── dose_logs/{logId}
        ├── medId, medName, scheduledTime, takenAt, isTaken

caregivers/{caregiverId}
  ├── uid, name, photoUrl, caregiverType (family|pro)
  ├── bio, yearsOfExperience
  ├── hourlyRate, dailyRate
  ├── certifications, specializations
  ├── workHoursStart, workHoursEnd
  ├── isVerified, isAvailableForHire, createdAt
  ├── assigned_patients/{patientId}
  │     ├── patientId, patientName, managerId, accessCode, connectedAt, isActive
  ├── deal_requests/{requestId}
  │     ├── patientId, patientName, managerId, managerName, accessCode, status, createdAt
  └── care_logs/{logId}
        ├── patientId, patientName, type (observation|medicationNote|vitalNote|general), note, createdAt

pro_caregivers/{id} / pro_doctors/{id} / pro_hospitals/{id} / pro_pharmacies/{id}
  ├── name, specialty, rating, isVerified, photoUrl, ...
```

## Security & Persistence

| Layer | Implementation |
|---|---|
| Auth tokens | Firebase Auth SDK (internal persistence) |
| Credentials | `flutter_secure_storage` (AES / EncryptedSharedPreferences) |
| UI settings | `shared_preferences` (onboarding seen, theme) |
| Firestore rules | Manager + caregiver role checks; `canAccessPatient()` helper; access code query allowance |
| Firestore | `persistenceEnabled: true`, unlimited cache |
| Notifications | `flutter_local_notifications` with `zonedSchedule` (daily recurring) |
| Haptics | `HapticFeedback` system throughout all interactions |
| Java 8 | Core library desugaring enabled for notification scheduling |

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
4. Deploy Firestore security rules: `firebase deploy --only firestore:rules`

### Firestore Rules

Deploy `firestore.rules` at the project root. Key rules:

```javascript
// Patients: manager or caregiver — plus access code query for caregiver linking
match /patients/{patientId} {
  allow read: if isAuthenticated() && (
    resource.data.managerId == request.auth.uid ||
    resource.data.caregiverId == request.auth.uid ||
    request.query.limit == 1   // access code lookup
  );
}

// Caregiver subcollections
match /caregivers/{caregiverId}/deal_requests/{requestId} {
  allow create: if isAuthenticated();
  allow read, update, delete: if isOwner(caregiverId);
}
match /caregivers/{caregiverId}/assigned_patients/{patientId} {
  allow read, write: if isOwner(caregiverId);
}
```

## Roadmap

- [x] Clean architecture setup
- [x] Design system (Teal + Coral Executive Bento theme)
- [x] Auth UI (splash, onboarding, login, signup, forgot password)
- [x] GoRouter with auth + role guards + push routes
- [x] Firebase Auth (Email/Password + Google Sign-In)
- [x] Role selection (5-node circular orbit UI with animated dot rings)
- [x] Executive Bento Dashboard (adherence ring, smart action, pill timeline, vitals, lifestyle, SOS)
- [x] Multi-patient manager with `resolvedActivePatientIdProvider`
- [x] My Care Circle card (live caregiver data lookup, role badge, info sheet)
- [x] Medication tracking with Firestore subcollections
- [x] Local notification alarms (recurring daily via Cupertino picker + Material wrapper fix)
- [x] Discovery Hub (4-tab: Doctors / Caregivers / Hospitals / Pharmacy)
- [x] Notification History Screen
- [x] Role-aware floating nav (Patient: 4 tabs / Caregiver: 3 tabs)
- [x] Haptic feedback system (light / selection / medium / heavy / repeating SOS)
- [x] Firestore security rules (role-based, subcollections, access code query)
- [x] Account management (settings, sign out, delete account)
- [x] **Caregiver Onboarding** — dual-track (Family free / Pro with rates + bio)
- [x] **Caregiver Home** — greeting AppBar, Link Patient card, bento grid, Quick Note, Daily Duty List
- [x] **Caregiver Alerts Screen** — Emergency | Missed Meds | Hiring tabs with live badge counts
- [x] **Available for Hire toggle** in Work Profile
- [x] **Access Code linking** — caregiver enters patient code → atomic Firestore handshake
- [x] **Caregiver-Patient Handshake** — dual path (access code + deal requests), atomic transactions
- [x] **Care Logs** — private per-patient observation notes
- [x] **PDF Health Summary** — 7-day report via `pdf` + `printing`
- [x] **SOS Overlay** — full-screen pulse + repeating heavyImpact haptic
- [x] PatientDetailsScreen `readOnly` mode (hides Add Med + access code for caregivers)
- [ ] Google Places API integration (Discovery Hub nearby results)
- [ ] FCM push notifications (caregiver real-time SOS + med alerts)
- [ ] Vitals data entry and historical charting
- [ ] Dark mode theme

## License

This project is private and not published to pub.dev.
