import 'package:cloud_firestore/cloud_firestore.dart';

class DoseLogModel {
  final String id; // "{date}_{medId}_{HHmm}"
  final String medId;
  final String medName;
  final String reminderTime; // "08:00"
  final String date; // "2024-01-15"
  final DateTime? takenAt;

  const DoseLogModel({
    required this.id,
    required this.medId,
    required this.medName,
    required this.reminderTime,
    required this.date,
    this.takenAt,
  });

  factory DoseLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DoseLogModel(
      id: doc.id,
      medId: d['medId'] ?? '',
      medName: d['medName'] ?? '',
      reminderTime: d['reminderTime'] ?? '',
      date: d['date'] ?? '',
      takenAt: (d['takenAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'medId': medId,
        'medName': medName,
        'reminderTime': reminderTime,
        'date': date,
        'takenAt': FieldValue.serverTimestamp(),
      };

  String get key => '${medId}_$reminderTime';
}
