import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _onDidReceiveBackgroundNotificationResponse(NotificationResponse details) async {}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
      );

      const androidChannel = AndroidNotificationChannel(
        'salon_reminders',
        'Appointment Reminders',
        description: 'Reminders for upcoming appointments',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Stable, collision-resistant notification id derived from a booking doc id.
  static int notificationIdForBooking(String bookingId) {
    var hash = 0x811c9dc5;
    for (final unit in bookingId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> scheduleAppointmentReminder({
    required String bookingId,
    required String shopName,
    required String serviceName,
    required DateTime appointmentDateTime,
  }) async {
    if (kIsWeb) return;
    await init();
    final reminderTime = appointmentDateTime.subtract(const Duration(minutes: 30));
    if (reminderTime.isBefore(DateTime.now())) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'salon_reminders',
        'Appointment Reminders',
        channelDescription: 'Reminders for upcoming appointments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    final tzScheduled = tz.TZDateTime.from(reminderTime, tz.local);
    final id = notificationIdForBooking(bookingId);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Appointment Reminder',
      body: 'Your appointment at $shopName ($serviceName) starts in 30 minutes. Please start heading to the shop to arrive on time.',
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String bookingId) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: notificationIdForBooking(bookingId));
  }

  /// Shows a push notification received while the app is in the foreground.
  Future<void> showPush({
    required String title,
    required String body,
    String? channelId,
  }) async {
    if (kIsWeb) return;
    await init();
    final ch = channelId ?? 'salon_push';
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          ch,
          'Push Notifications',
          description: 'Booking and queue notifications',
          importance: Importance.high,
        ));
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ch,
          'Push Notifications',
          channelDescription: 'Booking and queue notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
