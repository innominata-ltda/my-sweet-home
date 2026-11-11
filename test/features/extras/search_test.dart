import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/extras/data/global_search_repository_provider.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_global_search_repository.dart';
import 'package:my_sweet_home/features/extras/data/repositories/fake_global_search_repository.dart';
import 'package:my_sweet_home/features/extras/domain/models/global_search_result.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_screen.dart';

void main() {
  group('T-09 — Busca Global FakeGlobalSearchRepository (RF-010, RN-256)', () {
    late FakeGlobalSearchRepository repository;

    setUp(() {
      repository = FakeGlobalSearchRepository();
    });

    test('Busca vazia retorna lista vazia', () async {
      repository.addItem(
        const GlobalSearchResult(
          id: 'p1',
          title: 'Arroz',
          type: GlobalSearchResultType.product,
          targetId: 'prod-1',
        ),
      );

      final res = await repository.search('   ');
      expect(res.isOk, isTrue);
      expect(res.valueOrNull!.items, isEmpty);
    });

    test('Busca por termo retorna resultados agrupados por tipo', () async {
      repository.addItems([
        const GlobalSearchResult(
          id: 'p1',
          title: 'Arroz Branco 5kg',
          type: GlobalSearchResultType.product,
          targetId: 'prod-1',
        ),
        const GlobalSearchResult(
          id: 'e1',
          title: 'Compra de Arroz',
          subtitle: 'R\$ 25.00',
          type: GlobalSearchResultType.expense,
          targetId: 'exp-1',
        ),
        const GlobalSearchResult(
          id: 't1',
          title: 'Comprar arroz e feijão',
          type: GlobalSearchResultType.task,
          targetId: 'task-1',
        ),
        const GlobalSearchResult(
          id: 'r1',
          title: 'Arroz de Forno',
          type: GlobalSearchResultType.recipe,
          targetId: 'rec-1',
        ),
        const GlobalSearchResult(
          id: 'sl1',
          title: 'Lista de Arroz',
          type: GlobalSearchResultType.shoppingList,
          targetId: 'shop-1',
        ),
      ]);

      final res = await repository.search('arroz');
      expect(res.isOk, isTrue);

      final results = res.valueOrNull!;
      expect(results.items.length, equals(5));

      final grouped = results.groupedByType;
      expect(grouped[GlobalSearchResultType.product]!.length, equals(1));
      expect(grouped[GlobalSearchResultType.expense]!.length, equals(1));
      expect(grouped[GlobalSearchResultType.task]!.length, equals(1));
      expect(grouped[GlobalSearchResultType.recipe]!.length, equals(1));
      expect(grouped[GlobalSearchResultType.shoppingList]!.length, equals(1));
    });
  });

  group(
    'T-09 — DriftGlobalSearchRepository com SQLite (RF-010, RN-256, CA-4.1)',
    () {
      late AppDatabase db;
      late DriftGlobalSearchRepository driftRepo;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        driftRepo = DriftGlobalSearchRepository(db);
      });

      tearDown(() async {
        await db.close();
      });

      test('Busca cobre produtos (nome e apelidos), despesas, tarefas, receitas e listas', () async {
        // 1. Inserir produto com apelido
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: 'p-1',
                canonicalName: 'Feijão Carioca',
                defaultUnit: 'kg',
              ),
            );
        await db
            .into(db.productAliases)
            .insert(
              ProductAliasesCompanion.insert(
                id: 'pa-1',
                productId: 'p-1',
                alias: 'Feijão de Corda',
                normalizedAlias: 'feijao corda',
                source: 'user',
              ),
            );

        // 2. Inserir despesa
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'e-1',
                amountCents: 1500,
                occurredOn: '2026-10-01',
                description: const Value('Feijão e legumes'),
              ),
            );

        // 3. Inserir tarefa
        await db
            .into(db.tasks)
            .insert(TasksCompanion.insert(id: 't-1', title: 'Cozinhar feijão'));

        // 4. Inserir receita
        await db
            .into(db.recipes)
            .insert(
              RecipesCompanion.insert(id: 'r-1', title: 'Sopa de Feijão'),
            );

        // 5. Inserir lista de compras
        await db
            .into(db.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(id: 'sl-1', name: 'Feijão semanal'),
            );

        final res = await driftRepo.search('feijao');
        expect(res.isOk, isTrue);

        final results = res.valueOrNull!;
        final grouped = results.groupedByType;

        expect(grouped[GlobalSearchResultType.product]?.length, equals(1));
        expect(grouped[GlobalSearchResultType.expense]?.length, equals(1));
        expect(grouped[GlobalSearchResultType.task]?.length, equals(1));
        expect(grouped[GlobalSearchResultType.recipe]?.length, equals(1));
        expect(grouped[GlobalSearchResultType.shoppingList]?.length, equals(1));
      });

      test(
        'Search ignores archived products, deleted expenses, and deleted tasks',
        () async {
          // Produto arquivado
          await db
              .into(db.products)
              .insert(
                ProductsCompanion.insert(
                  id: 'p-archived',
                  canonicalName: 'Sabão Arquivado',
                  defaultUnit: 'un',
                  isArchived: const Value(true),
                ),
              );

          // Deleted expense
          await db
              .into(db.expenses)
              .insert(
                ExpensesCompanion.insert(
                  id: 'e-deleted',
                  amountCents: 2000,
                  occurredOn: '2026-10-01',
                  description: const Value('Sabão em pó'),
                  deletedAt: const Value('2026-10-01T10:00:00Z'),
                ),
              );

          // Deleted task
          await db
              .into(db.tasks)
              .insert(
                TasksCompanion.insert(
                  id: 't-deleted',
                  title: 'Comprar Sabão',
                  deletedAt: const Value('2026-10-01T10:00:00Z'),
                ),
              );

          final res = await driftRepo.search('sabao');
          expect(res.isOk, isTrue);
          expect(res.valueOrNull!.items, isEmpty);
        },
      );

      test('CA-4.1: Dada uma base com 5.000 produtos, 10.000 despesas e 200 receitas, busca por "arroz" responde em menos de 200ms', () async {
        // Batch population of large database
        await db.transaction(() async {
          // 5.000 produtos
          final productCompanions = List.generate(
            5000,
            (i) => ProductsCompanion.insert(
              id: 'prod-$i',
              canonicalName: i == 2500
                  ? 'Arroz Parboilizado'
                  : 'Produto Generico $i',
              defaultUnit: 'un',
            ),
          );
          await db.batch((batch) {
            batch.insertAll(db.products, productCompanions);
          });

          // 10.000 despesas
          final expenseCompanions = List.generate(
            10000,
            (i) => ExpensesCompanion.insert(
              id: 'exp-$i',
              amountCents: 1000 + i,
              occurredOn: '2026-09-01',
              description: Value(
                i == 5000 ? 'Compra de Arroz no Mercado' : 'Despesa Variada $i',
              ),
            ),
          );
          await db.batch((batch) {
            batch.insertAll(db.expenses, expenseCompanions);
          });

          // 200 receitas
          final recipeCompanions = List.generate(
            200,
            (i) => RecipesCompanion.insert(
              id: 'rec-$i',
              title: i == 100 ? 'Arroz Carreteiro' : 'Receita Especial $i',
            ),
          );
          await db.batch((batch) {
            batch.insertAll(db.recipes, recipeCompanions);
          });
        });

        // Warm-up query
        await driftRepo.search('teste');

        // Medir tempo de resposta para "arroz"
        final stopwatch = Stopwatch()..start();
        final result = await driftRepo.search('arroz');
        stopwatch.stop();

        expect(result.isOk, isTrue);
        final results = result.valueOrNull!;
        expect(results.items, isNotEmpty);

        final grouped = results.groupedByType;
        expect(grouped[GlobalSearchResultType.product]!.length, equals(1));
        expect(grouped[GlobalSearchResultType.expense]!.length, equals(1));
        expect(grouped[GlobalSearchResultType.recipe]!.length, equals(1));

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'A busca global deve responder em menos de 200ms',
        );
      });
    },
  );

  group('GlobalSearchScreen Widget Test', () {
    testWidgets('Digitar termo de busca exibe resultados agrupados por tipo', (
      tester,
    ) async {
      final fakeRepo = FakeGlobalSearchRepository([
        const GlobalSearchResult(
          id: 'p1',
          title: 'Detergente Neutro',
          type: GlobalSearchResultType.product,
          targetId: 'p-1',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalSearchRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(home: GlobalSearchScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Busca Global'), findsOneWidget);
      expect(find.text('Busca no app'), findsOneWidget);

      // Digitar termo no campo de busca
      await tester.enterText(find.byType(TextField), 'detergente');
      await tester.pumpAndSettle();

      expect(find.text('Produtos'), findsOneWidget);
      expect(find.text('Detergente Neutro'), findsOneWidget);
    });
  });

  group('GlobalSearchResult model', () {
    test('operator == e hashCode', () {
      const res1 = GlobalSearchResult(
        id: 'r1',
        title: 'Arroz',
        subtitle: '1kg',
        type: GlobalSearchResultType.product,
        targetId: 'prod-1',
      );
      const res2 = GlobalSearchResult(
        id: 'r1',
        title: 'Arroz',
        subtitle: '1kg',
        type: GlobalSearchResultType.product,
        targetId: 'prod-1',
      );
      const res3 = GlobalSearchResult(
        id: 'r2',
        title: 'Feijão',
        type: GlobalSearchResultType.product,
        targetId: 'prod-2',
      );

      expect(res1, equals(res1));
      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1, isNot(equals(res3)));
      expect(res1, isNot(equals('res')));
    });

    test('GlobalSearchResults groupedByType agrupa corretamente', () {
      final results = const GlobalSearchResults(
        items: [
          GlobalSearchResult(
            id: '1',
            title: 'Item 1',
            type: GlobalSearchResultType.product,
            targetId: 't1',
          ),
          GlobalSearchResult(
            id: '2',
            title: 'Item 2',
            type: GlobalSearchResultType.expense,
            targetId: 't2',
          ),
        ],
      );

      final grouped = results.groupedByType;
      expect(grouped[GlobalSearchResultType.product]?.length, 1);
      expect(grouped[GlobalSearchResultType.expense]?.length, 1);
      expect(grouped[GlobalSearchResultType.recipe], isEmpty);
    });
  });
}
