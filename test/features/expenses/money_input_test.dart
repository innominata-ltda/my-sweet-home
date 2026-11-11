import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';

void main() {
  group('Money input parsing (CA-1.1)', () {
    test('parse "32" -> Money(3200)', () {
      final m = Money.tryParsePtBr('32');
      expect(m, isNotNull);
      expect(m!.cents, 3200);
    });

    test('parse "0" -> Money(0)', () {
      final m = Money.tryParsePtBr('0');
      expect(m, isNotNull);
      expect(m!.cents, 0);
    });

    test('parse "0,01" -> Money(1)', () {
      final m = Money.tryParsePtBr('0,01');
      expect(m, isNotNull);
      expect(m!.cents, 1);
    });

    test('parse "1.234,56" -> Money(123456)', () {
      final m = Money.tryParsePtBr('1.234,56');
      expect(m, isNotNull);
      expect(m!.cents, 123456);
    });

    test('parse "12,3" -> Money(1230)', () {
      final m = Money.tryParsePtBr('12,3');
      expect(m, isNotNull);
      expect(m!.cents, 1230);
    });
  });
}
