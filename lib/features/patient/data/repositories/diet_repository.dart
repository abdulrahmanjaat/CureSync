import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diet_log_model.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class DietRepository {
  final FirebaseFirestore _firestore;

  DietRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _todayRef(String patientId) => _firestore
      .collection('patients')
      .doc(patientId)
      .collection('diet_logs')
      .doc(_todayStr());

  Stream<DietLogModel?> todayStream(String patientId) {
    return _todayRef(patientId)
        .snapshots()
        .map((s) => s.exists ? DietLogModel.fromFirestore(s) : null);
  }

  Future<void> logDiet({
    required String patientId,
    required int calories,
    int calorieGoal = 2000,
  }) async {
    final log = DietLogModel(
      patientId: patientId,
      date: _todayStr(),
      calories: calories,
      calorieGoal: calorieGoal,
    );
    await _todayRef(patientId).set(log.toFirestore());
  }
}
