import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/data/purchase/sqlite_purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';

import 'package:my_sweet_home/core/time/clock.dart';

void main() {
  late db.AppDatabase database;
  late SqlitePurchaseRepository repository;

  setUp(() {
    database = db.AppDatabase.memory();
    repository = SqlitePurchaseRepository(database, SystemClock());
  });

  tearDown(() async {
    await database.close();
  });

  test('Saves and fetches a purchase with items', () async {
    // Setup: Insert store and generic products for foreign keys (SQLite enables foreign keys)
    await database
        .into(database.stores)
        .insert(db.StoresCompanion.insert(id: 's1', name: 'Mercado Teste'));
    await database
        .into(database.categories)
        .insert(
          db.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Mercado',
            kind: 'product',
            iconKey: 'cart',
          ),
        );
    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod1',
            canonicalName: 'Arroz',
            categoryId: const Value('cat1'),
            defaultUnit: 'kg',
          ),
        );
    await database
        .into(database.products)
        .insert(
          db.ProductsCompanion.insert(
            id: 'prod2',
            canonicalName: 'Feijão',
            categoryId: const Value('cat1'),
            defaultUnit: 'kg',
          ),
        );

    final item1 = PurchaseItem(
      id: 'i1',
      productId: 'prod1',
      quantity: const Quantity(1000, Unit.un),
      unitPrice: const Money(400),
      totalPrice: const Money(400),
    );
    final item2 = PurchaseItem(
      id: 'i2',
      productId: 'prod2',
      quantity: const Quantity(2000, Unit.kg),
      unitPrice: const Money(500),
      totalPrice: const Money(1000),
    );

    final purchase = Purchase(
      id: 'p1',
      storeId: 's1',
      date: DateTime.utc(2026, 9, 25),
      items: [item1, item2],
      totalAmount: const Money(1400),
      discountAmount: Money.zero,
    );

    // Salva
    final saveResult = await repository.save(purchase);
    expect(saveResult.isOk, isTrue);

    // Busca
    final findResult = await repository.findById('p1');
    expect(findResult.isOk, isTrue);

    final loaded = findResult.valueOrNull!;
    expect(loaded.id, 'p1');
    expect(loaded.storeId, 's1');
    expect(loaded.date, DateTime.utc(2026, 9, 25));
    expect(loaded.totalAmount, const Money(1400));
    expect(loaded.items, hasLength(2));
    expect(loaded.items[0].id, 'i1');
    expect(loaded.items[0].productId, 'prod1');
    expect(loaded.items[0].quantity, const Quantity(1000, Unit.un));
    expect(loaded.items[1].id, 'i2');
    expect(loaded.items[1].productId, 'prod2');
    expect(loaded.items[1].quantity, const Quantity(2000, Unit.kg));
  });

  test(
    'Exclui logicamente e restaura uma compra e seus price points',
    () async {
      // Setup
      await database
          .into(database.stores)
          .insert(db.StoresCompanion.insert(id: 's2', name: 'Mercado Delete'));
      await database
          .into(database.categories)
          .insert(
            db.CategoriesCompanion.insert(
              id: 'cat2',
              name: 'M',
              kind: 'product',
              iconKey: 'x',
            ),
          );
      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'prod3',
              canonicalName: 'Suco',
              categoryId: const Value('cat2'),
              defaultUnit: 'un',
            ),
          );

      final purchase = Purchase(
        id: 'p2',
        storeId: 's2',
        date: DateTime.utc(2026, 9, 25),
        items: [
          PurchaseItem(
            id: 'i3',
            productId: 'prod3',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(400),
            totalPrice: const Money(400),
          ),
        ],
        totalAmount: const Money(400),
        discountAmount: Money.zero,
      );
      await repository.save(purchase);

      // Insere um price point vinculado
      await database
          .into(database.pricePoints)
          .insert(
            db.PricePointsCompanion.insert(
              id: 'pp1',
              productId: const Value('prod3'),
              storeId: const Value('s2'),
              observedAt: DateTime.utc(2026, 9, 25).toIso8601String(),
              unitPriceCents: 400,
              normalizedPriceCents: 400,
              quantityMilli: 1000,
              unit: 'un',
              purchaseItemId: const Value('i3'),
              source: 'manual',
            ),
          );

      // Soft delete
      final delRes = await repository.delete('p2');
      expect(delRes.isOk, isTrue);

      // Verifica BD purchases
      final pRow = await (database.select(
        database.purchases,
      )..where((t) => t.id.equals('p2'))).getSingle();
      expect(pRow.deletedAt != null, isTrue);

      // Verifica BD pricePoints
      final ppRow = await (database.select(
        database.pricePoints,
      )..where((t) => t.id.equals('pp1'))).getSingle();
      expect(ppRow.deletedAt != null, isTrue);

      // Restore
      final restRes = await repository.restore('p2');
      expect(restRes.isOk, isTrue);

      // Verifica BD purchases
      final pRow2 = await (database.select(
        database.purchases,
      )..where((t) => t.id.equals('p2'))).getSingle();
      expect(pRow2.deletedAt == null, isTrue);

      // Verifica BD pricePoints
      final ppRow2 = await (database.select(
        database.pricePoints,
      )..where((t) => t.id.equals('pp1'))).getSingle();
      expect(ppRow2.deletedAt == null, isTrue);
    },
  );

  test(
    'getAll retorna todas as compras ativas e ignora soft-deleted',
    () async {
      await database
          .into(database.stores)
          .insert(db.StoresCompanion.insert(id: 's1', name: 'Mercado Teste'));
      await database
          .into(database.categories)
          .insert(
            db.CategoriesCompanion.insert(
              id: 'cat1',
              name: 'Mercado',
              kind: 'product',
              iconKey: 'cart',
            ),
          );
      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'prod1',
              canonicalName: 'Arroz',
              categoryId: const Value('cat1'),
              defaultUnit: 'kg',
            ),
          );

      final purchase1 = Purchase(
        id: 'p1',
        storeId: 's1',
        date: DateTime.utc(2026, 3, 1),
        items: [
          PurchaseItem(
            id: 'i1',
            productId: 'prod1',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(500),
            totalPrice: const Money(500),
          ),
        ],
        totalAmount: const Money(500),
        discountAmount: Money.zero,
      );
      final purchase2 = Purchase(
        id: 'p2',
        storeId: 's1',
        date: DateTime.utc(2026, 3, 2),
        items: [],
        totalAmount: const Money(1000),
        discountAmount: Money.zero,
      );

      await repository.save(purchase1);
      await repository.save(purchase2);

      final resBefore = await repository.getAll();
      expect(resBefore.isOk, isTrue);
      expect(resBefore.valueOrNull!.length, 2);

      await repository.delete('p1');
      final resAfter = await repository.getAll();
      expect(resAfter.isOk, isTrue);
      final remaining = resAfter.valueOrNull!;
      expect(remaining.length, 1);
      expect(remaining.first.id, 'p2');
    },
  );

  test(
    'Salvar compra persiste pontos de precos (PricePoints) automaticamente',
    () async {
      await database
          .into(database.stores)
          .insert(db.StoresCompanion.insert(id: 's10', name: 'Mercado Preco'));
      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'prod10',
              canonicalName: 'Leite',
              defaultUnit: 'l',
            ),
          );

      final item = PurchaseItem(
        id: 'item_leite',
        productId: 'prod10',
        rawDescription: 'Leite Integral 1L',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(450),
        totalPrice: const Money(450),
      );

      final purchase = Purchase(
        id: 'p_pp',
        storeId: 's10',
        date: DateTime.utc(2026, 9, 25),
        items: [item],
        totalAmount: const Money(450),
        discountAmount: Money.zero,
      );

      final res = await repository.save(purchase);
      expect(res.isOk, isTrue);

      final points = await database.select(database.pricePoints).get();
      expect(points, hasLength(1));
      expect(points.first.productId, 'prod10');
      expect(points.first.storeId, 's10');
      expect(points.first.unitPriceCents, 450);
      expect(points.first.normalizedPriceCents, 450);
      expect(points.first.purchaseItemId, 'item_leite');

      // Updating purchase with a different item replaces previous price points
      final updatedItem = PurchaseItem(
        id: 'item_leite_v2',
        productId: 'prod10',
        rawDescription: 'Leite Integral 1L Promoção',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(399),
        totalPrice: const Money(399),
      );
      final updatedPurchase = Purchase(
        id: 'p_pp',
        storeId: 's10',
        date: DateTime.utc(2026, 9, 26),
        items: [updatedItem],
        totalAmount: const Money(399),
        discountAmount: Money.zero,
      );
      final updateRes = await repository.save(updatedPurchase);
      expect(updateRes.isOk, isTrue);

      final pointsAfter = await database.select(database.pricePoints).get();
      expect(pointsAfter, hasLength(1));
      expect(pointsAfter.first.purchaseItemId, 'item_leite_v2');
      expect(pointsAfter.first.unitPriceCents, 399);
    },
  );
}
