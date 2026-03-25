import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_option_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/patient/presentation/screens/patient_details_screen.dart';
import '../../features/patient/presentation/screens/add_medication_screen.dart';
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
      final role = userData.valueOrNull?.role;
      final currentPath = state.uri.path;

      debugPrint('DEBUG ROUTER: path=$currentPath, '
          'loggedIn=$isLoggedIn, role=$role');

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

      // CASE 2: Logged in but NO role
      if (role == null) {
        if (currentPath == '/role-selection') return null;
        return '/role-selection';
      }

      // CASE 3: Logged in WITH role
      if (isOnPublicPage || currentPath == '/role-selection') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ── Auth routes ──
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

      // ── Main app (bottom nav) ──
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainWrapper(),
      ),

      // ── Patient detail ──
      GoRoute(
        path: '/patient/:id',
        builder: (context, state) => PatientDetailsScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),

      // ── Add medication ──
      GoRoute(
        path: '/patient/:id/add-med',
        builder: (context, state) => AddMedicationScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
