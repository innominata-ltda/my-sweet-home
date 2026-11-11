import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/notifications/local_notification_scheduler.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../fakes/fake_exact_alarm_permission.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin plugin;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    registerFallbackValue(tz.TZDateTime.now(tz.local));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = MockFlutterLocalNotificationsPlugin();
  });

  test('schedule calls zonedSchedule with correct parameters', () async {
    final scheduler = LocalNotificationScheduler(plugin);
    final notification = ScheduledNotification(
      id: 'test_id',
      title: 'Title',
      body: 'Body',
      scheduledAt: DateTime(2026, 1, 1, 10, 0),
    );

    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenAnswer((_) async {});

    final result = await scheduler.schedule(notification);

    expect(result.isOk, true);
    verify(
      () => plugin.zonedSchedule(
        id: notification.id.hashCode,
        title: 'Title',
        body: 'Body',
        scheduledDate: any(named: 'scheduledDate', that: isA<tz.TZDateTime>()),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      ),
    ).called(1);
  });

  test('CA-4.5: schedule uses inexactAllowWhileIdle when exactAlarmPermission returns false', () async {
    final fakePermission = FakeExactAlarmPermission(false);
    final scheduler = LocalNotificationScheduler(
      plugin,
      exactAlarmPermission: fakePermission,
    );
    final notification = ScheduledNotification(
      id: 'test_inexact',
      title: 'Inexact Title',
      body: 'Inexact Body',
      scheduledAt: DateTime(2026, 1, 1, 10, 0),
    );

    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenAnswer((_) async {});

    final result = await scheduler.schedule(notification);

    expect(result.isOk, true);
    verify(
      () => plugin.zonedSchedule(
        id: notification.id.hashCode,
        title: 'Inexact Title',
        body: 'Inexact Body',
        scheduledDate: any(named: 'scheduledDate', that: isA<tz.TZDateTime>()),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      ),
    ).called(1);
  });

  test('cancel calls plugin.cancel with hash code', () async {
    final scheduler = LocalNotificationScheduler(plugin);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

    final result = await scheduler.cancel('test_id');

    expect(result.isOk, true);
    verify(() => plugin.cancel(id: 'test_id'.hashCode)).called(1);
  });

  test('schedule and cancel return Err on plugin exception', () async {
    final scheduler = LocalNotificationScheduler(plugin);
    final notification = ScheduledNotification(
      id: 'err_id',
      title: 'T',
      body: 'B',
      scheduledAt: DateTime(2026, 1, 1),
    );

    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenThrow(Exception('Schedule fail'));
    expect((await scheduler.schedule(notification)).isErr, isTrue);

    when(() => plugin.cancel(id: any(named: 'id')))
        .thenThrow(Exception('Cancel fail'));
    expect((await scheduler.cancel('err_id')).isErr, isTrue);
  });

  test('pending returns mapped requests and empty list on error', () async {
    final scheduler = LocalNotificationScheduler(plugin);
    when(() => plugin.pendingNotificationRequests()).thenAnswer(
      (_) async => [
        const PendingNotificationRequest(123, 'Title', 'Body', 'payload'),
      ],
    );

    final result = await scheduler.pending();

    expect(result.length, 1);
    expect(result.first.id, '123');
    expect(result.first.title, 'Title');
    expect(result.first.body, 'Body');

    when(() => plugin.pendingNotificationRequests())
        .thenThrow(Exception('Pending fail'));
    expect(await scheduler.pending(), isEmpty);
  });

  test('permission checks android and ios platforms', () async {
    final scheduler = LocalNotificationScheduler(plugin);

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

    expect(await scheduler.permission(), PermissionState.denied);
  });

  test('ScheduledNotification equality and hashCode', () {
    final now = DateTime(2026, 1, 1);
    final n1 = ScheduledNotification(
      id: '1',
      title: 'T',
      body: 'B',
      scheduledAt: now,
    );
    final n2 = ScheduledNotification(
      id: '1',
      title: 'T',
      body: 'B',
      scheduledAt: now,
    );
    final n3 = ScheduledNotification(
      id: '2',
      title: 'T',
      body: 'B',
      scheduledAt: now,
    );

    expect(n1, equals(n2));
    expect(n1.hashCode, equals(n2.hashCode));
    expect(n1 == n3, isFalse);
  });

  test('rescheduleAllAfterBoot success when all succeed', () async {
    final scheduler = LocalNotificationScheduler(
      plugin,
      reschedulers: [() async => const Ok(null)],
    );
    final result = await scheduler.rescheduleAllAfterBoot();
    expect(result.isOk, isTrue);
  });

  test(
    'rescheduleAllAfterBoot calls all reschedulers and stops on error',
    () async {
      int count1 = 0;
      int count2 = 0;
      int count3 = 0;

      final scheduler = LocalNotificationScheduler(
        plugin,
        reschedulers: [
          () async {
            count1++;
            return const Ok(null);
          },
          () async {
            count2++;
            return Err(StorageFailure(detail: 'Error'));
          },
          () async {
            count3++;
            return const Ok(null);
          },
        ],
      );

      final result = await scheduler.rescheduleAllAfterBoot();

      expect(result.isErr, true);
      expect(count1, 1);
      expect(count2, 1);
      expect(count3, 0); // Stops early
    },
  );
}
