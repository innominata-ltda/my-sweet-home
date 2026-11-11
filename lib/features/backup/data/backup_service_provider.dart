import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

/// Provider para [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  return DriftBackupService(db, clock: clock);
});
