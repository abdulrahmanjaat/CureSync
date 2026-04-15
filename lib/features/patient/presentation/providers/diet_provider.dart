import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/diet_log_model.dart';
import '../../data/repositories/diet_repository.dart';

final dietRepositoryProvider = Provider<DietRepository>((ref) {
  return DietRepository();
});

final todayDietLogProvider =
    StreamProvider.autoDispose.family<DietLogModel?, String>((ref, patientId) {
  return ref.watch(dietRepositoryProvider).todayStream(patientId);
});
