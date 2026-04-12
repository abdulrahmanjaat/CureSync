import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsModel {
  final String? id;
  final String patientId;
  final int systolic;
  final int diastolic;
  final int pulse;
  final int oxygenSaturation;
  final DateTime recordedAt;

  const VitalsModel({
    this.id,
    required this.patientId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.oxygenSaturation,
    required this.recordedAt,
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VitalsModel(
      id: doc.id,
      patientId: d['patientId'] ?? '',
      systolic: (d['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (d['diastolic'] as num?)?.toInt() ?? 0,
      pulse: (d['pulse'] as num?)?.toInt() ?? 0,
      oxygenSaturation: (d['oxygenSaturation'] as num?)?.toInt() ?? 0,
      recordedAt: (d['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'oxygenSaturation': oxygenSaturation,
        'recordedAt': FieldValue.serverTimestamp(),
      };

  String get bpLabel => '$systolic/$diastolic';

  String get bpStatus {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1';
    return 'Stage 2';
  }

  bool get bpNormal => systolic < 120 && diastolic < 80;
  bool get bpElevated => systolic >= 120 && systolic < 130 && diastolic < 80;

  String get pulseStatus {
    if (pulse < 60) return 'Low';
    if (pulse <= 100) return 'Normal';
    return 'High';
  }

  bool get pulseNormal => pulse >= 60 && pulse <= 100;

  String get spo2Status {
    if (oxygenSaturation >= 95) return 'Normal';
    if (oxygenSaturation >= 90) return 'Low';
    return 'Critical';
  }
}
