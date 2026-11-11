import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/domain/usecases/send_ingredients_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_preparation_screen.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/fake_recipe_repository.dart';
import '../../../fakes/sequential_id_generator.dart';

class _FakeShoppingListRepo implements ShoppingListRepository {
  final Map<String, ShoppingList> lists = {};

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    final list = lists[id];
    if (list != null) return Ok(list);
    return const Err(NotFoundFailure(what: 'List'));
  }

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    return Ok(lists.values.toList());
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    lists[list.id] = list;
    return const Ok(null);
  }
}

void main() {
  group('SPEC-015 Recipes Flows (CA-5.1, CA-5.2, CA-5.3)', () {
    testWidgets(
      'CA-5.1: FAB navega para /receitas/nova, cola receita, adiciona ingrediente e tag via diálogo, salva e aparece na listagem',
      (tester) async {
        final clock = FakeClock(DateTime(2026, 10, 25));
        final fakeRepo = FakeRecipeRepository(clock);
        final listController = RecipeListController(fakeRepo);

        final router = GoRouter(
          initialLocation: '/receitas',
          routes: [
            GoRoute(
              path: '/receitas',
              builder: (context, state) =>
                  RecipeListScreen(controller: listController),
              routes: [
                GoRoute(
                  path: 'nova',
                  builder: (context, state) => RecipeDraftScreen(
                    idGenerator: SequentialIdGenerator(),
                    repository: fakeRepo,
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        // 1. FAB "+" exists
        final fab = find.byKey(const Key('create_recipe_fab'));
        expect(fab, findsOneWidget);

        // 2. Tap FAB to navigate to /receitas/nova
        await tester.tap(fab);
        await tester.pumpAndSettle();
        expect(find.byType(RecipeDraftScreen), findsOneWidget);

        // 3. Paste recipe text
        final pasteButton = find.byKey(const Key('paste_recipe_button'));
        expect(pasteButton, findsOneWidget);
        await tester.tap(pasteButton);
        await tester.pumpAndSettle();

        const pastedRecipeText = '''
Bolo de Cenoura
3 cenouras médias
2 xícaras de açúcar
3 ovos
Bater tudo no liquidificador e assar por 40 minutos em banho-maria.
''';

        await tester.enterText(
          find.byKey(const Key('paste_recipe_input')),
          pastedRecipeText,
        );
        await tester.tap(find.byKey(const Key('confirm_paste_recipe_button')));
        await tester.pumpAndSettle();

        expect(find.text('Bolo de Cenoura'), findsOneWidget);

        // 4. Add ingredient via dialog
        await tester.tap(find.byKey(const Key('add_ingredient_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('ingredient_name_input')),
          '1 colher de fermento',
        );
        await tester.tap(
          find.byKey(const Key('confirm_add_ingredient_button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 colher de fermento'), findsOneWidget);

        // 5. Add tag via dialog
        await tester.tap(find.byKey(const Key('add_tag_chip')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('tag_input')), 'Sobremesa');
        await tester.tap(find.byKey(const Key('confirm_add_tag_button')));
        await tester.pumpAndSettle();
        expect(find.text('Sobremesa'), findsOneWidget);

        // 6. Save recipe
        await tester.tap(find.byKey(const Key('save_recipe_button')));
        await tester.pumpAndSettle();

        // 7. Pop back to list and check if Bolo de Cenoura is visible
        expect(find.byType(RecipeListScreen), findsOneWidget);
        expect(find.text('Bolo de Cenoura'), findsOneWidget);
      },
    );

    testWidgets(
      'CA-5.2: Envia ingredientes escalados para lista de compras via SendIngredientsToShoppingListUseCase',
      (tester) async {
        final clock = FakeClock(DateTime(2026, 10, 25));
        final fakeRecipeRepo = FakeRecipeRepository(clock);
        final fakeShoppingRepo = _FakeShoppingListRepo();

        final initialList = ShoppingList(
          id: 'list_1',
          name: 'Compras da Semana',
          createdAt: DateTime.now(),
          items: const [],
        );
        await fakeShoppingRepo.save(initialList);

        const recipe = Recipe(
          id: 'rec_1',
          title: 'Arroz com Frango',
          timeMinutes: 30,
          servings: 2,
          prepText: 'Cozinhar frango e misturar ao arroz.',
          ingredients: [
            Ingredient(
              name: 'Arroz',
              quantity: Quantity(200000, Unit.g), // 200g
            ),
            Ingredient(
              name: 'Peito de Frango',
              quantity: Quantity(400000, Unit.g), // 400g
            ),
          ],
        );
        await fakeRecipeRepo.upsert(
          NewRecipe(
            id: recipe.id,
            title: recipe.title,
            ingredients: recipe.ingredients,
            prepText: recipe.prepText,
            timeMinutes: recipe.timeMinutes,
            servings: recipe.servings,
          ),
        );

        final detailController = RecipeDetailController(
          fakeRecipeRepo,
          recipe.id,
        );
        final sendUseCase = SendIngredientsToShoppingListUseCase(
          fakeShoppingRepo,
          SequentialIdGenerator(),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RecipeDetailScreen(
              controller: detailController,
              scaler: const StandardIngredientScaler(),
              sendIngredientsUseCase: sendUseCase,
              shoppingListRepository: fakeShoppingRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check initial servings (2)
        expect(find.byKey(const Key('portions_servings_text')), findsOneWidget);

        // Increase servings from 2 to 4
        await tester.tap(find.byKey(const Key('increase_servings_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('increase_servings_button')));
        await tester.pumpAndSettle();

        // Tap "Enviar ingredientes para lista de compras"
        final sendButton = find.byKey(
          const Key('send_ingredients_to_shopping_button'),
        );
        expect(sendButton, findsOneWidget);
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        // Verify SnackBar confirmation
        expect(
          find.text('Ingredientes enviados para a lista de compras!'),
          findsOneWidget,
        );

        // Verify shopping list received scaled ingredients
        final savedList = (await fakeShoppingRepo.getById('list_1'))
            .valueOrNull;
        expect(savedList, isNotNull);
        expect(savedList!.items.length, 2);
        // Scaled 2 -> 4 (scale factor = 2.0): 200g -> 400g (400000 milli)
        final arrozItem = savedList.items.firstWhere(
          (i) => i.parsedName == 'Arroz',
        );
        expect(arrozItem.parsedQuantity?.valueMilli, 400000);
      },
    );

    testWidgets(
      'CA-5.3: Registrar preços navega para /compras/nova e Modo Passo a Passo exibe texto real dos passos carregados do repositório',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final clock = FakeClock(DateTime(2026, 10, 25));
        final fakeRecipeRepo = FakeRecipeRepository(clock);

        const recipe = Recipe(
          id: 'rec_strogonoff',
          title: 'Strogonoff Clássico',
          timeMinutes: 45,
          servings: 4,
          prepText: 'Passo 1: Doure a cebola e o alho.\nPasso 2: Adicione o frango em cubos e sele bem.\nPasso 3: Acrescente o molho de tomate, mostarda, champignon e finalize com creme de leite.',
          ingredients: [Ingredient(name: 'Frango')],
        );
        await fakeRecipeRepo.upsert(
          NewRecipe(
            id: recipe.id,
            title: recipe.title,
            ingredients: recipe.ingredients,
            prepText: recipe.prepText,
            timeMinutes: recipe.timeMinutes,
            servings: recipe.servings,
          ),
        );

        final detailController = RecipeDetailController(
          fakeRecipeRepo,
          recipe.id,
        );

        final router = GoRouter(
          initialLocation: '/receitas/rec_strogonoff',
          routes: [
            GoRoute(
              path: '/receitas/:id',
              builder: (context, state) => RecipeDetailScreen(
                controller: detailController,
                scaler: const StandardIngredientScaler(),
              ),
              routes: [
                GoRoute(
                  path: 'preparo',
                  builder: (context, state) => RecipePreparationScreen(
                    recipeId: state.pathParameters['id']!,
                    repository: fakeRecipeRepo,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/compras/nova',
              builder: (context, state) => const Scaffold(
                body: Text('Tela Registrar Preços Nova Compra'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Test "Register prices" button
        final registerPricesButton = find.byKey(
          const Key('register_prices_button'),
        );
        expect(registerPricesButton, findsOneWidget);
        await tester.tap(registerPricesButton);
        await tester.pumpAndSettle();
        expect(find.text('Tela Registrar Preços Nova Compra'), findsOneWidget);

        // Go back
        router.go('/receitas/rec_strogonoff');
        await tester.pumpAndSettle();

        // 2. Test "Modo Passo a Passo" button
        final prepButton = find.byKey(const Key('recipe_preparation_button'));
        expect(prepButton, findsOneWidget);
        await tester.tap(prepButton);
        await tester.pumpAndSettle();

        // 3. Verify real recipe prep text from repository is displayed
        expect(find.byType(RecipePreparationScreen), findsOneWidget);
        expect(find.text('Strogonoff Clássico'), findsOneWidget);
        final prepTextFinder = find.byKey(const Key('recipe_prep_text'));
        expect(prepTextFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(prepTextFinder);
        expect(textWidget.data, contains('Passo 1: Doure a cebola e o alho.'));
        expect(
          textWidget.data,
          contains('Passo 3: Acrescente o molho de tomate'),
        );
      },
    );
  });
}
