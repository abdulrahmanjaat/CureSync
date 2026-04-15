import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sleep_log_model.dart';
import '../../data/repositories/sleep_repository.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepository();
});

final todaySleepLogProvider =
    StreamProvider.autoDispose.family<SleepLogModel?, String>((ref, patientId) {
  return ref.watch(sleepRepositoryProvider).todayStream(patientId);
});
