import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String? id;
  final String patientId;
  final String name;
  final String dosage;
  final int durationDays;
  final List<String> reminderTimes; // ["08:00", "14:00", "21:00"]
  final DateTime startDate;
  final bool isActive;

  const MedicationModel({
    this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.durationDays,
    required this.reminderTimes,
    required this.startDate,
    this.isActive = true,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      id: doc.id,
      patientId: d['patientId'] ?? '',
      name: d['name'] ?? '',
      dosage: d['dosage'] ?? '',
      durationDays: d['durationDays'] ?? 0,
      reminderTimes: List<String>.from(d['reminderTimes'] ?? []),
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'durationDays': durationDays,
      'reminderTimes': reminderTimes,
      'startDate': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  DateTime get endDate => startDate.add(Duration(days: durationDays));
  bool get isExpired => DateTime.now().isAfter(endDate);

  String get frequencyLabel {
    final count = reminderTimes.length;
    if (count == 1) return 'Once daily';
    if (count == 2) return 'Twice daily';
    if (count == 3) return '3 times daily';
    return '$count times daily';
  }
}
