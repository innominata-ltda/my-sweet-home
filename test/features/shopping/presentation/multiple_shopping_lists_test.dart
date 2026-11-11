import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';

import '../../../../test/fakes/fake_clock.dart';
import '../../../../test/fakes/sequential_id_generator.dart';

class _FakeShoppingListRepository implements ShoppingListRepository {
  _FakeShoppingListRepository(Map<String, ShoppingList> initial)
    : lists = Map.from(initial);

  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final l = lists[id];
    if (l != null) return Ok(l);
    return const Err(NotFoundFailure(what: 'Lista não encontrada'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    lists[list.id] = list;
    return const Ok(null);
  }
}

class _FakePricePointRepository implements PricePointRepository {
  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async => const Ok([]);

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async => const Ok([]);

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async => const Ok(
    PriceStats(averagePrice: Money(1000), observationsCount: 1, windowDays: 30),
  );

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async => const Ok(null);
}

Widget _buildTestApp({
  required ShoppingListRepository repository,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/listas',
        builder: (context, state) => const ShoppingListScreen(listId: 'list-1'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ShoppingListScreen(listId: id);
            },
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      pricePointRepositoryProvider.overrideWithValue(
        _FakePricePointRepository(),
      ),
      idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      clockProvider.overrideWithValue(
        FakeClock(DateTime.utc(2026, 10, 15, 12, 0, 0)),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
    ),
  );
}

void main() {
  group('SPEC-004 / T-B08 — Managing multiple shopping lists', () {
    late _FakeShoppingListRepository repository;
    late ShoppingList list1;
    late ShoppingList list2;

    setUp(() {
      list1 = ShoppingList(
        id: 'list-1',
        name: 'Supermercado Mensal',
        createdAt: DateTime.utc(2026, 10, 1),
        items: const [
          ShoppingItem(
            id: 'item-1',
            rawText: 'Arroz 5kg',
            parsedName: 'Arroz',
            parsedQuantity: Quantity(5000, Unit.kg),
          ),
        ],
      );

      list2 = ShoppingList(
        id: 'list-2',
        name: 'Feira Semanal',
        createdAt: DateTime.utc(2026, 10, 2),
        items: const [
          ShoppingItem(
            id: 'item-2',
            rawText: 'Tomate 1kg',
            parsedName: 'Tomate',
            parsedQuantity: Quantity(1000, Unit.kg),
          ),
        ],
      );

      repository = _FakeShoppingListRepository({
        'list-1': list1,
        'list-2': list2,
      });
    });

    testWidgets('Deve listar todas as listas e alternar entre elas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          initialLocation: '/listas/list-1',
        ),
      );
      await tester.pumpAndSettle();

      // Confirma que a tela exibe a lista 1
      expect(find.text('Supermercado Mensal'), findsOneWidget);
      expect(find.text('Arroz 5kg'), findsOneWidget);

      // Abre o modal de gerenciar listas
      final manageButton = find.byIcon(AppIcons.checklist);
      expect(manageButton, findsOneWidget);
      await tester.tap(manageButton);
      await tester.pumpAndSettle();

      // Modal aberto contendo ambas as listas
      expect(find.text('Minhas Listas de Compras'), findsOneWidget);
      expect(find.text('Supermercado Mensal'), findsWidgets);
      expect(find.text('Feira Semanal'), findsOneWidget);

      // Toca na lista "Feira Semanal"
      await tester.tap(find.text('Feira Semanal'));
      await tester.pumpAndSettle();

      // Confirma que alternou para a tela da lista 2
      expect(find.text('Feira Semanal'), findsOneWidget);
      expect(find.text('Tomate 1kg'), findsOneWidget);
    });

    testWidgets('Must create a new list and navigate to it', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          initialLocation: '/listas/list-1',
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal de gerenciar listas
      await tester.tap(find.byIcon(AppIcons.checklist));
      await tester.pumpAndSettle();

      // Toca em "Nova Lista"
      final novaListaBtn = find.text('Nova Lista');
      expect(novaListaBtn, findsOneWidget);
      await tester.tap(novaListaBtn);
      await tester.pumpAndSettle();

      // Creation dialog
      expect(find.text('Nova Lista de Compras'), findsOneWidget);
      final textField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Farmácia');
      await tester.pumpAndSettle();

      final criarBtn = find.text('Criar');
      await tester.tap(criarBtn);
      await tester.pumpAndSettle();

      // Verifica se a nova lista foi criada e aberta na tela
      expect(find.text('Farmácia'), findsOneWidget);
      expect(repository.lists.values.any((l) => l.name == 'Farmácia'), isTrue);
    });

    testWidgets('Should duplicate an existing list through options menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          initialLocation: '/listas/list-1',
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal de gerenciar listas
      await tester.tap(find.byIcon(AppIcons.checklist));
      await tester.pumpAndSettle();

      // Abre o menu popup da primeira lista
      final moreButton = find.byKey(const ValueKey('list-menu-list-1'));
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Toca em "Duplicar"
      final duplicateOption = find.text('Duplicar');
      expect(duplicateOption, findsOneWidget);
      await tester.tap(duplicateOption);
      await tester.pumpAndSettle();

      // Confirms a copy was created in repository
      final hasCopy = repository.lists.values.any(
        (l) =>
            l.name.contains('Cópia') || l.name == 'Supermercado Mensal (Cópia)',
      );
      expect(hasCopy, isTrue);
    });

    testWidgets('Should rename an existing list through options menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          initialLocation: '/listas/list-1',
        ),
      );
      await tester.pumpAndSettle();

      // Abre o modal de gerenciar listas
      await tester.tap(find.byIcon(AppIcons.checklist));
      await tester.pumpAndSettle();

      // Abre o menu popup da primeira lista
      final moreButton = find.byKey(const ValueKey('list-menu-list-1'));
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Toca em "Renomear"
      final renameOption = find.text('Renomear');
      expect(renameOption, findsOneWidget);
      await tester.tap(renameOption);
      await tester.pumpAndSettle();

      // Rename dialog
      expect(find.text('Renomear Lista'), findsOneWidget);
      final textField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Supermercado do Bairro');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Fecha o modal se ainda estiver aberto
      if (find.text('Minhas Listas de Compras').evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }

      // Confirms new name in repository and screen
      expect(repository.lists['list-1']?.name, 'Supermercado do Bairro');
      expect(find.text('Supermercado do Bairro'), findsOneWidget);
    });

    testWidgets(
      'Deve arquivar uma lista de compras através do menu de opções',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            repository: repository,
            initialLocation: '/listas/list-1',
          ),
        );
        await tester.pumpAndSettle();

        // Abre o modal de gerenciar listas
        await tester.tap(find.byIcon(AppIcons.checklist));
        await tester.pumpAndSettle();

        // Abre o menu popup da segunda lista
        final moreButton = find.byKey(const ValueKey('list-menu-list-2'));
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        // Toca em "Arquivar"
        final archiveOption = find.text('Arquivar');
        expect(archiveOption, findsOneWidget);
        await tester.tap(archiveOption);
        await tester.pumpAndSettle();

        // Confirms that list-2 is marked as archived
        expect(repository.lists['list-2']?.isArchived, isTrue);
      },
    );
  });
}
