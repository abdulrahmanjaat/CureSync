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
  final DateTime createdAt;

  const PatientModel({
    this.patientId,
    required this.managerId,
    required this.name,
    required this.age,
    required this.relation,
    required this.accessCode,
    this.caregiverId,
    required this.createdAt,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'managerId': managerId,
      'name': name,
      'age': age,
      'relation': relation,
      'accessCode': accessCode,
      'caregiverId': caregiverId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String generateAccessCode() {
    final random = Random();
    return (10000 + random.nextInt(90000)).toString();
  }
}
