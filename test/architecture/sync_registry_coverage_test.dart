library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';
import 'package:my_sweet_home/data/sync/tables/sync_triggers.dart';

void main() {
  group('SPEC-013 / T-03: Testes de Arquitetura — Cobertura do Registro de Sync', () {
    late AppDatabase db;
    late SyncTableRegistryImpl registry;
    late Set<String> allDbTableNames;

    setUp(() {
      db = AppDatabase.memory();
      registry = SyncTableRegistryImpl();
      allDbTableNames = db.allTables.map((t) => t.actualTableName).toSet();
    });

    tearDown(() async {
      await db.close();
    });

    test('Every AppDatabase table is categorized as synced, derived, or local (plan §Risk)', () {
      final registeredTables = registry.tables.map((t) => t.table).toSet();
      final localTables = registry.localTables;

      final missingTables = allDbTableNames.difference(
        registeredTables.union(localTables),
      );
      expect(
        missingTables,
        isEmpty,
        reason:
            'Database tables not registered in SyncTableRegistryImpl:\n'
            '${missingTables.join('\n')}\n'
            'Every table must be registered in registry.tables (with derived: true/false) '
            'ou em localTables.',
      );

      final extraTables = registeredTables
          .union(localTables)
          .difference(allDbTableNames);
      expect(
        extraTables,
        isEmpty,
        reason:
            'Registered tables that do not exist in database:\n'
            '${extraTables.join('\n')}',
      );
    });

    test('Registered and local tables are strictly disjoint', () {
      final registeredTables = registry.tables.map((t) => t.table).toSet();
      final localTables = registry.localTables;

      final intersection = registeredTables.intersection(localTables);
      expect(
        intersection,
        isEmpty,
        reason:
            'Tables cannot be simultaneously registered for sync and local:\n'
            '${intersection.join('\n')}',
      );
    });

    test(
      'Every synchronized (non-derived) table has triggers in SyncTriggers',
      () {
        final syncedSpecs = registry.tables.where((t) => !t.derived);
        final triggerTables = SyncTriggers.syncedTablesAndColumns.keys.toSet();

        final missingTriggers = syncedSpecs
            .map((s) => s.table)
            .toSet()
            .difference(triggerTables);

        expect(
          missingTriggers,
          isEmpty,
          reason:
              'Tables marked as synchronizable but without triggers in SyncTriggers:\n'
              '${missingTriggers.join('\n')}',
        );
      },
    );

    test('Nenhuma tabela derivada ou estritamente local possui triggers de sync', () {
      final derivedTables = registry.tables
          .where((t) => t.derived)
          .map((t) => t.table)
          .toSet();
      final localTables = registry.localTables;
      final triggerTables = SyncTriggers.syncedTablesAndColumns.keys.toSet();

      final derivedWithTriggers = derivedTables.intersection(triggerTables);
      expect(
        derivedWithTriggers,
        isEmpty,
        reason:
            'Derived tables (RN-327) MUST NOT have synchronization triggers:\n'
            '${derivedWithTriggers.join('\n')}',
      );

      final localWithTriggers = localTables.intersection(triggerTables);
      expect(
        localWithTriggers,
        isEmpty,
        reason:
            'Local tables (RN-312) MUST NOT have synchronization triggers:\n'
            '${localWithTriggers.join('\n')}',
      );
    });

    test('Colunas monitoradas por triggers existem na tabela correspondente', () {
      for (final table in db.allTables) {
        final tableName = table.actualTableName;
        final monitoredCols = SyncTriggers.syncedTablesAndColumns[tableName];
        if (monitoredCols == null) continue;

        final actualColNames = table.$columns.map((c) => c.$name).toSet();
        for (final col in monitoredCols) {
          expect(
            actualColNames,
            contains(col),
            reason:
                'Column "$col" monitored by trigger does not exist in table "$tableName"',
          );
        }
      }
    });

    test('Excluded columns (RN-312) exist in schema and NEVER in triggers', () {
      for (final spec in registry.tables) {
        if (spec.excludedColumns.isEmpty) continue;

        final table = db.allTables.firstWhere(
          (t) => t.actualTableName == spec.table,
        );
        final actualColNames = table.$columns.map((c) => c.$name).toSet();

        for (final excluded in spec.excludedColumns) {
          expect(
            actualColNames,
            contains(excluded),
            reason:
                'Excluded column "$excluded" does not exist in table "${spec.table}"',
          );
        }

        final triggerCols =
            SyncTriggers.syncedTablesAndColumns[spec.table] ?? [];
        final violation = spec.excludedColumns.intersection(
          triggerCols.toSet(),
        );
        expect(
          violation,
          isEmpty,
          reason:
              'Excluded columns of "${spec.table}" MUST NOT be in SyncTriggers:\n'
              '${violation.join('\n')}',
        );
      }

      // Verifies canonical cases of RN-312
      final tasksSpec = registry.findTable('tasks');
      expect(
        tasksSpec?.excludedColumns,
        containsAll({'remote_event_id', 'remote_etag', 'sync_state'}),
        reason:
            'Google Calendar link (remote_event_id, remote_etag, sync_state) '
            'must be excluded from sync (RN-312)',
      );

      final purchasesSpec = registry.findTable('purchases');
      expect(
        purchasesSpec?.excludedColumns,
        containsAll({'receipt_image_path', 'receipt_key'}),
        reason:
            'Fotos de cupom (receipt_image_path) e chaves fiscais (receipt_key) '
            'must be excluded from sync (RN-312)',
      );
    });

    test('Natural keys from RN-326 are configured and exist in schema', () {
      final productsSpec = registry.findTable('products');
      expect(
        productsSpec?.naturalKey,
        contains('canonical_name'),
        reason: 'RN-326: products have naturalKey by canonical name',
      );

      final storesSpec = registry.findTable('stores');
      expect(
        storesSpec?.naturalKey,
        contains('cnpj'),
        reason: 'RN-326: lojas possuem naturalKey por CNPJ',
      );

      final budgetsSpec = registry.findTable('budgets');
      expect(
        budgetsSpec?.naturalKey,
        containsAll(['year_month', 'category_id']),
        reason: 'RN-326: budgets have naturalKey by year_month + category',
      );

      for (final spec in registry.tables) {
        if (spec.naturalKey == null) continue;
        final table = db.allTables.firstWhere(
          (t) => t.actualTableName == spec.table,
        );
        final actualColNames = table.$columns.map((c) => c.$name).toSet();

        for (final col in spec.naturalKey!) {
          expect(
            actualColNames,
            contains(col),
            reason:
                'Coluna de chave natural "$col" deve existir na tabela "${spec.table}"',
          );
        }
      }
    });

    test('recurring_rules has dynamic area by kind: task -> home; expense/bill -> finance; invalid -> ArgumentError', () {
      final spec = registry.findTable('recurring_rules')!;
      expect(spec.areaOf({'kind': 'task'}), equals(SyncArea.home));
      expect(spec.areaOf({'kind': 'expense'}), equals(SyncArea.finance));
      expect(spec.areaOf({'kind': 'bill'}), equals(SyncArea.finance));

      // Edge case: invalid or null kind throws ArgumentError and does not silently fallback
      expect(
        () => spec.areaOf({'kind': 'invalid_kind'}),
        throwsArgumentError,
        reason: 'invalid kind must throw ArgumentError to prevent leaking unintended area',
      );
      expect(
        () => spec.areaOf({'kind': null}),
        throwsArgumentError,
        reason: 'null kind must throw ArgumentError',
      );
      expect(
        () => spec.areaOf({}),
        throwsArgumentError,
        reason: 'map without kind must throw ArgumentError',
      );
    });

    test('effectiveAreas activates catalog only if functional area is present (Home or Finances)', () {
      expect(SyncTableRegistryImpl.effectiveAreas({}), isEmpty);
      expect(
        SyncTableRegistryImpl.effectiveAreas({SyncArea.catalog}),
        isEmpty,
        reason: 'Catalog must not sync in isolation without active Home or Finances (RN-311)',
      );
      expect(
        SyncTableRegistryImpl.effectiveAreas({SyncArea.home}),
        equals({SyncArea.home, SyncArea.catalog}),
      );
      expect(
        SyncTableRegistryImpl.effectiveAreas({SyncArea.finance}),
        equals({SyncArea.finance, SyncArea.catalog}),
      );
      expect(
        SyncTableRegistryImpl.effectiveAreas({SyncArea.home, SyncArea.finance}),
        equals({SyncArea.home, SyncArea.finance, SyncArea.catalog}),
      );
    });

    test('findTable e isLocal respondem corretamente para tabelas existentes e inexistentes', () {
      expect(registry.findTable('products'), isNotNull);
      expect(registry.findTable('non_existent_table'), isNull);

      expect(registry.isLocal('settings'), isTrue);
      expect(registry.isLocal('products'), isFalse);
      expect(registry.isLocal('unknown_table'), isFalse);
    });

    test('localTables is immutable set', () {
      expect(
        () => (registry.localTables as dynamic).add('malicious_table'),
        throwsUnsupportedError,
      );
    });
  });
}
