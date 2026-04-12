import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/patient/data/models/medication_model.dart';
import '../models/assigned_patient_model.dart';
import '../models/care_log_model.dart';
import '../models/caregiver_profile_model.dart';
import '../models/deal_request_model.dart';

class CaregiverRepository {
  final FirebaseFirestore _db;

  CaregiverRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ─── Work Profile ─────────────────────────────────────────────────────────────

  Stream<CaregiverProfileModel?> profileStream(String uid) {
    return _db
        .collection('caregivers')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? CaregiverProfileModel.fromFirestore(s) : null);
  }

  Future<void> saveProfile(CaregiverProfileModel profile) async {
    await _db
        .collection('caregivers')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setAvailability(String uid, bool isAvailable) async {
    await _db
        .collection('caregivers')
        .doc(uid)
        .update({'isAvailableForHire': isAvailable});
  }

  /// Sync a Pro Caregiver profile to the root-level discovery_hub collection
  /// so patients can find them via the Discovery Hub.
  /// Family members must never call this.
  Future<void> syncToDiscoveryHub(CaregiverProfileModel profile) async {
    await _db.collection('pro_caregivers').doc(profile.uid).set({
      'uid': profile.uid,
      'name': profile.name,
      if (profile.photoUrl != null) 'photoUrl': profile.photoUrl,
      'bio': profile.bio ?? '',
      'yearsOfExperience': profile.yearsOfExperience,
      'hourlyRate': profile.hourlyRate,
      'dailyRate': profile.dailyRate,
      'specializations': profile.specializations,
      'isVerified': profile.isVerified,
      'isAvailableForHire': profile.isAvailableForHire,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Assigned Patients ────────────────────────────────────────────────────────

  Stream<List<AssignedPatientModel>> assignedPatientsStream(
      String caregiverId) {
    return _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('assigned_patients')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) =>
            s.docs.map(AssignedPatientModel.fromFirestore).toList());
  }

  /// Link a patient by entering their 5-digit access code.
  /// Looks up the patient, then atomically adds to assigned_patients
  /// and writes caregiverId onto the patient document.
  /// Returns null on success, or an error message string.
  Future<String?> linkPatientByCode(
      String caregiverId, String accessCode) async {
    final code = accessCode.trim().toUpperCase();
    if (code.isEmpty) return 'Please enter an access code';

    // Find patient by accessCode
    final snap = await _db
        .collection('patients')
        .where('accessCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return 'No patient found with that code. Check the code and try again.';
    }

    final patientDoc = snap.docs.first;
    final data = patientDoc.data();
    final patientId = patientDoc.id;

    // Check not already linked
    final existingRef = _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('assigned_patients')
        .doc(patientId);

    final existing = await existingRef.get();
    if (existing.exists && (existing.data()?['isActive'] == true)) {
      return 'You are already linked to this patient.';
    }

    // Atomic handshake: add to assigned_patients + update patient doc
    try {
      await _db.runTransaction((txn) async {
        txn.set(existingRef, {
          'patientId': patientId,
          'patientName': data['name'] as String? ?? 'Patient',
          'managerId': data['managerId'] as String? ?? '',
          'accessCode': code,
          'connectedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        txn.update(patientDoc.reference, {
          'caregiverId': caregiverId,
          // Add the caregiver/family member to the access list
          'accessList': FieldValue.arrayUnion([caregiverId]),
        });
      });
      return null; // success
    } catch (e) {
      return 'Failed to link patient: ${e.toString()}';
    }
  }

  /// Live patient document — used for SOS flag, vitals, overdue status
  Stream<Map<String, dynamic>?> patientLiveDataStream(String patientId) {
    return _db
        .collection('patients')
        .doc(patientId)
        .snapshots()
        .map((s) => s.exists ? s.data() : null);
  }

  /// Read-only medications stream for assigned patient
  Stream<List<MedicationModel>> patientMedicationsStream(String patientId) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(MedicationModel.fromFirestore).toList());
  }

  /// Today's dose logs for overdue calculation
  Stream<List<String>> todayTakenKeysStream(String patientId) {
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('patients')
        .doc(patientId)
        .collection('dose_logs')
        .where('takenAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('takenAt', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.docs
            .map((d) {
              final data = d.data();
              final medId = data['medId'] as String? ?? '';
              final time = data['scheduledTime'] as String? ?? '';
              return '${medId}_$time';
            })
            .toList());
  }

  // ─── Care Logs (Caregiver can Write) ─────────────────────────────────────────

  Stream<List<CareLogModel>> careLogsStream(
      String caregiverId, String patientId) {
    return _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('care_logs')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(CareLogModel.fromFirestore).toList());
  }

  Future<void> addCareLog(String caregiverId, CareLogModel log) async {
    await _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('care_logs')
        .add(log.toFirestore());
  }

  /// Fetch all care logs for a patient across all dates (for PDF export)
  Future<List<CareLogModel>> careLogsForPdf(
      String caregiverId, String patientId, DateTime since) async {
    final snap = await _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('care_logs')
        .where('patientId', isEqualTo: patientId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map(CareLogModel.fromFirestore).toList();
  }

  // ─── Deal Requests ────────────────────────────────────────────────────────────

  Stream<List<DealRequestModel>> dealRequestsStream(String caregiverId) {
    return _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('deal_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DealRequestModel.fromFirestore).toList());
  }

  /// Handshake: Accept deal — atomic transaction
  ///   1. Mark request → accepted
  ///   2. Add to assigned_patients sub-collection
  ///   3. Write caregiverId onto patient document
  Future<void> acceptDeal(
      String caregiverId, DealRequestModel request) async {
    await _db.runTransaction((txn) async {
      final reqRef = _db
          .collection('caregivers')
          .doc(caregiverId)
          .collection('deal_requests')
          .doc(request.id);

      final assignedRef = _db
          .collection('caregivers')
          .doc(caregiverId)
          .collection('assigned_patients')
          .doc(request.patientId);

      final patientRef =
          _db.collection('patients').doc(request.patientId);

      txn.update(reqRef, {'status': DealStatus.accepted.name});

      txn.set(assignedRef, {
        'patientId': request.patientId,
        'patientName': request.patientName,
        'managerId': request.managerId,
        'accessCode': request.accessCode,
        'connectedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      txn.update(patientRef, {
        'caregiverId': caregiverId,
        'accessList': FieldValue.arrayUnion([caregiverId]),
      });
    });
  }

  Future<void> rejectDeal(
      String caregiverId, String requestId) async {
    await _db
        .collection('caregivers')
        .doc(caregiverId)
        .collection('deal_requests')
        .doc(requestId)
        .update({'status': DealStatus.rejected.name});
  }

  /// Revoke access — patient disconnects or caregiver removes patient
  Future<void> revokeAccess(
      String caregiverId, String patientId) async {
    await _db.runTransaction((txn) async {
      final assignedRef = _db
          .collection('caregivers')
          .doc(caregiverId)
          .collection('assigned_patients')
          .doc(patientId);

      final patientRef =
          _db.collection('patients').doc(patientId);

      txn.update(assignedRef, {'isActive': false});
      txn.update(patientRef, {
        'caregiverId': FieldValue.delete(),
        'accessList': FieldValue.arrayRemove([caregiverId]),
      });
    });
  }

  Future<void> triggerSos(String patientId) async {
    await _db.collection('patients').doc(patientId).update({
      'isSosActive': true,
      'sosTriggerTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearSos(String patientId) async {
    await _db.collection('patients').doc(patientId).update({
      'isSosActive': false,
    });
  }
}
