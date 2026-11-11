import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
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

class _ControllableShoppingListRepository implements ShoppingListRepository {
  _ControllableShoppingListRepository({
    this.shouldFail = true,
    Map<String, ShoppingList>? lists,
  }) : lists = lists ?? {};

  bool shouldFail;
  final Map<String, ShoppingList> lists;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Falha temporária de I/O'));
    }
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Falha temporária de I/O'));
    }
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

void main() {
  group(
    'SPEC-004 / T-B01 — Recuperação do erro ao carregar lista de compras',
    () {
      testWidgets(
        'Tocar no botão Tentar novamente recarrega com sucesso quando a falha é sanada',
        (tester) async {
          final sampleList = ShoppingList(
            id: 'list-retry',
            name: 'Lista de Teste',
            createdAt: DateTime(2026, 10, 1),
            items: const [
              ShoppingItem(
                id: 'item-1',
                rawText: 'Arroz 1kg',
                parsedName: 'Arroz',
                parsedQuantity: Quantity(1000, Unit.kg),
              ),
            ],
          );

          final repo = _ControllableShoppingListRepository(
            shouldFail: true,
            lists: {'list-retry': sampleList},
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                shoppingListRepositoryProvider.overrideWithValue(repo),
                pricePointRepositoryProvider.overrideWithValue(
                  _FakePricePointRepository(),
                ),
              ],
              child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale('pt'),
                home: ShoppingListScreen(listId: 'list-retry'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Confirms display of error state with retry button
          expect(find.text('Falha ao carregar lista de compras'), findsWidgets);
          final retryButton = find.text('Tentar de novo');
          expect(retryButton, findsOneWidget);
          expect(find.text('Arroz 1kg'), findsNothing);

          // 2. Error is resolved in repository
          repo.shouldFail = false;

          // 3. Toca em 'Tentar de novo'
          await tester.tap(retryButton);
          await tester.pumpAndSettle();

          // 4. A tela deve se recuperar e exibir o item da lista
          expect(find.text('Tentar de novo'), findsNothing);
          expect(find.text('Arroz 1kg'), findsOneWidget);
        },
      );

      testWidgets(
        'Tocar no botão Tentar de novo provisiona/recupera lista utilizável quando id não existe',
        (tester) async {
          final existingList = ShoppingList(
            id: 'fallback-list',
            name: 'Lista Padrão',
            createdAt: DateTime(2026, 10, 1),
            items: const [],
          );

          final repo = _ControllableShoppingListRepository(
            shouldFail: false,
            lists: {'fallback-list': existingList},
          );

          // Acesso com id inexistente
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                shoppingListRepositoryProvider.overrideWithValue(repo),
                pricePointRepositoryProvider.overrideWithValue(
                  _FakePricePointRepository(),
                ),
              ],
              child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale('pt'),
                home: ShoppingListScreen(listId: 'inexistent-id'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Inicialmente em erro
          expect(find.text('Falha ao carregar lista de compras'), findsWidgets);
          final retryButton = find.text('Tentar de novo');
          expect(retryButton, findsOneWidget);

          // When retrying, must not stay stuck on same error
          await tester.tap(retryButton);
          await tester.pumpAndSettle();

          expect(find.text('Tentar de novo'), findsNothing);
        },
      );
    },
  );
}
