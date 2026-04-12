import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/water_log_model.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class WaterTrackerRepository {
  final FirebaseFirestore _firestore;

  WaterTrackerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _todayRef(String patientId) => _firestore
      .collection('patients')
      .doc(patientId)
      .collection('water_logs')
      .doc(_todayStr());

  Stream<WaterLogModel?> todayStream(String patientId) {
    return _todayRef(patientId)
        .snapshots()
        .map((s) => s.exists ? WaterLogModel.fromFirestore(s) : null);
  }

  /// Increments today's glass count by 1. Creates the document if it doesn't exist.
  Future<void> logGlass(String patientId, {int currentGoal = 8}) async {
    final ref = _todayRef(patientId);
    final today = _todayStr();

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        txn.set(ref, {
          'patientId': patientId,
          'date': today,
          'glassesConsumed': 1,
          'dailyGoal': currentGoal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final current =
            (snap.data() as Map<String, dynamic>)['glassesConsumed'] as int? ??
                0;
        txn.update(ref, {
          'glassesConsumed': current + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Decrements today's glass count by 1 (min 0).
  Future<void> removeGlass(String patientId) async {
    final ref = _todayRef(patientId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final current =
          (snap.data() as Map<String, dynamic>)['glassesConsumed'] as int? ?? 0;
      if (current > 0) {
        txn.update(ref, {
          'glassesConsumed': current - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Updates the daily goal, preserving current consumed count.
  Future<void> updateGoal(String patientId, int goal) async {
    await _todayRef(patientId).set(
      {
        'patientId': patientId,
        'date': _todayStr(),
        'dailyGoal': goal,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
