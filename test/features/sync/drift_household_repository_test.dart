import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_settings_repository.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdKeyStore keyStore;
  late FakeSettingsRepository settingsRepository;
  late FakeClock clock;
  late SequentialIdGenerator idGenerator;
  late DriftHouseholdRepository repository;

  final testKey = HouseholdKey(List.generate(32, (i) => i));

  setUp(() async {
    db = AppDatabase.memory();
    keyStore = FakeHouseholdKeyStore();
    settingsRepository = FakeSettingsRepository();
    clock = FakeClock(DateTime.utc(2026, 10, 15, 12, 0));
    idGenerator = SequentialIdGenerator();

    repository = DriftHouseholdRepository(
      db: db,
      keyStore: keyStore,
      settingsRepository: settingsRepository,
      clock: clock,
      idGenerator: idGenerator,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftHouseholdRepository.getHousehold & watchHousehold', () {
    test('returns Ok(null) when no household exists in database', () async {
      final result = await repository.getHousehold();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test(
      'watchHousehold emite null inicialmente e atualiza após criação',
      () async {
        final expectation = expectLater(
          repository.watchHousehold(),
          emitsInOrder([
            isNull,
            predicate<Household?>((h) => h != null && h.name == 'Casa Silva'),
          ]),
        );

        await pumpEventQueue();

        await repository.createHousehold(
          name: 'Casa Silva',
          deviceName: 'Meu Celular',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        await expectation;
      },
    );

    test(
      'recupera auto-recuperando quando existem múltiplas casas ativas',
      () async {
        final now = DateTime.utc(2026, 10, 15, 10, 0);
        final earlier = DateTime.utc(2026, 10, 14, 10, 0);

        // Inserir duas casas ativas manualmente
        await db
            .into(db.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: 'house-old',
                name: 'Casa Antiga',
                localSiteId: 'site-old',
                sharedAreas: 'home',
                createdAt: earlier.toIso8601String(),
                joinedAt: earlier.toIso8601String(),
                active: const Value(true),
              ),
            );

        await db
            .into(db.syncHouseholds)
            .insert(
              SyncHouseholdsCompanion.insert(
                id: 'house-new',
                name: 'Casa Nova',
                localSiteId: 'site-new',
                sharedAreas: 'home,finance',
                createdAt: now.toIso8601String(),
                joinedAt: now.toIso8601String(),
                active: const Value(true),
              ),
            );

        final result = await repository.getHousehold();
        expect(result.isOk, isTrue);
        final household = result.valueOrNull!;
        expect(household.id, 'house-new');
        expect(household.name, 'Casa Nova');

        // Verifica que a antiga foi desativada
        final oldRow = await (db.select(
          db.syncHouseholds,
        )..where((tbl) => tbl.id.equals('house-old'))).getSingle();
        expect(oldRow.active, isFalse);
      },
    );

    test('retorna Err(HouseholdFailure) se ocorrer falha no banco', () async {
      await db.customStatement('DROP TABLE sync_household;');
      final result = await repository.getHousehold();
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.getMembers & watchMembers', () {
    test('lista apenas membros ativos ordenados por joinedAt asc', () async {
      await repository.createHousehold(
        name: 'Casa Silva',
        deviceName: 'Aparelho 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      await repository.upsertMember(
        siteId: 'site-remote-1',
        deviceName: 'Aparelho 2',
        lastSeenAt: DateTime.utc(2026, 10, 15, 12, 5),
      );

      final membersRes = await repository.getMembers();
      expect(membersRes.isOk, isTrue);
      final members = membersRes.valueOrNull!;
      expect(members.length, 2);
      expect(members[0].name, 'Aparelho 1');
      expect(members[1].name, 'Aparelho 2');
    });

    test('watchMembers emite membros ativos em ordem', () async {
      final expectation = expectLater(
        repository.watchMembers(),
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await pumpEventQueue();

      await repository.createHousehold(
        name: 'Casa Silva',
        deviceName: 'Aparelho 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      await expectation;
    });

    test(
      'retorna Err(HouseholdFailure) ao listar membros se falha no banco',
      () async {
        await db.customStatement('DROP TABLE sync_members;');
        final result = await repository.getMembers();
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<HouseholdFailure>());
      },
    );
  });

  group('DriftHouseholdRepository.createHousehold', () {
    test('cria casa com consentimento, salva chave e membros', () async {
      expect(settingsRepository.householdSyncAllowed, isFalse);

      final res = await repository.createHousehold(
        name: 'Nossa Casa',
        deviceName: 'Telefone Principal',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      expect(res.isOk, isTrue);
      final household = res.valueOrNull!;
      expect(household.name, 'Nossa Casa');
      expect(
        household.sharedAreas,
        containsAll([SyncArea.home, SyncArea.catalog]),
      );
      expect(settingsRepository.householdSyncAllowed, isTrue);

      final storedKey = await keyStore.read();
      expect(storedKey.valueOrNull, equals(testKey));

      final members = (await repository.getMembers()).valueOrNull!;
      expect(members, hasLength(1));
      expect(members.first.name, 'Telefone Principal');
    });

    test('fails and does not create if key write fails', () async {
      keyStore.failNext = true;

      final res = await repository.createHousehold(
        name: 'Nossa Casa',
        deviceName: 'Telefone Principal',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      expect(res.isErr, isTrue);
    });

    test('desativa casa e membros anteriores ao criar nova', () async {
      await repository.createHousehold(
        name: 'Primeira Casa',
        deviceName: 'Tel 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      final firstHousehold = (await repository.getHousehold()).valueOrNull!;

      await repository.createHousehold(
        name: 'Segunda Casa',
        deviceName: 'Tel 2',
        sharedAreas: {SyncArea.finance},
        key: testKey,
      );

      final secondHousehold = (await repository.getHousehold()).valueOrNull!;
      expect(secondHousehold.id, isNot(equals(firstHousehold.id)));
      expect(secondHousehold.name, 'Segunda Casa');

      final allHouseholds = await db.select(db.syncHouseholds).get();
      expect(allHouseholds.length, 2);
      expect(
        allHouseholds.firstWhere((h) => h.id == firstHousehold.id).active,
        isFalse,
      );
      expect(
        allHouseholds.firstWhere((h) => h.id == secondHousehold.id).active,
        isTrue,
      );
    });
  });

  group('DriftHouseholdRepository.updateSharedAreas', () {
    test('updates active areas keeping catalog', () async {
      await repository.createHousehold(
        name: 'Casa',
        deviceName: 'Tel',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      final updateRes = await repository.updateSharedAreas({SyncArea.finance});
      expect(updateRes.isOk, isTrue);

      final updated = (await repository.getHousehold()).valueOrNull!;
      expect(
        updated.sharedAreas,
        containsAll([SyncArea.finance, SyncArea.catalog]),
      );
      expect(updated.sharedAreas.contains(SyncArea.home), isFalse);
    });

    test('retorna Err se banco falhar', () async {
      await db.customStatement('DROP TABLE sync_household;');
      final updateRes = await repository.updateSharedAreas({SyncArea.finance});
      expect(updateRes.isErr, isTrue);
      expect(updateRes.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.runInitialBackfill', () {
    test('inserts column versions for existing records in shared areas and ignores unshared areas', () async {
      // Insert categories and tasks before creating household (home area)
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-home-1',
              name: 'Limpeza',
              kind: 'task',
              iconKey: 'cleaning',
            ),
          );

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-1',
              title: 'Limpar chão',
              categoryId: const Value('cat-home-1'),
              isCompleted: const Value(false),
              createdAt: const Value('2026-10-15T10:00:00.000Z'),
              updatedAt: const Value('2026-10-15T10:00:00.000Z'),
            ),
          );

      // Insert expense (finance area - unshared)
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'exp-1',
              description: const Value('Mercado'),
              amountCents: 2500,
              occurredOn: '2026-10-15',
            ),
          );

      final createRes = await repository.createHousehold(
        name: 'Casa Com Tarefas',
        deviceName: 'Aparelho 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      expect(createRes.isOk, isTrue);

      final columnVersions = await db.select(db.syncColumnVersions).get();
      expect(columnVersions, isNotEmpty);
      expect(
        columnVersions.any(
          (v) => v.tableNameCol == 'tasks' && v.rowId == 'task-1',
        ),
        isTrue,
      );
      // Verify unshared area table was ignored by backfill
      expect(columnVersions.any((v) => v.tableNameCol == 'expenses'), isFalse);
    });

    test('retorna Err se falhar', () async {
      final household = Household(
        id: 'h1',
        name: 'C',
        localSiteId: 's1',
        sharedAreas: {SyncArea.home},
        createdAt: DateTime.utc(2026, 1, 1),
        joinedAt: DateTime.utc(2026, 1, 1),
      );
      await db.customStatement('DROP TABLE tasks;');
      final res = await repository.runInitialBackfill(household);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.hasPendingLocalChanges', () {
    test('returns Ok(false) when no household exists', () async {
      final res = await repository.hasPendingLocalChanges();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull, isFalse);
    });

    test(
      'quando só há este aparelho, verifica contagem de versões locais',
      () async {
        await repository.createHousehold(
          name: 'Casa Solo',
          deviceName: 'Tel 1',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        // Right after creation without local data, syncColumnVersions may be empty
        await db.delete(db.syncColumnVersions).go();
        final emptyRes = await repository.hasPendingLocalChanges();
        expect(emptyRes.isOk, isTrue);
        expect(emptyRes.valueOrNull, isFalse);

        // Insert local version
        final household = (await repository.getHousehold()).valueOrNull!;
        await db
            .into(db.syncColumnVersions)
            .insert(
              SyncColumnVersionsCompanion.insert(
                tableNameCol: 'tasks',
                rowId: 't1',
                columnName: 'title',
                hlc: '100:0:site-1',
                siteId: household.localSiteId,
                updatedAt: '2026-10-15T12:00:00.000Z',
              ),
            );

        final filledRes = await repository.hasPendingLocalChanges();
        expect(filledRes.isOk, isTrue);
        expect(filledRes.valueOrNull, isTrue);
      },
    );

    test('when there are other members, verifies sync_peer_vectors covering local versions', () async {
      await repository.createHousehold(
        name: 'Casa Com Pares',
        deviceName: 'Tel 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      final household = (await repository.getHousehold()).valueOrNull!;

      // Adicionar outro membro
      await repository.upsertMember(
        siteId: 'site-remote-2',
        deviceName: 'Tel 2',
      );

      // Insert local version
      await db
          .into(db.syncColumnVersions)
          .insert(
            SyncColumnVersionsCompanion.insert(
              tableNameCol: 'tasks',
              rowId: 't1',
              columnName: 'title',
              hlc: '0000000000100:0000:site-1',
              siteId: household.localSiteId,
              updatedAt: '2026-10-15T12:00:00.000Z',
            ),
          );

      // Without peer vector covering -> has pending changes
      final pendingRes1 = await repository.hasPendingLocalChanges();
      expect(pendingRes1.isOk, isTrue);
      expect(pendingRes1.valueOrNull, isTrue);

      // Insert peer vector covering local version
      await db
          .into(db.syncPeerVectors)
          .insert(
            SyncPeerVectorsCompanion.insert(
              householdId: household.id,
              siteId: household.localSiteId,
              hlc: '0000000000200:0000:site-1',
              updatedAt: '2026-10-15T12:00:00.000Z',
            ),
          );

      final pendingRes2 = await repository.hasPendingLocalChanges();
      expect(pendingRes2.isOk, isTrue);
      expect(pendingRes2.valueOrNull, isFalse);
    });

    test('retorna Err se falha no banco', () async {
      await repository.createHousehold(
        name: 'Casa',
        deviceName: 'Tel',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );
      await db.customStatement('DROP TABLE sync_column_versions;');
      final res = await repository.hasPendingLocalChanges();
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.leaveHousehold', () {
    test(
      'sair mantendo cópia preserva dados e apaga chave e consentimento',
      () async {
        await repository.createHousehold(
          name: 'Casa Para Sair',
          deviceName: 'Tel',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        // Inserir categoria
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-stay',
                name: 'Geral',
                kind: 'task',
                iconKey: 'icon',
              ),
            );

        final leaveRes = await repository.leaveHousehold(keepCopy: true);
        expect(leaveRes.isOk, isTrue);

        expect(settingsRepository.householdSyncAllowed, isFalse);
        expect((await keyStore.read()).valueOrNull, isNull);

        final household = (await repository.getHousehold()).valueOrNull;
        expect(household, isNull);

        final cat = await (db.select(
          db.categories,
        )..where((tbl) => tbl.id.equals('cat-stay'))).getSingleOrNull();
        expect(cat, isNotNull);
      },
    );

    test(
      'sair sem manter cópia limpa tabelas compartilhadas exceto catálogo base',
      () async {
        await repository.createHousehold(
          name: 'Casa Limpar',
          deviceName: 'Tel',
          sharedAreas: {SyncArea.home, SyncArea.catalog},
          key: testKey,
        );

        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-del',
                title: 'Para apagar',
                isCompleted: const Value(false),
                createdAt: const Value('2026-10-15T10:00:00.000Z'),
                updatedAt: const Value('2026-10-15T10:00:00.000Z'),
              ),
            );

        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-keep',
                canonicalName: 'Arroz',
                defaultUnit: 'kg',
                createdAt: const Value('2026-10-15T10:00:00.000Z'),
                updatedAt: const Value('2026-10-15T10:00:00.000Z'),
              ),
            );

        final leaveRes = await repository.leaveHousehold(keepCopy: false);
        expect(leaveRes.isOk, isTrue);

        final tasks = await db.select(db.tasks).get();
        expect(tasks, isEmpty);

        final products = await db.select(db.products).get();
        expect(products, hasLength(1));
      },
    );

    test(
      'se não há casa ativa, leaveHousehold retorna Ok(null) sem erro',
      () async {
        final leaveRes = await repository.leaveHousehold(keepCopy: true);
        expect(leaveRes.isOk, isTrue);
      },
    );

    test('retorna Err se falha no banco', () async {
      await repository.createHousehold(
        name: 'Casa',
        deviceName: 'Tel',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );
      await db.customStatement('DROP TABLE sync_column_versions;');
      final res = await repository.leaveHousehold(keepCopy: false);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.getJoinPreviewData', () {
    test(
      'conta registros por área corretamente separando recurring_rules',
      () async {
        // Home: tasks
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-p1',
                title: 'Lavar louça',
                isCompleted: const Value(false),
                createdAt: const Value('2026-10-15T10:00:00.000Z'),
                updatedAt: const Value('2026-10-15T10:00:00.000Z'),
              ),
            );

        // Recurring rules: 1 task (home), 1 expense (finance)
        await db
            .into(db.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: 'rule-task',
                kind: 'task',
                title: 'Regar plantas',
                rrule: 'FREQ=WEEKLY;INTERVAL=1',
                startsOn: '2026-10-15',
              ),
            );
        await db
            .into(db.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: 'rule-exp',
                kind: 'expense',
                title: 'Internet',
                rrule: 'FREQ=MONTHLY;INTERVAL=1',
                startsOn: '2026-10-15',
              ),
            );

        // Catalog: products
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'prod-p1',
                canonicalName: 'Feijão',
                defaultUnit: 'kg',
                createdAt: const Value('2026-10-15T10:00:00.000Z'),
                updatedAt: const Value('2026-10-15T10:00:00.000Z'),
              ),
            );

        final previewRes = await repository.getJoinPreviewData();
        expect(previewRes.isOk, isTrue);
        final preview = previewRes.valueOrNull!;
        expect(
          preview.homeRecordsCount,
          greaterThanOrEqualTo(2),
        ); // task + recurring rule task
        expect(
          preview.financeRecordsCount,
          greaterThanOrEqualTo(1),
        ); // recurring rule expense
        expect(preview.catalogRecordsCount, greaterThanOrEqualTo(1)); // product
      },
    );

    test('returns zero counts when there are no records', () async {
      final previewRes = await repository.getJoinPreviewData();
      expect(previewRes.isOk, isTrue);
      final preview = previewRes.valueOrNull!;
      expect(preview.homeRecordsCount, 0);
      expect(preview.financeRecordsCount, 0);
      expect(preview.catalogRecordsCount, 0);
    });

    test('retorna Err se banco falhar', () async {
      await db.customStatement('DROP TABLE tasks;');
      final previewRes = await repository.getJoinPreviewData();
      expect(previewRes.isErr, isTrue);
      expect(previewRes.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.joinHousehold', () {
    test(
      'entra na casa, salva membros existentes e ativa sincronização',
      () async {
        final remoteMember = Member(
          id: 'm-remote-1',
          householdId: 'h-joined',
          siteId: 'site-remote-1',
          name: 'Aparelho do Parceiro',
          joinedAt: DateTime.utc(2026, 10, 10),
          lastSeenAt: DateTime.utc(2026, 10, 15),
        );

        final remoteMember2 = Member(
          id: 'm-remote-2',
          householdId: 'h-joined',
          siteId: 'site-remote-2',
          name: 'Aparelho Sem LastSeen',
          joinedAt: DateTime.utc(2026, 10, 11),
          lastSeenAt: null,
        );

        final joinRes = await repository.joinHousehold(
          householdId: 'h-joined',
          householdName: 'Nossa Casa Compartilhada',
          deviceName: 'Meu Aparelho',
          sharedAreas: {SyncArea.home},
          key: testKey,
          existingMembers: [remoteMember, remoteMember2],
        );

        expect(joinRes.isOk, isTrue);
        final household = joinRes.valueOrNull!;
        expect(household.id, 'h-joined');
        expect(household.name, 'Nossa Casa Compartilhada');
        expect(settingsRepository.householdSyncAllowed, isTrue);

        final members = (await repository.getMembers()).valueOrNull!;
        expect(members.length, 3);
        expect(members.any((m) => m.name == 'Meu Aparelho'), isTrue);
        expect(members.any((m) => m.name == 'Aparelho do Parceiro'), isTrue);
        expect(members.any((m) => m.name == 'Aparelho Sem LastSeen'), isTrue);
      },
    );

    test('falha ao entrar se escrita da chave falhar', () async {
      keyStore.failNext = true;
      final joinRes = await repository.joinHousehold(
        householdId: 'h-joined',
        householdName: 'Nossa Casa',
        deviceName: 'Meu Aparelho',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );
      expect(joinRes.isErr, isTrue);
    });

    test('retorna Err se falha no banco', () async {
      await db.customStatement('DROP TABLE sync_household;');
      final joinRes = await repository.joinHousehold(
        householdId: 'h-fail',
        householdName: 'Nossa Casa',
        deviceName: 'Meu Aparelho',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );
      expect(joinRes.isErr, isTrue);
      expect(joinRes.failureOrNull, isA<HouseholdFailure>());
    });
  });

  group('DriftHouseholdRepository.removeMember & upsertMember', () {
    test('removeMember marca isActive como false', () async {
      await repository.createHousehold(
        name: 'Casa Membros',
        deviceName: 'Tel 1',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );

      await repository.upsertMember(
        siteId: 'site-remote-3',
        deviceName: 'Tel 3',
      );

      final members = (await repository.getMembers()).valueOrNull!;
      final memberToRemove = members.firstWhere((m) => m.name == 'Tel 3');

      final removeRes = await repository.removeMember(memberToRemove.id);
      expect(removeRes.isOk, isTrue);

      final activeMembers = (await repository.getMembers()).valueOrNull!;
      expect(activeMembers.any((m) => m.id == memberToRemove.id), isFalse);
    });

    test('removeMember retorna Err se falha no banco', () async {
      await db.customStatement('DROP TABLE sync_members;');
      final removeRes = await repository.removeMember('m-any');
      expect(removeRes.isErr, isTrue);
      expect(removeRes.failureOrNull, isA<HouseholdFailure>());
    });

    test(
      'upsertMember ignora se não há casa ativa ou se siteId for local',
      () async {
        final resNoHouse = await repository.upsertMember(
          siteId: 'site-x',
          deviceName: 'Tel X',
        );
        expect(resNoHouse.isOk, isTrue);

        await repository.createHousehold(
          name: 'Casa Local',
          deviceName: 'Tel Local',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        final household = (await repository.getHousehold()).valueOrNull!;
        final resLocalSite = await repository.upsertMember(
          siteId: household.localSiteId,
          deviceName: 'Outro Nome',
        );
        expect(resLocalSite.isOk, isTrue);

        final members = (await repository.getMembers()).valueOrNull!;
        expect(members.single.name, 'Tel Local');
      },
    );

    test(
      'upsertMember atualiza nome e lastSeenAt de membro existente',
      () async {
        await repository.createHousehold(
          name: 'Casa Local',
          deviceName: 'Tel Local',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        await repository.upsertMember(
          siteId: 'site-peer-1',
          deviceName: '', // testa fallback para 'Aparelho'
        );

        final m1 = (await repository.getMembers()).valueOrNull!.firstWhere(
          (m) => m.siteId == 'site-peer-1',
        );
        expect(m1.name, 'Aparelho');

        final seenDate = DateTime.utc(2026, 10, 16, 14, 0);
        await repository.upsertMember(
          siteId: 'site-peer-1',
          deviceName: 'Novo Nome do Peer',
          lastSeenAt: seenDate,
        );

        final m2 = (await repository.getMembers()).valueOrNull!.firstWhere(
          (m) => m.siteId == 'site-peer-1',
        );
        expect(m2.name, 'Novo Nome do Peer');
        expect(m2.lastSeenAt, seenDate);
      },
    );

    test('upsertMember retorna Err se falha no banco', () async {
      await repository.createHousehold(
        name: 'Casa Local',
        deviceName: 'Tel Local',
        sharedAreas: {SyncArea.home},
        key: testKey,
      );
      await db.customStatement('DROP TABLE sync_members;');
      final res = await repository.upsertMember(
        siteId: 'site-peer-err',
        deviceName: 'Err',
      );
      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<HouseholdFailure>());
    });
  });
}
