import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/notifications/retention_notification_coordinator.dart';
import 'package:my_sweet_home/core/notifications/retention_notification_planner.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/time/clock.dart';

import '../../fakes/fake_settings_repository.dart';
import '../../fakes/recording_scheduler.dart';

final class _FixedClock extends Clock {
  DateTime _now;
  _FixedClock(this._now);

  void advance(Duration delta) {
    _now = _now.add(delta);
  }

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime nowUtc() => _now.toUtc();
}

void main() {
  group('RetentionNotificationPlanner', () {
    test('plans 7 Fibonacci slots at 10:00 local time', () {
      const planner = RetentionNotificationPlanner();
      final anchor = DateTime(2026, 11, 1, 21, 45);
      final planned = planner.plan(
        anchorLocal: anchor,
        nowLocal: anchor,
        messageBuilder: (days) =>
            RetentionMessage(title: 'T$days', body: 'B$days'),
      );

      expect(planned, hasLength(7));
      expect(planned.map((n) => n.id).toList(), [
        'retention_fib_3',
        'retention_fib_5',
        'retention_fib_8',
        'retention_fib_13',
        'retention_fib_21',
        'retention_fib_34',
        'retention_fib_55',
      ]);
      expect(planned.first.scheduledAt, DateTime(2026, 11, 4, 10, 0));
      expect(planned.last.scheduledAt, DateTime(2026, 12, 26, 10, 0));
    });

    test('filters out past slots when nowLocal is after some intervals', () {
      const planner = RetentionNotificationPlanner();
      final anchor = DateTime(2026, 11, 1, 10, 0);
      final now = DateTime(2026, 11, 10, 12, 0); // 9 days later
      final planned = planner.plan(
        anchorLocal: anchor,
        nowLocal: now,
        messageBuilder: (days) =>
            RetentionMessage(title: 'T$days', body: 'B$days'),
      );

      expect(planned.map((n) => n.id).toList(), [
        'retention_fib_13',
        'retention_fib_21',
        'retention_fib_34',
        'retention_fib_55',
      ]);
    });
  });

  group('RetentionNotificationCoordinator', () {
    late RecordingScheduler scheduler;
    late FakeSettingsRepository settings;
    late _FixedClock clock;
    late RetentionNotificationCoordinator coordinator;

    setUp(() {
      scheduler = RecordingScheduler();
      settings = FakeSettingsRepository();
      clock = _FixedClock(DateTime(2026, 11, 14, 14, 0));
      coordinator = RetentionNotificationCoordinator(
        scheduler: scheduler,
        settings: settings,
        clock: clock,
      );
    });

    test(
      'onAppOpenedOrResumed records timestamp, cancels old, schedules 7 slots',
      () async {
        await coordinator.onAppOpenedOrResumed();

        expect(
          await settings.getLastAppOpenTimestamp(),
          DateTime(2026, 11, 14, 14, 0),
        );
        expect(scheduler.scheduled, hasLength(7));
        expect(
          scheduler.scheduled.first.scheduledAt,
          DateTime(2026, 11, 17, 10, 0),
        );
      },
    );

    test('onAppOpenedOrResumed cancels existing and schedules nothing when disabled', () async {
      await coordinator.onAppOpenedOrResumed();
      expect(scheduler.scheduled, hasLength(7));

      await coordinator.onSettingChanged(false);
      expect(await settings.isRetentionNotificationsEnabled(), isFalse);
      expect(scheduler.scheduled, isEmpty);

      await coordinator.onAppOpenedOrResumed();
      expect(scheduler.scheduled, isEmpty);
    });

    test(
      'onAppOpenedOrResumed skips scheduling when permission is denied',
      () async {
        scheduler.setPermission(PermissionState.denied);

        await coordinator.onAppOpenedOrResumed();
        expect(scheduler.scheduled, isEmpty);
      },
    );

    test('onSettingChanged(true) reschedules future slots from lastAppOpenTimestamp', () async {
      await settings.setRetentionNotificationsEnabled(false);
      await settings.setLastAppOpenTimestamp(DateTime(2026, 11, 10, 9, 0));
      // clock is 2026-11-14 14:00 (4 days later -> +3d is past, +5..+55 are future)
      await coordinator.onSettingChanged(true);

      expect(await settings.isRetentionNotificationsEnabled(), isTrue);
      expect(scheduler.scheduled, hasLength(6));
      expect(scheduler.scheduled.first.id, 'retention_fib_5');
    });

    test(
      'rescheduleRemainingAfterBoot reschedules only future slots from anchor',
      () async {
        await settings.setLastAppOpenTimestamp(DateTime(2026, 11, 1, 10, 0));
        clock.advance(
          const Duration(days: 0),
        ); // 2026-11-14 14:00 -> +13d (Nov 14 10:00) is past!

        final result = await coordinator.rescheduleRemainingAfterBoot();
        expect(result.isOk, isTrue);
        expect(scheduler.scheduled.map((n) => n.id).toList(), [
          'retention_fib_21',
          'retention_fib_34',
          'retention_fib_55',
        ]);
      },
    );

    test(
      'rescheduleRemainingAfterBoot does nothing when disabled or no timestamp',
      () async {
        var result = await coordinator.rescheduleRemainingAfterBoot();
        expect(result.isOk, isTrue);
        expect(scheduler.scheduled, isEmpty);

        await settings.setLastAppOpenTimestamp(DateTime(2026, 11, 14, 10, 0));
        await settings.setRetentionNotificationsEnabled(false);
        result = await coordinator.rescheduleRemainingAfterBoot();
        expect(result.isOk, isTrue);
        expect(scheduler.scheduled, isEmpty);
      },
    );
  });
}
