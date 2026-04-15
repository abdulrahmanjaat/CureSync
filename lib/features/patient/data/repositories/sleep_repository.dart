import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sleep_log_model.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class SleepRepository {
  final FirebaseFirestore _firestore;

  SleepRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _todayRef(String patientId) => _firestore
      .collection('patients')
      .doc(patientId)
      .collection('sleep_logs')
      .doc(_todayStr());

  Stream<SleepLogModel?> todayStream(String patientId) {
    return _todayRef(patientId)
        .snapshots()
        .map((s) => s.exists ? SleepLogModel.fromFirestore(s) : null);
  }

  Future<void> logSleep({
    required String patientId,
    required int hours,
    required int minutes,
    String? bedtime,
    String? wakeTime,
  }) async {
    final log = SleepLogModel(
      patientId: patientId,
      date: _todayStr(),
      hoursSlept: hours,
      minutesSlept: minutes,
      bedtime: bedtime,
      wakeTime: wakeTime,
    );
    await _todayRef(patientId).set(log.toFirestore());
  }
}
