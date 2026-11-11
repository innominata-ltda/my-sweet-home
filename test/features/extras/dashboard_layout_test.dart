import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/extras/data/dashboard_layout_repository_provider.dart';
import 'package:my_sweet_home/features/extras/data/drift_dashboard_layout_repository.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_controller.dart';

import '../../fakes/fake_dashboard_layout_repository.dart';

void main() {
  group('DashboardLayoutConfig Domain Model (RN-370, RN-371, RN-372, RN-373)', () {
    test('RN-370: DashboardItemKind contains exactly 9 catalog card types', () {
      expect(DashboardItemKind.values, [
        DashboardItemKind.mascotGreeting,
        DashboardItemKind.monthBalance,
        DashboardItemKind.dueBills,
        DashboardItemKind.todayTasks,
        DashboardItemKind.shoppingList,
        DashboardItemKind.stockAlert,
        DashboardItemKind.firstHomeChecklist,
        DashboardItemKind.economyGoal,
        DashboardItemKind.favoriteRecipes,
      ]);
    });

    test(
      'RN-371: defaultOrder contém os 5 cards padrão na ordem estipulada',
      () {
        expect(DashboardLayoutConfig.defaultOrder, [
          DashboardItemKind.mascotGreeting,
          DashboardItemKind.monthBalance,
          DashboardItemKind.dueBills,
          DashboardItemKind.todayTasks,
          DashboardItemKind.shoppingList,
        ]);
      },
    );

    test(
      'RN-371: hiddenItems retorna os 4 cards não visíveis na instalação limpa',
      () {
        const config = DashboardLayoutConfig(
          visibleItems: DashboardLayoutConfig.defaultOrder,
        );

        expect(config.hiddenItems, [
          DashboardItemKind.stockAlert,
          DashboardItemKind.firstHomeChecklist,
          DashboardItemKind.economyGoal,
          DashboardItemKind.favoriteRecipes,
        ]);
      },
    );

    test('RN-372: moveUp moves item one position up and does not modify first item', () {
      const config = DashboardLayoutConfig(
        visibleItems: DashboardLayoutConfig.defaultOrder,
      );

      // Move monthBalance (index 1) up -> becomes index 0
      final updated = config.moveUp(DashboardItemKind.monthBalance);
      expect(updated.visibleItems.first, DashboardItemKind.monthBalance);
      expect(updated.visibleItems[1], DashboardItemKind.mascotGreeting);

      // Move first item up does nothing
      final unchanged = updated.moveUp(DashboardItemKind.monthBalance);
      expect(unchanged.visibleItems, updated.visibleItems);

      // Move non-existent item does nothing
      final noOp = config.moveUp(DashboardItemKind.stockAlert);
      expect(noOp.visibleItems, config.visibleItems);
    });

    test('RN-372: moveDown moves item one position down and does not modify last item', () {
      const config = DashboardLayoutConfig(
        visibleItems: DashboardLayoutConfig.defaultOrder,
      );

      // Move mascotGreeting (index 0) down -> becomes index 1
      final updated = config.moveDown(DashboardItemKind.mascotGreeting);
      expect(updated.visibleItems.first, DashboardItemKind.monthBalance);
      expect(updated.visibleItems[1], DashboardItemKind.mascotGreeting);

      // Move last item (shoppingList) down does nothing
      final unchanged = config.moveDown(DashboardItemKind.shoppingList);
      expect(unchanged.visibleItems, config.visibleItems);

      // Move hidden item does nothing
      final noOp = config.moveDown(DashboardItemKind.stockAlert);
      expect(noOp.visibleItems, config.visibleItems);
    });

    test('RN-372 & CA-3.3: reorder reposiciona itens corretamente tratando drag-and-drop', () {
      const config = DashboardLayoutConfig(
        visibleItems: DashboardLayoutConfig.defaultOrder,
      );

      // Move todayTasks (index 3) to top (index 0)
      final movedToTop = config.reorder(3, 0);
      expect(movedToTop.visibleItems, [
        DashboardItemKind.todayTasks,
        DashboardItemKind.mascotGreeting,
        DashboardItemKind.monthBalance,
        DashboardItemKind.dueBills,
        DashboardItemKind.shoppingList,
      ]);

      // Arrastar item para baixo (ex: mascotGreeting de 0 para depois de monthBalance no Flutter passa newIndex 2)
      final movedDown = config.reorder(0, 2);
      expect(movedDown.visibleItems[0], DashboardItemKind.monthBalance);
      expect(movedDown.visibleItems[1], DashboardItemKind.mascotGreeting);

      // Invalid indices return same config
      expect(config.reorder(-1, 2).visibleItems, config.visibleItems);
      expect(config.reorder(10, 2).visibleItems, config.visibleItems);
    });

    test(
      'RN-372 & RN-373: hide remove o card da lista visível sem apagar dados',
      () {
        const config = DashboardLayoutConfig(
          visibleItems: DashboardLayoutConfig.defaultOrder,
        );

        final withoutGreeting = config.hide(DashboardItemKind.mascotGreeting);
        expect(
          withoutGreeting.visibleItems.contains(
            DashboardItemKind.mascotGreeting,
          ),
          isFalse,
        );
        expect(
          withoutGreeting.hiddenItems.contains(
            DashboardItemKind.mascotGreeting,
          ),
          isTrue,
        );

        final withoutTwo = withoutGreeting.hide(DashboardItemKind.dueBills);
        expect(
          withoutTwo.visibleItems.contains(DashboardItemKind.dueBills),
          isFalse,
        );
        expect(withoutTwo.visibleItems.length, 3);

        // Hiding already hidden item does not modify list
        expect(
          withoutTwo.hide(DashboardItemKind.dueBills).visibleItems,
          withoutTwo.visibleItems,
        );
      },
    );

    test('RN-372: show adds catalog item to end of visible list', () {
      const config = DashboardLayoutConfig(
        visibleItems: DashboardLayoutConfig.defaultOrder,
      );

      final withStock = config.show(DashboardItemKind.stockAlert);
      expect(withStock.visibleItems.last, DashboardItemKind.stockAlert);
      expect(
        withStock.hiddenItems.contains(DashboardItemKind.stockAlert),
        isFalse,
      );

      // Re-adding already visible item does not duplicate
      expect(
        withStock.show(DashboardItemKind.stockAlert).visibleItems,
        withStock.visibleItems,
      );
    });

    test('RN-375: toJson and fromJson safely serialize and deserialize with fallback', () {
      const config = DashboardLayoutConfig(
        visibleItems: [
          DashboardItemKind.todayTasks,
          DashboardItemKind.stockAlert,
        ],
      );

      final json = config.toJson();
      expect(json, ['todayTasks', 'stockAlert']);

      final restored = DashboardLayoutConfig.fromJson(json);
      expect(restored.visibleItems, [
        DashboardItemKind.todayTasks,
        DashboardItemKind.stockAlert,
      ]);

      // Fallback to defaultOrder if invalid type
      final invalid = DashboardLayoutConfig.fromJson({'foo': 'bar'});
      expect(invalid.visibleItems, DashboardLayoutConfig.defaultOrder);

      // Unknown items are filtered and known items preserved
      final withUnknown = DashboardLayoutConfig.fromJson([
        'todayTasks',
        'invalidCard',
        'dueBills',
      ]);
      expect(withUnknown.visibleItems, [
        DashboardItemKind.todayTasks,
        DashboardItemKind.dueBills,
      ]);
    });
  });

  group('DriftDashboardLayoutRepository (RN-375)', () {
    late AppDatabase db;
    late DriftDashboardLayoutRepository repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = DriftDashboardLayoutRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('RN-371 & RN-375: clean install returns defaultOrder', () async {
      final result = await repository.load();
      expect(result.isOk, isTrue);
      expect(
        result.valueOrNull!.visibleItems,
        DashboardLayoutConfig.defaultOrder,
      );
    });

    test(
      'CA-3.3 & RN-375: salvar layout e recarregar preserva a ordem persistida',
      () async {
        const customConfig = DashboardLayoutConfig(
          visibleItems: [
            DashboardItemKind.todayTasks,
            DashboardItemKind.shoppingList,
            DashboardItemKind.stockAlert,
          ],
        );

        final saveResult = await repository.save(customConfig);
        expect(saveResult.isOk, isTrue);

        final loadResult = await repository.load();
        expect(loadResult.isOk, isTrue);
        expect(loadResult.valueOrNull!.visibleItems, customConfig.visibleItems);
      },
    );

    test('RN-375: valor corrompido em settings faz fallback silencioso para defaultOrder', () async {
      // Inserir JSON quebrado na chave 'dashboard_layout_v1'
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion(
              key: const drift.Value(
                DriftDashboardLayoutRepository.settingsKey,
              ),
              value: const drift.Value('{quebrado...'),
            ),
          );

      final result = await repository.load();
      expect(result.isOk, isTrue);
      expect(
        result.valueOrNull!.visibleItems,
        DashboardLayoutConfig.defaultOrder,
      );
    });

    test('RN-375: resetToDefault restores 5 default cards', () async {
      const customConfig = DashboardLayoutConfig(
        visibleItems: [DashboardItemKind.stockAlert],
      );
      await repository.save(customConfig);

      final resetResult = await repository.resetToDefault();
      expect(resetResult.isOk, isTrue);
      expect(
        resetResult.valueOrNull!.visibleItems,
        DashboardLayoutConfig.defaultOrder,
      );

      final loadResult = await repository.load();
      expect(
        loadResult.valueOrNull!.visibleItems,
        DashboardLayoutConfig.defaultOrder,
      );
    });
  });

  group(
    'DashboardLayoutController (RN-372, RN-373, RN-375, CA-3.3, CA-3.4)',
    () {
      late FakeDashboardLayoutRepository fakeRepo;
      late DashboardLayoutController controller;

      setUp(() async {
        fakeRepo = FakeDashboardLayoutRepository();
        controller = DashboardLayoutController(repository: fakeRepo);
        // Aguardar carga inicial
        await Future<void>.delayed(Duration.zero);
      });

      tearDown(() {
        controller.dispose();
      });

      test(
        'inicializa com os itens padrão no estado DashboardLayoutLoaded',
        () {
          expect(controller.value, isA<DashboardLayoutLoaded>());
          final loaded = controller.value as DashboardLayoutLoaded;
          expect(loaded.visibleItems, DashboardLayoutConfig.defaultOrder);
          expect(loaded.hiddenItems.length, 4);
        },
      );

      test('CA-3.3: moving todayTasks to top updates state and persists in repository', () async {
        // todayTasks is at position 3 in default
        await controller.reorder(3, 0);

        expect(controller.value, isA<DashboardLayoutLoaded>());
        final loaded = controller.value as DashboardLayoutLoaded;
        expect(loaded.visibleItems.first, DashboardItemKind.todayTasks);

        // Verify persistence in repository
        final repoLoad = await fakeRepo.load();
        expect(
          repoLoad.valueOrNull!.visibleItems.first,
          DashboardItemKind.todayTasks,
        );
      });

      test('CA-3.4: ocultar dueBills e mascotGreeting remove os cards sem apagar dados; readicionar restaura', () async {
        // Ocultar dueBills e mascotGreeting
        await controller.hide(DashboardItemKind.dueBills);
        await controller.hide(DashboardItemKind.mascotGreeting);

        final loaded = controller.value as DashboardLayoutLoaded;
        expect(
          loaded.visibleItems.contains(DashboardItemKind.dueBills),
          isFalse,
        );
        expect(
          loaded.visibleItems.contains(DashboardItemKind.mascotGreeting),
          isFalse,
        );
        expect(loaded.hiddenItems.contains(DashboardItemKind.dueBills), isTrue);
        expect(
          loaded.hiddenItems.contains(DashboardItemKind.mascotGreeting),
          isTrue,
        );

        // Re-add from catalog
        await controller.show(DashboardItemKind.dueBills);
        final restored = controller.value as DashboardLayoutLoaded;
        expect(
          restored.visibleItems.contains(DashboardItemKind.dueBills),
          isTrue,
        );
        expect(restored.visibleItems.last, DashboardItemKind.dueBills);
      });

      test(
        'RN-372: moveUp e moveDown operam de forma reativa e persistente',
        () async {
          await controller.moveUp(DashboardItemKind.monthBalance);
          var loaded = controller.value as DashboardLayoutLoaded;
          expect(loaded.visibleItems.first, DashboardItemKind.monthBalance);

          await controller.moveDown(DashboardItemKind.monthBalance);
          loaded = controller.value as DashboardLayoutLoaded;
          expect(loaded.visibleItems[1], DashboardItemKind.monthBalance);
        },
      );

      test('RN-375: resetToDefault restaura a ordem original no controller e no repo', () async {
        await controller.hide(DashboardItemKind.mascotGreeting);
        await controller.hide(DashboardItemKind.monthBalance);

        await controller.resetToDefault();
        final loaded = controller.value as DashboardLayoutLoaded;
        expect(loaded.visibleItems, DashboardLayoutConfig.defaultOrder);
      });

      test(
        'trata falha de persistência emitindo DashboardLayoutError',
        () async {
          fakeRepo.shouldFail = true;
          await controller.hide(DashboardItemKind.shoppingList);

          expect(controller.value, isA<DashboardLayoutError>());
        },
      );
    },
  );

  group('dashboardLayoutRepositoryProvider', () {
    test(
      'fornece fallback em memória quando databaseProvider não está disponível',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final repo = container.read(dashboardLayoutRepositoryProvider);
        final loadRes = await repo.load();
        expect(loadRes.isOk, isTrue);

        const customConfig = DashboardLayoutConfig(
          visibleItems: [DashboardItemKind.todayTasks],
        );
        final saveRes = await repo.save(customConfig);
        expect(saveRes.isOk, isTrue);

        final resetRes = await repo.resetToDefault();
        expect(resetRes.isOk, isTrue);
      },
    );

    test('provides DriftDashboardLayoutRepository when databaseProvider is available', () {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final repo = container.read(dashboardLayoutRepositoryProvider);
      expect(repo, isA<DriftDashboardLayoutRepository>());
    });
  });
}
