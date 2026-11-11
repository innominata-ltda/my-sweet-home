import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/diagnostics/diagnostic_log_port.dart';
import 'package:my_sweet_home/core/notifications/scheduled_notification.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/data/database/database_vault.dart';
import 'package:my_sweet_home/features/backup/data/sqlite_wipe_all_data_use_case.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';
import 'package:my_sweet_home/features/backup/presentation/wipe_all_data_controller.dart';

import '../../fakes/fake_database_key_store.dart';
import '../../fakes/fake_diagnostic_log.dart';
import '../../fakes/fake_file_store.dart';
import '../../fakes/recording_scheduler.dart';

void main() {
  late db.AppDatabase database;
  late FakeFileStore fileStore;
  late RecordingScheduler notificationScheduler;
  late SqliteWipeAllDataUseCase useCase;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    fileStore = FakeFileStore();
    notificationScheduler = RecordingScheduler();

    useCase = SqliteWipeAllDataUseCase(
      db: database,
      fileStore: fileStore,
      notificationScheduler: notificationScheduler,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('apaga todas as tabelas do banco sem deixar dados (CA-2.1, RN-233)', () async {
    // Insert data into multiple database tables
    await database
        .into(database.categories)
        .insert(
          db.CategoriesCompanion.insert(
            id: 'cat_1',
            name: 'Alimentação',
            kind: 'expense',
            iconKey: 'catFood',
          ),
        );

    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod_1',
            canonicalName: 'Arroz 5kg',
            defaultUnit: 'kg',
          ),
        );

    await database
        .into(database.expenses)
        .insert(
          db.ExpensesCompanion.insert(
            id: 'exp_1',
            amountCents: 2500,
            occurredOn: '2026-10-01',
            categoryId: const Value('cat_1'),
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          db.TasksCompanion.insert(id: 'task_1', title: 'Limpar geladeira'),
        );

    await database
        .into(database.settings)
        .insert(db.SettingsCompanion.insert(key: 'theme', value: 'dark'));

    await database
        .into(database.consents)
        .insert(db.ConsentsCompanion.insert(key: 'cloud_ocr', granted: true));

    // Verify database contained data prior to wipe
    final categoriesBefore = await database.select(database.categories).get();
    final productsBefore = await database.select(database.products).get();
    final expensesBefore = await database.select(database.expenses).get();
    final tasksBefore = await database.select(database.tasks).get();
    final settingsBefore = await database.select(database.settings).get();
    final consentsBefore = await database.select(database.consents).get();

    expect(categoriesBefore, isNotEmpty);
    expect(productsBefore, isNotEmpty);
    expect(expensesBefore, isNotEmpty);
    expect(tasksBefore, isNotEmpty);
    expect(settingsBefore, isNotEmpty);
    expect(consentsBefore, isNotEmpty);

    // Executa o wipe
    await useCase();

    // Verify that ALL database tables are completely empty
    for (final table in database.allTables) {
      final rows = await database.select(table).get();
      expect(
        rows,
        isEmpty,
        reason:
            'A tabela ${table.actualTableName} deveria estar vazia após o wipe.',
      );
    }
  });

  test(
    'apaga arquivos armazenados e cancela notificações pendentes (RN-233)',
    () async {
      // Salva arquivos no fake file store
      final photoPath = await fileStore.save(
        Uint8List.fromList([1, 2, 3]),
        name: 'receipt_1.jpg',
      );
      final recipePhotoPath = await fileStore.save(
        Uint8List.fromList([4, 5, 6]),
        name: 'recipe_1.jpg',
      );
      final attPath = await fileStore.save(
        Uint8List.fromList([7, 8, 9]),
        name: 'att_1.pdf',
      );

      // Insere registros referentes aos arquivos no banco
      await database
          .into(database.purchases)
          .insert(
            db.PurchasesCompanion.insert(
              id: 'purch_1',
              purchasedAt: '2026-10-01',
              totalCents: 5000,
              source: 'manual',
              receiptImagePath: Value(photoPath),
            ),
          );

      await database
          .into(database.recipes)
          .insert(
            db.RecipesCompanion.insert(
              id: 'rec_1',
              title: 'Bolo de Cenoura',
              photoPath: Value(recipePhotoPath),
            ),
          );

      await database
          .into(database.attachments)
          .insert(db.AttachmentsCompanion.insert(id: 'att_1', path: attPath));

      // Schedule pending notification
      await notificationScheduler.schedule(
        ScheduledNotification(
          id: 'notif_1',
          title: 'Lembrete de Conta',
          body: 'Conta de luz vence amanhã',
          scheduledAt: DateTime(2026, 10, 5),
        ),
      );

      expect(await fileStore.exists(photoPath), isTrue);
      expect(await fileStore.exists(recipePhotoPath), isTrue);
      expect(await fileStore.exists(attPath), isTrue);
      expect(await notificationScheduler.pending(), isNotEmpty);

      // Executa o wipe
      await useCase();

      // Verifica que arquivos foram apagados
      expect(await fileStore.exists(photoPath), isFalse);
      expect(await fileStore.exists(recipePhotoPath), isFalse);
      expect(await fileStore.exists(attPath), isFalse);

      // Verify that pending notifications were cancelled
      expect(await notificationScheduler.pending(), isEmpty);
    },
  );

  test('CA-3.6 & CA-4.10: Wipe all removes database files, Keystore key, and diagnostic log', () async {
    final tempDir = Directory.systemTemp.createTempSync('msh_wipe_test_');
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    final dbFile = File('${tempDir.path}/app.db')..writeAsStringSync('db');
    final walFile = File('${tempDir.path}/app.db-wal')
      ..writeAsStringSync('wal');
    final shmFile = File('${tempDir.path}/app.db-shm')
      ..writeAsStringSync('shm');
    final journalFile = File('${tempDir.path}/app.db-journal')
      ..writeAsStringSync('journal');
    final encTmpFile = File('${tempDir.path}/app.db.enc-tmp')
      ..writeAsStringSync('tmp');

    final keyStore = FakeDatabaseKeyStore(
      initialKey: Uint8List.fromList(List.generate(32, (i) => i)),
    );
    final vault = DefaultDatabaseVault(
      keyStore: keyStore,
      dbFileProvider: () async => dbFile,
      inBackground: false,
    );

    final diagnosticLog = FakeDiagnosticLog();
    await diagnosticLog.record(
      DiagnosticEntry.fromError(
        atUtc: DateTime.utc(2026, 10, 31),
        level: DiagnosticLevel.error,
        origin: 'test.origin',
        error: Exception('Sample error'),
      ),
    );
    expect(await diagnosticLog.entries(), isNotEmpty);

    final fullWipeUseCase = SqliteWipeAllDataUseCase(
      db: database,
      fileStore: fileStore,
      vault: vault,
      diagnosticLog: diagnosticLog,
    );

    // Executa Apagar Tudo
    await fullWipeUseCase();

    // CA-3.6: Arquivos de banco removidos
    expect(dbFile.existsSync(), isFalse);
    expect(walFile.existsSync(), isFalse);
    expect(shmFile.existsSync(), isFalse);
    expect(journalFile.existsSync(), isFalse);
    expect(encTmpFile.existsSync(), isFalse);

    // CA-3.6: Chave apagada do armazenamento seguro
    final keyResult = await keyStore.read();
    expect(keyResult.valueOrNull, isNull);

    // CA-4.10: Diagnostic log completely clean
    expect(await diagnosticLog.entries(), isEmpty);
  });

  test('WipeAllDataController: success and friendly UI message without leaking raw exception (CA-4.3)', () async {
    final controller = WipeAllDataController(wipeAllDataUseCase: useCase);
    expect(controller.value, isA<WipeAllDataInitial>());

    await controller.executeWipe();
    expect(controller.value, isA<WipeAllDataSuccess>());

    // Intentional failure
    final failingController = WipeAllDataController(
      wipeAllDataUseCase: _FailingWipeUseCase(),
    );
    await failingController.executeWipe();
    expect(failingController.value, isA<WipeAllDataError>());
    final err = failingController.value as WipeAllDataError;
    // CA-4.3: No file paths, no Exception class name, no technical leaks
    expect(err.message.contains('/'), isFalse);
    expect(err.message.contains('Exception'), isFalse);
  });
}

class _FailingWipeUseCase implements WipeAllDataUseCase {
  @override
  Future<void> call() async =>
      throw Exception('raw internal db failure /data/user/0/db');
}
