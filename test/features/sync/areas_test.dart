import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/set_areas_usecase.dart';

import '../../../test/fakes/fake_household_repository.dart';

void main() {
  group('T-13 / RF-121 — Toggling Shared Areas (CA-2.1)', () {
    late FakeHouseholdRepository repo;
    late SetAreasUseCase useCase;

    setUp(() {
      final now = DateTime.utc(2026, 3, 15);
      final household = Household(
        id: 'h-1',
        name: 'Casa da Duda',
        localSiteId: 's-1',
        sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
        createdAt: now,
        joinedAt: now,
        active: true,
      );
      repo = FakeHouseholdRepository(initialHousehold: household);
      useCase = SetAreasUseCase(repo);
    });

    tearDown(() {
      repo.dispose();
    });

    test('rejects empty set of areas', () async {
      final result = await useCase.execute({});
      expect(result.isErr, isTrue);
    });

    test('updates active areas to Home only', () async {
      final result = await useCase.execute({SyncArea.home});
      expect(result.isOk, isTrue);

      final h = repo.household!;
      expect(h.sharedAreas, contains(SyncArea.home));
      expect(h.sharedAreas, isNot(contains(SyncArea.finance)));
    });

    test('updates active areas to Finance only', () async {
      final result = await useCase.execute({SyncArea.finance});
      expect(result.isOk, isTrue);

      final h = repo.household!;
      expect(h.sharedAreas, contains(SyncArea.finance));
      expect(h.sharedAreas, isNot(contains(SyncArea.home)));
    });
  });
}
