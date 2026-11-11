import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';

void main() {
  group('Ingredient model', () {
    test('operator == e hashCode', () {
      const ing1 = Ingredient(
        name: 'Farinha',
        quantity: Quantity(500, Unit.g),
        productId: 'prod-farinha',
      );
      const ing2 = Ingredient(
        name: 'Farinha',
        quantity: Quantity(500, Unit.g),
        productId: 'prod-farinha',
      );
      const ing3 = Ingredient(
        name: 'Açúcar',
        quantity: Quantity(200, Unit.g),
        productId: 'prod-acucar',
      );

      expect(ing1, equals(ing1));
      expect(ing1, equals(ing2));
      expect(ing1.hashCode, equals(ing2.hashCode));
      expect(ing1, isNot(equals(ing3)));
      expect(ing1, isNot(equals('farinha')));
    });
  });

  group('Recipe e NewRecipe model', () {
    test('Recipe copyWith, operator == e hashCode', () {
      const ing = Ingredient(name: 'Ovo', quantity: Quantity(2, Unit.un));
      const recipe = Recipe(
        id: 'r1',
        title: 'Bolo Simples',
        ingredients: [ing],
        prepText: 'Misturar e assar',
        timeMinutes: 40,
        servings: 8,
        tags: {'sobremesa'},
        isFavorite: false,
      );

      final recipe2 = Recipe(
        id: 'r1',
        title: 'Bolo Simples',
        ingredients: [ing],
        prepText: 'Misturar e assar',
        timeMinutes: 40,
        servings: 8,
        tags: {'sobremesa'},
        isFavorite: false,
      );

      expect(recipe, equals(recipe));
      expect(recipe, equals(recipe2));
      expect(recipe.hashCode, equals(recipe2.hashCode));
      expect(recipe, isNot(equals('recipe')));

      final updated = recipe.copyWith(
        title: 'Bolo de Chocolate',
        ingredients: [
          ing,
          const Ingredient(name: 'Cacau', quantity: Quantity(100, Unit.g)),
        ],
        prepText: 'Misturar cacau e assar',
        timeMinutes: 45,
        servings: 10,
        tags: {'doce', 'chocolate'},
        isFavorite: true,
      );

      expect(updated.title, 'Bolo de Chocolate');
      expect(updated.ingredients.length, 2);
      expect(updated.prepText, 'Misturar cacau e assar');
      expect(updated.timeMinutes, 45);
      expect(updated.servings, 10);
      expect(updated.tags, {'doce', 'chocolate'});
      expect(updated.isFavorite, isTrue);
      expect(recipe, isNot(equals(updated)));
    });

    test('NewRecipe instantiates with default and custom values', () {
      const newRecipe = NewRecipe(
        id: 'new-1',
        title: 'Panqueca',
        ingredients: [],
        prepText: 'Fritar na frigideira',
        timeMinutes: 15,
        servings: 2,
        tags: {'cafe'},
        isFavorite: true,
      );

      expect(newRecipe.id, 'new-1');
      expect(newRecipe.title, 'Panqueca');
      expect(newRecipe.ingredients, isEmpty);
      expect(newRecipe.prepText, 'Fritar na frigideira');
      expect(newRecipe.timeMinutes, 15);
      expect(newRecipe.servings, 2);
      expect(newRecipe.tags, {'cafe'});
      expect(newRecipe.isFavorite, isTrue);
    });
  });
}
