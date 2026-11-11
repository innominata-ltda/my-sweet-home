import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide Category, Expense;
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';
import 'package:my_sweet_home/features/backup/presentation/encrypted_backup_dialog.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/date_range.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/services/default_expense_exporter.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

import '../../fakes/fake_file_store.dart';
import '../../fakes/recording_background_runner.dart';

class _FakeCategoryRepo implements CategoryRepository {
  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async => const Ok([]);
  @override
  Future<Result<Category, Failure>> upsert(Category c) async => Ok(c);
  @override
  Future<Result<void, Failure>> deactivate(CategoryId id) async =>
      const Ok(null);
  @override
  Future<Result<int, Failure>> ensureDefaults() async => const Ok(0);
}

class _FakeExpenseRepo implements ExpenseRepository {
  @override
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  }) async => Ok([
    Expense(
      id: const ExpenseId('exp-1'),
      amount: const Money(1500),
      occurredOn: DateTime.utc(2026, 10, 1),
      description: 'Café',
    ),
  ]);

  @override
  Future<Result<Expense, Failure>> add(NewExpense e, {String? rrule}) =>
      throw UnimplementedError();
  @override
  Future<Result<Expense?, Failure>> byId(ExpenseId id) async =>
      const Err(NotFoundFailure(what: 'expense'));
  @override
  Future<String?> getRecurringRrule(String ruleId) async => null;
  @override
  Future<Result<TrashTicket, Failure>> remove(ExpenseId id) =>
      throw UnimplementedError();
  @override
  Future<Result<Expense, Failure>> update(
    ExpenseId id,
    NewExpense e, {
    String? rrule,
  }) => throw UnimplementedError();
}

void main() {
  group('DriftBackupService — Concurrency & Stages (RN-424, CA-5.1)', () {
    late AppDatabase db;
    late FakeFileStore fakeFileStore;
    late RecordingBackgroundRunner runner;
    late DriftBackupService backupService;

    setUp(() {
      db = AppDatabase.memory();
      fakeFileStore = FakeFileStore();
      runner = RecordingBackgroundRunner();
      backupService = DriftBackupService(
        db,
        fileStore: fakeFileStore,
        runner: runner,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('CA-5.1: exportEncryptedBackup emite BackupStages na ordem e delega processamento ao BackgroundRunnerPort', () async {
      final stages = <BackupStage>[];

      final result = await backupService.exportEncryptedBackup(
        'senha-forte-123',
        onStage: stages.add,
      );

      expect(result.isOk, isTrue);
      expect(
        runner.runCount,
        greaterThan(0),
        reason: 'Heavy serialization and cipher must be delegated to BackgroundRunnerPort',
      );

      expect(
        stages,
        equals([
          BackupStage.collecting,
          BackupStage.encrypting,
          BackupStage.writing,
          BackupStage.done,
        ]),
        reason: 'Stages must be emitted in correct sequence',
      );

      final initialRunCount = runner.runCount;

      // Descriptografa para certificar integridade do backup gerado
      final decryptRes = await backupService.importEncryptedBackup(
        result.valueOrNull!,
        'senha-forte-123',
      );
      expect(decryptRes.isOk, isTrue);
      expect(
        runner.runCount,
        greaterThan(initialRunCount),
        reason: 'Backup import and decryption must also be delegated to BackgroundRunnerPort',
      );
    });

    test(
      'SyncBatchCodecImpl delega seal e open ao BackgroundRunnerPort (RN-424)',
      () async {
        final syncRunner = RecordingBackgroundRunner();
        final codec = SyncBatchCodecImpl(runner: syncRunner);
        final key = HouseholdKey(List.filled(32, 7));

        final batch = SyncBatch(
          householdId: 'house-1',
          fromSiteId: 'site-a',
          senderVector: const VersionVector({}),
        );

        final sealRes = await codec.seal(batch, key);
        expect(sealRes.isOk, isTrue);
        expect(syncRunner.runCount, equals(1));

        final openRes = await codec.open(sealRes.valueOrNull!, key);
        expect(openRes.isOk, isTrue);
        expect(syncRunner.runCount, equals(2));
        expect(openRes.valueOrNull!.fromSiteId, equals('site-a'));
      },
    );

    test('DefaultExpenseExporter delegates PDF and CSV generation to BackgroundRunnerPort (RN-424)', () async {
      final exportRunner = RecordingBackgroundRunner();
      final exporter = DefaultExpenseExporter(
        expenseRepository: _FakeExpenseRepo(),
        categoryRepository: _FakeCategoryRepo(),
        runner: exportRunner,
      );

      final range = DateRange(
        DateTime.utc(2026, 10, 1),
        DateTime.utc(2026, 10, 31),
      );

      final csvRes = await exporter.toCsv(range);
      expect(csvRes.isOk, isTrue);
      expect(exportRunner.runCount, equals(1));

      final pdfRes = await exporter.toPdf(range);
      expect(pdfRes.isOk, isTrue);
      expect(exportRunner.runCount, equals(2));
    });

    testWidgets(
      'EncryptedBackupExportDialog exibe progresso com stageNotifier reativo',
      (tester) async {
        final stageNotifier = ValueNotifier<BackupStage?>(null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EncryptedBackupExportDialog(
                stageNotifier: stageNotifier,
                onExportRequested: (pass, {includePhotos = false}) async {
                  stageNotifier.value = BackupStage.encrypting;
                },
              ),
            ),
          ),
        );

        // Preenche senhas
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha do Backup *'),
          'senha123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar Senha *'),
          'senha123',
        );
        await tester.pumpAndSettle();

        // Toca em exportar
        await tester.tap(find.text('Exportar Criptografado'));
        await tester.pump();

        // Check indicator and stage text
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(
          find.text('Criptografando com AES-256 e Argon2id...'),
          findsOneWidget,
        );

        // Atualiza para writing
        stageNotifier.value = BackupStage.writing;
        await tester.pump();
        expect(find.text('Finalizando arquivo de backup...'), findsOneWidget);
      },
    );
  });
}
