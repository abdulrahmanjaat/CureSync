import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dose_log_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/repositories/medication_repository.dart';
import 'patient_provider.dart';
import 'active_patient_provider.dart';
import '../widgets/dashboard/pill_timeline.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

final medicationsStreamProvider =
    StreamProvider.family<List<MedicationModel>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).medicationsStream(patientId);
});

final todayDoseLogsProvider =
    StreamProvider.family<List<DoseLogModel>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).todayDoseLogsStream(patientId);
});

/// Resolves the active patient: explicit selection OR first patient in list
final resolvedActivePatientIdProvider = Provider<String?>((ref) {
  final explicit = ref.watch(activePatientIdProvider);
  if (explicit != null) return explicit;
  final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];
  return patients.isNotEmpty ? patients.first.patientId : null;
});

/// Derived: today's pill timeline entries for a patient
final todayPillTimelineProvider =
    Provider.family<List<PillTimelineEntry>, String>((ref, patientId) {
  final meds = ref.watch(medicationsStreamProvider(patientId)).valueOrNull ?? [];
  final logs = ref.watch(todayDoseLogsProvider(patientId)).valueOrNull ?? [];

  final takenKeys = {for (final log in logs) log.key};

  final entries = <PillTimelineEntry>[];
  for (final med in meds.where((m) => m.isActive && !m.isExpired)) {
    for (final time in med.reminderTimes) {
      entries.add(PillTimelineEntry(
        rawTime: time,
        time: _formatTime(time),
        medId: med.id ?? '',
        medName: med.name,
        isTaken: takenKeys.contains('${med.id}_$time'),
      ));
    }
  }
  entries.sort((a, b) => _timeToMinutes(a.rawTime) - _timeToMinutes(b.rawTime));
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

/// Derived: next upcoming dose for smart action card
final nextDoseProvider = Provider.family<PillTimelineEntry?, String>(
  (ref, patientId) {
    final entries = ref.watch(todayPillTimelineProvider(patientId));
    final nowMinutes = _nowMinutes();
    // Find the first dose that is not taken and time hasn't passed
    final upcoming = entries.where((e) =>
        !e.isTaken && _timeToMinutes(e.rawTime) >= nowMinutes);
    if (upcoming.isNotEmpty) return upcoming.first;
    // Fallback: first not taken (overdue)
    final overdue = entries.where((e) => !e.isTaken);
    return overdue.isNotEmpty ? overdue.first : null;
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
