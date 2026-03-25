import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/medication_model.dart';
import '../../data/repositories/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

final medicationsStreamProvider =
    StreamProvider.family<List<MedicationModel>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).medicationsStream(patientId);
});
