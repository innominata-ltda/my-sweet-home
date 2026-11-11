import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

void main() {
  group('ShoppingList serialization', () {
    test('toJson and fromJson work correctly', () {
      final date = DateTime(2026, 9, 25, 12, 0).toUtc();
      final list = ShoppingList(
        id: 'list_1',
        name: 'Compras da Semana',
        createdAt: date,
        storeId: 'store_1',
        isArchived: true,
        items: [
          ShoppingItem(id: 'item_1', rawText: 'Leite', parsedName: 'Leite'),
        ],
      );

      final json = list.toJson();
      expect(json, {
        'id': 'list_1',
        'name': 'Compras da Semana',
        'createdAt': date.toIso8601String(),
        'storeId': 'store_1',
        'isArchived': true,
        'items': [
          {
            'id': 'item_1',
            'rawText': 'Leite',
            'parsedName': 'Leite',
            'parsedQuantity': null,
            'productId': null,
            'boughtAt': null,
          },
        ],
      });

      final parsed = ShoppingList.fromJson(json);
      expect(parsed, list);
    });

    test('copyWith, operator == e hashCode', () {
      final now = DateTime(2026, 9, 20);
      final item = const ShoppingItem(
        id: 'i1',
        rawText: 'Pão',
        parsedName: 'Pão',
      );
      final list1 = ShoppingList(
        id: 'l1',
        name: 'Padaria',
        createdAt: now,
        storeId: 's1',
        isArchived: false,
        items: [item],
      );
      final list2 = ShoppingList(
        id: 'l1',
        name: 'Padaria',
        createdAt: now,
        storeId: 's1',
        isArchived: false,
        items: [item],
      );

      expect(list1, equals(list1));
      expect(list1, equals(list2));
      expect(list1.hashCode, equals(list2.hashCode));
      expect(list1, isNot(equals('list')));

      final cleared = list1.copyWith(clearStoreId: true);
      expect(cleared.storeId, isNull);
      expect(list1, isNot(equals(cleared)));

      final renamed = list1.copyWith(name: 'Padaria e Açougue');
      expect(renamed.name, 'Padaria e Açougue');
      expect(list1, isNot(equals(renamed)));
    });
  });
}
