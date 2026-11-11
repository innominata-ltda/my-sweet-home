import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_draft_controller.dart';

class FakeIdGenerator implements IdGenerator {
  @override
  String newId() => 'fake-id';
}

void main() {
  group('RecipeDraftController', () {
    test('Initializes with empty/default values', () {
      final controller = RecipeDraftController();
      expect(controller.value.title, isEmpty);
      expect(controller.value.ingredients, isEmpty);
      expect(controller.value.prepText, isEmpty);
      expect(controller.value.timeMinutes, 0);
      expect(controller.value.servings, 1);
    });

    test('Updates basic fields correctly', () {
      final controller = RecipeDraftController();
      controller.updateTitle('Nova Receita');
      controller.updatePrepText('Misture tudo');
      controller.updateTimeMinutes(30);
      controller.updateServings(4);

      expect(controller.value.title, 'Nova Receita');
      expect(controller.value.prepText, 'Misture tudo');
      expect(controller.value.timeMinutes, 30);
      expect(controller.value.servings, 4);
    });

    test('Ignores invalid values (servings <= 0 or time < 0)', () {
      final controller = RecipeDraftController();
      controller.updateTimeMinutes(-5);
      controller.updateServings(0);
      controller.updateServings(-1);

      expect(controller.value.timeMinutes, 0);
      expect(controller.value.servings, 1);
    });

    test('Adiciona e remove ingredientes', () {
      final controller = RecipeDraftController();
      final ingredient = Ingredient(
        name: 'Ovo',
        quantity: Quantity(1000, Unit.un),
      );

      controller.addIngredient(ingredient);
      expect(controller.value.ingredients, [ingredient]);

      controller.removeIngredient(0);
      expect(controller.value.ingredients, isEmpty);
    });

    test('Modifica favoritos e tags', () {
      final controller = RecipeDraftController();
      expect(controller.value.isFavorite, isFalse);
      expect(controller.value.tags, isEmpty);

      controller.toggleFavorite();
      expect(controller.value.isFavorite, isTrue);

      controller.addTag('rapido');
      controller.addTag('doce');
      expect(controller.value.tags, {'rapido', 'doce'});

      controller.removeTag('rapido');
      expect(controller.value.tags, {'doce'});
    });

    test(
      'Lança StateError ao criar receita sem título ou sem ingredientes',
      () {
        final controller = RecipeDraftController();
        final idGen = FakeIdGenerator();

        expect(() => controller.buildRecipe(idGen), throwsStateError);

        controller.updateTitle('Bolo');
        expect(() => controller.buildRecipe(idGen), throwsStateError);

        controller.addIngredient(Ingredient(name: 'Farinha'));
        final recipe = controller.buildRecipe(idGen);
        expect(recipe.title, 'Bolo');
        expect(recipe.ingredients.length, 1);
      },
    );
  });
}
