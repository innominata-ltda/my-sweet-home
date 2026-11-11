import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/sync/data/drift_household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/leave_household_usecase.dart';

import '../../../test/fakes/fake_clock.dart';
import '../../../test/fakes/fake_household_key_store.dart';
import '../../../test/fakes/fake_settings_repository.dart';

void main() {
  group('T-15 / RF-126 — Sair da Casa Compartilhada (CA-7.2, CA-7.3)', () {
    late AppDatabase db;
    late FakeHouseholdKeyStore keyStore;
    late FakeSettingsRepository settingsRepo;
    late FakeClock clock;
    late DriftHouseholdRepository repository;
    late LeaveHouseholdUseCase useCase;

    setUp(() async {
      db = AppDatabase.memory();
      keyStore = FakeHouseholdKeyStore();
      settingsRepo = FakeSettingsRepository();
      clock = FakeClock(DateTime.utc(2026, 3, 15, 10, 0));
      repository = DriftHouseholdRepository(
        db: db,
        keyStore: keyStore,
        settingsRepository: settingsRepo,
        clock: clock,
      );
      useCase = LeaveHouseholdUseCase(repository);

      // Criar casa inicial
      await repository.createHousehold(
        name: 'Casa da Duda',
        deviceName: 'Celular da Duda',
        sharedAreas: {SyncArea.home, SyncArea.finance},
        key: HouseholdKey(List.generate(32, (i) => i)),
      );

      // Inserir uma despesa e uma tarefa compartilhada
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'exp-1',
              categoryId: const Value.absent(),
              amountCents: 1500,
              occurredOn: '2026-03-15T10:00:00Z',
              createdAt: const Value('2026-03-15T10:00:00Z'),
              updatedAt: const Value('2026-03-15T10:00:00Z'),
            ),
          );

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-1',
              title: 'Lavar a louça',
              isCompleted: const Value(false),
              createdAt: const Value('2026-03-15T10:00:00Z'),
              updatedAt: const Value('2026-03-15T10:00:00Z'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('CA-7.2: Leaving keeping copy preserves local data, deactivates household and clears key', () async {
      final result = await useCase.execute(keepCopy: true);
      expect(result.isOk, isTrue);

      // 1. Household is no longer active
      final h = (await repository.getHousehold()).valueOrNull;
      expect(h, isNull);

      // 2. Chave apagada do armazenamento seguro
      final key = (await keyStore.read()).valueOrNull;
      expect(key, isNull);

      // 3. Consentimento revogado
      expect(await settingsRepo.isHouseholdSyncAllowed(), isFalse);

      // 4. Dados continuam no banco local
      final expCount = await db.expenses.select().get();
      expect(expCount.length, equals(1));
      expect(expCount.first.id, equals('exp-1'));

      final taskCount = await db.tasks.select().get();
      expect(taskCount.length, equals(1));
      expect(taskCount.first.id, equals('task-1'));
    });

    test('CA-7.3: Sair apagando remove dados compartilhados, desativa casa e limpa chave', () async {
      final result = await useCase.execute(keepCopy: false);
      expect(result.isOk, isTrue);

      // 1. Household is no longer active
      final h = (await repository.getHousehold()).valueOrNull;
      expect(h, isNull);

      // 2. Chave apagada
      final key = (await keyStore.read()).valueOrNull;
      expect(key, isNull);

      // 3. Consentimento revogado
      expect(await settingsRepo.isHouseholdSyncAllowed(), isFalse);

      // 4. Dados compartilhados apagados do banco local
      final expCount = await db.expenses.select().get();
      expect(expCount, isEmpty);

      final taskCount = await db.tasks.select().get();
      expect(taskCount, isEmpty);
    });
  });
}
