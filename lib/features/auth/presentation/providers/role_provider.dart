import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { patient, caregiver }

class RoleNotifier extends StateNotifier<UserRole?> {
  RoleNotifier() : super(null);

  void selectRole(UserRole role) => state = role;

  void clear() => state = null;
}

final roleProvider = StateNotifierProvider<RoleNotifier, UserRole?>((ref) {
  return RoleNotifier();
});
