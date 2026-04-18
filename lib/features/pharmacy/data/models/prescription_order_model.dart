import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, processing, ready, dispensed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending    => 'Pending',
        OrderStatus.processing => 'Processing',
        OrderStatus.ready      => 'Ready',
        OrderStatus.dispensed  => 'Dispensed',
        OrderStatus.cancelled  => 'Cancelled',
      };
  String get value => switch (this) {
        OrderStatus.pending    => 'pending',
        OrderStatus.processing => 'processing',
        OrderStatus.ready      => 'ready',
        OrderStatus.dispensed  => 'dispensed',
        OrderStatus.cancelled  => 'cancelled',
      };
  static OrderStatus fromString(String? v) => switch (v) {
        'processing' => OrderStatus.processing,
        'ready'      => OrderStatus.ready,
        'dispensed'  => OrderStatus.dispensed,
        'cancelled'  => OrderStatus.cancelled,
        _            => OrderStatus.pending,
      };
}

class OrderMedication {
  final String name;
  final String dosage;
  final String frequency;
  final int durationDays;
  final bool inStock;

  const OrderMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.inStock = true,
  });

  factory OrderMedication.fromMap(Map<String, dynamic> m) => OrderMedication(
        name:         m['name']         as String? ?? '',
        dosage:       m['dosage']       as String? ?? '',
        frequency:    m['frequency']    as String? ?? '',
        durationDays: (m['durationDays'] as num?)?.toInt() ?? 7,
        inStock:      m['inStock']      as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name':         name,
        'dosage':       dosage,
        'frequency':    frequency,
        'durationDays': durationDays,
        'inStock':      inStock,
      };
}

class PrescriptionOrderModel {
  final String? id;
  final String pharmacyId;
  final String prescriptionId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final int patientAge;
  final List<OrderMedication> medications;
  final String? diagnosis;
  final String? notes;
  final OrderStatus status;
  final DateTime receivedAt;
  final DateTime? dispensedAt;

  const PrescriptionOrderModel({
    this.id,
    required this.pharmacyId,
    required this.prescriptionId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.medications,
    this.diagnosis,
    this.notes,
    required this.status,
    required this.receivedAt,
    this.dispensedAt,
  });

  factory PrescriptionOrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawMeds =
        (d['medications'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return PrescriptionOrderModel(
      id:               doc.id,
      pharmacyId:       d['pharmacyId']       as String? ?? '',
      prescriptionId:   d['prescriptionId']   as String? ?? '',
      doctorName:       d['doctorName']        as String? ?? '',
      patientId:        d['patientId']         as String? ?? '',
      patientName:      d['patientName']       as String? ?? 'Unknown',
      patientAge:       (d['patientAge']       as num?)?.toInt() ?? 0,
      medications:      rawMeds.map(OrderMedication.fromMap).toList(),
      diagnosis:        d['diagnosis']         as String?,
      notes:            d['notes']             as String?,
      status:           OrderStatusX.fromString(d['status'] as String?),
      receivedAt:       (d['receivedAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
      dispensedAt:      (d['dispensedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'pharmacyId':     pharmacyId,
        'prescriptionId': prescriptionId,
        'doctorName':     doctorName,
        'patientId':      patientId,
        'patientName':    patientName,
        'patientAge':     patientAge,
        'medications':    medications.map((m) => m.toMap()).toList(),
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (notes != null) 'notes': notes,
        'status':         status.value,
        'receivedAt':     FieldValue.serverTimestamp(),
        if (dispensedAt != null)
          'dispensedAt': Timestamp.fromDate(dispensedAt!),
      };
}
