import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Streams the full ProfileImage record (avatarIndex + localImagePath)
/// for the currently signed-in user.
///
/// Consumed by both [ProfileScreen] (edit UI) and [HomeScreen] (avatar chip)
/// so changes on the profile page instantly reflect on the dashboard without
/// any hot-reload or route-push trickery.
final profileImageRecordProvider =
    StreamProvider.autoDispose<ProfileImage?>((ref) {
  final db   = ref.watch(appDatabaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final data = ref.watch(currentUserDataProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return db.watchProfileImage(user.uid, data?.role ?? 'patient');
});
