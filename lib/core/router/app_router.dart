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
import '../../features/patient/presentation/screens/patient_management_screen.dart';
import '../../features/patient/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notification_history_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_onboarding_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_alerts_screen.dart';
import '../../features/caregiver/presentation/screens/pending_deals_screen.dart';
import '../../features/manager/presentation/screens/manager_patient_view_screen.dart';
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
  }

  late final ProviderSubscription _authSub;
  late final ProviderSubscription _userSub;

  @override
  void dispose() {
    _authSub.close();
    _userSub.close();
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

      // CASE 4: Role-specific guards

      // add-med is write access — only patients (own data) and managers
      // (managed patient data) are allowed. Family / pro-caregiver roles are
      // read-only observers and must never write medication records.
      if (currentPath.endsWith('/add-med')) {
        if (role != UserRole.patient && role != UserRole.manager) {
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
        builder: (context, state) => PatientDetailsScreen(
          patientId: state.pathParameters['id']!,
          readOnly: true,
        ),
      ),
    ],
  );
});
