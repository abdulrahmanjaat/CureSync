import 'package:flutter_test/flutter_test.dart';

import 'package:cure_sync/features/auth/presentation/providers/role_provider.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 3 — /patient/:id/add-med role guard.
  //
  // The router redirect (app_router.dart) uses the expression:
  //   role != UserRole.patient && role != UserRole.manager
  // to decide whether to block a request to any path ending in '/add-med'.
  //
  // These tests lock down:
  //   1. Which Firestore role strings map to which enum values.
  //   2. That the guard expression blocks exactly the right roles.
  //   3. That no future rename of the enum silently breaks either mapping.
  // ═══════════════════════════════════════════════════════════════════════════
  group('add-med route guard — role serialisation', () {
    // ── Firestore string → enum mapping ─────────────────────────────────────
    test('fromString maps every known role string correctly', () {
      expect(UserRoleX.fromString('patient'), equals(UserRole.patient));
      expect(UserRoleX.fromString('manager'), equals(UserRole.manager));
      expect(UserRoleX.fromString('family'), equals(UserRole.family));
      expect(UserRoleX.fromString('pro_caregiver'),
          equals(UserRole.proCaregiver));
      // Unknown / null must return null — treated as "no role" by the router
      expect(UserRoleX.fromString(null), isNull);
      expect(UserRoleX.fromString(''), isNull);
      expect(UserRoleX.fromString('unknown_role'), isNull);
    });

    // ── enum → Firestore string mapping ─────────────────────────────────────
    test('firestoreValue round-trips back through fromString', () {
      for (final role in UserRole.values) {
        final roundTripped = UserRoleX.fromString(role.firestoreValue);
        expect(
          roundTripped,
          equals(role),
          reason: 'firestoreValue for $role must round-trip via fromString',
        );
      }
    });
  });

  group('add-med route guard — access control', () {
    // The guard condition mirrored from app_router.dart:
    bool wouldBeBlocked(UserRole? role) =>
        role != UserRole.patient && role != UserRole.manager;

    // ── Roles that MUST be blocked ───────────────────────────────────────────
    test('family role is blocked from /add-med', () {
      final role = UserRoleX.fromString('family');
      expect(
        wouldBeBlocked(role),
        isTrue,
        reason: 'Family members are read-only observers '
            'and must never write medication records',
      );
    });

    test('pro_caregiver role is blocked from /add-med', () {
      final role = UserRoleX.fromString('pro_caregiver');
      expect(
        wouldBeBlocked(role),
        isTrue,
        reason: 'Pro-caregivers are read-only observers '
            'and must never write medication records',
      );
    });

    test('null role (not yet assigned) is blocked from /add-med', () {
      expect(
        wouldBeBlocked(null),
        isTrue,
        reason: 'An unauthenticated or role-less user '
            'must never reach add-med',
      );
    });

    // ── Roles that MUST be allowed ───────────────────────────────────────────
    test('patient role is allowed through to /add-med', () {
      final role = UserRoleX.fromString('patient');
      expect(
        wouldBeBlocked(role),
        isFalse,
        reason: 'Patients own their medication data and must be able to add',
      );
    });

    test('manager role is allowed through to /add-med', () {
      final role = UserRoleX.fromString('manager');
      expect(
        wouldBeBlocked(role),
        isFalse,
        reason: 'Managers create medication records for their patients',
      );
    });

    // ── Exhaustive check: every enum value is explicitly classified ──────────
    test('every UserRole value is either explicitly allowed or explicitly blocked',
        () {
      const allowed = {UserRole.patient, UserRole.manager};
      const blocked = {UserRole.family, UserRole.proCaregiver};

      // If a new role is added to the enum without updating this test,
      // the test will fail and force the developer to make an intentional
      // allow/block decision for the new role.
      final allRoles = UserRole.values.toSet();
      expect(
        allRoles,
        equals(allowed.union(blocked)),
        reason: 'A new UserRole was added without updating the add-med '
            'role guard classification. '
            'Add it to either "allowed" or "blocked" above.',
      );
    });
  });
}
