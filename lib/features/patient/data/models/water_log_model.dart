import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLogModel {
  final String patientId;
  final String date; // YYYY-MM-DD
  final int glassesConsumed;
  final int dailyGoal;
  final DateTime updatedAt;

  const WaterLogModel({
    required this.patientId,
    required this.date,
    required this.glassesConsumed,
    this.dailyGoal = 8,
    required this.updatedAt,
  });

  factory WaterLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WaterLogModel(
      patientId: d['patientId'] as String? ?? '',
      date: d['date'] as String? ?? '',
      glassesConsumed: (d['glassesConsumed'] as num?)?.toInt() ?? 0,
      dailyGoal: (d['dailyGoal'] as num?)?.toInt() ?? 8,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'date': date,
        'glassesConsumed': glassesConsumed,
        'dailyGoal': dailyGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  double get progress =>
      dailyGoal > 0 ? (glassesConsumed / dailyGoal).clamp(0.0, 1.0) : 0.0;

  bool get goalMet => glassesConsumed >= dailyGoal;

  int get remaining => (dailyGoal - glassesConsumed).clamp(0, dailyGoal);
}
