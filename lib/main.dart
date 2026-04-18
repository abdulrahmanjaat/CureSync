import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/preferences_service.dart';
import 'core/utils/snackbar_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

// ─── FCM background handler ───────────────────────────────────────────────────
// Must be registered before runApp() and must be a top-level function.
// The annotation ensures it survives tree-shaking in release builds.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) =>
    firebaseMessagingBackgroundHandler(message);

// ─── App-wide navigator key ───────────────────────────────────────────────────
// Shared with FcmService so tap-on-notification can navigate without a
// BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background handler BEFORE runApp.
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Give FcmService access to the navigator for tap-on-notification routing.
  FcmService.navigatorKey = appNavigatorKey;

  // Enable Firestore offline persistence.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Init SharedPreferences (non-blocking).
  await PreferencesService.init();

  // Init local notification channels and timezone data.
  await NotificationService.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:         Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: CureSyncApp()));
}

class CureSyncApp extends ConsumerWidget {
  const CureSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // ── FCM init: fires whenever auth state changes ───────────────────────────
    // Uses ref.listen so it runs as a side-effect, not during build.
    ref.listen(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      if (user != null) {
        FcmService.init(uid: user.uid).catchError(
          (e) => debugPrint('[FCM] init error: $e'),
        );
      }
    });

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title:                    'CureSync',
          debugShowCheckedModeBanner: false,
          theme:                    AppTheme.lightTheme,
          routerConfig:             router,
          scaffoldMessengerKey:     SnackbarService.messengerKey,
        );
      },
    );
  }
}
