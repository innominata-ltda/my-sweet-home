import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';

import '../../fakes/fake_clock.dart';

/// Registro de tabelas de teste para validar o ChangeSource.
class _TestSyncTableRegistry implements SyncTableRegistry {
  final Map<String, SyncTableSpec> _specs;

  _TestSyncTableRegistry(List<SyncTableSpec> specs)
    : _specs = {for (final s in specs) s.table: s};

  @override
  Iterable<SyncTableSpec> get tables => _specs.values;

  @override
  SyncTableSpec? findTable(String table) => _specs[table];

  @override
  Set<String> get localTables => const {};

  @override
  bool isLocal(String table) => false;
}

void main() {
  late AppDatabase db;
  late FakeClock fakeClock;
  late ChangeCapture changeCapture;
  late _TestSyncTableRegistry registry;
  late DriftChangeSource changeSource;

  const localSiteId = 'site-local-1111';
  const householdId = 'hh-1234-5678';

  setUp(() async {
    db = AppDatabase.memory();
    fakeClock = FakeClock(DateTime.utc(2026, 10, 22, 12, 0, 0));
    changeCapture = ChangeCapture(db: db, clock: fakeClock);

    // Creates default category to satisfy FKs of products and expenses
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-1',
            name: 'Geral',
            kind: 'both',
            iconKey: 'cart',
            colorHex: const Value('0xFF0000'),
          ),
        );

    registry = _TestSyncTableRegistry([
      SyncTableSpec(
        table: 'products',
        areaOf: (_) => SyncArea.catalog,
        excludedColumns: {'is_archived'},
      ),
      SyncTableSpec(
        table: 'shopping_items',
        areaOf: (_) => SyncArea.home,
        excludedColumns: {'source'},
      ),
      SyncTableSpec(table: 'expenses', areaOf: (_) => SyncArea.finance),
      SyncTableSpec(
        table: 'price_points',
        areaOf: (_) => SyncArea.finance,
        derived: true, // RN-327: nunca transmitida
      ),
      SyncTableSpec(table: 'recipes', areaOf: (_) => SyncArea.home),
      SyncTableSpec(table: 'recipe_tags', areaOf: (_) => SyncArea.home),
    ]);

    changeSource = DriftChangeSource(db: db, registry: registry);
  });

  tearDown(() async {
    await db.close();
  });

  group('ChangeCapture - Disabled by default', () {
    test(
      'without active household, writes DO NOT record in sync_column_versions',
      () async {
        expect(await changeCapture.isHouseholdActive(), isFalse);

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-1',
                canonicalName: 'Arroz 5kg',
                categoryId: const Value('cat-1'),
                defaultUnit: 'kg',
              ),
            );

        final count = await changeCapture.countCapturedVersions();
        expect(count, equals(0));

        final tombstones = await changeCapture.countCapturedTombstones();
        expect(tombstones, equals(0));
      },
    );

    test('without active household, updates/deletes DO NOT record versions/tombstones', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-1',
              canonicalName: 'Arroz 5kg',
              categoryId: const Value('cat-1'),
              defaultUnit: 'kg',
            ),
          );

      await (db.update(db.products)..where((p) => p.id.equals('prod-1'))).write(
        const ProductsCompanion(canonicalName: Value('Arroz Parboilizado')),
      );

      await (db.delete(db.products)..where((p) => p.id.equals('prod-1'))).go();

      expect(await changeCapture.countCapturedVersions(), equals(0));
      expect(await changeCapture.countCapturedTombstones(), equals(0));
    });
  });

  group('ChangeCapture - Household activation and version capture', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test(
      'with active household, insert records version for each monitored column',
      () async {
        expect(await changeCapture.isHouseholdActive(), isTrue);
        expect(await changeCapture.getActiveHouseholdId(), equals(householdId));
        expect(await changeCapture.getLocalSiteId(), equals(localSiteId));

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-1',
                canonicalName: 'Leite Integral',
                categoryId: const Value('cat-1'),
                defaultUnit: 'L',
              ),
            );

        final versions = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'prod-1',
        );

        // Colunas monitoradas de products: canonical_name, category_id, default_unit, package_size_milli, is_archived
        expect(versions.length, equals(5));

        final canonicalCol = versions.firstWhere(
          (v) => v.column == 'canonical_name',
        );
        expect(canonicalCol.table, equals('products'));
        expect(canonicalCol.rowId, equals('prod-1'));
        expect(canonicalCol.siteId, equals(localSiteId));
        expect(canonicalCol.hlc.siteId, equals(localSiteId));
      },
    );

    test(
      'update records version ONLY for columns that actually changed',
      () async {
        final initialHlc = Hlc(millis: 1000, counter: 0, siteId: localSiteId);
        await changeCapture.runWithHlc(initialHlc, () async {
          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'prod-1',
                  canonicalName: 'Leite Integral',
                  categoryId: const Value('cat-1'),
                  defaultUnit: 'L',
                ),
              );
        });

        final initialVersions = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'prod-1',
        );
        final initialCanonicalHlc = initialVersions
            .firstWhere((v) => v.column == 'canonical_name')
            .hlc;
        final initialUnitHlc = initialVersions
            .firstWhere((v) => v.column == 'default_unit')
            .hlc;

        // Atualiza apenas canonical_name com HLC posterior
        final nextHlc = Hlc(millis: 2000, counter: 0, siteId: localSiteId);

        await changeCapture.runWithHlc(nextHlc, () async {
          await (db.update(
            db.products,
          )..where((p) => p.id.equals('prod-1'))).write(
            const ProductsCompanion(canonicalName: Value('Leite Desnatado')),
          );
        });

        final updatedVersions = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'prod-1',
        );

        final updatedCanonical = updatedVersions.firstWhere(
          (v) => v.column == 'canonical_name',
        );
        final updatedUnit = updatedVersions.firstWhere(
          (v) => v.column == 'default_unit',
        );

        // canonical_name foi atualizado com o novo HLC
        expect(updatedCanonical.hlc, equals(nextHlc));
        expect(updatedCanonical.hlc > initialCanonicalHlc, isTrue);

        // default_unit DID NOT change, so preserves previous HLC
        expect(updatedUnit.hlc, equals(initialUnitHlc));
      },
    );

    test('update without real change DOES NOT re-record versions', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-1',
              canonicalName: 'Leite Integral',
              categoryId: const Value('cat-1'),
              defaultUnit: 'L',
            ),
          );

      final before = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-1',
      );

      fakeClock.advance(const Duration(minutes: 5));

      // Grava o mesmo nome
      await (db.update(db.products)..where((p) => p.id.equals('prod-1'))).write(
        const ProductsCompanion(canonicalName: Value('Leite Integral')),
      );

      final after = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-1',
      );

      expect(
        after.firstWhere((v) => v.column == 'canonical_name').hlc,
        equals(before.firstWhere((v) => v.column == 'canonical_name').hlc),
      );
    });

    test('delete grava tombstone na sync_row_tombstones', () async {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-del',
              canonicalName: 'Produto Tempor\u00E1rio',
              categoryId: const Value('cat-1'),
              defaultUnit: 'un',
            ),
          );

      expect(await changeCapture.countCapturedTombstones(), equals(0));

      await (db.delete(
        db.products,
      )..where((p) => p.id.equals('prod-del'))).go();

      final tombstones = await changeCapture.getCapturedTombstones(
        tableName: 'products',
        rowId: 'prod-del',
      );
      expect(tombstones.length, equals(1));
      expect(tombstones.first.table, equals('products'));
      expect(tombstones.first.rowId, equals('prod-del'));
      expect(tombstones.first.hlc.siteId, equals(localSiteId));
    });

    test('deactivateHousehold faz os triggers pararem de disparar', () async {
      await changeCapture.deactivateHousehold();
      expect(await changeCapture.isHouseholdActive(), isFalse);

      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-inactive',
              canonicalName: 'Produto Desativado',
              categoryId: const Value('cat-1'),
              defaultUnit: 'un',
            ),
          );

      final versions = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-inactive',
      );
      expect(versions, isEmpty);
    });
  });

  group('ChangeCapture - Remote echo suppression (Remote Echo Guard)', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test(
      'runAsRemote does not fire triggers on insert, update, or delete',
      () async {
        await changeCapture.runAsRemote(() async {
          expect(await changeCapture.isApplyingRemote(), isTrue);

          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'prod-remote-1',
                  canonicalName: 'Caf\u00E9 Remoto',
                  categoryId: const Value('cat-1'),
                  defaultUnit: 'pct',
                ),
              );

          await (db.update(
            db.products,
          )..where((p) => p.id.equals('prod-remote-1'))).write(
            const ProductsCompanion(
              canonicalName: Value('Caf\u00E9 Remoto Especial'),
            ),
          );

          await (db.delete(
            db.products,
          )..where((p) => p.id.equals('prod-remote-1'))).go();
        });

        // Guard disabled after block
        expect(await changeCapture.isApplyingRemote(), isFalse);

        // No column version or tombstone was generated (no echo!)
        expect(await changeCapture.countCapturedVersions(), equals(0));
        expect(await changeCapture.countCapturedTombstones(), equals(0));
      },
    );

    test(
      'runAsRemote restores protection even if action throws exception',
      () async {
        expect(await changeCapture.isApplyingRemote(), isFalse);

        try {
          await changeCapture.runAsRemote(() async {
            expect(await changeCapture.isApplyingRemote(), isTrue);
            throw Exception('Erro simulado');
          });
        } catch (_) {}

        expect(await changeCapture.isApplyingRemote(), isFalse);
      },
    );

    test(
      'nested runAsRemote preserves active state until outermost block exits',
      () async {
        await changeCapture.runAsRemote(() async {
          expect(await changeCapture.isApplyingRemote(), isTrue);

          await changeCapture.runAsRemote(() async {
            expect(await changeCapture.isApplyingRemote(), isTrue);
          });

          expect(await changeCapture.isApplyingRemote(), isTrue);
        });

        expect(await changeCapture.isApplyingRemote(), isFalse);
      },
    );

    test('after runAsRemote, normal local writes trigger again', () async {
      await changeCapture.runAsRemote(() async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-remote',
                canonicalName: 'Item Remoto',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
      });

      expect(await changeCapture.countCapturedVersions(), equals(0));

      // Agora uma escrita local comum
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-local',
              canonicalName: 'Item Local',
              categoryId: const Value('cat-1'),
              defaultUnit: 'un',
            ),
          );

      final localVersions = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-local',
      );
      expect(localVersions, isNotEmpty);
    });
  });

  group('ChangeCapture - HLC injection and clock advance', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test(
      'runWithHlc injects configured HLC and restores after execution',
      () async {
        final customHlc = Hlc(
          millis: 1700000000000,
          counter: 42,
          siteId: localSiteId,
        );

        await changeCapture.runWithHlc(customHlc, () async {
          expect(await changeCapture.getCurrentHlc(), equals(customHlc));

          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'prod-hlc',
                  canonicalName: 'Produto com HLC',
                  categoryId: const Value('cat-1'),
                  defaultUnit: 'un',
                ),
              );
        });

        expect(await changeCapture.getCurrentHlc(), isNull);

        final versions = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'prod-hlc',
        );
        expect(versions.first.hlc, equals(customHlc));
      },
    );

    test('advanceLocalHlc increments clock from current time', () async {
      final hlc1 = await changeCapture.advanceLocalHlc();
      expect(hlc1.siteId, equals(localSiteId));

      fakeClock.advance(const Duration(seconds: 1));
      final hlc2 = await changeCapture.advanceLocalHlc();

      expect(hlc2 > hlc1, isTrue);
    });
  });

  group('DriftChangeSource - Change query and version vector', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test(
      'localVector returns empty vector when no versions recorded',
      () async {
        final vector = await changeSource.localVector();
        expect(vector.maxBySite, isEmpty);
      },
    );

    test('localVector consolidates highest HLC of column versions, tombstones and peers', () async {
      final hlc1 = Hlc(millis: 1000, counter: 0, siteId: localSiteId);
      final hlc2 = Hlc(millis: 2000, counter: 0, siteId: localSiteId);
      final remoteHlc = Hlc(millis: 1500, counter: 0, siteId: 'site-remote-2');

      await changeCapture.runWithHlc(hlc1, () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-v1',
                canonicalName: 'P1',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
      });

      await changeCapture.runWithHlc(hlc2, () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-v2',
                canonicalName: 'P2',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
      });

      // Registra tombstone de um terceiro site
      final tombHlc = Hlc(millis: 3000, counter: 0, siteId: 'site-remote-3');
      await db.customStatement(
        '''
        INSERT INTO sync_row_tombstones (id, table_name, row_id, hlc, purged_at)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [
          'tomb-1',
          'products',
          'p-old',
          tombHlc.pack(),
          fakeClock.nowUtc().toIso8601String(),
        ],
      );

      // Registra vetor conhecido de outro par
      await db.customStatement(
        '''
        INSERT INTO sync_peer_vectors (household_id, site_id, hlc, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
        [
          householdId,
          'site-remote-2',
          remoteHlc.pack(),
          fakeClock.nowUtc().toIso8601String(),
        ],
      );

      // Record another peer vector with lower HLC than known to cover else branch
      final lowerHlc = Hlc(millis: 500, counter: 0, siteId: localSiteId);
      await db.customStatement(
        '''
        INSERT INTO sync_peer_vectors (household_id, site_id, hlc, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
        [
          householdId,
          localSiteId,
          lowerHlc.pack(),
          fakeClock.nowUtc().toIso8601String(),
        ],
      );

      final vector = await changeSource.localVector();
      expect(vector.maxBySite[localSiteId], equals(hlc2));
      expect(vector.maxBySite['site-remote-2'], equals(remoteHlc));
      expect(vector.maxBySite['site-remote-3'], equals(tombHlc));

      // Also test getCapturedVersions with columnName filter
      final colFiltered = await changeCapture.getCapturedVersions(
        tableName: 'products',
        rowId: 'prod-v2',
        columnName: 'canonical_name',
      );
      expect(colFiltered.length, equals(1));
      expect(colFiltered.first.column, equals('canonical_name'));
    });

    test('changesNotCoveredBy filters by peer version vector', () async {
      final hlc1 = Hlc(millis: 1000, counter: 0, siteId: localSiteId);
      final hlc2 = Hlc(millis: 2000, counter: 0, siteId: localSiteId);

      await changeCapture.runWithHlc(hlc1, () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-known',
                canonicalName: 'Produto Antigo',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
      });

      await changeCapture.runWithHlc(hlc2, () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-new',
                canonicalName: 'Produto Novo',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
      });

      // Peer already knows up to hlc1
      final peerVector = VersionVector({localSiteId: hlc1});
      final res = await changeSource.changesNotCoveredBy(peerVector, {
        SyncArea.catalog,
      });

      expect(res.isOk, isTrue);
      final changes = res.valueOrNull!;

      // Only prod-new (with hlc2) should be returned
      expect(changes.every((c) => c.rowId == 'prod-new'), isTrue);
      expect(
        changes.any(
          (c) => c.column == 'canonical_name' && c.value == 'Produto Novo',
        ),
        isTrue,
      );
    });

    test('changesNotCoveredBy filters by requested areas and excludes non-syncable columns', () async {
      final hlc = Hlc(millis: 1000, counter: 0, siteId: localSiteId);

      await changeCapture.runWithHlc(hlc, () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-cat',
                canonicalName: 'Arroz',
                categoryId: const Value('cat-1'),
                defaultUnit: 'kg',
                isArchived: const Value(false), // excludedColumns em registry!
              ),
            );

        await db
            .into(db.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(id: 'list-1', name: 'Mercado'),
            );

        await db
            .into(db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                id: 'item-1',
                listId: const Value('list-1'),
                position: 0,
                quantityMilli: const Value(1000),
                unit: const Value('kg'),
                source: 'manual', // excludedColumns em registry!
              ),
            );
      });

      // Requesting only HOME area: product (catalog) does NOT come, purchase item (home) COMES
      final resHome = await changeSource.changesNotCoveredBy(
        VersionVector.empty,
        {SyncArea.home},
      );
      expect(resHome.isOk, isTrue);
      final homeChanges = resHome.valueOrNull!;

      expect(homeChanges.any((c) => c.table == 'products'), isFalse);
      expect(homeChanges.any((c) => c.table == 'shopping_items'), isTrue);

      // Excluded columns must not be in changes
      expect(homeChanges.any((c) => c.column == 'source'), isFalse);
    });

    test(
      'changesNotCoveredBy does not transmit derived data (RN-327)',
      () async {
        final hlc = Hlc(millis: 1000, counter: 0, siteId: localSiteId);

        await changeCapture.runWithHlc(hlc, () async {
          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'p-1',
                  canonicalName: 'Produto P1',
                  categoryId: const Value('cat-1'),
                  defaultUnit: 'un',
                ),
              );

          await db
              .into(db.pricePoints)
              .insert(
                PricePointsCompanion.insert(
                  id: 'pp-1',
                  productId: const Value('p-1'),
                  unitPriceCents: 500,
                  normalizedPriceCents: 500,
                  quantityMilli: 1000,
                  unit: 'un',
                  observedAt: '2026-10-22T10:00:00Z',
                  source: 'manual',
                ),
              );
        });

        final res = await changeSource.changesNotCoveredBy(
          VersionVector.empty,
          {SyncArea.finance},
        );
        expect(res.isOk, isTrue);
        final changes = res.valueOrNull!;

        // price_points is derived, must never be transmitted
        expect(changes.any((c) => c.table == 'price_points'), isFalse);
      },
    );
  });

  group('CA-5.1 - Concurrency scenario and integrity without echo', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test('Milk item with locally changed quantity and remote checking without echo', () async {
      // Cria a lista
      await db
          .into(db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              id: 'list-supermercado',
              name: 'Supermercado',
            ),
          );

      // 1. Estado inicial comum: Leite com quantidade 1 (1000 milli), is_checked = 0
      final hlcBase = Hlc(millis: 1000, counter: 0, siteId: 'site-criador');
      await changeCapture.runWithHlc(hlcBase, () async {
        await db
            .into(db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                id: 'item-leite',
                listId: const Value('list-supermercado'),
                freeText: const Value('Leite'),
                quantityMilli: const Value(1000),
                unit: const Value('un'),
                isChecked: const Value(false),
                position: 0,
                source: 'manual',
              ),
            );
      });

      // 2. Aparelho local (A) altera quantidade para 2 (2000 milli)
      final hlcA = Hlc(millis: 2000, counter: 0, siteId: localSiteId);
      await changeCapture.runWithHlc(hlcA, () async {
        await (db.update(db.shoppingItems)
              ..where((i) => i.id.equals('item-leite')))
            .write(const ShoppingItemsCompanion(quantityMilli: Value(2000)));
      });

      // Captured local changes have quantity_milli = 2000
      final localChangesRes = await changeSource.changesNotCoveredBy(
        VersionVector({'site-criador': hlcBase}),
        {SyncArea.home},
      );
      expect(localChangesRes.isOk, isTrue);
      final localChanges = localChangesRes.valueOrNull!;
      final qtyChange = localChanges.firstWhere(
        (c) => c.column == 'quantity_milli',
      );
      expect(qtyChange.value, equals(2000));
      expect(qtyChange.hlc, equals(hlcA));

      // 3. Remote change from B arrives checking item (is_checked = 1)
      // Aplica como remota (sem gerar eco)
      await changeCapture.runAsRemote(() async {
        await (db.update(
          db.shoppingItems,
        )..where((i) => i.id.equals('item-leite'))).write(
          const ShoppingItemsCompanion(
            isChecked: Value(true),
            checkedAt: Value('2026-10-22T12:05:00Z'),
          ),
        );
      });

      // 4. Verifies database state: quantity is 2 AND marked as checked!
      final itemInDb = await (db.select(
        db.shoppingItems,
      )..where((i) => i.id.equals('item-leite'))).getSingle();
      expect(itemInDb.quantityMilli, equals(2000));
      expect(itemInDb.isChecked, isTrue);

      // 5. Verifies remote application DID NOT generate additional column versions for B (no echo!)
      final versionsB = await changeCapture.getCapturedVersions(
        tableName: 'shopping_items',
        rowId: 'item-leite',
      );
      expect(versionsB.any((v) => v.siteId == 'site-b'), isFalse);
    });
  });

  group('DriftChangeSource & ChangeCapture - Special cases and coverage', () {
    setUp(() async {
      await changeCapture.activateHousehold(
        householdId: householdId,
        name: 'Casa Teste',
        localSiteId: localSiteId,
      );
    });

    test(
      'captura e serializa recipe_tags com chave composta recipe_id:tag',
      () async {
        await db
            .into(db.recipes)
            .insert(
              RecipesCompanion.insert(
                id: 'rec-1',
                title: 'Bolo de Cenoura',
                instructions: const Value('Misture tudo e asse.'),
              ),
            );

        final hlcTag = Hlc(millis: 1500, counter: 0, siteId: localSiteId);
        await changeCapture.runWithHlc(hlcTag, () async {
          await db
              .into(db.recipeTags)
              .insert(
                const RecipeTagsCompanion(
                  recipeId: Value('rec-1'),
                  tag: Value('sobremesa'),
                ),
              );
        });

        final versions = await changeCapture.getCapturedVersions(
          tableName: 'recipe_tags',
          rowId: 'rec-1:sobremesa',
        );
        expect(versions, isNotEmpty);
        expect(versions.first.rowId, equals('rec-1:sobremesa'));

        final res = await changeSource.changesNotCoveredBy(
          VersionVector.empty,
          {SyncArea.home},
        );
        expect(res.isOk, isTrue);
        final changes = res.valueOrNull!;
        final tagChange = changes.firstWhere((c) => c.table == 'recipe_tags');
        expect(tagChange.rowId, equals('rec-1:sobremesa'));
        expect(tagChange.value, isNotNull);
      },
    );

    test(
      'clearCapturedVersions e clearCapturedTombstones limpam registros',
      () async {
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-clear',
                canonicalName: 'Produto Limpar',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );
        expect(await changeCapture.countCapturedVersions(), greaterThan(0));

        await (db.delete(
          db.products,
        )..where((p) => p.id.equals('p-clear'))).go();
        expect(await changeCapture.countCapturedTombstones(), greaterThan(0));

        await changeCapture.clearCapturedVersions();
        expect(await changeCapture.countCapturedVersions(), equals(0));

        await changeCapture.clearCapturedTombstones();
        expect(await changeCapture.countCapturedTombstones(), equals(0));
      },
    );

    test('CapturedColumnVersion e CapturedRowTombstone suportam igualdade, hashCode e toString', () {
      final hlc = Hlc(millis: 1000, counter: 0, siteId: 's1');
      final v1 = CapturedColumnVersion(
        table: 'products',
        rowId: 'p1',
        column: 'canonical_name',
        hlc: hlc,
        siteId: 's1',
        updatedAt: '2026-10-22T12:00:00Z',
      );
      final v2 = CapturedColumnVersion(
        table: 'products',
        rowId: 'p1',
        column: 'canonical_name',
        hlc: hlc,
        siteId: 's1',
        updatedAt: '2026-10-22T12:00:00Z',
      );
      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1.key, equals('products:p1:canonical_name'));
      expect(v1.toString(), contains('products:p1:canonical_name'));

      final t1 = CapturedRowTombstone(
        id: 't1',
        table: 'products',
        rowId: 'p1',
        hlc: hlc,
        purgedAt: '2026-10-22T12:00:00Z',
      );
      final t2 = CapturedRowTombstone(
        id: 't1',
        table: 'products',
        rowId: 'p1',
        hlc: hlc,
        purgedAt: '2026-10-22T12:00:00Z',
      );
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1.toString(), contains('products:p1'));
    });

    test(
      'changesNotCoveredBy retorna StorageFailure se o banco falhar',
      () async {
        await db.close();
        final res = await changeSource.changesNotCoveredBy(
          VersionVector.empty,
          {SyncArea.catalog},
        );
        expect(res.isErr, isTrue);
      },
    );

    test(
      'activateHousehold desativa qualquer casa previamente ativa',
      () async {
        await changeCapture.activateHousehold(
          householdId: 'hh-111',
          name: 'Casa Antiga',
          localSiteId: 'site-1',
        );
        expect(await changeCapture.getActiveHouseholdId(), equals('hh-111'));

        await changeCapture.activateHousehold(
          householdId: 'hh-222',
          name: 'Casa Nova',
          localSiteId: 'site-2',
        );
        expect(await changeCapture.getActiveHouseholdId(), equals('hh-222'));

        final allActive = await db
            .customSelect('SELECT id FROM sync_household WHERE active = 1')
            .get();
        expect(allActive.length, equals(1));
        expect(allActive.first.data['id'], equals('hh-222'));
      },
    );

    test(
      'advanceLocalHlc preserves monotonicity even with physical clock retreat',
      () async {
        await changeCapture.activateHousehold(
          householdId: householdId,
          name: 'Casa',
          localSiteId: localSiteId,
        );

        // 1. Records a version with clock at 15:00
        fakeClock.setTo(DateTime.utc(2026, 10, 22, 15, 0, 0));
        final hlc1500 = await changeCapture.advanceLocalHlc();

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-mono',
                canonicalName: 'Item Monot\u00F4nico',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );

        // 2. Clears temporary HLC from settings (simulates app restart)
        await changeCapture.setCurrentHlc(null);
        expect(await changeCapture.getCurrentHlc(), isNull);

        // 3. System clock regresses to 14:00 (negative clock drift)
        fakeClock.setTo(DateTime.utc(2026, 10, 22, 14, 0, 0));

        // 4. advanceLocalHlc deve obrigatoriamente produzir HLC maior que o de 15:00
        final advanced = await changeCapture.advanceLocalHlc();
        expect(advanced.compareTo(hlc1500), greaterThan(0));
        expect(advanced.millis, greaterThanOrEqualTo(hlc1500.millis));
      },
    );

    test(
      'runWithNextHlc executes action with advanced HLC and restores state',
      () async {
        await changeCapture.activateHousehold(
          householdId: householdId,
          name: 'Casa',
          localSiteId: localSiteId,
        );

        final before = await changeCapture.getCurrentHlc();

        Hlc? insideHlc;
        await changeCapture.runWithNextHlc((hlc) async {
          insideHlc = hlc;
          expect(await changeCapture.getCurrentHlc(), equals(hlc));
        });

        expect(insideHlc, isNotNull);
        expect(await changeCapture.getCurrentHlc(), equals(before));
      },
    );

    test(
      'changesNotCoveredBy cleans orphan versions of purged database records',
      () async {
        await changeCapture.activateHousehold(
          householdId: householdId,
          name: 'Casa',
          localSiteId: localSiteId,
        );

        // Inserts product normally to generate versions
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-orphan',
                canonicalName: 'Produto Fantasma',
                categoryId: const Value('cat-1'),
                defaultUnit: 'un',
              ),
            );

        final versionsBefore = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'p-orphan',
        );
        expect(versionsBefore, isNotEmpty);

        // Simulates hard delete of product with trigger suppression (or trash purge)
        await changeCapture.runAsRemote(() async {
          await (db.delete(
            db.products,
          )..where((tbl) => tbl.id.equals('p-orphan'))).go();
        });

        // Calls changesNotCoveredBy: must detect line absence and clean orphan versions
        final res = await changeSource.changesNotCoveredBy(
          VersionVector.empty,
          {SyncArea.catalog},
        );
        expect(res.isOk, isTrue);

        final versionsAfter = await changeCapture.getCapturedVersions(
          tableName: 'products',
          rowId: 'p-orphan',
        );
        expect(versionsAfter, isEmpty);
      },
    );

    test('localVector isola vetores de pares apenas da casa ativa', () async {
      await changeCapture.activateHousehold(
        householdId: 'hh-current',
        name: 'Casa Atual',
        localSiteId: localSiteId,
      );

      // Vetor da casa antiga inativa
      await db.customStatement(
        'INSERT INTO sync_peer_vectors (household_id, site_id, hlc, updated_at) '
        'VALUES (?, ?, ?, ?)',
        [
          'hh-old',
          'peer-old',
          '2026-10-22T10:00:00.000Z:00000:peer-old',
          '2026-10-22T10:00:00.000Z',
        ],
      );

      // Vetor da casa ativa
      await db.customStatement(
        'INSERT INTO sync_peer_vectors (household_id, site_id, hlc, updated_at) '
        'VALUES (?, ?, ?, ?)',
        [
          'hh-current',
          'peer-active',
          '2026-10-22T12:00:00.000Z:00000:peer-active',
          '2026-10-22T12:00:00.000Z',
        ],
      );

      final vector = await changeSource.localVector();
      expect(vector.maxBySite.containsKey('peer-active'), isTrue);
      expect(vector.maxBySite.containsKey('peer-old'), isFalse);
    });

    test(
      'recipe_tags with multiple colons in tag works and cleans if deleted',
      () async {
        await changeCapture.activateHousehold(
          householdId: householdId,
          name: 'Casa',
          localSiteId: localSiteId,
        );

        await db
            .into(db.recipes)
            .insert(
              RecipesCompanion.insert(id: 'rec-colon', title: 'Bolo Especial'),
            );

        await db
            .into(db.recipeTags)
            .insert(
              RecipeTagsCompanion.insert(
                recipeId: 'rec-colon',
                tag: 'tipo:sobremesa:rapida',
              ),
            );

        final res = await changeSource.changesNotCoveredBy(
          VersionVector.empty,
          {SyncArea.home},
        );
        expect(res.isOk, isTrue);
        final tagVersions = res.valueOrNull!
            .where((c) => c.table == 'recipe_tags')
            .toList();
        expect(tagVersions, isNotEmpty);
        expect(
          tagVersions.any(
            (c) => c.column == 'tag' && c.value == 'tipo:sobremesa:rapida',
          ),
          isTrue,
        );

        // Deleta tag do banco sem trigger para simular expurgo
        await changeCapture.runAsRemote(() async {
          await db.customStatement(
            'DELETE FROM recipe_tags WHERE recipe_id = ? AND tag = ?',
            ['rec-colon', 'tipo:sobremesa:rapida'],
          );
        });

        // When called again, must clean orphan recipe_tags version
        await changeSource.changesNotCoveredBy(VersionVector.empty, {
          SyncArea.home,
        });
        final orphaned = await changeCapture.getCapturedVersions(
          tableName: 'recipe_tags',
          rowId: 'rec-colon:tipo:sobremesa:rapida',
        );
        expect(orphaned, isEmpty);
      },
    );

    test('getCapturedTombstones filtra por sinceHlc', () async {
      final hlc1 = Hlc(millis: 1000, counter: 0, siteId: localSiteId);
      final hlc2 = Hlc(millis: 2000, counter: 0, siteId: localSiteId);

      await db.customStatement(
        'INSERT INTO sync_row_tombstones (id, table_name, row_id, hlc, purged_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['t1', 'products', 'p1', hlc1.pack(), '2026-10-22T10:00:00Z'],
      );
      await db.customStatement(
        'INSERT INTO sync_row_tombstones (id, table_name, row_id, hlc, purged_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['t2', 'products', 'p2', hlc2.pack(), '2026-10-22T12:00:00Z'],
      );

      final allTombstones = await changeCapture.getCapturedTombstones();
      expect(allTombstones.length, equals(2));

      final filtered = await changeCapture.getCapturedTombstones(
        sinceHlc: hlc1,
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('t2'));
    });
  });
}
