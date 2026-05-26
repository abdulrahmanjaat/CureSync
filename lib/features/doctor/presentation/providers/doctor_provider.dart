import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/repositories/doctor_repository.dart';

// ── Current doctor UID ────────────────────────────────────────────────────────

final _doctorUidProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid ?? '';
});

// ── Doctor own profile stream (pro_doctors/{uid}) ─────────────────────────────
//
// Single source of truth for the signed-in doctor's work profile. The router
// listens to this to gate dashboard access until onboarding is complete.
//
// • autoDispose:  released when no live listeners remain. The router keeps it
//                 alive while a doctor is signed in; on sign-out it drops.
// • Role guard:   `uid.isEmpty` short-circuits to an empty stream so a logged
//                 -out or wrong-role user cannot trigger a Firestore read.
final doctorProfileProvider =
    StreamProvider.autoDispose<DoctorModel?>((ref) {
  final uid = ref.watch(_doctorUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('pro_doctors')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? DoctorModel.fromFirestore(doc) : null);
});

// ── Today's appointments ──────────────────────────────────────────────────────

final todayAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(_doctorUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return doctorRepository.todayAppointmentsStream(uid);
});

// ── All appointments ──────────────────────────────────────────────────────────

final allAppointmentsProvider =
    StreamProvider<List<AppointmentModel>>((ref) {
  final uid = ref.watch(_doctorUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return doctorRepository.appointmentsStream(uid);
});

// ── Prescriptions ─────────────────────────────────────────────────────────────

final doctorPrescriptionsProvider =
    StreamProvider<List<PrescriptionModel>>((ref) {
  final uid = ref.watch(_doctorUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return doctorRepository.prescriptionsStream(uid);
});

// ── Unique patient count ──────────────────────────────────────────────────────

final doctorPatientCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(_doctorUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return doctorRepository.uniquePatientCountStream(uid);
});

// ── Stats ─────────────────────────────────────────────────────────────────────

class DoctorStats {
  final int todayTotal;
  final int todayPending;
  final int todayCompleted;
  final int totalPatients;
  final int activePrescriptions;

  const DoctorStats({
    required this.todayTotal,
    required this.todayPending,
    required this.todayCompleted,
    required this.totalPatients,
    required this.activePrescriptions,
  });
}

final doctorStatsProvider = Provider<DoctorStats>((ref) {
  final today     = ref.watch(todayAppointmentsProvider).valueOrNull ?? [];
  final rxs       = ref.watch(doctorPrescriptionsProvider).valueOrNull ?? [];
  final patients  = ref.watch(doctorPatientCountProvider).valueOrNull ?? 0;

  return DoctorStats(
    todayTotal:          today.length,
    todayPending:        today.where((a) => a.status == AppointmentStatus.pending).length,
    todayCompleted:      today.where((a) => a.status == AppointmentStatus.completed).length,
    totalPatients:       patients,
    activePrescriptions: rxs.where((r) => r.status == PrescriptionStatus.active).length,
  );
});

// ── Actions ───────────────────────────────────────────────────────────────────

Future<void> updateAppointmentStatus(
    String id, AppointmentStatus status) async {
  await doctorRepository.updateAppointmentStatus(id, status);
}

Future<String> createPrescription(PrescriptionModel rx) async {
  return doctorRepository.createPrescription(rx);
}
