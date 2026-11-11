import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';
import 'package:my_sweet_home/data/database/database.dart';

/// Service orchestrating update verification, 24-hour cooldown enforcement,
/// and persistence in Drift database (RN-041, RN-042, RN-043).
class AppUpdateService {
  AppUpdateService({required this.port, required this.clock, required this.db});

  final AppUpdatePort port;
  final Clock clock;
  final AppDatabase db;

  static const String settingKeyLastPrompt = 'last_update_prompt_timestamp';
  static const Duration cooldownDuration = Duration(hours: 24);

  /// Silent check during Dashboard bootstrap (RN-041).
  ///
  /// Enforces 24-hour cooldown between prompts. If device is offline or store
  /// is unreachable, failure is silently ignored and returns `null`.
  Future<AppUpdateInfo?> checkSilentlyForDashboard() async {
    final lastPrompt = await getLastPromptTimestamp();
    if (lastPrompt != null) {
      final elapsed = clock.nowUtc().difference(lastPrompt);
      if (elapsed < cooldownDuration) {
        return null;
      }
    }

    final result = await port.checkForUpdate();
    return result.fold(
      (info) => info.updateAvailable ? info : null,
      (failure) => null, // Silently ignored when offline or store unavailable
    );
  }

  /// Records that update prompt was dismissed with "Not now" or initiated,
  /// activating the 24-hour cooldown period (RN-042).
  Future<void> recordDismissedFor24Hours() async {
    final now = clock.nowUtc();
    try {
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion(
              key: const Value(settingKeyLastPrompt),
              value: Value(now.toIso8601String()),
              updatedAt: Value(now.toIso8601String()),
            ),
          );
    } catch (_) {}
  }

  /// Triggers native update flow through the port.
  Future<Result<void, AppUpdateFailure>> startUpdate() async {
    await recordDismissedFor24Hours();
    return port.startUpdate();
  }

  /// Manual check initiated by user on About screen (RN-043).
  ///
  /// Bypasses the 24-hour cooldown and returns the full result for user feedback.
  Future<Result<AppUpdateInfo, AppUpdateFailure>> checkManually() async {
    return port.checkForUpdate();
  }

  /// Returns recorded timestamp when update prompt was last displayed.
  Future<DateTime?> getLastPromptTimestamp() async {
    try {
      final row =
          await (db.select(db.settings)
                ..where((tbl) => tbl.key.equals(settingKeyLastPrompt)))
              .getSingleOrNull();
      if (row == null) return null;
      return DateTime.tryParse(row.value);
    } catch (_) {
      return null;
    }
  }
}
