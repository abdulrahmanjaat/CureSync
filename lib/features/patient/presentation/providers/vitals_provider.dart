import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vitals_model.dart';
import '../../data/repositories/vitals_repository.dart';

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository();
});

final latestVitalsProvider =
    StreamProvider.autoDispose.family<VitalsModel?, String>((ref, patientId) {
  return ref.watch(vitalsRepositoryProvider).latestVitalsStream(patientId);
});
