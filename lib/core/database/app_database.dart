import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

/// Cached medication schedules — synced from Firestore when online.
class CachedMedications extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text()();
  TextColumn get frequency => text()();
  TextColumn get reminderTime => text()(); // "HH:mm"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Locally queued dose logs — written offline, synced when back online.
class PendingDoseLogs extends Table {
  IntColumn get localId =>
      integer().autoIncrement()();
  TextColumn get patientId => text()();
  TextColumn get medId => text()();
  TextColumn get medName => text()();
  TextColumn get scheduledTime => text()(); // "HH:mm"
  DateTimeColumn get takenAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

/// Cached vitals snapshot — latest entry per patient.
class CachedVitals extends Table {
  TextColumn get patientId => text()();
  RealColumn get heartRate => real().nullable()();
  RealColumn get bloodPressureSystolic => real().nullable()();
  RealColumn get bloodPressureDiastolic => real().nullable()();
  RealColumn get oxygenSaturation => real().nullable()();
  RealColumn get temperature => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {patientId};
}

/// Per-user, per-role avatar selection and local image path.
/// avatarIndex: fallback icon index (0-7) when no photo chosen.
/// localImagePath: absolute path to a photo picked from gallery/camera.
///   When set, the image file is shown in the UI instead of the icon avatar.
class ProfileImages extends Table {
  TextColumn get uid => text()();
  TextColumn get role => text()(); // 'patient', 'family', 'pro_caregiver', 'manager'
  IntColumn get avatarIndex =>
      integer().withDefault(const Constant(0))();
  TextColumn get localImagePath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid, role};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
    tables: [CachedMedications, PendingDoseLogs, CachedVitals, ProfileImages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v2: create ProfileImages table
          if (from < 2) await m.createAll();
          // v2 → v3: add localImagePath column to ProfileImages
          if (from < 3) {
            await customStatement(
              'ALTER TABLE profile_images ADD COLUMN local_image_path TEXT;',
            );
          }
        },
      );

  // ── Medications ──────────────────────────────────────────────────────────────

  Stream<List<CachedMedication>> watchMedications(String patientId) {
    return (select(cachedMedications)
          ..where((t) =>
              t.patientId.equals(patientId) & t.isActive.equals(true)))
        .watch();
  }

  Future<void> upsertMedication(CachedMedicationsCompanion entry) async {
    await into(cachedMedications).insertOnConflictUpdate(entry);
  }

  Future<void> deleteMedication(String id) async {
    await (delete(cachedMedications)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Pending Dose Logs ─────────────────────────────────────────────────────────

  Future<int> queueDoseLog(PendingDoseLogsCompanion entry) {
    return into(pendingDoseLogs).insert(entry);
  }

  Stream<List<PendingDoseLog>> watchUnsynced() {
    return (select(pendingDoseLogs)
          ..where((t) => t.synced.equals(false)))
        .watch();
  }

  Future<void> markSynced(int localId) async {
    await (update(pendingDoseLogs)
          ..where((t) => t.localId.equals(localId)))
        .write(const PendingDoseLogsCompanion(synced: Value(true)));
  }

  // ── Vitals ────────────────────────────────────────────────────────────────────

  Future<void> upsertVitals(CachedVitalsCompanion entry) async {
    await into(cachedVitals).insertOnConflictUpdate(entry);
  }

  Future<CachedVital?> getVitals(String patientId) {
    return (select(cachedVitals)
          ..where((t) => t.patientId.equals(patientId)))
        .getSingleOrNull();
  }

  // ── Profile Images ────────────────────────────────────────────────────────────

  /// Streams the avatar index for a specific user+role combination.
  Stream<ProfileImage?> watchProfileImage(String uid, String role) {
    return (select(profileImages)
          ..where((t) => t.uid.equals(uid) & t.role.equals(role)))
        .watchSingleOrNull();
  }

  Future<void> upsertProfileImage(
      String uid, String role, int avatarIndex) async {
    await into(profileImages).insertOnConflictUpdate(
      ProfileImagesCompanion(
        uid: Value(uid),
        role: Value(role),
        avatarIndex: Value(avatarIndex),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// ─── Connection ───────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'curesync.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
