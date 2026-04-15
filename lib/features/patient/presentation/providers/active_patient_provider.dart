import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// Tracks which patient profile the manager is currently viewing.
/// Scoped to the current authenticated user — automatically resets to null
/// whenever the user logs out or a different account signs in, preventing
/// a manager's patient selection from leaking into a patient-role session.
final activePatientIdProvider = StateProvider<String?>((ref) {
  // Declare a dependency on authState. When the auth user changes (logout /
  // account switch), Riverpod invalidates this StateProvider and re-runs this
  // initialiser, resetting the selection back to null.
  ref.watch(authStateProvider);
  return null;
});
