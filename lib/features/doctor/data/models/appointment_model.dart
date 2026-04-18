import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentType { routine, followUp, emergency, consultation, checkup }
enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow }

extension AppointmentTypeX on AppointmentType {
  String get label => switch (this) {
        AppointmentType.routine      => 'Routine',
        AppointmentType.followUp     => 'Follow-up',
        AppointmentType.emergency    => 'Emergency',
        AppointmentType.consultation => 'Consultation',
        AppointmentType.checkup      => 'Check-up',
      };
  String get value => switch (this) {
        AppointmentType.routine      => 'routine',
        AppointmentType.followUp     => 'follow_up',
        AppointmentType.emergency    => 'emergency',
        AppointmentType.consultation => 'consultation',
        AppointmentType.checkup      => 'checkup',
      };
  static AppointmentType fromString(String? v) => switch (v) {
        'follow_up'     => AppointmentType.followUp,
        'emergency'     => AppointmentType.emergency,
        'consultation'  => AppointmentType.consultation,
        'checkup'       => AppointmentType.checkup,
        _               => AppointmentType.routine,
      };
}

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.pending   => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.noShow    => 'No Show',
      };
  String get value => switch (this) {
        AppointmentStatus.pending   => 'pending',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.noShow    => 'no_show',
      };
  static AppointmentStatus fromString(String? v) => switch (v) {
        'confirmed' => AppointmentStatus.confirmed,
        'completed' => AppointmentStatus.completed,
        'cancelled' => AppointmentStatus.cancelled,
        'no_show'   => AppointmentStatus.noShow,
        _           => AppointmentStatus.pending,
      };
}

class AppointmentModel {
  final String? id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final int patientAge;
  final DateTime scheduledAt;
  final AppointmentType type;
  final AppointmentStatus status;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  const AppointmentModel({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.scheduledAt,
    required this.type,
    required this.status,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id:           doc.id,
      doctorId:     d['doctorId']     as String? ?? '',
      patientId:    d['patientId']    as String? ?? '',
      patientName:  d['patientName']  as String? ?? 'Unknown',
      patientAge:   (d['patientAge']  as num?)?.toInt() ?? 0,
      scheduledAt:  (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type:         AppointmentTypeX.fromString(d['type'] as String?),
      status:       AppointmentStatusX.fromString(d['status'] as String?),
      reason:       d['reason']       as String? ?? '',
      notes:        d['notes']        as String?,
      createdAt:    (d['createdAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId':    doctorId,
        'patientId':   patientId,
        'patientName': patientName,
        'patientAge':  patientAge,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'type':        type.value,
        'status':      status.value,
        'reason':      reason,
        if (notes != null) 'notes': notes,
        'createdAt':   FieldValue.serverTimestamp(),
      };
}
