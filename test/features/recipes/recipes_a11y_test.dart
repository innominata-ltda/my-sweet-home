import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_screen.dart';

import '../../fakes/fake_recipe_repository.dart';
import '../../fakes/sequential_id_generator.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: child,
  );
}

void main() {
  group('T-B01: Acessibilidade TalkBack pt-BR em telas de receitas', () {
    testWidgets(
      'RecipeDraftScreen acessibilidade de salvar, ingrediente e porções',
      (tester) async {
        await tester.pumpWidget(
          _wrap(RecipeDraftScreen(idGenerator: SequentialIdGenerator())),
        );
        await tester.pumpAndSettle();

        // 1. Save button
        expect(find.byTooltip('Salvar receita'), findsOneWidget);
        expect(find.bySemanticsLabel('Salvar receita'), findsOneWidget);

        // 2. Time and servings spinboxes
        expect(find.byTooltip('Diminuir Porções'), findsOneWidget);
        expect(find.byTooltip('Aumentar Porções'), findsOneWidget);
        expect(find.bySemanticsLabel('Diminuir Porções'), findsOneWidget);
        expect(find.bySemanticsLabel('Aumentar Porções'), findsOneWidget);

        // Add an ingredient to test deletion
        await tester.tap(find.text('Adicionar Ingrediente'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('ingredient_name_input')),
          'Farinha de Trigo',
        );
        await tester.tap(
          find.byKey(const Key('confirm_add_ingredient_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Remover ingrediente'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'Remover ingrediente.*')),
          findsOneWidget,
        );
      },
    );

    testWidgets('RecipeDetailScreen accessibility of favorites and servings', (
      tester,
    ) async {
      final repo = FakeRecipeRepository(SystemClock());
      final res = await repo.upsert(
        const NewRecipe(
          title: 'Bolo Caseiro',
          ingredients: [Ingredient(name: 'Farinha')],
          prepText: 'Assar',
          timeMinutes: 30,
          servings: 4,
        ),
      );
      final recipe = res.valueOrNull!;

      final controller = RecipeDetailController(repo, recipe.id);
      await controller.load();

      await tester.pumpWidget(
        _wrap(
          RecipeDetailScreen(
            controller: controller,
            scaler: const StandardIngredientScaler(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Favorite button
      expect(find.byTooltip('Marcar como favorito'), findsOneWidget);
      expect(find.bySemanticsLabel('Marcar como favorito'), findsOneWidget);

      // Servings
      expect(find.byTooltip('Diminuir porções'), findsOneWidget);
      expect(find.byTooltip('Aumentar porções'), findsOneWidget);
      expect(find.bySemanticsLabel('Diminuir porções'), findsOneWidget);
      expect(find.bySemanticsLabel('Aumentar porções'), findsOneWidget);
    });

    testWidgets(
      'RecipeListScreen acessibilidade de filtro, FAB e item favorito',
      (tester) async {
        final repo = FakeRecipeRepository(SystemClock());
        await repo.upsert(
          const NewRecipe(
            title: 'Bolo de Milho',
            ingredients: [],
            prepText: 'Misturar',
            timeMinutes: 40,
            servings: 6,
            isFavorite: true,
          ),
        );

        final controller = RecipeListController(repo);
        await controller.load();

        await tester.pumpWidget(
          _wrap(RecipeListScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // FAB
        expect(find.byTooltip('Criar receita'), findsOneWidget);
        expect(find.bySemanticsLabel('Criar receita'), findsOneWidget);

        // Item favorito
        expect(find.byTooltip('Desmarcar favorito'), findsOneWidget);
        expect(find.bySemanticsLabel('Desmarcar favorito'), findsOneWidget);
      },
    );
  });
}
