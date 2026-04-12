import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedPatientModel {
  final String patientId;
  final String patientName;
  final String managerId;
  final String accessCode;
  final DateTime connectedAt;
  final bool isActive;

  const AssignedPatientModel({
    required this.patientId,
    required this.patientName,
    required this.managerId,
    required this.accessCode,
    required this.connectedAt,
    this.isActive = true,
  });

  factory AssignedPatientModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AssignedPatientModel(
      patientId: doc.id,
      patientName: d['patientName'] as String? ?? '',
      managerId: d['managerId'] as String? ?? '',
      accessCode: d['accessCode'] as String? ?? '',
      connectedAt:
          (d['connectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'managerId': managerId,
        'accessCode': accessCode,
        'connectedAt': FieldValue.serverTimestamp(),
        'isActive': isActive,
      };
}
