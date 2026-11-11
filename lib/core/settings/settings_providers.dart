import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/settings/drift_settings_repository.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';

/// Provider for settings and user consents repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  return DriftSettingsRepository(db, clock: clock);
});

/// Notifier for visual effects and particles state (RF-014, RNF-001, RNF-002).
class VisualEffectsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadInitial();
    return true; // Optimistic initial value
  }

  Future<void> _loadInitial() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final value = await repo.isVisualEffectsEnabled();
      state = value;
    } catch (_) {
      // Ignored in test environments where databaseProvider is unconfigured.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setVisualEffectsEnabled(enabled);
    } catch (_) {}
  }
}

final visualEffectsEnabledProvider =
    NotifierProvider<VisualEffectsNotifier, bool>(VisualEffectsNotifier.new);

/// Notifier for onboarding completion state (RF-009).
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadInitial();
    return false;
  }

  Future<void> _loadInitial() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final value = await repo.isOnboardingCompleted();
      state = value;
    } catch (_) {
      // Ignored in test environments where databaseProvider is unconfigured.
    }
  }

  Future<void> setCompleted(bool completed) async {
    state = completed;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.setOnboardingCompleted(completed);
    } catch (_) {}
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
      OnboardingCompletedNotifier.new,
    );
