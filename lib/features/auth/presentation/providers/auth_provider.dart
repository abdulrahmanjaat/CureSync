import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'role_provider.dart';

// ─── Repository Provider ────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ─── Auth State Stream ──────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─── User Data (Firestore) ──────────────────────────────────────
final userDataProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).getUserData(uid);
});

// ─── Auth Controller ────────────────────────────────────────────
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncData(null));

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<({bool success, bool isNewUser, String? error})> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      return (success: true, isNewUser: result.isNewUser, error: null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return (success: false, isNewUser: false, error: _mapAuthError(e.code));
    }
  }

  Future<({bool success, bool isNewUser, String? error})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );
      // Check if user has a role set
      final userData = await _repo.getUserData(user.uid);
      final hasRole = userData?.role != null;
      state = const AsyncData(null);
      return (success: true, isNewUser: !hasRole, error: null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return (success: false, isNewUser: false, error: _mapAuthError(e.code));
    }
  }

  Future<({bool success, bool isNewUser, String? error})>
      signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final result = await _repo.signInWithGoogle();
      state = const AsyncData(null);
      return (success: true, isNewUser: result.isNewUser, error: null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return (success: false, isNewUser: false, error: _mapAuthError(e.code));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return (success: false, isNewUser: false, error: e.toString());
    }
  }

  Future<void> updateRole(UserRole role) async {
    final user = _repo.currentUser;
    if (user == null) return;

    final roleStr = role == UserRole.patient ? 'patient' : 'caregiver';
    await _repo.updateUserRole(user.uid, roleStr);
    _ref.read(roleProvider.notifier).selectRole(role);
  }

  Future<({bool success, String? error})> sendPasswordReset(
      String email) async {
    try {
      await _repo.sendPasswordResetEmail(email);
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _ref.read(roleProvider.notifier).clear();
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email',
      'wrong-password' => 'Incorrect password',
      'email-already-in-use' => 'An account already exists with this email',
      'invalid-email' => 'Please enter a valid email address',
      'weak-password' => 'Password must be at least 6 characters',
      'too-many-requests' => 'Too many attempts. Please try again later',
      'user-disabled' => 'This account has been disabled',
      'sign-in-cancelled' => 'Sign-in was cancelled',
      'invalid-credential' => 'Invalid email or password',
      _ => 'Something went wrong. Please try again',
    };
  }
}
