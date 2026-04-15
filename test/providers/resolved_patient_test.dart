// ignore_for_file: avoid_manual_providers_as_generated_provider_dependency

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cure_sync/features/auth/data/models/user_model.dart';
import 'package:cure_sync/features/auth/presentation/providers/auth_provider.dart';
import 'package:cure_sync/features/patient/presentation/providers/active_patient_provider.dart';
import 'package:cure_sync/features/patient/presentation/providers/medication_provider.dart';
import 'package:cure_sync/features/patient/presentation/providers/patient_provider.dart';

import '../helpers/fakes.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 1 — resolvedActivePatientIdProvider is locked to the patient's own
  //          UID regardless of any stale manager selection in state.
  // ═══════════════════════════════════════════════════════════════════════════
  group('resolvedActivePatientIdProvider', () {
    test(
        'returns the patient\'s own uid for patient role, '
        'ignoring any stale manager selection', () async {
      // Arrange ----------------------------------------------------------------
      final patientUser = MockFirebaseUser('patient-uid-123');

      final container = ProviderContainer(
        overrides: [
          // Signed-in user is "patient-uid-123"
          authStateProvider.overrideWith(
            (_) => Stream.value(patientUser),
          ),
          // Their Firestore document says role = 'patient'
          currentUserDataProvider.overrideWith(
            (_) => Stream.value(UserModel(
              uid: 'patient-uid-123',
              name: 'Test Patient',
              email: 'patient@test.com',
              role: 'patient',
              createdAt: DateTime(2024),
            )),
          ),
          // No managed patients in the list
          patientsStreamProvider.overrideWith(
            (_) => Stream.value([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for both async providers to emit their first values
      await container.read(authStateProvider.future);
      await container.read(currentUserDataProvider.future);

      // Simulate a stale manager session: some other patient was selected before
      // this patient-role user logged in (the bug we fixed in C1).
      container.read(activePatientIdProvider.notifier).state =
          'stale-manager-selected-patient-xyz';

      // Act -------------------------------------------------------------------
      final resolved = container.read(resolvedActivePatientIdProvider);

      // Assert ----------------------------------------------------------------
      expect(
        resolved,
        equals('patient-uid-123'),
        reason: 'Patient role must always resolve to their own uid',
      );
      expect(
        resolved,
        isNot(equals('stale-manager-selected-patient-xyz')),
        reason: 'Stale manager selection must never leak into a patient session',
      );
    });

    test(
        'returns the explicitly selected patient for manager role', () async {
      // Arrange ----------------------------------------------------------------
      final managerUser = MockFirebaseUser('manager-uid-456');

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (_) => Stream.value(managerUser),
          ),
          currentUserDataProvider.overrideWith(
            (_) => Stream.value(UserModel(
              uid: 'manager-uid-456',
              name: 'Test Manager',
              email: 'manager@test.com',
              role: 'manager',
              createdAt: DateTime(2024),
            )),
          ),
          patientsStreamProvider.overrideWith(
            (_) => Stream.value([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(currentUserDataProvider.future);

      // Manager selects a patient from their list
      container.read(activePatientIdProvider.notifier).state =
          'manager-chosen-patient-abc';

      // Act -------------------------------------------------------------------
      final resolved = container.read(resolvedActivePatientIdProvider);

      // Assert ----------------------------------------------------------------
      expect(
        resolved,
        equals('manager-chosen-patient-abc'),
        reason: 'Manager role must respect the explicit patient selection',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 2 — activePatientIdProvider resets to null whenever the authenticated
  //          user changes (logout / account switch).
  // ═══════════════════════════════════════════════════════════════════════════
  group('activePatientIdProvider', () {
    test(
        'resets to null when a different user signs in, '
        'clearing any previous patient selection', () async {
      // Arrange ----------------------------------------------------------------
      final authStreamController = StreamController<MockFirebaseUser?>();
      addTearDown(authStreamController.close);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (_) => authStreamController.stream,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Listen to activePatientIdProvider so Riverpod keeps it alive and
      // re-evaluates it when its authState dependency changes.
      final subscription = container.listen(
        activePatientIdProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      // User A (manager) signs in
      authStreamController.add(MockFirebaseUser('manager-uid'));
      // Allow the stream event and Riverpod dependency graph to update
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Manager selects a patient — simulates the C1 leak scenario
      container.read(activePatientIdProvider.notifier).state =
          'selected-patient-abc';
      expect(
        container.read(activePatientIdProvider),
        equals('selected-patient-abc'),
        reason: 'Selection should be set correctly before the auth change',
      );

      // User B signs in (a patient-role user on the same device)
      authStreamController.add(MockFirebaseUser('patient-uid-999'));
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Act + Assert ----------------------------------------------------------
      expect(
        container.read(activePatientIdProvider),
        isNull,
        reason:
            'activePatientIdProvider must reset to null after a user change '
            'so user B never sees user A\'s patient selection',
      );
    });

    test('initialises to null for a freshly signed-in user', () async {
      // Arrange ----------------------------------------------------------------
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (_) => Stream.value(MockFirebaseUser('any-uid')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      // Act + Assert ----------------------------------------------------------
      expect(
        container.read(activePatientIdProvider),
        isNull,
        reason: 'Initial state must be null — no patient pre-selected',
      );
    });
  });
}
