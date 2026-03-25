import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_option_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/dashboard_placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.path;

      // Auth screens that don't require login
      const authPaths = [
        '/',
        '/onboarding',
        '/login-option',
        '/login',
        '/signup',
      ];
      final isOnAuthPage = authPaths.contains(currentPath);

      // If logged in and on auth page, go to dashboard
      // (skip splash/onboarding/login)
      if (isLoggedIn && isOnAuthPage) {
        // Allow role-selection since user may need to pick role
        return '/dashboard';
      }

      // If not logged in and trying to access protected page
      if (!isLoggedIn && !isOnAuthPage && currentPath != '/role-selection') {
        return '/login-option';
      }

      return null; // no redirect
    },
    routes: [
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
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPlaceholderScreen(),
      ),
    ],
  );
});
