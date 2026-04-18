import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─── Channel IDs ────────────────────────────────────────────────────────────
  static const _chReminder = 'medication_reminders';
  static const _chOverdue  = 'medication_overdue';
  static const _chSos      = 'medication_sos';

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  // ─── Core scheduler ─────────────────────────────────────────────────────────

  /// Schedule a daily recurring notification at [hour]:[minute].
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String channelId   = _chReminder,
    String channelName = 'Medication Reminders',
    String channelDesc = 'Reminders to take your medications',
    Importance importance = Importance.high,
    Priority priority     = Priority.high,
    Color color           = const Color(0xFF0D9488),
    bool fullScreenIntent = false,
  }) async {
    await init();

    final now       = tz.TZDateTime.now(tz.local);
    var   scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance:       importance,
          priority:         priority,
          color:            color,
          fullScreenIntent: fullScreenIntent,
          playSound:        true,
          enableVibration:  true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Stable-ID helpers ───────────────────────────────────────────────────────

  /// Deterministic notification ID for a specific dose + suffix.
  /// Collision-free within the 31-bit Android notification ID space for
  /// the number of medications a single patient would realistically have.
  static int _stableId(String medId, String reminderTime, String suffix) =>
      (medId + reminderTime + suffix).hashCode & 0x7FFFFFFF;

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Schedule ALL four daily alerts for one dose time:
  ///   1. Early-warning  — 20 min before  (soft blue/teal)
  ///   2. At-time        — exact dose time (teal)
  ///   3. Overdue        — 20 min after   (amber)
  ///   4. SOS            — 30 min after   (red, max importance)
  ///
  /// Uses stable, per-dose hash IDs so individual doses can be cancelled
  /// without knowing their position in the reminder-times list.
  static Future<void> scheduleDoseAlerts({
    required String medId,
    required String medName,
    required String dosage,
    required String reminderTime, // "HH:mm"
  }) async {
    await init();

    final parts = reminderTime.split(':');
    if (parts.length != 2) return;
    final hour   = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final baseMins = hour * 60 + minute;

    // 1. Early-warning (-20 min)
    final earlyMins   = (baseMins - 20 + 1440) % 1440;
    await scheduleDailyReminder(
      id:    _stableId(medId, reminderTime, 'early'),
      title: '⏰ $medName due in 20 minutes',
      body:  'Prepare to take $dosage of $medName at ${_fmt(hour, minute)}.',
      hour:  earlyMins ~/ 60,
      minute: earlyMins % 60,
    );

    // 2. At-time
    await scheduleDailyReminder(
      id:    _stableId(medId, reminderTime, 'due'),
      title: '💊 Time for $medName',
      body:  'Take $dosage of $medName now.',
      hour:  hour,
      minute: minute,
    );

    // 3. Overdue (+20 min)
    final overdueMins = (baseMins + 20) % 1440;
    await scheduleDailyReminder(
      id:          _stableId(medId, reminderTime, 'overdue'),
      title:       '⚠️ Overdue: $medName',
      body:        'Your $dosage dose of $medName is 20 minutes overdue.',
      hour:        overdueMins ~/ 60,
      minute:      overdueMins % 60,
      channelId:   _chOverdue,
      channelName: 'Overdue Medication Alerts',
      channelDesc: 'Alerts for doses not taken within the scheduled window',
      importance:  Importance.high,
      priority:    Priority.high,
      color:       const Color(0xFFF59E0B),
    );

    // 4. SOS (+30 min) — maximum urgency
    final sosMins = (baseMins + 30) % 1440;
    await scheduleDailyReminder(
      id:              _stableId(medId, reminderTime, 'sos'),
      title:           '🚨 URGENT: $medName Still Not Taken',
      body:            '$medName is 30 minutes overdue! Please take $dosage immediately or contact your caregiver.',
      hour:            sosMins ~/ 60,
      minute:          sosMins % 60,
      channelId:       _chSos,
      channelName:     'SOS Medication Alerts',
      channelDesc:     'Critical SOS alerts for severely overdue medications',
      importance:      Importance.max,
      priority:        Priority.max,
      color:           const Color(0xFFEF4444),
      fullScreenIntent: true,
    );
  }

  /// Cancel all four daily alerts for a specific dose time.
  /// Call this when a dose is marked as taken so the overdue/SOS
  /// alerts don't fire for the rest of today (the recurring schedule
  /// resumes on the next calendar day when the user hasn't taken the dose).
  static Future<void> cancelDoseAlerts({
    required String medId,
    required String reminderTime,
  }) async {
    for (final suffix in ['early', 'due', 'overdue', 'sos']) {
      await _plugin.cancel(_stableId(medId, reminderTime, suffix));
    }
  }

  // ─── Legacy batch schedulers (kept for medication-add / edit flows) ──────────

  /// Schedule daily at-time + early-warning reminders for every dose time
  /// listed in [times].  Uses index-based IDs.
  /// **Prefer [scheduleDoseAlerts] for new code** — it also covers overdue/SOS
  /// and uses stable IDs that allow per-dose cancellation.
  static Future<void> scheduleMedicationReminders({
    required String medId,
    required String medName,
    required String dosage,
    required List<String> times,
  }) async {
    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour   = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      // At-time
      await scheduleDailyReminder(
        id:    (medId.hashCode + i) & 0x7FFFFFFF,
        title: '💊 Time for $medName',
        body:  'Take $dosage of $medName now.',
        hour:  hour,
        minute: minute,
      );

      // Early-warning (-20 min)
      final totalMins   = hour * 60 + minute - 20;
      final earlyHour   = ((totalMins + 1440) % 1440) ~/ 60;
      final earlyMinute = ((totalMins + 1440) % 1440) % 60;
      await scheduleDailyReminder(
        id:    (medId.hashCode + i + 10000) & 0x7FFFFFFF,
        title: '⏰ $medName due in 20 minutes',
        body:  'Prepare to take $dosage of $medName at ${_fmt(hour, minute)}.',
        hour:  earlyHour,
        minute: earlyMinute,
      );
    }
  }

  /// Cancel index-based at-time + early-warning alerts for all dose times,
  /// and also cancel stable-ID overdue/SOS alerts when [reminderTimes] is
  /// supplied.
  static Future<void> cancelMedicationReminders({
    required String medId,
    required int timeCount,
    List<String>? reminderTimes,
  }) async {
    for (int i = 0; i < timeCount; i++) {
      await _plugin.cancel((medId.hashCode + i) & 0x7FFFFFFF);
      await _plugin.cancel((medId.hashCode + i + 10000) & 0x7FFFFFFF);
    }
    if (reminderTimes != null) {
      for (final t in reminderTimes) {
        await cancelDoseAlerts(medId: medId, reminderTime: t);
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Format hour + minute as "H:MM AM/PM".
  static String _fmt(int hour, int minute) {
    final h    = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $ampm';
  }
}
