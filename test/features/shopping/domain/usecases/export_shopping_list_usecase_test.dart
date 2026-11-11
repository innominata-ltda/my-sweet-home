import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/export_shopping_list_usecase.dart';

void main() {
  group('ExportShoppingListUseCase', () {
    test('exports a ShoppingList to a JSON string successfully', () {
      final date = DateTime(2026, 9, 25, 12, 0).toUtc();
      final list = ShoppingList(
        id: 'list_1',
        name: 'Compras da Semana',
        createdAt: date,
        storeId: 'store_1',
        isArchived: true,
        items: [],
      );

      final usecase = ExportShoppingListUseCase();
      final result = usecase.call(list);

      expect(result.isOk, isTrue);

      final jsonString = result.valueOrNull!;
      expect(jsonString, contains('"id":"list_1"'));
      expect(jsonString, contains('"name":"Compras da Semana"'));
      expect(jsonString, contains('"storeId":"store_1"'));
    });
  });
}
