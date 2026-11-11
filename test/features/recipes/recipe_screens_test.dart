import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';

import '../../fakes/fake_recipe_repository.dart';

import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: child,
  );
}

void main() {
  group('Recipe Screens', () {
    late FakeRecipeRepository repo;

    setUp(() {
      repo = FakeRecipeRepository(SystemClock());
    });

    testWidgets('RecipeListScreen Empty State', (tester) async {
      final controller = RecipeListController(repo);
      await tester.pumpWidget(_wrap(RecipeListScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma receita ainda. Comece pela que você mais faz.'),
        findsOneWidget,
      );
      await expectLater(
        find.byType(RecipeListScreen),
        matchesGoldenFile('goldens/recipe_list_empty.png'),
      );
    });

    testWidgets('RecipeListScreen Success State', (tester) async {
      await repo.upsert(
        const NewRecipe(
          title: 'Bolo de Cenoura',
          ingredients: [],
          prepText: 'Misturar tudo',
          timeMinutes: 45,
          servings: 8,
        ),
      );

      final controller = RecipeListController(repo);
      await tester.pumpWidget(_wrap(RecipeListScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Bolo de Cenoura'), findsOneWidget);
      expect(find.text('45 min • 8 porções'), findsOneWidget);
      await expectLater(
        find.byType(RecipeListScreen),
        matchesGoldenFile('goldens/recipe_list_success.png'),
      );
    });

    testWidgets('RecipeDetailScreen Loading State', (tester) async {
      repo.simulateDelay = true;
      final controller = RecipeDetailController(repo, 'not_found');
      await tester.pumpWidget(
        _wrap(
          RecipeDetailScreen(
            controller: controller,
            scaler: const StandardIngredientScaler(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      // Removed golden for loading state to avoid unstable tests on CI due to CircularProgressIndicator
    });

    testWidgets('RecipeDetailScreen Error State', (tester) async {
      final controller = RecipeDetailController(repo, 'not_found');
      await tester.pumpWidget(
        _wrap(
          RecipeDetailScreen(
            controller: controller,
            scaler: const StandardIngredientScaler(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar receita'), findsOneWidget);
      await expectLater(
        find.byType(RecipeDetailScreen),
        matchesGoldenFile('goldens/recipe_detail_error.png'),
      );
    });

    testWidgets('RecipeDetailScreen Success State', (tester) async {
      final result = await repo.upsert(
        const NewRecipe(
          title: 'Pudim',
          ingredients: [],
          prepText: 'Assar no banho maria',
          timeMinutes: 60,
          servings: 4,
        ),
      );

      final recipe = (result as Ok<Recipe, Failure>).value;

      final controller = RecipeDetailController(repo, recipe.id);
      await tester.pumpWidget(
        _wrap(
          RecipeDetailScreen(
            controller: controller,
            scaler: const StandardIngredientScaler(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pudim'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('4 porções'), findsOneWidget);
      expect(find.text('Assar no banho maria'), findsOneWidget);
      expect(find.text('Custo indisponível'), findsOneWidget);

      await expectLater(
        find.byType(RecipeDetailScreen),
        matchesGoldenFile('goldens/recipe_detail_success.png'),
      );
    });
  });
}
