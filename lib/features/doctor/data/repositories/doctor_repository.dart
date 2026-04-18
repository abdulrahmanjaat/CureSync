import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';
import '../models/prescription_model.dart';

class DoctorRepository {
  final _db = FirebaseFirestore.instance;

  // ── Appointments ─────────────────────────────────────────────────────────────

  Stream<List<AppointmentModel>> appointmentsStream(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> todayAppointmentsStream(String doctorId) {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end   = start.add(const Duration(days: 1));
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledAt')
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, AppointmentStatus status) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': status.value,
    });
  }

  Future<String> createAppointment(AppointmentModel appt) async {
    final ref = await _db.collection('appointments').add(appt.toFirestore());
    return ref.id;
  }

  // ── Prescriptions ─────────────────────────────────────────────────────────────

  Stream<List<PrescriptionModel>> prescriptionsStream(String doctorId) {
    return _db
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PrescriptionModel.fromFirestore).toList());
  }

  Future<String> createPrescription(PrescriptionModel rx) async {
    final ref = await _db.collection('prescriptions').add(rx.toFirestore());
    return ref.id;
  }

  Future<void> updatePrescriptionStatus(
      String rxId, PrescriptionStatus status) async {
    await _db.collection('prescriptions').doc(rxId).update({
      'status': status.value,
    });
  }

  // ── Patient lookup ─────────────────────────────────────────────────────────

  /// Distinct patient IDs from appointments made with this doctor.
  Stream<int> uniquePatientCountStream(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((s) => s.docs.map((d) => d['patientId'] as String).toSet().length);
  }
}

final _repo = DoctorRepository();
DoctorRepository get doctorRepository => _repo;
