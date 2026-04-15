import 'package:cloud_firestore/cloud_firestore.dart';

class DietLogModel {
  final String patientId;
  final String date; // "YYYY-MM-DD"
  final int calories;
  final int calorieGoal;
  final DateTime? updatedAt;

  const DietLogModel({
    required this.patientId,
    required this.date,
    required this.calories,
    this.calorieGoal = 2000,
    this.updatedAt,
  });

  double get progress =>
      calorieGoal > 0 ? (calories / calorieGoal).clamp(0.0, 1.0) : 0.0;

  String get label => '$calories';

  String get statusLabel {
    if (calories == 0) return 'Not logged';
    if (calories < calorieGoal * 0.8) return 'Under';
    if (calories <= calorieGoal * 1.1) return 'On track';
    return 'Over';
  }

  factory DietLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DietLogModel(
      patientId: d['patientId'] ?? '',
      date: d['date'] ?? '',
      calories: d['calories'] ?? 0,
      calorieGoal: d['calorieGoal'] ?? 2000,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'date': date,
        'calories': calories,
        'calorieGoal': calorieGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
