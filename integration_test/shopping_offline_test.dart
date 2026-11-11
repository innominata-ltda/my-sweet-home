import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point_repository.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/store_ranking.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/add_shopping_item_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/create_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/toggle_shopping_item_usecase.dart';
import 'package:my_sweet_home/features/shopping/presentation/shopping_list_screen.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Modo avião ativo (CA-6.1, RN-088): nenhuma requisição de rede permitida.',
    );
  }
}

class InMemoryShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingList> _lists = {};

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(_lists.values.toList());
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = _lists[id];
    if (list != null) {
      return Ok(list);
    }
    return Err(NotFoundFailure(what: 'ShoppingList $id'));
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    _lists[list.id] = list;
    return const Ok(null);
  }
}

class SequentialIdGenerator implements IdGenerator {
  int _counter = 0;
  @override
  String newId() => 'id-${++_counter}';
}

class FakePricePointRepository implements PricePointRepository {
  @override
  Future<Result<List<PricePoint>, Failure>> getByProduct(
    String productId, {
    required DateTime since,
    String? storeId,
  }) async =>
      const Ok([]);

  @override
  Future<Result<List<StoreRanking>, Failure>> getCheapestStores(
    String productId, {
    required DateTime since,
    int windowDays = 30,
    int minObservations = 2,
  }) async =>
      const Ok([]);

  @override
  Future<Result<PriceStats, Failure>> getStatsByProduct(
    String productId, {
    required DateTime since,
    required int windowDays,
  }) async =>
      const Ok(PriceStats(
        averagePrice: Money(0),
        observationsCount: 0,
        windowDays: 30,
      ));

  @override
  Future<Result<void, Failure>> saveAll(
    List<PricePoint> points, {
    String? purchaseId,
  }) async =>
      const Ok(null);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  group('T-V1 — CA-6.1 & RN-088: Operações de Lista de Compras Offline', () {
    late InMemoryShoppingListRepository repository;
    late SequentialIdGenerator idGenerator;
    late SystemClock clock;
    late CreateShoppingListUseCase createUseCase;
    late AddShoppingItemUseCase addUseCase;
    late ToggleShoppingItemUseCase toggleUseCase;

    setUp(() {
      repository = InMemoryShoppingListRepository();
      idGenerator = SequentialIdGenerator();
      clock = const SystemClock();
      createUseCase = CreateShoppingListUseCase(repository, idGenerator, clock);
      addUseCase = AddShoppingItemUseCase(
        repository,
        idGenerator,
        const DefaultShoppingItemParser(),
      );
      toggleUseCase = ToggleShoppingItemUseCase(repository, clock);
    });

    test('Criar lista, adicionar, marcar e desmarcar itens em modo avião (domínio)', () async {
      // 1. Criar lista offline (CA-6.1)
      final createResult = await createUseCase('Mercado Semanal');
      expect(createResult.isOk, isTrue, reason: 'Criação de lista offline deve ter sucesso');
      final list = createResult.valueOrNull!;
      expect(list.name, equals('Mercado Semanal'));

      // 2. Adicionar itens offline (CA-6.1)
      final addResult1 = await addUseCase(listId: list.id, rawText: '2kg de arroz');
      expect(addResult1.isOk, isTrue, reason: 'Adição de item offline deve ter sucesso');
      final listWithItem1 = addResult1.valueOrNull!;
      expect(listWithItem1.items, hasLength(1));
      final item1 = listWithItem1.items.first;
      expect(item1.parsedName, equals('arroz'));

      final addResult2 = await addUseCase(listId: list.id, rawText: '1L de leite');
      expect(addResult2.isOk, isTrue);
      final listWithItem2 = addResult2.valueOrNull!;
      expect(listWithItem2.items, hasLength(2));

      // 3. Marcar item offline (CA-6.1)
      final checkResult = await toggleUseCase(
        listId: list.id,
        itemId: item1.id,
        isBought: true,
      );
      expect(checkResult.isOk, isTrue, reason: 'Marcação de item offline deve ter sucesso');
      final checkedList = checkResult.valueOrNull!;
      final checkedItem = checkedList.items.firstWhere((i) => i.id == item1.id);
      expect(checkedItem.isBought, isTrue);

      // 4. Desmarcar item offline (CA-6.1)
      final uncheckResult = await toggleUseCase(
        listId: list.id,
        itemId: item1.id,
        isBought: false,
      );
      expect(uncheckResult.isOk, isTrue, reason: 'Desmarcação de item offline deve ter sucesso');
      final uncheckedList = uncheckResult.valueOrNull!;
      final uncheckedItem = uncheckedList.items.firstWhere((i) => i.id == item1.id);
      expect(uncheckedItem.isBought, isFalse);

      // 5. Verify offline persistence in repository
      final storedListResult = await repository.getById(list.id);
      expect(storedListResult.isOk, isTrue);
      final storedList = storedListResult.valueOrNull!;
      expect(storedList.items, hasLength(2));
    });

    testWidgets('Interface da lista de compras funciona offline (UI + widgets)', (tester) async {
      // Prepara uma lista inicial
      final createResult = await createUseCase('Mercado UI Offline');
      final initialList = createResult.valueOrNull!;
      await addUseCase(listId: initialList.id, rawText: 'Feijão 1kg');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(repository),
            pricePointRepositoryProvider.overrideWithValue(FakePricePointRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ShoppingListScreen(listId: initialList.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que a tela abre offline
      expect(find.text('Mercado UI Offline'), findsOneWidget);
      expect(find.text('Feijão 1kg'), findsOneWidget);

      // Toca no item para marcar como comprado
      await tester.tap(find.text('Feijão 1kg'));
      await tester.pumpAndSettle();

      // Undo snackbar is visible
      expect(find.text('Desfazer'), findsOneWidget);

      // Adiciona novo item pela UI
      await tester.enterText(find.byType(TextField).first, '3un de detergente');
      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pumpAndSettle();

      // Verifica que o novo item foi adicionado e exibido offline
      expect(find.text('3un de detergente'), findsOneWidget);
    });
  });
}
