import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/backup/data/backup_service_provider.dart';
import 'package:my_sweet_home/features/backup/data/drift_backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/backup_bundle.dart';
import 'package:my_sweet_home/features/backup/presentation/import_backup_screen.dart';

void main() {
  group('T-03 — ImportBackupScreen Widget Tests (RN-232)', () {
    late AppDatabase db;
    late DriftBackupService backupService;

    setUp(() {
      db = AppDatabase.memory();
      backupService = DriftBackupService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createWidgetUnderTest(String jsonContent) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          backupServiceProvider.overrideWithValue(backupService),
        ],
        child: MaterialApp(
          home: ImportBackupScreen(
            jsonContent: jsonContent,
            backupService: backupService,
          ),
        ),
      );
    }

    testWidgets(
      'Exibe pré-visualização de registros e explicações dos modos Substituir e Mesclar',
      (tester) async {
        final tables = {
          'categories': [
            {
              'id': 'cat_1',
              'name': 'Alimentação',
              'kind': 'expense',
              'icon_key': 'food',
            },
          ],
          'tasks': [
            {'id': 'task_1', 'title': 'Comprar pão'},
            {'id': 'task_2', 'title': 'Limpar sala'},
          ],
        };
        final checksum = await BackupBundle.computeChecksum(tables);
        final bundle = BackupBundle(
          schemaVersion: db.schemaVersion,
          exportedAt: '2026-10-01T12:00:00',
          tables: tables,
          csv: {},
          checksum: checksum,
        );

        final jsonContent = bundle.toJsonString();

        await tester.pumpWidget(createWidgetUnderTest(jsonContent));
        await tester.pumpAndSettle();

        // Preview with affected count
        expect(find.text('Pré-visualização do Backup'), findsOneWidget);
        expect(find.text('3 registros afetados'), findsOneWidget);
        expect(find.text('categories: 1'), findsOneWidget);
        expect(find.text('tasks: 2'), findsOneWidget);

        // Options and explanatory phrases (RN-232)
        expect(find.text('Substituir tudo'), findsOneWidget);
        expect(
          find.text(
            'Apaga todos os dados atuais do aplicativo e substitui pelos dados do backup.',
          ),
          findsOneWidget,
        );

        expect(find.text('Mesclar'), findsOneWidget);
        expect(
          find.text(
            'Mantém os dados atuais e adiciona novos registros ou atualiza existentes sem apagar nada.',
          ),
          findsOneWidget,
        );

        // Button with default label (Replace)
        expect(find.text('Substituir e restaurar backup'), findsOneWidget);
      },
    );

    testWidgets(
      'Alterna para o modo Mesclar e executa importação com sucesso',
      (tester) async {
        // Populate local database with pre-existing category
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat_local',
                name: 'Existente',
                kind: 'expense',
                iconKey: 'local',
              ),
            );

        final tables = {
          'categories': [
            {
              'id': 'cat_backup',
              'name': 'Vinda do Backup',
              'kind': 'expense',
              'icon_key': 'backup',
            },
          ],
        };
        final checksum = await BackupBundle.computeChecksum(tables);
        final bundle = BackupBundle(
          schemaVersion: db.schemaVersion,
          exportedAt: '2026-10-01T12:00:00',
          tables: tables,
          csv: {},
          checksum: checksum,
        );

        await tester.pumpWidget(createWidgetUnderTest(bundle.toJsonString()));
        await tester.pumpAndSettle();

        // Tapa no modo Mesclar
        await tester.tap(find.text('Mesclar'));
        await tester.pumpAndSettle();

        // Confirmation button changes to "Merge backup data"
        expect(find.text('Mesclar dados do backup'), findsOneWidget);

        // Confirm import
        final buttonFinder = find.text('Mesclar dados do backup');
        await tester.scrollUntilVisible(
          buttonFinder,
          50.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        // Tela de sucesso exibida
        expect(find.text('Dados mesclados com sucesso!'), findsOneWidget);

        // Verifica se o banco local possui as 2 categorias (Local + Backup)
        final cats = await db.select(db.categories).get();
        expect(cats.length, equals(2));
      },
    );

    testWidgets('Displays error message when backup JSON is invalid', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest('{ json invalido'));
      await tester.pumpAndSettle();

      expect(find.text('Falha na importação'), findsOneWidget);
      expect(
        find.textContaining('Formato de arquivo de backup inválido'),
        findsOneWidget,
      );
    });
  });
}
