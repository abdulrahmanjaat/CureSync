import 'package:cloud_firestore/cloud_firestore.dart';

enum DealStatus { pending, accepted, rejected }

class DealRequestModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String managerId;
  final String managerName;
  final String accessCode;
  final DealStatus status;
  final DateTime createdAt;

  const DealRequestModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.managerId,
    required this.managerName,
    required this.accessCode,
    this.status = DealStatus.pending,
    required this.createdAt,
  });

  factory DealRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DealRequestModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      managerId: d['managerId'] as String? ?? '',
      managerName: d['managerName'] as String? ?? '',
      accessCode: d['accessCode'] as String? ?? '',
      status: _parseStatus(d['status'] as String?),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'managerId': managerId,
        'managerName': managerName,
        'accessCode': accessCode,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DealStatus _parseStatus(String? v) =>
      DealStatus.values.firstWhere(
        (s) => s.name == v,
        orElse: () => DealStatus.pending,
      );
}
