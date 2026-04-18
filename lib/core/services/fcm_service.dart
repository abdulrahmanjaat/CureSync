import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

// ─── Top-level background handler ────────────────────────────────────────────
// Must be a top-level function (not a class method) — required by FCM.
// Registered via FirebaseMessaging.onBackgroundMessage() in main.dart BEFORE
// runApp().

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs.
  // Show a local notification so the user sees it while the app is in the
  // background or terminated state.
  await NotificationService.init();
  await _showFcmLocalNotification(message);
}

// ─── Helper: display an FCM payload as a local heads-up notification ─────────

Future<void> _showFcmLocalNotification(RemoteMessage message) async {
  final n = message.notification;
  if (n == null) return;

  final type = message.data['type'] as String? ?? '';

  // Choose channel and importance based on message type.
  final bool isSos      = type == 'sos';
  final bool isOverdue  = type == 'overdue';

  final channelId   = isSos     ? 'medication_sos'
                    : isOverdue ? 'medication_overdue'
                                : 'medication_reminders';
  final channelName = isSos     ? 'SOS Medication Alerts'
                    : isOverdue ? 'Overdue Medication Alerts'
                                : 'Medication Reminders';
  final importance  = isSos     ? Importance.max
                    : isOverdue ? Importance.high
                                : Importance.high;
  final priority    = isSos     ? Priority.max : Priority.high;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.show(
    message.hashCode & 0x7FFFFFFF,
    n.title,
    n.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance:       importance,
        priority:         priority,
        fullScreenIntent: isSos,
        playSound:        true,
        enableVibration:  true,
      ),
    ),
    payload: _buildPayload(message.data),
  );
}

String _buildPayload(Map<String, dynamic> data) =>
    '${data['type'] ?? ''}|${data['patientId'] ?? ''}|${data['route'] ?? ''}';

// ─── Service class ────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;

  /// A nullable navigator key that the app must set before calling [init].
  /// Used so FCM tap handlers can navigate without a BuildContext.
  ///
  /// Set this in main.dart:
  /// ```dart
  /// FcmService.navigatorKey = myNavigatorKey;
  /// ```
  static GlobalKey<NavigatorState>? navigatorKey;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Call once after auth resolves, passing the signed-in user's UID.
  /// Safe to call again on re-auth — idempotent token save.
  static Future<void> init({required String uid}) async {
    // 1. Request permission (required on iOS and Android 13+).
    final settings = await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied — no push notifications.');
      return;
    }

    // 2. Retrieve & persist current token.
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);

    // 3. Refresh listener — keeps Firestore up-to-date if the token rotates.
    _messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));

    // 4. Foreground message handler.
    //    FCM does NOT show a heads-up notification when the app is open, so
    //    we display one ourselves via the local-notification plugin.
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[FCM foreground] ${message.notification?.title}');
      await _showFcmLocalNotification(message);
    });

    // 5. App opened by tapping a notification (background → foreground).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM tapped] ${message.data}');
      _handleTap(message.data);
    });

    // 6. App launched from terminated state by a notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM launch] ${initial.data}');
      // Delay navigation until the widget tree is ready.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleTap(initial.data);
      });
    }
  }

  // ─── Tap navigation ────────────────────────────────────────────────────────

  static void _handleTap(Map<String, dynamic> data) {
    final nav   = navigatorKey?.currentState;
    if (nav == null) return;

    final type      = data['type'] as String? ?? '';
    final patientId = data['patientId'] as String? ?? '';
    final route     = data['route'] as String?;

    // If the backend supplied an explicit route, use it directly.
    if (route != null && route.isNotEmpty) {
      nav.pushNamed(route);
      return;
    }

    // Otherwise derive the destination from the message type.
    switch (type) {
      case 'dose_reminder':
      case 'overdue':
      case 'sos':
        // Patient tapped a dose alert → open their home/notification screen.
        nav.pushNamed('/notifications');
      case 'manager_missed':
        nav.pushNamed('/manager/notifications');
      case 'family_alert':
        nav.pushNamed('/family/notifications');
      case 'caregiver_alert':
        if (patientId.isNotEmpty) {
          nav.pushNamed('/caregiver/patient/$patientId');
        }
      default:
        // Fallback: go to notifications for the current role.
        nav.pushNamed('/notifications');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
    debugPrint('[FCM] Token saved for $uid');
  }

  /// Remove the FCM token from Firestore on sign-out so the device no longer
  /// receives push notifications for this user.
  static Future<void> clearToken(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': FieldValue.delete()});
    await _messaging.deleteToken();
    debugPrint('[FCM] Token cleared for $uid');
  }
}
