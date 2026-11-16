import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/notifications/adapters/exact_alarm_permission_adapter.dart';
import 'package:my_sweet_home/core/notifications/local_notification_scheduler.dart';
import 'package:my_sweet_home/core/notifications/notification_bootstrap.dart';
import 'package:my_sweet_home/core/notifications/notification_providers.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIosPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  });

  group('initializeLocalNotifications', () {
    test('initializes plugin and sets tz.local via timezoneLoader', () async {
      final plugin = _MockPlugin();
      NotificationResponse? tapped;
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);

      await initializeLocalNotifications(
        plugin,
        timezoneLoader: () async => 'America/Sao_Paulo',
        onNotificationTap: (r) => tapped = r,
      );

      expect(tz.local.name, 'America/Sao_Paulo');
      expect(tapped, isNull);
      verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('falls back to offset matching when timezoneLoader fails', () async {
      final plugin = _MockPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);

      await initializeLocalNotifications(
        plugin,
        timezoneLoader: () async => throw Exception('Channel missing'),
      );

      expect(tz.local.name, isNotEmpty);
    });

    test('degrades gracefully when plugin.initialize throws', () async {
      final plugin = _MockPlugin();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenThrow(Exception('Platform unavailable'));

      await expectLater(
        initializeLocalNotifications(plugin, timezoneLoader: () async => 'UTC'),
        completes,
      );
    });
  });

  group('LocalNotificationScheduler.requestPermission', () {
    test('requests Android notifications permission when available', () async {
      final plugin = _MockPlugin();
      final android = _MockAndroidPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(() => android.requestNotificationsPermission())
          .thenAnswer((_) async => true);

      final scheduler = LocalNotificationScheduler(plugin);
      expect(await scheduler.requestPermission(), PermissionState.granted);
    });

    test('returns denied when Android permission is declined', () async {
      final plugin = _MockPlugin();
      final android = _MockAndroidPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(() => android.requestNotificationsPermission())
          .thenAnswer((_) async => false);

      final scheduler = LocalNotificationScheduler(plugin);
      expect(await scheduler.requestPermission(), PermissionState.denied);
    });

    test('requests iOS permissions when Android plugin is absent', () async {
      final plugin = _MockPlugin();
      final ios = _MockIosPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(ios);
      when(() => ios.requestPermissions(alert: true, badge: true, sound: true))
          .thenAnswer((_) async => true);

      final scheduler = LocalNotificationScheduler(plugin);
      expect(await scheduler.requestPermission(), PermissionState.granted);
    });

    test(
      'returns denied when both Android and iOS plugins are absent',
      () async {
        final plugin = _MockPlugin();
        when(
          () => plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);
        when(
          () => plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);

        final scheduler = LocalNotificationScheduler(plugin);
        expect(await scheduler.requestPermission(), PermissionState.denied);
      },
    );

    test('returns denied when platform implementation throws', () async {
      final plugin = _MockPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenThrow(Exception('Missing binding'));

      final scheduler = LocalNotificationScheduler(plugin);
      expect(await scheduler.requestPermission(), PermissionState.denied);
    });
  });

  group('notificationSchedulerProvider', () {
    test('provides LocalNotificationScheduler', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(notificationSchedulerProvider),
        isA<LocalNotificationScheduler>(),
      );
    });
  });

  group('ExactAlarmPermissionAdapter', () {
    test(
      'returns true and no-ops openSettings on non-Android platforms',
      () async {
        final adapter = ExactAlarmPermissionAdapter(isAndroidOverride: false);
        expect(await adapter.canScheduleExact(), isTrue);
        await expectLater(adapter.openSettings(), completes);
      },
    );

    test(
      'queries Android plugin for exact alarms and opens settings',
      () async {
        final plugin = _MockPlugin();
        final android = _MockAndroidPlugin();
        when(
          () => plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(android);
        when(() => android.canScheduleExactNotifications())
            .thenAnswer((_) async => false);
        when(() => android.requestExactAlarmsPermission())
            .thenAnswer((_) async => true);

        final adapter = ExactAlarmPermissionAdapter(
          plugin: plugin,
          isAndroidOverride: true,
        );
        expect(await adapter.canScheduleExact(), isFalse);
        await adapter.openSettings();
        verify(() => android.requestExactAlarmsPermission()).called(1);
      },
    );

    test('falls back to MethodChannel when plugin is null', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('test/exact_alarm');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'canScheduleExact') return false;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final adapter = ExactAlarmPermissionAdapter(
        channel: channel,
        isAndroidOverride: true,
      );
      expect(await adapter.canScheduleExact(), isFalse);
      await expectLater(adapter.openSettings(), completes);
    });
  });
}
