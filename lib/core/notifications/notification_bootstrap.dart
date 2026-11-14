import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const MethodChannel _timezoneChannel = MethodChannel(
  'br.com.innominata.mysweethome/timezone',
);

/// Initializes timezone data, configures `tz.local`, and initializes the local
/// notifications plugin safely.
Future<void> initializeLocalNotifications(
  FlutterLocalNotificationsPlugin plugin, {
  Future<String?> Function()? timezoneLoader,
  void Function(NotificationResponse)? onNotificationTap,
  Clock clock = const SystemClock(),
}) async {
  try {
    tz_data.initializeTimeZones();
    await _configureLocalTimezone(timezoneLoader: timezoneLoader, clock: clock);
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
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  } catch (_) {}
}

Future<void> _configureLocalTimezone({
  Future<String?> Function()? timezoneLoader,
  required Clock clock,
}) async {
  String? tzName;
  try {
    tzName =
        await (timezoneLoader?.call() ??
            _timezoneChannel.invokeMethod<String>('getLocalTimezone'));
  } catch (_) {
    tzName = null;
  }

  if (tzName != null &&
      tzName.isNotEmpty &&
      tz.timeZoneDatabase.locations.containsKey(tzName)) {
    tz.setLocalLocation(tz.getLocation(tzName));
    return;
  }

  final offsetMs = clock.nowLocal().timeZoneOffset.inMilliseconds;
  for (final location in tz.timeZoneDatabase.locations.values) {
    if (location.currentTimeZone.offset == offsetMs) {
      tz.setLocalLocation(location);
      return;
    }
  }
}
