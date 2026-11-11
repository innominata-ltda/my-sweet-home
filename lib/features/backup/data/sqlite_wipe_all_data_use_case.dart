import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';
import 'package:my_sweet_home/core/notifications/notification_scheduler_port.dart';
import 'package:my_sweet_home/core/storage/file_store_port.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';

/// SQLite implementation of wipe all data use case (RF-006, RN-233, RN-418, RN-435, CA-3.6, CA-4.10).
class SqliteWipeAllDataUseCase implements WipeAllDataUseCase {
  final AppDatabase db;
  final FileStorePort fileStore;
  final NotificationSchedulerPort? notificationScheduler;
  final DatabaseVaultPort? vault;
  final DiagnosticLogPort? diagnosticLog;

  SqliteWipeAllDataUseCase({
    required this.db,
    required this.fileStore,
    this.notificationScheduler,
    this.vault,
    this.diagnosticLog,
  });

  @override
  Future<void> call() async {
    // 1. Coleta e remove arquivos armazenados vinculados a anexos, fotos de cupom e receitas
    try {
      final attachments = await db.select(db.attachments).get();
      for (final att in attachments) {
        if (att.path.isNotEmpty) {
          try {
            await fileStore.delete(att.path);
          } catch (_) {}
        }
      }
    } catch (_) {}

    try {
      final purchases = await db.select(db.purchases).get();
      for (final p in purchases) {
        if (p.receiptImagePath != null && p.receiptImagePath!.isNotEmpty) {
          try {
            await fileStore.delete(p.receiptImagePath!);
          } catch (_) {}
        }
      }
    } catch (_) {}

    try {
      final recipes = await db.select(db.recipes).get();
      for (final r in recipes) {
        if (r.photoPath != null && r.photoPath!.isNotEmpty) {
          try {
            await fileStore.delete(r.photoPath!);
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 2. Apaga todas as linhas de todas as tabelas sem violar FKs
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    try {
      await db.transaction(() async {
        for (final table in db.allTables.toList().reversed) {
          await db.delete(table).go();
        }
      });
    } finally {
      await db.customStatement('PRAGMA foreign_keys = ON;');
    }

    // 3. Cancels all pending scheduled notifications
    if (notificationScheduler != null) {
      try {
        final pending = await notificationScheduler!.pending();
        for (final item in pending) {
          try {
            await notificationScheduler!.cancel(item.id);
          } catch (_) {}
        }
      } catch (_) {}
    }

    // 4. Clears local diagnostic log (RN-435, CA-4.10)
    if (diagnosticLog != null) {
      try {
        await diagnosticLog!.wipe();
      } catch (_) {}
    }

    // 5. Destroys encrypted database vault: deletes database files and key in secure storage (RN-418, CA-3.6)
    if (vault != null) {
      final destroyRes = await vault!.destroy();
      if (destroyRes.isErr) {
        throw destroyRes.failureOrNull!;
      }
    }
  }
}
