import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/notifications/local_notification_scheduler.dart';
import 'package:my_sweet_home/core/notifications/notification_bootstrap.dart';
import 'package:my_sweet_home/core/notifications/notification_providers.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';

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
    test('initializes plugin and timezones without throwing', () async {
      final plugin = _MockPlugin();
      when(() => plugin.initialize(settings: any(named: 'settings')))
          .thenAnswer((_) async => true);

      await initializeLocalNotifications(plugin);

      verify(() => plugin.initialize(settings: any(named: 'settings')))
          .called(1);
    });

    test('degrades gracefully when plugin.initialize throws', () async {
      final plugin = _MockPlugin();
      when(() => plugin.initialize(settings: any(named: 'settings')))
          .thenThrow(Exception('Platform unavailable'));

      await expectLater(initializeLocalNotifications(plugin), completes);
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
}
