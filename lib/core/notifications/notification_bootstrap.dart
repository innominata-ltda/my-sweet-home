import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Initializes timezone data and the local notifications plugin safely.
Future<void> initializeLocalNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  try {
    tz_data.initializeTimeZones();
  } catch (_) {}

  try {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await plugin.initialize(settings: settings);
  } catch (_) {}
}
