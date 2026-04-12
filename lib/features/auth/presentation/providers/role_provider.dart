import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hard-separated roles — each maps to a distinct UI and permission set.
enum UserRole { patient, family, proCaegiver, manager }

extension UserRoleX on UserRole {
  String get firestoreValue => switch (this) {
        UserRole.patient => 'patient',
        UserRole.family => 'family',
        UserRole.proCaegiver => 'pro_caregiver',
        UserRole.manager => 'manager',
      };

  static UserRole? fromString(String? v) => switch (v) {
        'patient' => UserRole.patient,
        'family' => UserRole.family,
        'pro_caregiver' => UserRole.proCaegiver,
        'manager' => UserRole.manager,
        _ => null,
      };
}

class RoleNotifier extends StateNotifier<UserRole?> {
  RoleNotifier() : super(null);

  void selectRole(UserRole role) => state = role;
  void clear() => state = null;
}

final roleProvider =
    StateNotifierProvider<RoleNotifier, UserRole?>((ref) => RoleNotifier());
