import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/shopping/domain/models/known_price.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';

void main() {
  group('ShoppingItem serialization', () {
    test('toJson and fromJson work correctly with all fields', () {
      final date = DateTime(2026, 9, 25, 12, 0).toUtc();
      final item = ShoppingItem(
        id: '123',
        rawText: '2kg de arroz',
        parsedName: 'arroz',
        parsedQuantity: Quantity(2000, Unit.kg),
        productId: 'prod_1',
        boughtAt: date,
      );

      final json = item.toJson();
      expect(json, {
        'id': '123',
        'rawText': '2kg de arroz',
        'parsedName': 'arroz',
        'parsedQuantity': {'valueMilli': 2000, 'unit': 'kg'},
        'productId': 'prod_1',
        'boughtAt': date.toIso8601String(),
      });

      final parsed = ShoppingItem.fromJson(json);
      expect(parsed, item);
    });

    test('toJson and fromJson work correctly with null fields', () {
      final item = ShoppingItem(
        id: '123',
        rawText: 'arroz',
        parsedName: 'arroz',
      );

      final json = item.toJson();
      expect(json, {
        'id': '123',
        'rawText': 'arroz',
        'parsedName': 'arroz',
        'parsedQuantity': null,
        'productId': null,
        'boughtAt': null,
      });

      final parsed = ShoppingItem.fromJson(json);
      expect(parsed, item);
    });

    test('copyWith, isBought, operator == e hashCode', () {
      final now = DateTime(2026, 10, 5);
      final item1 = ShoppingItem(
        id: '1',
        rawText: 'leite 1l',
        parsedName: 'leite',
        parsedQuantity: const Quantity(1000, Unit.l),
        productId: 'p-leite',
        boughtAt: now,
      );

      final item2 = ShoppingItem(
        id: '1',
        rawText: 'leite 1l',
        parsedName: 'leite',
        parsedQuantity: const Quantity(1000, Unit.l),
        productId: 'p-leite',
        boughtAt: now,
      );

      expect(item1.isBought, isTrue);
      expect(item1, equals(item1));
      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
      expect(item1, isNot(equals('string')));

      final unbought = item1.copyWith(clearBoughtAt: true);
      expect(unbought.isBought, isFalse);
      expect(unbought.boughtAt, isNull);

      final modified = item1.copyWith(
        rawText: 'leite 2l',
        parsedQuantity: const Quantity(2000, Unit.l),
      );
      expect(modified.rawText, 'leite 2l');
      expect(item1, isNot(equals(modified)));
    });
  });

  group('ListEstimate model', () {
    test('isComplete, operator ==, hashCode e toString', () {
      final date = DateTime(2026, 8, 12);
      final est1 = ListEstimate(
        known: const Money(3500),
        itemsWithoutPrice: 0,
        oldestPriceUsed: date,
      );
      final est2 = ListEstimate(
        known: const Money(3500),
        itemsWithoutPrice: 0,
        oldestPriceUsed: date,
      );
      final est3 = ListEstimate(
        known: const Money(3500),
        itemsWithoutPrice: 2,
        oldestPriceUsed: date,
      );

      expect(est1.isComplete, isTrue);
      expect(est3.isComplete, isFalse);

      expect(est1, equals(est1));
      expect(est1, equals(est2));
      expect(est1.hashCode, equals(est2.hashCode));
      expect(est1, isNot(equals(est3)));
      expect(est1, isNot(equals('estimate')));
      expect(est1.toString(), contains('ListEstimate(known:'));
    });
  });

  group('KnownPrice model', () {
    test('operator ==, hashCode e toString', () {
      final now = DateTime(2026, 9, 1);
      final kp1 = KnownPrice(
        price: const Money(1250),
        recordedAt: now,
        storeId: 'store-1',
      );
      final kp2 = KnownPrice(
        price: const Money(1250),
        recordedAt: now,
        storeId: 'store-1',
      );
      final kp3 = KnownPrice(
        price: const Money(1500),
        recordedAt: now,
        storeId: 'store-2',
      );

      expect(kp1, equals(kp1));
      expect(kp1, equals(kp2));
      expect(kp1.hashCode, equals(kp2.hashCode));
      expect(kp1, isNot(equals(kp3)));
      expect(kp1, isNot(equals('known_price')));
      expect(kp1.toString(), contains('KnownPrice('));
    });
  });
}
