import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_sweet_home/core/notifications/exact_alarm_permission_port.dart';

/// Real adapter for exact alarm permission (Android 12+ / 14+) (RN-423, CA-4.5).
class ExactAlarmPermissionAdapter implements ExactAlarmPermissionPort {
  final FlutterLocalNotificationsPlugin? plugin;
  final MethodChannel channel;

  ExactAlarmPermissionAdapter({
    this.plugin,
    this.channel = const MethodChannel(
      'br.com.innominata.mysweethome/exact_alarm',
    ),
  });

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;

    try {
      if (plugin != null) {
        final androidPlugin = plugin!
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final canSchedule = await androidPlugin
              .canScheduleExactNotifications();
          if (canSchedule != null) return canSchedule;
        }
      }
      final result = await channel.invokeMethod<bool>('canScheduleExact');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> openSettings() async {
    if (!Platform.isAndroid) return;

    try {
      if (plugin != null) {
        final androidPlugin = plugin!
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          await androidPlugin.requestExactAlarmsPermission();
          return;
        }
      }
      await channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {
      // Ignore failures when opening platform settings
    }
  }
}
