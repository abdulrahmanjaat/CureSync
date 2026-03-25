import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication_model.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore;

  MedicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _medsRef(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('medications');

  Stream<List<MedicationModel>> medicationsStream(String patientId) {
    return _medsRef(patientId).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList();
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
  }) async {
    final doc = _medsRef(patientId).doc();
    final med = MedicationModel(
      id: doc.id,
      patientId: patientId,
      name: name,
      dosage: dosage,
      durationDays: durationDays,
      reminderTimes: reminderTimes,
      startDate: DateTime.now(),
    );
    await doc.set(med.toFirestore());
    return med;
  }

  Future<void> deleteMedication(String patientId, String medId) async {
    await _medsRef(patientId).doc(medId).delete();
  }

  Future<void> toggleActive(String patientId, String medId, bool active) async {
    await _medsRef(patientId).doc(medId).update({'isActive': active});
  }
}
