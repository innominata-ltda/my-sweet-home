import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/services/ingredient_scaler.dart';
import 'package:my_sweet_home/features/recipes/domain/services/recipe_cost_policy.dart';

void main() {
  group('StandardRecipeCostPolicy', () {
    final policy = StandardRecipeCostPolicy();

    // ─── Helpers ────────────────────────────────────────────────────────────

    /// Cria um [ScaledIngredient] simples com productId e quantidade.
    ScaledIngredient scaled({
      required String name,
      required Quantity qty,
      String? productId,
    }) {
      return ScaledIngredient(
        source: Ingredient(name: name, quantity: qty, productId: productId),
        exact: qty,
        display: name,
      );
    }

    /// Cria um [ScaledIngredient] sem medida exata ("a gosto").
    ScaledIngredient unscalable(String name) {
      return ScaledIngredient(
        source: Ingredient(name: name, quantity: null),
        exact: null,
        display: name,
      );
    }

    final priceArroz = KnownPrice(
      normalizedPrice: const Money(800), // R$8,00/kg
      normalizedUnit: Unit.kg,
      date: DateTime.utc(2026, 1, 1),
    );
    final priceOvo = KnownPrice(
      normalizedPrice: const Money(50), // R$0,50/un
      normalizedUnit: Unit.un,
      date: DateTime.utc(2026, 1, 5),
    );
    final priceOleo = KnownPrice(
      normalizedPrice: const Money(600), // R$6,00/l
      normalizedUnit: Unit.l,
      date: DateTime.utc(2026, 1, 10),
    );

    // ─── CA-2.1 ─────────────────────────────────────────────────────────────

    test(
      'CA-2.1: 4 ingredients, 3 with price -> CostEstimated(missing: 1)',
      () {
        // 4 scalable ingredients with productId
        // 3 with price: rice 500g, 2 eggs, 200ml oil
        // 1 without price: salt
        final ingredients = [
          scaled(
            name: 'arroz',
            qty: const Quantity(500000, Unit.g), // 500g
            productId: 'p-arroz',
          ),
          scaled(
            name: 'ovos',
            qty: const Quantity(2000, Unit.un), // 2 un
            productId: 'p-ovo',
          ),
          scaled(
            name: 'óleo',
            qty: const Quantity(200000, Unit.ml), // 200ml = 0.2l
            productId: 'p-oleo',
          ),
          scaled(
            name: 'sal',
            qty: const Quantity(5000, Unit.g), // 5g
            productId: 'p-sal', // productId exists but no price in map
          ),
        ];

        final prices = <ProductId, KnownPrice>{
          'p-arroz': priceArroz,
          'p-ovo': priceOvo,
          'p-oleo': priceOleo,
          // 'p-sal' deliberadamente ausente
        };

        final result = policy.estimate(
          ingredients: ingredients,
          lastPrices: prices,
        );

        expect(result, isA<CostEstimated>());
        final estimated = result as CostEstimated;
        expect(estimated.missing, 1);

        // Custo esperado:
        // rice: R$8.00/kg * 0.5kg = R$4.00 = 400 cents
        // eggs:  R$0.50/un * 2     = R$1.00 = 100 cents
        // oil:   R$6.00/l  * 0.2l  = R$1.20 = 120 cents
        // total = 620 cents
        expect(estimated.total, const Money(620));

        // Data mais antiga: arroz (2026-01-01)
        expect(estimated.oldestPriceUsed, DateTime.utc(2026, 1, 1));
      },
    );

    // ─── CA-2.2 ─────────────────────────────────────────────────────────────

    test(
      'CA-2.2: 5 ingredientes, 2 com preço (60% faltando) → CostUnknown',
      () {
        // 5 scalable ingredients with productId
        // only 2 with price (40%); 3 without price (60% > 30%) -> CostUnknown
        final ingredients = [
          scaled(
            name: 'arroz',
            qty: const Quantity(500000, Unit.g),
            productId: 'p-arroz',
          ),
          scaled(
            name: 'ovos',
            qty: const Quantity(2000, Unit.un),
            productId: 'p-ovo',
          ),
          scaled(
            name: 'feijão',
            qty: const Quantity(300000, Unit.g),
            productId: 'p-feijao',
          ),
          scaled(
            name: 'sal',
            qty: const Quantity(5000, Unit.g),
            productId: 'p-sal',
          ),
          scaled(
            name: 'alho',
            qty: const Quantity(10000, Unit.g),
            productId: 'p-alho',
          ),
        ];

        final prices = <ProductId, KnownPrice>{
          'p-arroz': priceArroz,
          'p-ovo': priceOvo,
          // beans, salt, garlic without price
        };

        final result = policy.estimate(
          ingredients: ingredients,
          lastPrices: prices,
        );

        expect(result, isA<CostUnknown>());
        final unknown = result as CostUnknown;
        expect(unknown.missing, 3);
        expect(unknown.total, 5);
      },
    );

    // ─── Edge cases ──────────────────────────────────────────────────────────

    test('Ingredient without productId does not count in denominator', () {
      // Scalable ingredient without productId -> does not count as candidate
      final ingredients = [
        ScaledIngredient(
          source: const Ingredient(
            name: 'genérico',
            quantity: Quantity(1000, Unit.un),
          ),
          exact: const Quantity(1000, Unit.un),
          display: 'genérico',
        ),
        scaled(
          name: 'arroz',
          qty: const Quantity(1000000, Unit.g), // 1kg
          productId: 'p-arroz',
        ),
      ];

      final prices = <ProductId, KnownPrice>{'p-arroz': priceArroz};

      final result = policy.estimate(
        ingredients: ingredients,
        lastPrices: prices,
      );

      // Apenas o arroz conta; 0 faltando de 1 → CostEstimated
      expect(result, isA<CostEstimated>());
      final estimated = result as CostEstimated;
      expect(estimated.missing, 0);
      expect(estimated.total, const Money(800)); // 1kg × R$8,00/kg
    });

    test(
      'Ingredient "to taste" (unscalable) does not count in denominator',
      () {
        final ingredients = [
          unscalable('sal a gosto'),
          scaled(
            name: 'arroz',
            qty: const Quantity(500000, Unit.g),
            productId: 'p-arroz',
          ),
        ];

        final prices = <ProductId, KnownPrice>{'p-arroz': priceArroz};

        final result = policy.estimate(
          ingredients: ingredients,
          lastPrices: prices,
        );

        expect(result, isA<CostEstimated>());
        final estimated = result as CostEstimated;
        expect(estimated.missing, 0);
        expect(estimated.total, const Money(400)); // 500g × R$8,00/kg = R$4,00
      },
    );

    test('Lista vazia retorna CostUnknown(missing: 0, total: 0)', () {
      final result = policy.estimate(ingredients: [], lastPrices: {});

      expect(result, isA<CostUnknown>());
      final unknown = result as CostUnknown;
      expect(unknown.missing, 0);
      expect(unknown.total, 0);
    });

    test(
      'Exatamente 30% sem preço — ainda CostEstimated (limiar exclusivo)',
      () {
        // 10 candidates, 3 missing = 30% -> still CostEstimated (> 30% is Unknown)
        final candidates = List.generate(
          10,
          (i) => scaled(
            name: 'item$i',
            qty: const Quantity(1000, Unit.un),
            productId: 'p$i',
          ),
        );

        final prices = <ProductId, KnownPrice>{
          for (int i = 0; i < 7; i++)
            'p$i': KnownPrice(
              normalizedPrice: const Money(100),
              normalizedUnit: Unit.un,
              date: DateTime.utc(2026, 1, 1),
            ),
        };

        final result = policy.estimate(
          ingredients: candidates,
          lastPrices: prices,
        );

        expect(result, isA<CostEstimated>());
        final estimated = result as CostEstimated;
        expect(estimated.missing, 3);
      },
    );
  });
}
