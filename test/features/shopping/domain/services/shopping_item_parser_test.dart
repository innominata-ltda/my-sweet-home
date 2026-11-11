import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';

void main() {
  late DefaultShoppingItemParser parser;

  setUp(() {
    parser = const DefaultShoppingItemParser();
  });

  group('DefaultShoppingItemParser', () {
    test('Should parse quantity and unit correctly - 2kg arroz', () {
      final result = parser.parse('2kg arroz');
      expect(result.name, 'arroz');
      expect(result.quantity, const Quantity(2000, Unit.kg));
    });

    test('Should parse fraction correctly - 1/2 kg beans', () {
      final result = parser.parse('1/2 kg de feijão');
      expect(result.name, 'feijão');
      expect(result.quantity, const Quantity(500, Unit.kg));
    });

    test('Should parse integer units correctly - 3 un apple', () {
      final result = parser.parse('3 un maçã');
      expect(result.name, 'maçã');
      expect(result.quantity, const Quantity(3000, Unit.un));
    });

    test('Should parse unit at the end correctly - leite 1L', () {
      final result = parser.parse('leite 1L');
      expect(result.name, 'leite');
      expect(result.quantity, const Quantity(1000, Unit.l));
    });

    test('Should parse only name correctly - arroz', () {
      final result = parser.parse('arroz');
      expect(result.name, 'arroz');
      expect(result.quantity, isNull);
    });

    test('Should parse units with "de" correctly - 2 cx de leite', () {
      final result = parser.parse('2 cx de leite');
      expect(result.name, 'leite');
      expect(result.quantity, const Quantity(2000, Unit.pack));
    });

    test('Should parse decimal quantities correctly - 1.5 kg carne', () {
      final result = parser.parse('1.5 kg carne');
      expect(result.name, 'carne');
      expect(result.quantity, const Quantity(1500, Unit.kg));
    });

    test(
      'Should parse decimal quantities with comma correctly - 1,5 kg carne',
      () {
        final result = parser.parse('1,5 kg carne');
        expect(result.name, 'carne');
        expect(result.quantity, const Quantity(1500, Unit.kg));
      },
    );

    test('Should parse all mapped units', () {
      expect(parser.parse('1 g sal').quantity, const Quantity(1000, Unit.g));
      expect(parser.parse('1 ml agua').quantity, const Quantity(1000, Unit.ml));
      expect(
        parser.parse('1 unidade bolo').quantity,
        const Quantity(1000, Unit.un),
      );
      expect(
        parser.parse('1 unidades ovo').quantity,
        const Quantity(1000, Unit.un),
      );
      expect(
        parser.parse('1 pc salgadinho').quantity,
        const Quantity(1000, Unit.pack),
      );
      expect(
        parser.parse('1 pacote salgadinho').quantity,
        const Quantity(1000, Unit.pack),
      );
      expect(
        parser.parse('1 pacotes salgadinho').quantity,
        const Quantity(1000, Unit.pack),
      );
      expect(
        parser.parse('1 caixa leite').quantity,
        const Quantity(1000, Unit.pack),
      );
      expect(
        parser.parse('1 caixas leite').quantity,
        const Quantity(1000, Unit.pack),
      );
      expect(
        parser.parse('1 litro suco').quantity,
        const Quantity(1000, Unit.l),
      );
      expect(
        parser.parse('1 litros suco').quantity,
        const Quantity(1000, Unit.l),
      );
    });

    test('Should fallback to raw text if regex matches entirely but leaves no name', () {
      final result = parser.parse('2kg');
      expect(result.name, '2kg');
      expect(result.quantity, const Quantity(2000, Unit.kg));
    });

    test('Should trim resulting name properly', () {
      final result = parser.parse('   2kg    arroz   ');
      expect(result.name, 'arroz');
      expect(result.quantity, const Quantity(2000, Unit.kg));
    });
  });
}
