import 'package:cloud_firestore/cloud_firestore.dart';

enum CareLogType { observation, medicationNote, vitalNote, general }

class CareLogModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String note;
  final CareLogType type;
  final DateTime createdAt;

  const CareLogModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.note,
    this.type = CareLogType.general,
    required this.createdAt,
  });

  factory CareLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CareLogModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      note: d['note'] as String? ?? '',
      type: _parseType(d['type'] as String?),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'note': note,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static CareLogType _parseType(String? v) => CareLogType.values.firstWhere(
        (t) => t.name == v,
        orElse: () => CareLogType.general,
      );
}
