import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';

void main() {
  group('StandardIngredientScaler', () {
    final scaler = StandardIngredientScaler();

    test(
      'CA-1.1: 2->1 porção, 500g de arroz vira 250g; "sal a gosto" intacto',
      () {
        final ingredients = [
          Ingredient(
            name: 'de arroz', // o "de" facilita o '$display $name' = '250g de arroz'
            quantity: Quantity(500000, Unit.g), // 500g = 500000 milli (Quantity.displayValue is valueMilli / 1000, so 500g -> displayValue = 500, valueMilli = 500000)
          ),
          Ingredient(name: 'sal a gosto', quantity: null),
        ];

        final scaled = scaler.scale(ingredients, from: 2, to: 1);

        expect(scaled, hasLength(2));

        expect(scaled[0].exact?.displayValue, 250.0);
        expect(scaled[0].exact?.unit, Unit.g);
        expect(scaled[0].display, '250g de arroz');
        expect(scaled[0].isScalable, true);

        expect(scaled[1].exact, isNull);
        expect(scaled[1].display, 'sal a gosto');
        expect(scaled[1].isScalable, false);
      },
    );

    test('CA-1.2: 2->3 servings, 2 eggs -> display "3 ovos", exact = 3.0', () {
      final ingredients = [
        Ingredient(
          name: 'ovos',
          quantity: Quantity(2000, Unit.un), // 2 un = 2000 milli
        ),
      ];

      final scaled = scaler.scale(ingredients, from: 2, to: 3);

      expect(scaled, hasLength(1));

      expect(scaled[0].exact?.displayValue, 3.0);
      expect(scaled[0].exact?.unit, Unit.un);
      expect(scaled[0].display, '3 ovos');
    });

    test('Escala fracionada (1.33)', () {
      final ingredients = [
        Ingredient(
          name: 'ovo',
          quantity: Quantity(1000, Unit.un), // 1 un
        ),
      ];

      final scaled = scaler.scale(ingredients, from: 3, to: 4);

      expect(scaled, hasLength(1));
      // 1 * 4 / 3 = 1.3333333333
      // exactMilli = 1000 * 4 ~/ 3 = 1333
      expect(scaled[0].exact?.displayValue, 1.333);
      // display = '1 a 2 ovo' (or ovos, but name is 'ovo' so it becomes '1 a 2 ovo')
      expect(scaled[0].display, '1 a 2 ovo');
    });
    test('Usable rounding for mass and volume', () {
      final ingredients = [
        Ingredient(
          name: 'de farinha',
          quantity: Quantity(250333, Unit.g), // 250.333 g
        ),
        Ingredient(
          name: 'de leite',
          quantity: Quantity(1333, Unit.ml), // 1.333 ml -> 1.33 ml
        ),
        Ingredient(
          name: 'de queijo',
          quantity: Quantity(1550, Unit.kg), // 1.55 kg -> 1.6 kg because >= 10 is missing. Wait, 1.55 kg is 1.55 < 10, so 2 decimal places -> 1.55kg
        ),
        Ingredient(
          name: 'de água',
          quantity: Quantity(
            15500,
            Unit.l,
          ), // 15.5 L -> >= 10 -> 1 decimal place -> 15.5L
        ),
        Ingredient(
          name: 'biscoito',
          quantity: Quantity(1000, Unit.pack), // 1 pack -> 1
        ),
      ];

      final scaled = scaler.scale(ingredients, from: 1, to: 1);

      expect(scaled[0].display, '250g de farinha');
      expect(scaled[1].display, '1,33ml de leite');
      expect(scaled[2].display, '1,55kg de queijo');
      expect(scaled[3].display, '15,5L de água');
      expect(scaled[4].display, '1 biscoito');
    });

    test('Throws exception when from or to <= 0', () {
      expect(() => scaler.scale([], from: 0, to: 1), throwsArgumentError);
      expect(() => scaler.scale([], from: 1, to: 0), throwsArgumentError);
    });
  });
}
