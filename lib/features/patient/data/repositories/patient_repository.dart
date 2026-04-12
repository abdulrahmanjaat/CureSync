import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/data/models/patient_model.dart';

class PatientRepository {
  final FirebaseFirestore _firestore;

  PatientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream all patients managed by this user
  Stream<List<PatientModel>> patientsStream(String managerId) {
    return _firestore
        .collection('patients')
        .where('managerId', isEqualTo: managerId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => PatientModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add a new patient profile
  Future<PatientModel> addPatient({
    required String managerId,
    required String name,
    required int age,
    required String relation,
  }) async {
    final code = PatientModel.generateAccessCode();
    final doc = _firestore.collection('patients').doc();
    final patient = PatientModel(
      patientId: doc.id,
      managerId: managerId,
      name: name,
      age: age,
      relation: relation,
      accessCode: code,
      createdAt: DateTime.now(),
    );
    await doc.set(patient.toFirestore());
    return patient;
  }

  /// Delete a patient profile
  Future<void> deletePatient(String patientId) async {
    await _firestore.collection('patients').doc(patientId).delete();
  }
}
