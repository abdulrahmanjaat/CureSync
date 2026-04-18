import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/role_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_option_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/patient/presentation/screens/patient_details_screen.dart';
import '../../features/patient/presentation/screens/add_medication_screen.dart';
import '../../features/patient/data/models/medication_model.dart';
import '../../features/patient/presentation/screens/patient_management_screen.dart';
import '../../features/patient/presentation/screens/profile_screen.dart';
import '../../features/patient/presentation/screens/report_screen.dart';
import '../../features/notifications/presentation/screens/notification_history_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_onboarding_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_alerts_screen.dart';
import '../../features/caregiver/presentation/screens/pending_deals_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_patient_view_screen.dart';
import '../../features/caregiver/presentation/providers/caregiver_provider.dart';
import '../../features/manager/presentation/screens/manager_patient_view_screen.dart';
import '../../features/manager/presentation/screens/manager_notifications_screen.dart';
import '../../features/family/presentation/screens/family_notifications_screen.dart';
import '../../shared/navigation/main_wrapper.dart';
import '../services/preferences_service.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _authSub = ref.listen(authStateProvider, (_, _) {
      debugPrint('DEBUG ROUTER: authState changed');
      notifyListeners();
    });
    _userSub = ref.listen(currentUserDataProvider, (_, _) {
      debugPrint('DEBUG ROUTER: userData changed');
      notifyListeners();
    });
    // Re-evaluate redirect whenever the pro-caregiver's onboarding status
    // changes (e.g. profile doc is created after the stream first fires).
    _onboardingSub = ref.listen(caregiverProfileProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription _authSub;
  late final ProviderSubscription _userSub;
  late final ProviderSubscription _onboardingSub;

  @override
  void dispose() {
    _authSub.close();
    _userSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userData = ref.read(currentUserDataProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final roleStr = userData.valueOrNull?.role;
      final role = UserRoleX.fromString(roleStr);
      final currentPath = state.uri.path;

      debugPrint('DEBUG ROUTER: path=$currentPath, '
          'loggedIn=$isLoggedIn, role=$roleStr');

      // ── Splash: always allow ──
      if (currentPath == '/') return null;

      // ── Public pages ──
      const publicPaths = {
        '/onboarding',
        '/login-option',
        '/login',
        '/signup',
      };
      final isOnPublicPage = publicPaths.contains(currentPath);

      // CASE 1: Not logged in
      if (!isLoggedIn) {
        if (isOnPublicPage) return null;
        final hasSeenOnboarding = PreferencesService.hasSeenOnboarding;
        return hasSeenOnboarding ? '/login-option' : '/onboarding';
      }

      // CASE 2: Logged in but NO role assigned yet
      if (role == null) {
        if (currentPath == '/role-selection') return null;
        // Pro-caregiver onboarding is accessible before role is confirmed
        if (currentPath == '/caregiver/onboarding') return null;
        return '/role-selection';
      }

      // CASE 3: Logged in WITH role — bounce off public / role-selection
      if (isOnPublicPage || currentPath == '/role-selection') {
        return '/dashboard';
      }

      // CASE 4: Pro-caregiver onboarding guard
      if (role == UserRole.proCaregiver) {
        final profileAsync = ref.read(caregiverProfileProvider);
        // Profile not yet loaded from Firestore — hold position and wait for
        // the _RouterNotifier subscription to re-fire once it arrives.
        if (!profileAsync.hasValue) return null;
        final done = profileAsync.valueOrNull?.onboardingComplete ?? false;
        // Block dashboard until setup is complete.
        if (!done && currentPath == '/dashboard') {
          return '/caregiver/onboarding';
        }
        // Already completed — never re-enter onboarding.
        if (done && currentPath == '/caregiver/onboarding') {
          return '/dashboard';
        }
      }

      // CASE 5: Role-specific guards

      // add-med is write access — patients (own data), managers (managed
      // patient data), and pro-caregivers (assigned patients) are allowed.
      // Family role is read-only and must never write medication records.
      if (currentPath.endsWith('/add-med')) {
        if (role != UserRole.patient &&
            role != UserRole.manager &&
            role != UserRole.proCaregiver) {
          return '/dashboard';
        }
      }

      // Only Patient and Manager may access the discovery hub.
      if (currentPath == '/discovery' &&
          role != UserRole.patient &&
          role != UserRole.manager) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login-option',
        builder: (context, state) => const LoginOptionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // ── Main app shell (role-aware bottom nav) ───────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainWrapper(),
      ),

      // ── Patient routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/patient/:id',
        builder: (context, state) => PatientDetailsScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/:id/add-med',
        builder: (context, state) => AddMedicationScreen(
          patientId: state.pathParameters['id']!,
          existing: state.extra is MedicationModel
              ? state.extra as MedicationModel
              : null,
        ),
      ),
      GoRoute(
        path: '/patient/:id/report',
        builder: (context, state) => ReportScreen(
          patientId: state.pathParameters['id']!,
          patientName: state.extra is String
              ? state.extra as String
              : 'Patient',
        ),
      ),
      GoRoute(
        path: '/manage-patients',
        builder: (context, state) => const PatientManagementScreen(),
      ),

      // ── Push routes (all roles) ──────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Manager routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/manager/patient/:id',
        builder: (context, state) => ManagerPatientViewScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/manager/notifications',
        builder: (context, state) => const ManagerNotificationsScreen(),
      ),
      GoRoute(
        path: '/family/notifications',
        builder: (context, state) => const FamilyNotificationsScreen(),
      ),

      // ── Caregiver / Family shared routes ────────────────────────────────
      GoRoute(
        path: '/caregiver/onboarding',
        builder: (context, state) => const CaregiverOnboardingScreen(),
      ),
      GoRoute(
        path: '/caregiver/alerts',
        builder: (context, state) => const CaregiverAlertsScreen(),
      ),
      GoRoute(
        path: '/caregiver/deals',
        builder: (context, state) => const PendingDealsScreen(),
      ),
      GoRoute(
        path: '/caregiver/patient/:id',
        builder: (context, state) => CaregiverPatientViewScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
