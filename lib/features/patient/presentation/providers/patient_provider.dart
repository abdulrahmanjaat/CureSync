import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/patient_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

/// Real-time stream of all patient profiles for the current user
final patientsStreamProvider = StreamProvider<List<PatientModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(patientRepositoryProvider).patientsStream(user.uid);
});

// ─── Patient-role self-management ─────────────────────────────────────────────

/// The patientId for the currently signed-in user's OWN health data.
///
/// For 'patient' role users this is their UID — the document
/// patients/{uid} is the single source of truth for their personal data.
/// Synchronous: available the moment auth resolves, no stream required.
final selfPatientIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Ensures patients/{uid} exists in Firestore for 'patient' role users.
/// Run once on dashboard mount; idempotent (no-op if doc already exists).
final selfPatientInitProvider = FutureProvider.autoDispose<void>((ref) async {
  final user     = ref.watch(authStateProvider).valueOrNull;
  final userData = ref.watch(currentUserDataProvider).valueOrNull;
  if (user == null) return;
  // Only patient-role users get a self-managed document.
  // Managers create separate patient profiles for family members.
  if (userData?.role != 'patient') return;
  await ref.read(patientRepositoryProvider).ensureSelfPatient(
        uid: user.uid,
        displayName: user.displayName ?? '',
      );
});
