import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/patient_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

/// Real-time stream of all patient profiles for the current user
final patientsStreamProvider = StreamProvider<List<PatientModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(patientRepositoryProvider).patientsStream(user.uid);
});
