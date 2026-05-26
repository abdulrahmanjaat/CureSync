import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hard-separated roles — each maps to a distinct UI surface and permission
/// set. No role may render, query, or write data belonging to another role.
///
/// Role matrix (5-tier, final):
///   • patient       → owns own medical record
///   • manager       → administers one or more patient records
///   • proCaregiver  → professional, paid, discoverable via Discovery Hub
///   • family        → read-only observer linked via access code
///   • doctor        → clinician — writes prescriptions, manages appointments
enum UserRole { patient, family, proCaregiver, manager, doctor }

extension UserRoleX on UserRole {
  String get firestoreValue => switch (this) {
        UserRole.patient      => 'patient',
        UserRole.family       => 'family',
        UserRole.proCaregiver => 'pro_caregiver',
        UserRole.manager      => 'manager',
        UserRole.doctor       => 'doctor',
      };

  static UserRole? fromString(String? v) => switch (v) {
        'patient'       => UserRole.patient,
        'family'        => UserRole.family,
        'pro_caregiver' => UserRole.proCaregiver,
        'manager'       => UserRole.manager,
        'doctor'        => UserRole.doctor,
        _               => null,
      };
}

class RoleNotifier extends StateNotifier<UserRole?> {
  RoleNotifier() : super(null);

  void selectRole(UserRole role) => state = role;
  void clear() => state = null;
}

/// autoDispose: role selection is a transient flow — reset between sessions.
final roleProvider = StateNotifierProvider.autoDispose<RoleNotifier, UserRole?>(
  (ref) => RoleNotifier(),
);
