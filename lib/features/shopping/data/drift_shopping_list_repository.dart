import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart'
    hide ShoppingList, ShoppingItem;
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';

class DriftShoppingListRepository implements ShoppingListRepository {
  const DriftShoppingListRepository(this._db, this._parser, this._clock);

  final AppDatabase _db;
  final ShoppingItemParser _parser;
  final Clock _clock;

  @override
  Future<Result<List<ShoppingList>, Failure>> getAll() async {
    try {
      final listsQuery = _db.select(_db.shoppingLists)
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]);
      final lists = await listsQuery.get();

      if (lists.isEmpty) {
        return const Ok([]);
      }

      final itemsQuery = _db.select(_db.shoppingItems)
        ..orderBy([(t) => OrderingTerm(expression: t.position)]);
      final allItems = await itemsQuery.get();

      final itemsByListId = <String, List<db.ShoppingItem>>{};
      for (final item in allItems) {
        itemsByListId.putIfAbsent(item.listId!, () => []).add(item);
      }

      final result = lists.map((listRow) {
        return _mapList(listRow, itemsByListId[listRow.id] ?? []);
      }).toList();

      return Ok(result);
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<ShoppingList, Failure>> getById(String id) async {
    try {
      final listQuery = _db.select(_db.shoppingLists)
        ..where((t) => t.id.equals(id));
      final listRow = await listQuery.getSingleOrNull();

      if (listRow == null) {
        if (id == 'default') {
          final defaultList = ShoppingList(
            id: 'default',
            name: 'Lista de Compras',
            createdAt: _clock.nowUtc(),
          );
          await save(defaultList);
          return Ok(defaultList);
        }
        return const Err(
          NotFoundFailure(what: 'Lista de compras não encontrada'),
        );
      }

      final itemsQuery = _db.select(_db.shoppingItems)
        ..where((t) => t.listId.equals(id))
        ..orderBy([(t) => OrderingTerm(expression: t.position)]);
      final items = await itemsQuery.get();

      return Ok(_mapList(listRow, items));
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> save(ShoppingList list) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.shoppingLists)
            .insertOnConflictUpdate(
              ShoppingListsCompanion(
                id: Value(list.id),
                name: Value(list.name),
                createdAt: Value(list.createdAt.toUtc().toIso8601String()),
                storeId: Value(list.storeId),
                isArchived: Value(list.isArchived),
                updatedAt: Value(_clock.nowUtc().toIso8601String()),
              ),
            );

        // Remove items that are no longer in list
        final itemIds = list.items.map((e) => e.id).toList();
        if (itemIds.isNotEmpty) {
          await (_db.delete(
                _db.shoppingItems,
              )..where((t) => t.listId.equals(list.id) & t.id.isNotIn(itemIds)))
              .go();
        } else {
          await (_db.delete(
            _db.shoppingItems,
          )..where((t) => t.listId.equals(list.id))).go();
        }

        // Insere ou atualiza os itens
        if (list.items.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAllOnConflictUpdate(_db.shoppingItems, [
              for (var i = 0; i < list.items.length; i++)
                ShoppingItemsCompanion(
                  id: Value(list.items[i].id),
                  listId: Value(list.id),
                  productId: Value(list.items[i].productId),
                  freeText: Value(list.items[i].rawText),
                  quantityMilli: Value(
                    list.items[i].parsedQuantity?.valueMilli,
                  ),
                  unit: Value(list.items[i].parsedQuantity?.unit.name),
                  isChecked: Value(list.items[i].isBought),
                  checkedAt: Value(
                    list.items[i].boughtAt?.toUtc().toIso8601String(),
                  ),
                  source: const Value('manual'), // fallback source
                  position: Value(i),
                ),
            ]);
          });
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: e.toString()));
    }
  }

  ShoppingList _mapList(
    db.ShoppingList listRow,
    List<db.ShoppingItem> itemsRows,
  ) {
    return ShoppingList(
      id: listRow.id,
      name: listRow.name,
      createdAt: listRow.createdAt != null
          ? DateTime.parse(listRow.createdAt!).toUtc()
          : _clock.nowUtc(),
      storeId: listRow.storeId,
      isArchived: listRow.isArchived,
      items: itemsRows.map(_mapItem).toList(),
    );
  }

  ShoppingItem _mapItem(db.ShoppingItem row) {
    final rawText = row.freeText ?? '';
    final parsed = _parser.parse(rawText);

    Quantity? quantity;
    if (row.quantityMilli != null && row.unit != null) {
      final unit = Unit.values.firstWhere(
        (e) => e.name == row.unit,
        orElse: () => Unit.un,
      );
      quantity = Quantity(row.quantityMilli!, unit);
    } else {
      quantity = parsed.quantity;
    }

    return ShoppingItem(
      id: row.id,
      rawText: rawText,
      parsedName: parsed.name,
      parsedQuantity: quantity,
      productId: row.productId,
      boughtAt: row.checkedAt != null
          ? DateTime.parse(row.checkedAt!).toUtc()
          : null,
    );
  }
}
