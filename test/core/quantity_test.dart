// Testes de Quantity — cobre CA-2.1 e RN-003 (SPEC-001)

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';

void main() {
  group('Quantity — conversion between units (CA-2.1)', () {
    test('1500g == 1kg in base thousandths', () {
      // 1500000 thousandths of g x 1 (g.milliPerUnit) = 1500000 base
      // 1500 thousandths of kg x 1000 (kg.milliPerUnit) = 1500000 base -> equal
      final g = Quantity(1500000, Unit.g); // 1500 g reais
      final kg = Quantity(1500, Unit.kg); // 1.500 kg reais = 1500 g
      expect(g, kg);
    });

    test('1000ml == 1l', () {
      expect(Quantity(1000, Unit.ml), Quantity(1, Unit.l));
    });

    test('convertTo g → kg', () {
      final result = Quantity(2000, Unit.g).convertTo(Unit.kg);
      expect(result.valueMilli, 2); // 2000 g / 1000 = 2 kg (in thousandths = 2)
      expect(result.unit, Unit.kg);
    });

    test('convertTo kg → g', () {
      final result = Quantity(1, Unit.kg).convertTo(Unit.g);
      expect(result.valueMilli, 1000); // 1 kg = 1000 g
      expect(result.unit, Unit.g);
    });

    test('convertTo ml → l', () {
      final result = Quantity(500, Unit.ml).convertTo(Unit.l);
      expect(
        result.valueMilli,
        0,
      ); // 500 ml / 1000 = 0.5l -> 0 in integer thousandths
      expect(result.unit, Unit.l);
    });

    test('convertTo mesma unidade retorna equivalente', () {
      final q = Quantity(250, Unit.g);
      expect(q.convertTo(Unit.g), q);
    });

    test('conversion g -> l throws ArgumentError (different dimensions)', () {
      expect(
        () => Quantity(1000, Unit.g).convertTo(Unit.l),
        throwsArgumentError,
      );
    });

    test('conversion g -> un throws ArgumentError', () {
      expect(
        () => Quantity(500, Unit.g).convertTo(Unit.un),
        throwsArgumentError,
      );
    });

    test('conversion l -> kg throws ArgumentError', () {
      expect(() => Quantity(1, Unit.l).convertTo(Unit.kg), throwsArgumentError);
    });
  });

  group('Quantity.displayValue', () {
    test('1500 g → 1.5', () {
      expect(Quantity(1500, Unit.g).displayValue, 1.5);
    });

    test('500 ml → 0.5', () {
      expect(Quantity(500, Unit.ml).displayValue, 0.5);
    });

    test('2000 un → 2.0', () {
      expect(Quantity(2000, Unit.un).displayValue, 2.0);
    });
  });

  group('Quantity.unitPriceFor', () {
    test('2000g for R\$10.00 -> R\$0.005/g-base = 0 cents/g-thousandth', () {
      // 1000 cents per 2000 g-thousandths x 1 g-per-g
      // = 1000 * 1000 / (2000 * 1) = 500 thousandths of cent per g
      // mas em centavos inteiros = 500 / 1000 = 0? Vamos calcular:
      // unitPriceFor: total.cents * 1000 / baseValueMilli
      // = 1000 * 1000 / (2000 * 1) = 500 cents per g-base? No...
      // Calculo: baseValueMilli = 2000 * 1 (Unit.g.milliPerUnit = 1)
      // = 2000 thousandths of g x 1 = 2000
      // cents * 1000 / 2000 = 1000000 / 2000 = 500 centavos/g-base
      // Analysis: price per base unit
      // Mass base = 1g. We have 2000 thousandths of g = 2 real g.
      // Total price = 1000 cents for 2 g -> 500 cents/g. Correct!
      final q = Quantity(2000, Unit.g);
      expect(q.unitPriceFor(Money(1000)).cents, 500);
    });

    test('1kg for R\$5.00 -> price per g-base', () {
      // 1 kg = 1000 g. baseValueMilli = 1 * 1000 (kg.milliPerUnit) = 1000
      // 500 * 1000 / 1000 = 500 centavos/g. Parece muito — 5,00 por kg = 0,005/g
      // Quantity(1000, Unit.kg) = 1.0 kg = 1000 thousandths of kg
      final q = Quantity(1000, Unit.kg); // 1.0 kg = 1000 thousandths of kg
      // base = 1000 * 1000 = 1000000 base-millis-g
      // cents * 1000 / 1000000 = 500 * 1000 / 1000000 = 0 centavos/g
      // Correto! 500 centavos para 1000g = 0.5 centavos/g → 0 em int
      expect(q.unitPriceFor(Money(500)).cents, 0);
    });

    test('quantidade zero retorna Money.zero', () {
      expect(Quantity(0, Unit.un).unitPriceFor(Money(999)), Money.zero);
    });
  });

  group('Quantity igualdade (CA-2.1)', () {
    test('1000g == 1000g', () {
      expect(Quantity(1000, Unit.g), Quantity(1000, Unit.g));
    });

    test('different units but same dimension — semantic equality', () {
      // 1000 thousandths of g x 1 = 1000 base; 1 thousandth of kg x 1000 = 1000 base -> EQUAL
      expect(Quantity(1000, Unit.g), equals(Quantity(1, Unit.kg)));
      // 1000000 thousandths of g x 1 = 1000000 base; 1000 thousandths of kg x 1000 = 1000000 -> EQUAL
      expect(Quantity(1000000, Unit.g), Quantity(1000, Unit.kg));
      // 500 g ≠ 1 kg (500 base vs 1000 base)
      expect(Quantity(500, Unit.g), isNot(equals(Quantity(1, Unit.kg))));
    });

    test('different dimensions are never equal', () {
      expect(Quantity(1000, Unit.g), isNot(equals(Quantity(1000, Unit.ml))));
    });
  });

  group('Unit — dimensions', () {
    test('un and pack are count', () {
      expect(Unit.un.dimension, Dimension.count);
      expect(Unit.pack.dimension, Dimension.count);
    });

    test('g and kg are mass', () {
      expect(Unit.g.dimension, Dimension.mass);
      expect(Unit.kg.dimension, Dimension.mass);
    });

    test('ml and l are volume', () {
      expect(Unit.ml.dimension, Dimension.volume);
      expect(Unit.l.dimension, Dimension.volume);
    });

    test('milliPerUnit: g=1, kg=1000, ml=1, l=1000', () {
      expect(Unit.g.milliPerUnit, 1);
      expect(Unit.kg.milliPerUnit, 1000);
      expect(Unit.ml.milliPerUnit, 1);
      expect(Unit.l.milliPerUnit, 1000);
    });
  });

  group('Quantity serialization and arithmetic', () {
    test('toJson and fromJson', () {
      final q = Quantity(1500, Unit.kg);
      final json = q.toJson();
      expect(json, {'valueMilli': 1500, 'unit': 'kg'});
      final parsed = Quantity.fromJson(json);
      expect(parsed.valueMilli, 1500);
      expect(parsed.unit, Unit.kg);
    });

    test('operator + and - with same dimension', () {
      final q1 = Quantity(1000, Unit.g);
      final q2 = Quantity(500, Unit.g);
      expect((q1 + q2).valueMilli, 1500);
      expect((q1 - q2).valueMilli, 500);

      // different units same dimension
      final qKg = Quantity(1, Unit.kg);
      expect((q1 + qKg).valueMilli, 2000);
      expect((qKg - q1).valueMilli, 0);

      // different dimension throws
      expect(() => q1 + Quantity(1, Unit.l), throwsArgumentError);
      expect(() => q1 - Quantity(1, Unit.l), throwsArgumentError);
    });
  });
}
