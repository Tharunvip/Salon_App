import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'firebase_service.dart';
import 'language_provider.dart';
import 'l10n/app_localizations.dart';
import 'pages/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme_provider.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  final notif = message.notification;
  if (notif != null) {
    await NotificationService().showPush(title: notif.title ?? '', body: notif.body ?? '');
  } else if (data['title'] != null) {
    await NotificationService().showPush(
      title: data['title'].toString(),
      body: data['body']?.toString() ?? '',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
      );
    } catch (e) {
      debugPrint('[AppCheck] activation failed (non-fatal): $e');
    }
  }

  if (!kDebugMode) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final notificationService = NotificationService();
  await notificationService.init();

  final langProvider = LanguageProvider();
  await langProvider.loadSavedLanguage();

  if (!kIsWeb) {
    try {
      await _setupPushMessaging();
    } catch (e) {
      debugPrint('[FCM] setup failed (non-fatal): $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: langProvider),
        Provider<FirebaseAnalytics>(create: (_) => FirebaseAnalytics.instance),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _setupPushMessaging() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notif = message.notification;
    NotificationService().showPush(
      title: notif?.title ?? message.data['title']?.toString() ?? 'Notification',
      body: notif?.body ?? message.data['body']?.toString() ?? '',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final notif = message.notification;
    if (notif != null) {
      NotificationService().showPush(title: notif.title ?? '', body: notif.body ?? '');
    }
  });

  messaging.onTokenRefresh.listen((token) {
    FirebaseService().updateFcmToken(token);
  });

  final svc = FirebaseService();
  await svc.refreshFcmToken();
  FirebaseAuth.instance.authStateChanges().listen((u) {
    if (u != null) svc.refreshFcmToken();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (c, tp, lp, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VIP Barber',
        theme: tp.lightTheme,
        darkTheme: tp.darkTheme,
        themeMode: tp.mode,
        locale: lp.locale,
        supportedLocales: LanguageProvider.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SplashScreen(),
      ),
    );
  }
}
