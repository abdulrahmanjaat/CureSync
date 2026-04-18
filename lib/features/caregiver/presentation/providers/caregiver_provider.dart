import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/patient/data/models/medication_model.dart';
import '../../data/models/assigned_patient_model.dart';
import '../../data/models/care_log_model.dart';
import '../../data/models/caregiver_profile_model.dart';
import '../../data/models/deal_request_model.dart';
import '../../data/repositories/caregiver_repository.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepository();
});

// ─── Work Profile ─────────────────────────────────────────────────────────────

final caregiverProfileProvider =
    StreamProvider<CaregiverProfileModel?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(caregiverRepositoryProvider).profileStream(uid);
});

/// Convenience bool provider — true once the pro-caregiver has submitted
/// the multi-step onboarding form (onboardingComplete == true in Firestore).
/// The router reads this to block access to /dashboard until setup is done.
final proOnboardingCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(caregiverProfileProvider).valueOrNull;
  // null means profile doc not yet loaded — treat as incomplete to be safe,
  // but only the router cares about this value after role is confirmed.
  return profile?.onboardingComplete ?? false;
});

// ─── Assigned Patients ────────────────────────────────────────────────────────

final assignedPatientsProvider =
    StreamProvider<List<AssignedPatientModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(caregiverRepositoryProvider)
      .assignedPatientsStream(uid);
});

// ─── Patient Live Data (for SOS + vitals) ────────────────────────────────────

final patientLiveDataProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, patientId) {
  return ref
      .watch(caregiverRepositoryProvider)
      .patientLiveDataStream(patientId);
});

// ─── Patient Medications (read-only) ─────────────────────────────────────────

final assignedPatientMedsProvider =
    StreamProvider.family<List<MedicationModel>, String>(
        (ref, patientId) {
  return ref
      .watch(caregiverRepositoryProvider)
      .patientMedicationsStream(patientId);
});

// ─── Today's Taken Keys (for overdue calculation) ────────────────────────────

final patientTakenKeysProvider =
    StreamProvider.family<List<String>, String>((ref, patientId) {
  return ref
      .watch(caregiverRepositoryProvider)
      .todayTakenKeysStream(patientId);
});

// ─── Medication Status per Patient ───────────────────────────────────────────

enum MedStatus { allClear, overdue, noMeds }

final patientMedStatusProvider =
    Provider.family<MedStatus, String>((ref, patientId) {
  final meds =
      ref.watch(assignedPatientMedsProvider(patientId)).valueOrNull ?? [];
  final takenKeys =
      ref.watch(patientTakenKeysProvider(patientId)).valueOrNull ?? [];
  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  if (meds.isEmpty) return MedStatus.noMeds;

  for (final med in meds.where((m) => m.isActive && !m.isExpired)) {
    for (final time in med.reminderTimes) {
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final medMinutes =
          (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      final key = '${med.id}_$time';
      if (medMinutes < nowMinutes && !takenKeys.contains(key)) {
        return MedStatus.overdue;
      }
    }
  }
  return MedStatus.allClear;
});

// ─── SOS Detection (any assigned patient with isSosActive = true) ─────────────

final sosTriggerProvider = Provider<AssignedPatientModel?>((ref) {
  final patients =
      ref.watch(assignedPatientsProvider).valueOrNull ?? [];
  for (final p in patients) {
    final live =
        ref.watch(patientLiveDataProvider(p.patientId)).valueOrNull;
    if (live?['isSosActive'] == true) return p;
  }
  return null;
});

// ─── Deal Requests ────────────────────────────────────────────────────────────

final dealRequestsProvider =
    StreamProvider<List<DealRequestModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(caregiverRepositoryProvider).dealRequestsStream(uid);
});

final pendingDealCountProvider = Provider<int>((ref) {
  final deals = ref.watch(dealRequestsProvider).valueOrNull ?? [];
  return deals.where((d) => d.status == DealStatus.pending).length;
});

// ─── Care Logs ────────────────────────────────────────────────────────────────

final careLogsProvider =
    StreamProvider.family<List<CareLogModel>, String>((ref, patientId) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(caregiverRepositoryProvider)
      .careLogsStream(uid, patientId);
});

// ─── Link Patient by Access Code ─────────────────────────────────────────────

class LinkPatientNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  LinkPatientNotifier(this._ref) : super(const AsyncData(null));

  Future<String?> link(String accessCode) async {
    state = const AsyncLoading();
    final uid = _ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      state = const AsyncData(null);
      return 'Not signed in';
    }
    try {
      final error = await _ref
          .read(caregiverRepositoryProvider)
          .linkPatientByCode(uid, accessCode);
      state = const AsyncData(null);
      return error; // null = success
    } catch (e) {
      state = const AsyncData(null);
      return e.toString();
    }
  }
}

final linkPatientProvider =
    StateNotifierProvider<LinkPatientNotifier, AsyncValue<void>>(
  (ref) => LinkPatientNotifier(ref),
);

// ─── Daily Duty List ──────────────────────────────────────────────────────────

class DutyItem {
  final String patientId;
  final String patientName;
  final String medName;
  final String time; // "HH:mm"
  final int sortKey; // total minutes for ordering
  final bool isTaken;

  const DutyItem({
    required this.patientId,
    required this.patientName,
    required this.medName,
    required this.time,
    required this.sortKey,
    this.isTaken = false,
  });
}

final dailyDutyListProvider = Provider<List<DutyItem>>((ref) {
  final patients =
      ref.watch(assignedPatientsProvider).valueOrNull ?? [];
  final duties = <DutyItem>[];

  for (final p in patients) {
    final meds =
        ref.watch(assignedPatientMedsProvider(p.patientId)).valueOrNull ?? [];
    final takenKeys =
        ref.watch(patientTakenKeysProvider(p.patientId)).valueOrNull ?? [];

    for (final m in meds.where((m) => m.isActive && !m.isExpired)) {
      for (final t in m.reminderTimes) {
        final parts = t.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts[1]) ?? 0;
        final key = '${m.id}_$t';
        duties.add(DutyItem(
          patientId: p.patientId,
          patientName: p.patientName,
          medName: m.name,
          time: t,
          sortKey: h * 60 + min,
          isTaken: takenKeys.contains(key),
        ));
      }
    }
  }

  duties.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return duties;
});

// ─── Missed Meds Count (for alerts badge) ────────────────────────────────────

final totalMissedMedsProvider = Provider<int>((ref) {
  final patients =
      ref.watch(assignedPatientsProvider).valueOrNull ?? [];
  var count = 0;
  for (final p in patients) {
    if (ref.watch(patientMedStatusProvider(p.patientId)) ==
        MedStatus.overdue) {
      count++;
    }
  }
  return count;
});
