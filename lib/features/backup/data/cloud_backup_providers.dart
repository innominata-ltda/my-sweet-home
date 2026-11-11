import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/features/backup/data/backup_service_provider.dart';
import 'package:my_sweet_home/features/backup/domain/cloud_backup_service.dart';

export 'package:my_sweet_home/app/providers.dart' show cloudStoragePortProvider;

/// Provider para [CloudBackupService].
final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  final cloudStoragePort = ref.watch(cloudStoragePortProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return CloudBackupService(
    backupService: backupService,
    cloudStoragePort: cloudStoragePort,
    settingsRepository: settingsRepository,
  );
});
