import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Schedule a daily recurring notification at [hour]:[minute]
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medications',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF0D9488),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule all reminders for a medication
  static Future<void> scheduleMedicationReminders({
    required String medId,
    required String medName,
    required String dosage,
    required List<String> times,
  }) async {
    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Use hash of medId + index as notification ID
      final notifId = (medId.hashCode + i) & 0x7FFFFFFF;

      await scheduleDailyReminder(
        id: notifId,
        title: 'Time for $medName',
        body: 'Take $dosage of $medName',
        hour: hour,
        minute: minute,
      );
    }
  }

  /// Cancel all notifications for a medication
  static Future<void> cancelMedicationReminders({
    required String medId,
    required int timeCount,
  }) async {
    for (int i = 0; i < timeCount; i++) {
      final notifId = (medId.hashCode + i) & 0x7FFFFFFF;
      await _plugin.cancel(notifId);
    }
  }
}
