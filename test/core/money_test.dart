// Testes de Money — cobre CA-1.1, CA-1.2, CA-1.3 (SPEC-001)
// Expected coverage: 100% of money.dart (parser rule, 95% threshold per 004-testing.md §2)

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';

void main() {
  group('Money — arithmetic (CA-1.1)', () {
    test('soma simples', () {
      expect((Money(1099) + Money(1)).cents, 1100);
    });

    test('soma formata corretamente em pt-BR', () {
      expect((Money(1099) + Money(1)).formatPtBr(), 'R\$ 11,00');
    });

    test('subtraction', () {
      expect((Money(500) - Money(200)).cents, 300);
    });

    test('subtraction resulting in negative', () {
      expect((Money(100) - Money(200)).cents, -100);
    });

    test('multiplication by integer factor', () {
      expect(Money(333).times(3).cents, 999);
    });

    test('timesRatio rounds to nearest cent', () {
      // 100 centavos × 1 ÷ 3 = 33.33... → 33
      expect(Money(100).timesRatio(1, 3).cents, 33);
      // 100 centavos × 2 ÷ 3 = 66.66... → 67
      expect(Money(100).timesRatio(2, 3).cents, 67);
    });

    test('Money.zero is 0 cents', () {
      expect(Money.zero.cents, 0);
    });

    test('comparison operators', () {
      expect(Money(100) < Money(200), isTrue);
      expect(Money(200) > Money(100), isTrue);
      expect(Money(100) <= Money(100), isTrue);
      expect(Money(100) >= Money(100), isTrue);
      expect(Money(100) < Money(100), isFalse);
    });
  });

  group('Money.split — distribution without losing cents (CA-1.2)', () {
    test('100 ÷ 3 = [34, 33, 33]', () {
      final parts = Money(100).split(3);
      expect(parts.map((m) => m.cents).toList(), [34, 33, 33]);
    });

    test('sum of parts matches original exactly', () {
      for (final total in [100, 101, 102, 199, 1000, 1001]) {
        for (final n in [2, 3, 4, 5, 7]) {
          final parts = Money(total).split(n);
          final sum = parts.fold(0, (acc, m) => acc + m.cents);
          expect(sum, total, reason: 'Money($total).split($n) soma errada');
        }
      }
    });

    test('1 part returns the value itself', () {
      expect(Money(999).split(1).single.cents, 999);
    });

    test('split de zero', () {
      final parts = Money(0).split(3);
      expect(parts.map((m) => m.cents).toList(), [0, 0, 0]);
    });

    test('10 partes de 10 = todas iguais a 1', () {
      final parts = Money(10).split(10);
      expect(parts.map((m) => m.cents).toList(), List.filled(10, 1));
    });
  });

  group('Money.tryParsePtBr — parsing (CA-1.3)', () {
    test('"12,3" → 1230', () {
      expect(Money.tryParsePtBr('12,3')?.cents, 1230);
    });

    test('"12,30" → 1230', () {
      expect(Money.tryParsePtBr('12,30')?.cents, 1230);
    });

    test('"12" (sem centavos) → 1200', () {
      expect(Money.tryParsePtBr('12')?.cents, 1200);
    });

    test('"1.234,56" → 123456', () {
      expect(Money.tryParsePtBr('1.234,56')?.cents, 123456);
    });

    test('"R\$ 1.234,56" → 123456', () {
      expect(Money.tryParsePtBr('R\$ 1.234,56')?.cents, 123456);
    });

    test('"0,01" → 1 centavo', () {
      expect(Money.tryParsePtBr('0,01')?.cents, 1);
    });

    test('"999.999,99" → 99999999 centavos', () {
      expect(Money.tryParsePtBr('999.999,99')?.cents, 99999999);
    });

    test('negativo "-12,50" → -1250', () {
      expect(Money.tryParsePtBr('-12,50')?.cents, -1250);
    });

    test('string vazia → null', () {
      expect(Money.tryParsePtBr(''), isNull);
    });

    test('invalid text -> null', () {
      expect(Money.tryParsePtBr('abc'), isNull);
    });

    test('three decimal places -> null', () {
      expect(Money.tryParsePtBr('1,234'), isNull);
    });

    test('double comma -> null', () {
      expect(Money.tryParsePtBr('1,,2'), isNull);
    });
  });

  group('Money.formatPtBr — formatting (CA-1.1)', () {
    test('Money(1100) → "R\$ 11,00"', () {
      expect(Money(1100).formatPtBr(), 'R\$ 11,00');
    });

    test('Money(0) → "R\$ 0,00"', () {
      expect(Money(0).formatPtBr(), 'R\$ 0,00');
    });

    test('Money(1) → "R\$ 0,01"', () {
      expect(Money(1).formatPtBr(), 'R\$ 0,01');
    });

    test('Money(100) → "R\$ 1,00"', () {
      expect(Money(100).formatPtBr(), 'R\$ 1,00');
    });

    test('Money(99999999) → "R\$ 999.999,99"', () {
      expect(Money(99999999).formatPtBr(), 'R\$ 999.999,99');
    });

    test('negativo Money(-1250) → "R\$ -12,50"', () {
      expect(Money(-1250).formatPtBr(), 'R\$ -12,50');
    });

    test('Money(123456789) — 7 digits with thousands separator', () {
      expect(Money(123456789).formatPtBr(), 'R\$ 1.234.567,89');
    });
  });

  group('Money.fromDouble — arredondamento', () {
    test('1.995 → 200 centavos', () {
      expect(Money.fromDouble(1.995).cents, 200);
    });

    test('0.001 → 0 centavos (abaixo de 0.5)', () {
      expect(Money.fromDouble(0.001).cents, 0);
    });

    test('0.005 → 1 centavo', () {
      expect(Money.fromDouble(0.005).cents, 1);
    });
  });
}
