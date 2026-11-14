import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/notifications/retention_notification_planner.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/time/clock.dart';

/// Coordinates scheduling, cancellation, and boot-time recovery of Fibonacci
/// retention reminders.
class RetentionNotificationCoordinator {
  final NotificationSchedulerPort _scheduler;
  final SettingsRepository _settings;
  final Clock _clock;
  final RetentionNotificationPlanner _planner;
  final RetentionMessageBuilder _messageBuilder;

  RetentionNotificationCoordinator({
    required NotificationSchedulerPort scheduler,
    required SettingsRepository settings,
    Clock clock = const SystemClock(),
    RetentionNotificationPlanner planner = const RetentionNotificationPlanner(),
    RetentionMessageBuilder? messageBuilder,
  }) : _scheduler = scheduler,
       _settings = settings,
       _clock = clock,
       _planner = planner,
       _messageBuilder = messageBuilder ?? _defaultMessage;

  static RetentionMessage _defaultMessage(int daysSinceOpen) {
    return RetentionMessage(
      title: 'Momo sentiu sua falta!',
      body:
          'Faz $daysSinceOpen dias que não organizamos a casa juntos. Que tal conferir suas tarefas e contas?',
    );
  }

  /// Records the app open timestamp, cancels any pending retention slots, and
  /// schedules a fresh Fibonacci sequence if enabled and permitted.
  Future<void> onAppOpenedOrResumed() async {
    final nowLocal = _clock.nowLocal();
    await _settings.setLastAppOpenTimestamp(nowLocal);
    await _cancelAll();

    final enabled = await _settings.isRetentionNotificationsEnabled();
    if (!enabled) return;

    final perm = await _scheduler.permission();
    if (perm != PermissionState.granted) return;

    await _scheduleFrom(anchorLocal: nowLocal, nowLocal: nowLocal);
  }

  /// Updates the retention preference and cancels or reschedules accordingly.
  Future<void> onSettingChanged(bool enabled) async {
    await _settings.setRetentionNotificationsEnabled(enabled);
    await _cancelAll();

    if (!enabled) return;

    final perm = await _scheduler.permission();
    if (perm != PermissionState.granted) return;

    final nowLocal = _clock.nowLocal();
    final anchorLocal = await _settings.getLastAppOpenTimestamp() ?? nowLocal;
    await _scheduleFrom(anchorLocal: anchorLocal, nowLocal: nowLocal);
  }

  /// Reschedules only future Fibonacci slots relative to
  /// `last_app_open_timestamp` after a device reboot.
  Future<Result<void, Failure>> rescheduleRemainingAfterBoot() async {
    for (final id in RetentionNotificationPlanner.allNotificationIds) {
      final cancelResult = await _scheduler.cancel(id);
      if (cancelResult.isErr) {
        return cancelResult;
      }
    }

    final enabled = await _settings.isRetentionNotificationsEnabled();
    if (!enabled) {
      return const Ok(null);
    }

    final anchorLocal = await _settings.getLastAppOpenTimestamp();
    if (anchorLocal == null) {
      return const Ok(null);
    }

    final perm = await _scheduler.permission();
    if (perm != PermissionState.granted) {
      return const Ok(null);
    }

    final nowLocal = _clock.nowLocal();
    final notifications = _planner.plan(
      anchorLocal: anchorLocal,
      nowLocal: nowLocal,
      messageBuilder: _messageBuilder,
    );
    for (final notification in notifications) {
      final result = await _scheduler.schedule(notification);
      if (result.isErr) {
        return result;
      }
    }
    return const Ok(null);
  }

  Future<void> _cancelAll() async {
    for (final id in RetentionNotificationPlanner.allNotificationIds) {
      await _scheduler.cancel(id);
    }
  }

  Future<void> _scheduleFrom({
    required DateTime anchorLocal,
    required DateTime nowLocal,
  }) async {
    final notifications = _planner.plan(
      anchorLocal: anchorLocal,
      nowLocal: nowLocal,
      messageBuilder: _messageBuilder,
    );
    for (final notification in notifications) {
      await _scheduler.schedule(notification);
    }
  }
}
