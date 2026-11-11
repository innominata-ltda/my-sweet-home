library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/sync/change_capture.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_table_registry_impl.dart';

import '../../fakes/fake_clock.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('RF-121 / SPEC-013: Sync filter by area and local data exclusion', () {
    late AppDatabase dbA;
    late AppDatabase dbB;
    late FakeClock clock;
    late ChangeCapture captureB;
    late SyncTableRegistryImpl registry;
    late DriftChangeSource sourceA;

    const siteA = 'site-device-a-1111';
    const siteB = 'site-device-b-2222';
    const householdId = 'hh-republica-4321';

    setUp(() async {
      dbA = AppDatabase.memory();
      dbB = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 10, 22, 14, 0, 0));
      captureB = ChangeCapture(db: dbB, clock: clock);
      registry = SyncTableRegistryImpl();
      sourceA = DriftChangeSource(db: dbA, registry: registry);

      // Configures active household in A and B with initial areas
      await dbA
          .into(dbA.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Rep\u00FAblica das Flores',
              localSiteId: siteA,
              sharedAreas: 'home,catalog',
              createdAt: '2026-10-22T10:00:00.000Z',
              joinedAt: '2026-10-22T10:00:00.000Z',
              active: const Value(true),
            ),
          );

      await dbB
          .into(dbB.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: householdId,
              name: 'Rep\u00FAblica das Flores',
              localSiteId: siteB,
              sharedAreas: 'home,catalog',
              createdAt: '2026-10-22T10:00:00.000Z',
              joinedAt: '2026-10-22T10:00:00.000Z',
              active: const Value(true),
            ),
          );
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    test('CA-2.1: Household sharing only "home" - expense is not transmitted, shopping item is', () async {
      // Shared category (catalog)
      await dbA
          .into(dbA.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-mercado',
              name: 'Mercado',
              kind: 'both',
              iconKey: 'cart',
            ),
          );

      // Shared product (catalog)
      await dbA
          .into(dbA.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-leite',
              canonicalName: 'Leite Integral 1L',
              categoryId: const Value('cat-mercado'),
              defaultUnit: 'l',
            ),
          );

      // Shopping list and item (home area)
      await dbA
          .into(dbA.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              id: 'list-semana',
              name: 'Compras da semana',
            ),
          );
      await dbA
          .into(dbA.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              id: 'item-leite',
              listId: const Value('list-semana'),
              productId: const Value('prod-leite'),
              quantityMilli: const Value(2000),
              unit: const Value('l'),
              position: 0,
              source: 'manual',
            ),
          );

      // Expense (finance area)
      await dbA
          .into(dbA.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'exp-privada-1',
              categoryId: const Value('cat-mercado'),
              amountCents: 4500,
              occurredOn: '2026-10-22',
              description: const Value('Almo\u00E7o individual'),
            ),
          );

      // Peer B has no version yet (empty vector)
      final peerVectorB = VersionVector.empty;

      // Sync only with 'home' area (plus implicit catalog via effectiveAreas)
      final activeAreas = SyncTableRegistryImpl.effectiveAreas({SyncArea.home});
      expect(activeAreas, equals({SyncArea.home, SyncArea.catalog}));

      final changesResult = await sourceA.changesNotCoveredBy(
        peerVectorB,
        activeAreas,
      );
      expect(changesResult.isOk, isTrue);

      final changes = changesResult.valueOrNull!;
      final tablesChanged = changes.map((c) => c.table).toSet();

      // shopping_items e shopping_lists DEVEM estar presentes
      expect(tablesChanged, contains('shopping_items'));
      expect(tablesChanged, contains('shopping_lists'));

      // Catalog MUST be present
      expect(tablesChanged, contains('products'));
      expect(tablesChanged, contains('categories'));

      // Expenses MUST NOT be present
      expect(
        tablesChanged,
        isNot(contains('expenses')),
        reason: 'CA-2.1: Expenses must not be sent when only "home" is active',
      );
      expect(changes.any((c) => c.rowId == 'exp-privada-1'), isFalse);

      // Simulates applying changes in database B under runAsRemote (no echo)
      await captureB.runAsRemote(() async {
        await dbB
            .into(dbB.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-mercado',
                name: 'Mercado',
                kind: 'both',
                iconKey: 'cart',
              ),
            );
        await dbB
            .into(dbB.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-leite',
                canonicalName: 'Leite Integral 1L',
                categoryId: const Value('cat-mercado'),
                defaultUnit: 'l',
              ),
            );
        await dbB
            .into(dbB.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(
                id: 'list-semana',
                name: 'Compras da semana',
              ),
            );
        await dbB
            .into(dbB.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                id: 'item-leite',
                listId: const Value('list-semana'),
                productId: const Value('prod-leite'),
                quantityMilli: const Value(2000),
                unit: const Value('l'),
                position: 0,
                source: 'manual',
              ),
            );
      });

      // B recebeu o item da lista
      final bItems = await dbB.select(dbB.shoppingItems).get();
      expect(bItems.length, equals(1));
      expect(bItems.first.id, equals('item-leite'));

      // B DID NOT receive the expense
      final bExpenses = await dbB.select(dbB.expenses).get();
      expect(bExpenses, isEmpty);
    });

    test(
      'CA-2.2: Catalog always accompanies any active shared area (RN-311)',
      () async {
        // Creates catalog elements
        await dbA
            .into(dbA.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-alimentos',
                name: 'Alimentos',
                kind: 'product',
                iconKey: 'food',
              ),
            );
        await dbA
            .into(dbA.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-arroz',
                canonicalName: 'Arroz Branco 5kg',
                categoryId: const Value('cat-alimentos'),
                defaultUnit: 'kg',
              ),
            );
        await dbA
            .into(dbA.productAliases)
            .insert(
              ProductAliasesCompanion.insert(
                id: 'alias-arroz-agulhinha',
                productId: 'prod-arroz',
                alias: 'Arroz Agulhinha',
                normalizedAlias: 'arroz agulhinha',
                source: 'user',
              ),
            );
        await dbA
            .into(dbA.stores)
            .insert(
              StoresCompanion.insert(
                id: 'store-extra',
                name: 'Supermercado Extra',
                cnpj: const Value('12.345.678/0001-90'),
              ),
            );

        // 1. Scenario: Only Home area active
        final homeEffective = SyncTableRegistryImpl.effectiveAreas({
          SyncArea.home,
        });
        final changesHome = (await sourceA.changesNotCoveredBy(
          VersionVector.empty,
          homeEffective,
        )).valueOrNull!;

        final homeTables = changesHome.map((c) => c.table).toSet();
        expect(homeTables, contains('products'));
        expect(homeTables, contains('product_aliases'));
        expect(homeTables, contains('categories'));
        expect(homeTables, contains('stores'));

        // 2. Scenario: Only Finances area active
        final financeEffective = SyncTableRegistryImpl.effectiveAreas({
          SyncArea.finance,
        });
        final changesFinance = (await sourceA.changesNotCoveredBy(
          VersionVector.empty,
          financeEffective,
        )).valueOrNull!;

        final financeTables = changesFinance.map((c) => c.table).toSet();
        expect(financeTables, contains('products'));
        expect(financeTables, contains('product_aliases'));
        expect(financeTables, contains('categories'));
        expect(financeTables, contains('stores'));
      },
    );

    test('CA-2.3: Integrity scan - no strictly local data (RN-312) propagates', () async {
      // Populates database A with local and sensitive elements
      // 1. Settings (tokens, mascot, preferences)
      await dbA
          .into(dbA.settings)
          .insert(
            SettingsCompanion.insert(
              key: 'auth_jwt_token',
              value: 'secret-token-bearer-12345',
            ),
          );
      await dbA
          .into(dbA.settings)
          .insert(
            SettingsCompanion.insert(
              key: 'notification_enabled',
              value: 'true',
            ),
          );

      // 2. Consents
      await dbA
          .into(dbA.consents)
          .insert(
            ConsentsCompanion.insert(
              key: 'household_sync',
              granted: true,
              grantedAt: const Value('2026-10-22T10:00:00.000Z'),
            ),
          );

      // 3. Attachments locais
      await dbA
          .into(dbA.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: 'att-cupom-local',
              path: '/local/internal/cupom_foto.jpg',
              kind: const Value('receipt'),
            ),
          );

      // 4. Product denials locais
      await dbA
          .into(dbA.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-limpeza',
              name: 'Limpeza',
              kind: 'product',
              iconKey: 'broom',
            ),
          );
      await dbA
          .into(dbA.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-sabao',
              canonicalName: 'Sab\u00E3o em p\u00F3',
              categoryId: const Value('cat-limpeza'),
              defaultUnit: 'kg',
            ),
          );
      await dbA
          .into(dbA.productDenials)
          .insert(
            ProductDenialsCompanion.insert(
              id: 'denial-1',
              productId: 'prod-sabao',
              rawText: 'sabao liquido',
              normalizedText: 'sabao liquido',
            ),
          );

      // 5. Tarefa com colunas de Google Calendar (RN-312)
      await dbA
          .into(dbA.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-gcal-1',
              title: 'Limpar a casa',
              remoteEventId: const Value('gcal-private-event-id-999'),
              remoteEtag: const Value('etag-private-xyz'),
              syncState: const Value('synced'),
            ),
          );

      // 6. Compra com foto e chave NFC-e (RN-312)
      await dbA
          .into(dbA.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'purch-nfe-1',
              purchasedAt: '2026-10-22T12:00:00.000Z',
              totalCents: 15000,
              source: 'ocr',
              receiptImagePath: const Value(
                '/photos/privadas/cupom_supermercado.png',
              ),
              receiptKey: const Value(
                '35200112345678000195550010000000011000000010',
              ),
            ),
          );

      // 7. PricePoints derivados (RN-327)
      await dbA
          .into(dbA.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp-derivado-1',
              productId: const Value('prod-sabao'),
              observedAt: '2026-10-22T12:00:00.000Z',
              unitPriceCents: 2500,
              normalizedPriceCents: 2500,
              quantityMilli: 1000,
              unit: 'kg',
              source: 'manual',
            ),
          );

      // Generates all changes for all active areas
      final allAreas = {SyncArea.catalog, SyncArea.home, SyncArea.finance};
      final changes = (await sourceA.changesNotCoveredBy(
        VersionVector.empty,
        allAreas,
      )).valueOrNull!;

      expect(changes, isNotEmpty);

      final localTableSet = registry.localTables;
      const forbiddenColumns = {
        'remote_event_id',
        'remote_etag',
        'sync_state',
        'receipt_image_path',
        'receipt_key',
      };

      for (final cv in changes) {
        // 1. Nenhuma tabela local trafega
        expect(
          localTableSet,
          isNot(contains(cv.table)),
          reason:
              'Local table "${cv.table}" violated RN-312 and appeared in transmitted changes',
        );

        // 2. Nenhuma tabela derivada trafega
        final spec = registry.findTable(cv.table);
        expect(
          spec?.derived,
          isNot(isTrue),
          reason:
              'Derived table "${cv.table}" violated RN-327 and appeared in transmitted changes',
        );

        // 3. No local exclusion column is transmitted
        expect(
          forbiddenColumns,
          isNot(contains(cv.column)),
          reason:
              'Sensitive/local column "${cv.column}" of table "${cv.table}" '
              'violated RN-312 and appeared in changes',
        );

        // 4. Sensitive values never appear in payload
        final strValue = cv.value?.toString() ?? '';
        expect(strValue, isNot(contains('secret-token')));
        expect(strValue, isNot(contains('gcal-private')));
        expect(strValue, isNot(contains('cupom_supermercado')));
        expect(
          strValue,
          isNot(contains('35200112345678000195550010000000011000000010')),
        );
      }
    });

    test('recurring_rules synchronizes to correct area depending on row kind (plan §Seams)', () async {
      // Recurring rule for task (Home Area)
      await dbA
          .into(dbA.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: 'rule-task-limpeza',
              kind: 'task',
              rrule: 'FREQ=WEEKLY;BYDAY=SA',
              startsOn: '2026-10-01',
              title: 'Faxina semanal',
            ),
          );

      // Recurring rule for expense (Finance Area)
      await dbA
          .into(dbA.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: 'rule-exp-internet',
              kind: 'expense',
              rrule: 'FREQ=MONTHLY;BYMONTHDAY=10',
              startsOn: '2026-10-01',
              title: 'Internet fibra',
              amountCents: const Value(12000),
            ),
          );

      // Recurring rule for fixed bill (Finance Area)
      await dbA
          .into(dbA.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: 'rule-bill-aluguel',
              kind: 'bill',
              rrule: 'FREQ=MONTHLY;BYMONTHDAY=5',
              startsOn: '2026-10-01',
              title: 'Aluguel ap\u00EA',
              amountCents: const Value(250000),
            ),
          );

      // 1. Sincronizando apenas Casa (home + catalog)
      final homeChanges = (await sourceA.changesNotCoveredBy(
        VersionVector.empty,
        {SyncArea.home, SyncArea.catalog},
      )).valueOrNull!;

      final homeRuleIds = homeChanges
          .where((c) => c.table == 'recurring_rules')
          .map((c) => c.rowId)
          .toSet();

      expect(homeRuleIds, contains('rule-task-limpeza'));
      expect(homeRuleIds, isNot(contains('rule-exp-internet')));
      expect(homeRuleIds, isNot(contains('rule-bill-aluguel')));

      // 2. Synchronizing only Finances (finance + catalog)
      final financeChanges = (await sourceA.changesNotCoveredBy(
        VersionVector.empty,
        {SyncArea.finance, SyncArea.catalog},
      )).valueOrNull!;

      final financeRuleIds = financeChanges
          .where((c) => c.table == 'recurring_rules')
          .map((c) => c.rowId)
          .toSet();

      expect(financeRuleIds, contains('rule-exp-internet'));
      expect(financeRuleIds, contains('rule-bill-aluguel'));
      expect(financeRuleIds, isNot(contains('rule-task-limpeza')));
    });

    test(
      'RN-315: Disabling an area stops sending new changes from that area',
      () async {
        // Initially household shared Home and Finances
        var activeAreas = {SyncArea.home, SyncArea.finance, SyncArea.catalog};

        await dbA
            .into(dbA.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-lazer',
                name: 'Lazer',
                kind: 'expense',
                iconKey: 'gamepad',
              ),
            );

        await dbA
            .into(dbA.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'exp-cinema-1',
                categoryId: const Value('cat-lazer'),
                amountCents: 6000,
                occurredOn: '2026-10-22',
                description: const Value('Cinema'),
              ),
            );

        final changes = (await sourceA.changesNotCoveredBy(
          VersionVector.empty,
          activeAreas,
        )).valueOrNull!;
        expect(changes.any((c) => c.rowId == 'exp-cinema-1'), isTrue);

        // Records highest vector reached
        final lastVector = await sourceA.localVector();

        // User disables Finances area
        activeAreas = SyncTableRegistryImpl.effectiveAreas({SyncArea.home});
        expect(activeAreas, equals({SyncArea.home, SyncArea.catalog}));

        // Adds new private expense after area disabling
        await dbA
            .into(dbA.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'exp-livro-2',
                categoryId: const Value('cat-lazer'),
                amountCents: 8500,
                occurredOn: '2026-10-22',
                description: const Value('Livro t\u00E9cnico'),
              ),
            );

        // Adiciona novo item de lista compartilhado
        await dbA
            .into(dbA.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(id: 'list-nova', name: 'Padaria'),
            );

        // Collects incremental changes since lastVector
        final incrementalChanges = (await sourceA.changesNotCoveredBy(
          lastVector,
          activeAreas,
        )).valueOrNull!;

        // Lista de padaria aparece
        expect(incrementalChanges.any((c) => c.rowId == 'list-nova'), isTrue);

        // New expense DOES NOT appear
        expect(
          incrementalChanges.any((c) => c.rowId == 'exp-livro-2'),
          isFalse,
        );
      },
    );

    test('RN-311: If no functional area (Home or Finances) is active, catalog does not sync isolated', () async {
      // Cria produtos no banco A
      await dbA
          .into(dbA.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-geral',
              name: 'Geral',
              kind: 'both',
              iconKey: 'cart',
            ),
          );
      await dbA
          .into(dbA.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod-geral',
              canonicalName: 'Produto Qualquer',
              categoryId: const Value('cat-geral'),
              defaultUnit: 'un',
            ),
          );

      // 1. Empty areas
      final emptyAreas = SyncTableRegistryImpl.effectiveAreas({});
      final changesEmpty = (await sourceA.changesNotCoveredBy(
        VersionVector.empty,
        emptyAreas,
      )).valueOrNull!;
      expect(changesEmpty, isEmpty);

      // 2. Only catalog passed without Home or Finances
      final catalogOnlyAreas = SyncTableRegistryImpl.effectiveAreas({
        SyncArea.catalog,
      });
      final changesCatalogOnly = (await sourceA.changesNotCoveredBy(
        VersionVector.empty,
        catalogOnlyAreas,
      )).valueOrNull!;
      expect(changesCatalogOnly, isEmpty);
    });
  });
}
