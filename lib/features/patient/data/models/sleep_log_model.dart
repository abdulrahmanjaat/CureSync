import 'package:cloud_firestore/cloud_firestore.dart';

class SleepLogModel {
  final String patientId;
  final String date; // "YYYY-MM-DD"
  final int hoursSlept; // 0-12
  final int minutesSlept; // 0, 15, 30, 45
  final String? bedtime; // "22:30"
  final String? wakeTime; // "06:30"
  final DateTime? updatedAt;

  const SleepLogModel({
    required this.patientId,
    required this.date,
    required this.hoursSlept,
    required this.minutesSlept,
    this.bedtime,
    this.wakeTime,
    this.updatedAt,
  });

  double get totalHours => hoursSlept + minutesSlept / 60.0;

  String get label {
    if (minutesSlept == 0) return '${hoursSlept}h';
    return '${hoursSlept}h ${minutesSlept}m';
  }

  /// Qualify the sleep duration
  String get qualityLabel {
    final total = totalHours;
    if (total >= 7 && total <= 9) return 'Great';
    if (total >= 6) return 'Fair';
    return 'Low';
  }

  factory SleepLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SleepLogModel(
      patientId: d['patientId'] ?? '',
      date: d['date'] ?? '',
      hoursSlept: d['hoursSlept'] ?? 0,
      minutesSlept: d['minutesSlept'] ?? 0,
      bedtime: d['bedtime'],
      wakeTime: d['wakeTime'],
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'date': date,
        'hoursSlept': hoursSlept,
        'minutesSlept': minutesSlept,
        if (bedtime != null) 'bedtime': bedtime,
        if (wakeTime != null) 'wakeTime': wakeTime,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
