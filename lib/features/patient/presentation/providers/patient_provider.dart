import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/patient_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/role_provider.dart';
import '../../data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

/// Real-time stream of patient profiles scoped strictly to the current user.
///
/// **Patient role**: returns ONLY the user's own self-document at
/// `patients/{uid}` via a direct document read — never a query.
/// A `WHERE managerId == uid` query is unsafe for patient-role users because
/// if the same UID was ever used as a manager (e.g. during role switching or
/// development testing), that query would also return manager-created patients,
/// leaking their medication and notification data into the patient's view.
///
/// **All other roles**: uses the repository query `WHERE managerId == uid`
/// which is the correct behavior for managers, family, and pro-caregivers.
final patientsStreamProvider = StreamProvider<List<PatientModel>>((ref) {
  final user     = ref.watch(authStateProvider).valueOrNull;
  final userData = ref.watch(currentUserDataProvider).valueOrNull;
  final role     = UserRoleX.fromString(userData?.role);

  if (user == null) return Stream.value([]);

  // Patient role: read the single known-safe document directly.
  // This is O(1) and cannot accidentally return other users' records.
  if (role == UserRole.patient) {
    return FirebaseFirestore.instance
        .collection('patients')
        .doc(user.uid)
        .snapshots()
        .map((snap) =>
            snap.exists ? [PatientModel.fromFirestore(snap)] : <PatientModel>[]);
  }

  // All other roles: managerId-based query (existing behaviour).
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

/// Direct real-time stream of the patient's own document — patients/{uid}.
///
/// Unlike [patientsStreamProvider] (which runs a query filtered by managerId),
/// this reads a single known document path and is therefore faster and
/// reliable even before [selfPatientInitProvider] has finished running.
/// Returns null if the document does not yet exist.
final selfPatientDocProvider = StreamProvider.autoDispose<PatientModel?>((ref) {
  final uid = ref.watch(selfPatientIdProvider);
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? PatientModel.fromFirestore(s) : null);
});

/// Direct real-time stream of ANY patient document by ID.
///
/// Used in trackingOnly mode (manager / caregiver view) where
/// [patientsStreamProvider] returns an empty list because the query
/// filters by managerId and caregivers are not managers.
final patientDocStreamProvider =
    StreamProvider.autoDispose.family<PatientModel?, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .snapshots()
      .map((s) => s.exists ? PatientModel.fromFirestore(s) : null);
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
