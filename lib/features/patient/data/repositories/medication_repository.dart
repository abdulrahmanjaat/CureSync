import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication_model.dart' show MedicationModel, MealTiming, MealTimingX;
import '../models/dose_log_model.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class MedicationRepository {
  final FirebaseFirestore _firestore;

  MedicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _medsRef(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('medications');

  CollectionReference _doseLogsRef(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('dose_logs');

  // ─── Medications ────────────────────────────────────────────────────────────

  Stream<List<MedicationModel>> medicationsStream(String patientId) {
    return _medsRef(patientId).snapshots().map((snap) {
      final list = <MedicationModel>[];
      for (final d in snap.docs) {
        try {
          list.add(MedicationModel.fromFirestore(d));
        } catch (_) {
          // Skip malformed documents rather than erroring the whole stream.
        }
      }
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Future<MedicationModel> addMedication({
    required String patientId,
    required String name,
    required String dosage,
    required int durationDays,
    required List<String> reminderTimes,
    MealTiming mealTiming = MealTiming.noRestriction,
    String? notes,
  }) async {
    final doc = _medsRef(patientId).doc();
    final med = MedicationModel(
      id: doc.id,
      patientId: patientId,
      name: name,
      dosage: dosage,
      durationDays: durationDays,
      reminderTimes: reminderTimes,
      mealTiming: mealTiming,
      notes: notes,
      startDate: DateTime.now(),
    );
    await doc.set(med.toFirestore());
    return med;
  }

  Future<void> updateMedication({
    required String patientId,
    required String medId,
    required String name,
    required String dosage,
    required int durationDays,
    required List<String> reminderTimes,
    MealTiming mealTiming = MealTiming.noRestriction,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'dosage': dosage,
      'durationDays': durationDays,
      'reminderTimes': reminderTimes,
      'mealTiming': mealTiming.firestoreValue,
      'notes': (notes != null && notes.isNotEmpty) ? notes : FieldValue.delete(),
    };
    await _medsRef(patientId).doc(medId).update(data);
  }

  Future<void> deleteMedication(String patientId, String medId) async {
    await _medsRef(patientId).doc(medId).delete();
  }

  Future<void> toggleActive(String patientId, String medId, bool active) async {
    await _medsRef(patientId).doc(medId).update({'isActive': active});
  }

  // ─── Dose Logs ───────────────────────────────────────────────────────────────

  Stream<List<DoseLogModel>> todayDoseLogsStream(String patientId) {
    final today = _todayStr();
    return _doseLogsRef(patientId)
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DoseLogModel.fromFirestore(d)).toList());
  }

  Future<void> markDoseTaken({
    required String patientId,
    required String medId,
    required String medName,
    required String reminderTime,
  }) async {
    final today = _todayStr();
    final docId = '${today}_${medId}_${reminderTime.replaceAll(':', '')}';
    final log = DoseLogModel(
      id: docId,
      medId: medId,
      medName: medName,
      reminderTime: reminderTime,
      date: today,
    );
    await _doseLogsRef(patientId).doc(docId).set(log.toFirestore());
  }

  Future<void> unmarkDoseTaken({
    required String patientId,
    required String medId,
    required String reminderTime,
  }) async {
    final today = _todayStr();
    final docId = '${today}_${medId}_${reminderTime.replaceAll(':', '')}';
    await _doseLogsRef(patientId).doc(docId).delete();
  }
}
