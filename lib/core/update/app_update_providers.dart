import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/update/app_update_adapter.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';
import 'package:my_sweet_home/core/update/app_update_service.dart';

/// Provider for native store update port.
final appUpdatePortProvider = Provider<AppUpdatePort>((ref) {
  return const MethodChannelAppUpdateAdapter();
});

/// Provider for update coordination service with cooldown tracking.
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final port = ref.watch(appUpdatePortProvider);
  final clock = ref.watch(clockProvider);
  final db = ref.watch(databaseProvider);
  return AppUpdateService(port: port, clock: clock, db: db);
});

/// Whether the current installation originated from Google Play.
final installedFromPlayStoreProvider = FutureProvider<bool>((ref) {
  return ref.watch(appUpdateServiceProvider).isInstalledFromPlayStore();
});
