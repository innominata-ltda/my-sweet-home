import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';
import 'package:my_sweet_home/core/storage/io_file_store_adapter.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/features/backup/data/sqlite_wipe_all_data_use_case.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';

/// Provider opcional para [DatabaseVaultPort].
final databaseVaultProvider = Provider<DatabaseVaultPort?>((ref) => null);

/// Provider opcional para [DiagnosticLogPort].
final diagnosticLogProvider = Provider<DiagnosticLogPort?>((ref) => null);

/// Provider para [WipeAllDataUseCase].
final wipeAllDataUseCaseProvider = Provider<WipeAllDataUseCase>((ref) {
  final db = ref.watch(databaseProvider);
  final vault = ref.watch(databaseVaultProvider);
  final diagnosticLog = ref.watch(diagnosticLogProvider);
  return SqliteWipeAllDataUseCase(
    db: db,
    fileStore: const IoFileStoreAdapter(),
    vault: vault,
    diagnosticLog: diagnosticLog,
  );
});
