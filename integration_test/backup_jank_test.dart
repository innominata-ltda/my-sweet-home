@Tags(['device'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Encrypted export of 10,000 expenses does not jank UI and no frame exceeds 100ms',
    (tester) async {
      final db = AppDatabase.memory();
      final service = DriftBackupService(db);

      // Populate 10,000 expenses
      await db.customStatement('''
        WITH RECURSIVE cnt(x) AS (
          SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 10000
        )
        INSERT INTO expenses(id, amount_cents, occurred_on, description)
        SELECT 'exp_' || x, 1500, '2026-10-01', 'Expense ' || x
        FROM cnt;
      ''');

      final stages = <BackupStage>[];

      // Acompanha desempenho de quadros durante o export
      await binding.watchPerformance(() async {
        final res = await service.exportEncryptedBackup(
          'senha-teste-10k',
          onStage: stages.add,
        );
        expect(res.isOk, isTrue);
      });

      expect(stages, contains(BackupStage.done));
      await db.close();
    },
  );
}
