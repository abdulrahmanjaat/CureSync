import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/role_provider.dart';
import '../../data/models/dose_log_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/repositories/medication_repository.dart';
import 'patient_provider.dart';
import 'active_patient_provider.dart';
import '../widgets/dashboard/pill_timeline.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

/// Emits a new [DateTime] every minute so that time-sensitive providers
/// (pill timeline due-windows, countdown labels) re-evaluate automatically.
/// A new value fires ~1 second after each full minute turn to account for
/// any system scheduling jitter.
final minuteTickProvider = StreamProvider<DateTime>((ref) async* {
  // Emit once immediately so dependents build with the correct initial time.
  yield DateTime.now();
  while (true) {
    final now = DateTime.now();
    // Sleep until 1 second past the next whole minute.
    final delay = Duration(
      seconds: 61 - now.second,
      milliseconds: -now.millisecond,
    );
    await Future.delayed(delay);
    yield DateTime.now();
  }
});

final medicationsStreamProvider =
    StreamProvider.family<List<MedicationModel>, String>(
        (ref, patientId) {
  return ref.watch(medicationRepositoryProvider).medicationsStream(patientId);
});

final todayDoseLogsProvider =
    StreamProvider.family<List<DoseLogModel>, String>(
        (ref, patientId) {
  return ref
      .watch(medicationRepositoryProvider)
      .todayDoseLogsStream(patientId);
});

/// Resolves the active patient ID, gated by role:
///
/// - **patient** role → always returns the user's own UID, regardless of any
///   value stored in [activePatientIdProvider]. This hard-blocks cross-user
///   data leakage even if a stale manager selection is still in the container.
/// - **manager / family / pro-caregiver** → respects the explicit selection in
///   [activePatientIdProvider], falling back to the first managed patient.
final resolvedActivePatientIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final userData = ref.watch(currentUserDataProvider).valueOrNull;
  final role     = UserRoleX.fromString(userData?.role);

  if (authUser == null) return null;

  // Patient-role: always locked to their own UID.
  if (role == UserRole.patient) return authUser.uid;

  // All other roles: explicit selection, or first managed patient.
  final explicit = ref.watch(activePatientIdProvider);
  if (explicit != null) return explicit;
  final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];
  return patients.isNotEmpty ? patients.first.patientId : null;
});

/// Derived: today's pill timeline entries for a patient.
///
/// Watches [minuteTickProvider] so that [PillTimelineEntry.isDue] and
/// [PillTimelineEntry.isMissed] are re-evaluated every minute.
///
/// **Window logic** (per dose, globally sorted by time):
///   • windowEnd = next dose's scheduled time (if later), else +120 min
///   • isDue    = !taken && scheduledMins ≤ now < windowEnd
///   • isMissed = !taken && now ≥ windowEnd
final todayPillTimelineProvider =
    Provider.family<List<PillTimelineEntry>, String>((ref, patientId) {
  // Rebuild every minute so due-window and missed flags stay accurate.
  ref.watch(minuteTickProvider);

  final meds = ref.watch(medicationsStreamProvider(patientId)).valueOrNull ?? [];
  final logs = ref.watch(todayDoseLogsProvider(patientId)).valueOrNull ?? [];

  final now = _nowMinutes();

  // Build lookup maps from today's dose logs.
  final takenKeys  = <String>{};
  final takenAtMap = <String, DateTime>{};
  for (final log in logs) {
    takenKeys.add(log.key);
    if (log.takenAt != null) takenAtMap[log.key] = log.takenAt!;
  }

  // Collect all (medId, medName, dosage, reminderTime) pairs across active meds.
  final allPairs = <({String medId, String medName, String dosage, String rawTime})>[];
  for (final med in meds.where((m) => m.isActive && !m.isExpired)) {
    for (final t in med.reminderTimes) {
      allPairs.add((medId: med.id ?? '', medName: med.name, dosage: med.dosage, rawTime: t));
    }
  }
  // Sort globally by scheduled time so window boundaries are correct.
  allPairs.sort(
      (a, b) => _timeToMinutes(a.rawTime) - _timeToMinutes(b.rawTime));

  final entries = <PillTimelineEntry>[];
  for (int i = 0; i < allPairs.length; i++) {
    final pair         = allPairs[i];
    final scheduledMin = _timeToMinutes(pair.rawTime);

    // Window ends when the next dose's time starts (if later), else +120 min.
    final int windowEndMin;
    if (i + 1 < allPairs.length) {
      final nextMin = _timeToMinutes(allPairs[i + 1].rawTime);
      windowEndMin  = nextMin > scheduledMin ? nextMin : scheduledMin + 120;
    } else {
      windowEndMin = scheduledMin + 120;
    }

    final key      = '${pair.medId}_${pair.rawTime}';
    final isTaken  = takenKeys.contains(key);
    final isDue    = !isTaken && scheduledMin <= now && now < windowEndMin;
    final isMissed = !isTaken && now >= windowEndMin;

    entries.add(PillTimelineEntry(
      rawTime:  pair.rawTime,
      time:     _formatTime(pair.rawTime),
      medId:    pair.medId,
      medName:  pair.medName,
      dosage:   pair.dosage,
      isTaken:  isTaken,
      isDue:    isDue,
      isMissed: isMissed,
      takenAt:  takenAtMap[key],
    ));
  }
  return entries;
});

/// Derived: (taken, total, percentage) for adherence ring
final todayAdherenceProvider = Provider.family<({int taken, int total}), String>(
  (ref, patientId) {
    final entries = ref.watch(todayPillTimelineProvider(patientId));
    final taken = entries.where((e) => e.isTaken).length;
    return (taken: taken, total: entries.length);
  },
);

/// Derived: next actionable dose for the SmartActionCard.
///
/// Priority order: due-now > next-upcoming > most-recent-missed.
final nextDoseProvider = Provider.family<PillTimelineEntry?, String>(
  (ref, patientId) {
    final entries = ref.watch(todayPillTimelineProvider(patientId));

    // 1. Active due window — patient should act right now.
    final due = entries.where((e) => e.isDue);
    if (due.isNotEmpty) return due.first;

    // 2. Upcoming — clock hasn't reached the scheduled time yet.
    final upcoming = entries.where((e) => !e.isTaken && !e.isDue && !e.isMissed);
    if (upcoming.isNotEmpty) return upcoming.first;

    // 3. Missed — all windows have elapsed; surface the most recent one.
    final missed = entries.where((e) => e.isMissed);
    return missed.isNotEmpty ? missed.last : null;
  },
);

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final ampm = hour < 12 ? 'AM' : 'PM';
  return '$h:${minute.toString().padLeft(2, '0')} $ampm';
}

int _timeToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

int _nowMinutes() {
  final now = DateTime.now();
  return now.hour * 60 + now.minute;
}
