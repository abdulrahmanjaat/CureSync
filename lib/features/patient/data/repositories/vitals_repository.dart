import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vitals_model.dart';

class VitalsRepository {
  final FirebaseFirestore _firestore;

  VitalsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _vitalsRef(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('vitals');

  Stream<VitalsModel?> latestVitalsStream(String patientId) {
    return _vitalsRef(patientId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : VitalsModel.fromFirestore(snap.docs.first));
  }

  Future<void> addVitals({
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required int oxygenSaturation,
  }) async {
    final doc = _vitalsRef(patientId).doc();
    final vitals = VitalsModel(
      id: doc.id,
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      oxygenSaturation: oxygenSaturation,
      recordedAt: DateTime.now(),
    );
    await doc.set(vitals.toFirestore());
  }
}
