import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/water_log_model.dart';
import '../../data/repositories/water_tracker_repository.dart';

final waterTrackerRepositoryProvider = Provider<WaterTrackerRepository>((ref) {
  return WaterTrackerRepository();
});

final todayWaterLogProvider =
    StreamProvider.autoDispose.family<WaterLogModel?, String>((ref, patientId) {
  return ref.watch(waterTrackerRepositoryProvider).todayStream(patientId);
});
