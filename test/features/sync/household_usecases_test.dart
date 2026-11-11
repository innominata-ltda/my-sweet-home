import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/create_household_usecase.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_key_store.dart';
import '../../../test/fakes/fake_settings_repository.dart';

void main() {
  group('CreateHouseholdUseCase', () {
    late FakeSettingsRepository settingsRepo;
    late FakeHouseholdKeyStore keyStore;
    late AppDatabase db;
    late FakeClock clock;
    late DriftHouseholdRepository repository;
    late CreateHouseholdUseCase useCase;

    setUp(() {
      db = AppDatabase.memory();
      settingsRepo = FakeSettingsRepository();
      keyStore = FakeHouseholdKeyStore();
      clock = FakeClock(DateTime.utc(2026, 3, 15, 10, 0));
      repository = DriftHouseholdRepository(
        db: db,
        keyStore: keyStore,
        settingsRepository: settingsRepo,
        clock: clock,
      );
      useCase = CreateHouseholdUseCase(
        repository: repository,
        keyGenerator: () => List.generate(32, (i) => i),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('rejeita nome da casa vazio', () async {
      final result = await useCase.execute(
        householdName: '   ',
        deviceName: 'Meu Celular',
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<HouseholdFailure>());
    });

    test('rejeita nome do aparelho vazio', () async {
      final result = await useCase.execute(
        householdName: 'Casa da Duda',
        deviceName: '',
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<HouseholdFailure>());
    });

    test(
      'cria casa com sucesso, grava consentimento, chave e membro',
      () async {
        final result = await useCase.execute(
          householdName: 'Casa da Duda',
          deviceName: 'Celular da Duda',
          sharedAreas: {SyncArea.home, SyncArea.finance},
        );

        expect(result.isOk, isTrue);
        final household = result.valueOrNull!;
        expect(household.name, equals('Casa da Duda'));
        expect(household.active, isTrue);
        expect(
          household.sharedAreas,
          containsAll([SyncArea.catalog, SyncArea.home, SyncArea.finance]),
        );

        // 1. Consentimento gravado em SettingsRepository
        expect(await settingsRepo.isHouseholdSyncAllowed(), isTrue);

        // 2. Chave armazenada em HouseholdKeyStore
        final storedKey = (await keyStore.read()).valueOrNull;
        expect(storedKey, isNotNull);
        expect(storedKey!.bytes, equals(List.generate(32, (i) => i)));

        // 3. Membro auto-cadastrado na casa
        final membersResult = await repository.getMembers();
        expect(membersResult.isOk, isTrue);
        final members = membersResult.valueOrNull!;
        expect(members.length, equals(1));
        expect(members.first.name, equals('Celular da Duda'));
        expect(members.first.siteId, equals(household.localSiteId));

        // 4. Pending local changes detected (CA-6.1)
        final pendingResult = await repository.hasPendingLocalChanges();
        expect(pendingResult.isOk, isTrue);
      },
    );

    test('updateSharedAreas updates active areas of household', () async {
      await useCase.execute(
        householdName: 'Casa Teste',
        deviceName: 'Aparelho 1',
        sharedAreas: {SyncArea.home},
      );

      final updateResult = await repository.updateSharedAreas({
        SyncArea.finance,
      });
      expect(updateResult.isOk, isTrue);

      final updatedHousehold = (await repository.getHousehold()).valueOrNull!;
      expect(updatedHousehold.sharedAreas, contains(SyncArea.finance));
      expect(updatedHousehold.sharedAreas, contains(SyncArea.catalog));
      expect(updatedHousehold.sharedAreas, isNot(contains(SyncArea.home)));
    });

    test('recupera-se graciosamente se houver mais de uma casa ativa residual no banco', () async {
      // Insert two active households directly into database to simulate inconsistent legacy state
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: 'house_old',
              name: 'Casa Velha',
              localSiteId: 'site_1',
              sharedAreas: 'home,catalog',
              createdAt: '2026-03-01T10:00:00Z',
              joinedAt: '2026-03-01T10:00:00Z',
              active: const Value(true),
            ),
          );
      await db
          .into(db.syncHouseholds)
          .insert(
            SyncHouseholdsCompanion.insert(
              id: 'house_new',
              name: 'Casa Nova',
              localSiteId: 'site_2',
              sharedAreas: 'home,finance,catalog',
              createdAt: '2026-03-10T10:00:00Z',
              joinedAt: '2026-03-10T10:00:00Z',
              active: const Value(true),
            ),
          );

      // watchHousehold does not throw exception and emits most recent
      final householdStream = repository.watchHousehold();
      final firstEmitted = await householdStream.first;
      expect(firstEmitted, isNotNull);
      expect(firstEmitted!.id, equals('house_new'));
      expect(firstEmitted.name, equals('Casa Nova'));

      // getHousehold retorna a mais recente e auto-cura desativando a antiga
      final getResult = await repository.getHousehold();
      expect(getResult.isOk, isTrue);
      expect(getResult.valueOrNull!.id, equals('house_new'));

      // Verifica que a antiga foi desativada
      final activeRows = await (db.select(
        db.syncHouseholds,
      )..where((tbl) => tbl.active.equals(true))).get();
      expect(activeRows.length, equals(1));
      expect(activeRows.first.id, equals('house_new'));
    });

    test(
      'criar ou entrar em nova casa desativa a anterior automaticamente',
      () async {
        await useCase.execute(
          householdName: 'Casa 1',
          deviceName: 'Aparelho 1',
        );
        final house1 = (await repository.getHousehold()).valueOrNull!;
        expect(house1.name, equals('Casa 1'));

        await useCase.execute(
          householdName: 'Casa 2',
          deviceName: 'Aparelho 1',
        );
        final house2 = (await repository.getHousehold()).valueOrNull!;
        expect(house2.name, equals('Casa 2'));

        // Apenas 1 casa ativa no banco
        final activeRows = await (db.select(
          db.syncHouseholds,
        )..where((tbl) => tbl.active.equals(true))).get();
        expect(activeRows.length, equals(1));
        expect(activeRows.first.id, equals(house2.id));
      },
    );
  });
}
