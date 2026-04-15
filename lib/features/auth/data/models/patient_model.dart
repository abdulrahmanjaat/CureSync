import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String? patientId;
  final String managerId;
  final String name;
  final int age;
  final String relation;
  final String accessCode;
  final String? caregiverId;
  /// All UIDs (manager + any linked caregivers/family) allowed to read
  /// this patient's sub-collections. Used by Firestore rules.
  final List<String> accessList;
  final DateTime createdAt;
  /// SOS state — written by [CaregiverRepository.triggerSos] and read by
  /// caregiver alert screens. Stored directly on the patient document.
  final bool isSosActive;
  final DateTime? sosTriggerTime;

  const PatientModel({
    this.patientId,
    required this.managerId,
    required this.name,
    required this.age,
    required this.relation,
    required this.accessCode,
    this.caregiverId,
    this.accessList = const [],
    required this.createdAt,
    this.isSosActive = false,
    this.sosTriggerTime,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      patientId: doc.id,
      managerId: data['managerId'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      relation: data['relation'] ?? '',
      accessCode: data['accessCode'] ?? '',
      caregiverId: data['caregiverId'],
      accessList: (data['accessList'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSosActive: data['isSosActive'] as bool? ?? false,
      sosTriggerTime:
          (data['sosTriggerTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'managerId': managerId,
      'name': name,
      'age': age,
      'relation': relation,
      'accessCode': accessCode,
      if (caregiverId != null) 'caregiverId': caregiverId,
      'accessList': accessList,
      // Use the model's own DateTime so the local object and Firestore are in
      // sync immediately after write (no FieldValue.serverTimestamp() mismatch).
      'createdAt': Timestamp.fromDate(createdAt),
      'isSosActive': isSosActive,
      if (sosTriggerTime != null)
        'sosTriggerTime': Timestamp.fromDate(sosTriggerTime!),
    };
  }

  static String generateAccessCode() {
    final random = Random();
    return (10000 + random.nextInt(90000)).toString();
  }
}
