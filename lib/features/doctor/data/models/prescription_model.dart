import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus { active, dispensed, expired, cancelled }

extension PrescriptionStatusX on PrescriptionStatus {
  String get label => switch (this) {
        PrescriptionStatus.active    => 'Active',
        PrescriptionStatus.dispensed => 'Dispensed',
        PrescriptionStatus.expired   => 'Expired',
        PrescriptionStatus.cancelled => 'Cancelled',
      };
  String get value => switch (this) {
        PrescriptionStatus.active    => 'active',
        PrescriptionStatus.dispensed => 'dispensed',
        PrescriptionStatus.expired   => 'expired',
        PrescriptionStatus.cancelled => 'cancelled',
      };
  static PrescriptionStatus fromString(String? v) => switch (v) {
        'dispensed' => PrescriptionStatus.dispensed,
        'expired'   => PrescriptionStatus.expired,
        'cancelled' => PrescriptionStatus.cancelled,
        _           => PrescriptionStatus.active,
      };
}

class PrescribedMedication {
  final String name;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;

  const PrescribedMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.instructions,
  });

  factory PrescribedMedication.fromMap(Map<String, dynamic> m) =>
      PrescribedMedication(
        name:         m['name']         as String? ?? '',
        dosage:       m['dosage']       as String? ?? '',
        frequency:    m['frequency']    as String? ?? '',
        durationDays: (m['durationDays'] as num?)?.toInt() ?? 7,
        instructions: m['instructions'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name':         name,
        'dosage':       dosage,
        'frequency':    frequency,
        'durationDays': durationDays,
        if (instructions != null) 'instructions': instructions,
      };
}

class PrescriptionModel {
  final String? id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final int patientAge;
  final List<PrescribedMedication> medications;
  final String? diagnosis;
  final String? notes;
  final PrescriptionStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? pharmacyId; // filled when dispensed

  const PrescriptionModel({
    this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.medications,
    this.diagnosis,
    this.notes,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.pharmacyId,
  });

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawMeds = (d['medications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return PrescriptionModel(
      id:          doc.id,
      doctorId:    d['doctorId']    as String? ?? '',
      doctorName:  d['doctorName']  as String? ?? '',
      patientId:   d['patientId']   as String? ?? '',
      patientName: d['patientName'] as String? ?? 'Unknown',
      patientAge:  (d['patientAge'] as num?)?.toInt() ?? 0,
      medications: rawMeds.map(PrescribedMedication.fromMap).toList(),
      diagnosis:   d['diagnosis']   as String?,
      notes:       d['notes']       as String?,
      status:      PrescriptionStatusX.fromString(d['status'] as String?),
      issuedAt:    (d['issuedAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:   (d['expiresAt']  as Timestamp?)?.toDate() ??
                   DateTime.now().add(const Duration(days: 30)),
      pharmacyId:  d['pharmacyId']  as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId':    doctorId,
        'doctorName':  doctorName,
        'patientId':   patientId,
        'patientName': patientName,
        'patientAge':  patientAge,
        'medications': medications.map((m) => m.toMap()).toList(),
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (notes != null) 'notes': notes,
        'status':      status.value,
        'issuedAt':    FieldValue.serverTimestamp(),
        'expiresAt':   Timestamp.fromDate(expiresAt),
        if (pharmacyId != null) 'pharmacyId': pharmacyId,
      };
}
