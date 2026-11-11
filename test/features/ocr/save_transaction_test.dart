import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/expenses/domain/models/category.dart'
    as exp_cat;
import 'package:my_sweet_home/features/ocr/data/sqlite_save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/prices/data/price_point/sqlite_price_point_repository.dart';
import 'package:my_sweet_home/features/prices/data/store/sqlite_store_repository.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import '../../fakes/fake_clock.dart';

void main() {
  late db.AppDatabase database;
  late SqliteSaveReceiptUseCase useCase;
  late Clock clock;

  setUp(() async {
    database = db.AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 9, 30, 18, 0, 0));
    useCase = SqliteSaveReceiptUseCase(
      database,
      clock: clock,
      idGenerator: const SequentialIdGenerator(),
    );

    // Register test products for links
    for (var i = 1; i <= 12; i++) {
      final id = 'prod_$i';
      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: id,
              canonicalName: 'Produto $i',
              defaultUnit: 'un',
            ),
          );
    }
  });

  tearDown(() async {
    await database.close();
  });

  ReceiptItemDraft createDraftItem({
    required int index,
    required bool selected,
    bool withProductMatch = true,
  }) {
    final productId = 'prod_$index';
    final product = Product(
      id: productId,
      canonicalName: 'Produto $index',
      categoryId: 'cat_market',
      defaultUnit: Unit.un,
      createdAt: clock.nowUtc(),
      updatedAt: clock.nowUtc(),
    );

    return ReceiptItemDraft(
      rawDescription: 'ITEM $index',
      quantity: const Quantity(1000, Unit.un),
      unitPrice: Money(1000 * index),
      totalPrice: Money(1000 * index),
      confidence: selected ? 0.9 : 0.4,
      selected: selected,
      match: withProductMatch
          ? ProductMatch(
              product: product,
              origin: const ExactSeedAlias(),
              score: 1.0,
            )
          : null,
    );
  }

  test('CA-5.1: Saves purchase, selected items (10 of 12), price points, and expense in one transaction', () async {
    // 12 itens no draft: 10 selecionados, 2 desmarcados (RN-200, CA-5.1)
    final items = List.generate(
      12,
      (i) => createDraftItem(index: i + 1, selected: i < 10),
    );

    final draft = ReceiptDraft(
      store: StoreDraft(
        name: 'Mercado Carrefour',
        rawCnpj: '45543915000181',
        cnpj: '45.543.915/0001-81',
        isCnpjValid: true,
      ),
      purchasedAt: DateTime.utc(2026, 9, 29, 15, 30),
      items: items,
      total: Money(55000),
      discount: Money(0),
      paymentMethod: 'credit_card',
      confidence: 0.92,
    );

    const options = SaveOptions(
      categoryId: exp_cat.CategoryId('cat_market'),
      createExpense: true,
      purchaseId: 'purchase_501',
      expenseId: 'expense_501',
    );

    final result = await useCase.call(draft, options);

    expect(result.isOk, isTrue);
    final purchase = result.valueOrNull!;
    expect(purchase.id, equals('purchase_501'));
    expect(purchase.items.length, equals(10));

    // Verificar tabela Purchases
    final purchasesInDb = await database.select(database.purchases).get();
    expect(purchasesInDb.length, equals(1));
    final purchaseRow = purchasesInDb.first;
    expect(purchaseRow.id, equals('purchase_501'));
    expect(purchaseRow.source, equals('ocr'));
    expect(purchaseRow.expenseId, equals('expense_501'));
    expect(purchaseRow.totalCents, equals(55000));

    // Verificar tabela PurchaseItems (deve ter exatamente os 10 selecionados)
    final itemsInDb = await database.select(database.purchaseItems).get();
    expect(itemsInDb.length, equals(10));
    for (var i = 0; i < 10; i++) {
      expect(itemsInDb[i].purchaseId, equals('purchase_501'));
      expect(itemsInDb[i].productId, equals('prod_${i + 1}'));
      expect(itemsInDb[i].position, equals(i));
    }

    // Verify PricePoints table (must have exactly 10 price points, 1 per linked item)
    final pointsInDb = await database.select(database.pricePoints).get();
    expect(pointsInDb.length, equals(10));
    for (final pt in pointsInDb) {
      expect(pt.source, equals('purchase'));
      expect(pt.storeId, equals(purchaseRow.storeId));
    }

    // Verificar leitura pelo SqlitePricePointRepository
    final pricePointRepo = SqlitePricePointRepository(database);
    final statsRes = await pricePointRepo.getByProduct(
      'prod_1',
      since: DateTime.utc(2026, 1, 1),
    );
    expect(statsRes.isOk, isTrue);
    expect(statsRes.valueOrNull!.length, equals(1));

    // Verificar tabela Expenses (1 despesa criada)
    final expensesInDb = await database.select(database.expenses).get();
    expect(expensesInDb.length, equals(1));
    final expenseRow = expensesInDb.first;
    expect(expenseRow.id, equals('expense_501'));
    expect(expenseRow.amountCents, equals(55000));
    expect(expenseRow.purchaseId, equals('purchase_501'));
    expect(expenseRow.categoryId, equals('cat_market'));

    // Verificar tabela Stores (1 estabelecimento criado com CNPJ limpo)
    final storesInDb = await database.select(database.stores).get();
    expect(storesInDb.length, equals(1));
    expect(storesInDb.first.name, equals('Mercado Carrefour'));
    expect(storesInDb.first.cnpj, equals('45543915000181'));

    // Verificar busca do estabelecimento por CNPJ pelo SqliteStoreRepository
    final storeRepo = SqliteStoreRepository(database);
    final storeRes = await storeRepo.findByCnpj('45543915000181');
    expect(storeRes.isOk, isTrue);
    expect(storeRes.valueOrNull!.name, equals('Mercado Carrefour'));
  });

  test('CA-5.2: Falha ao gravar o 8º item provoca rollback completo no SqliteSaveReceiptUseCase real', () async {
    final items = List.generate(
      12,
      (i) => createDraftItem(index: i + 1, selected: i < 10),
    );

    final draft = ReceiptDraft(
      store: StoreDraft(
        name: 'Supermercado Teste',
        rawCnpj: '45543915000181',
        cnpj: '45.543.915/0001-81',
        isCnpjValid: true,
      ),
      items: items,
      total: Money(55000),
      confidence: 0.9,
    );

    const options = SaveOptions(
      createExpense: true,
      purchaseId: 'purchase_failing',
    );

    // Pre-insert conflicting row at 8th item ID (position 7 -> purchase_failing_item_7)
    await database
        .into(database.purchases)
        .insert(
          db.PurchasesCompanion.insert(
            id: 'other_purchase',
            purchasedAt: clock.nowUtc().toIso8601String(),
            totalCents: 100,
            source: 'manual',
          ),
        );
    await database
        .into(database.purchaseItems)
        .insert(
          db.PurchaseItemsCompanion.insert(
            id: 'purchase_failing_item_7',
            purchaseId: 'other_purchase',
            rawDescription: 'Existing item blocking item 8',
            quantityMilli: 1000,
            unit: 'un',
            unitPriceCents: 100,
            totalPriceCents: 100,
            position: 0,
          ),
        );

    final result = await useCase.call(draft, options);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<StorageFailure>());

    // Ensure complete rollback: failing_purchase and its other items do not exist
    final purchasesInDb = await database.select(database.purchases).get();
    final itemsInDb = await database.select(database.purchaseItems).get();
    final pointsInDb = await database.select(database.pricePoints).get();
    final expensesInDb = await database.select(database.expenses).get();

    expect(purchasesInDb.where((p) => p.id == 'purchase_failing'), isEmpty);
    expect(itemsInDb.where((i) => i.purchaseId == 'purchase_failing'), isEmpty);
    expect(pointsInDb, isEmpty);
    expect(expensesInDb, isEmpty);
  });

  test(
    'Retorna erro de validação se nenhum item estiver selecionado',
    () async {
      final items = List.generate(
        5,
        (i) => createDraftItem(index: i + 1, selected: false),
      );

      final draft = ReceiptDraft(
        store: StoreDraft(name: 'Loja'),
        items: items,
        confidence: 0.5,
      );

      final result = await useCase.call(draft, const SaveOptions());

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      final purchasesInDb = await database.select(database.purchases).get();
      expect(purchasesInDb, isEmpty);
    },
  );

  test('Creates purchase items without price point when item is not linked to product', () async {
    final items = [
      createDraftItem(index: 1, selected: true, withProductMatch: true),
      createDraftItem(index: 2, selected: true, withProductMatch: false),
      createDraftItem(index: 3, selected: true, withProductMatch: true),
    ];

    final draft = ReceiptDraft(
      store: StoreDraft(name: 'Mercado Sem Vínculo'),
      items: items,
      confidence: 0.9,
    );

    final result = await useCase.call(draft, const SaveOptions());

    expect(result.isOk, isTrue);

    final itemsInDb = await database.select(database.purchaseItems).get();
    expect(itemsInDb.length, equals(3));
    expect(itemsInDb[1].productId, isNull);

    // Only 2 price points must be created (since only 2 items have productId)
    final pointsInDb = await database.select(database.pricePoints).get();
    expect(pointsInDb.length, equals(2));
  });

  test('T-19 (RN-201, RN-087): Saving receipt with writeOffShoppingListId writes off corresponding list items', () async {
    // Inserir lista de compras e itens na tabela SQLite
    await database
        .into(database.shoppingLists)
        .insert(
          db.ShoppingListsCompanion.insert(
            id: 'list_market',
            name: 'Lista de Mercado',
          ),
        );

    // Item 1 from list: prod_1 (will be in purchase) -> unchecked
    await database
        .into(database.shoppingItems)
        .insert(
          db.ShoppingItemsCompanion.insert(
            id: 'item_list_1',
            listId: const Value('list_market'),
            productId: const Value('prod_1'),
            freeText: const Value('Produto 1'),
            isChecked: const Value(false),
            position: 0,
            source: 'manual',
          ),
        );

    // Item 2 from list: prod_3 (will not be in purchase) -> unchecked
    await database
        .into(database.shoppingItems)
        .insert(
          db.ShoppingItemsCompanion.insert(
            id: 'item_list_2',
            listId: const Value('list_market'),
            productId: const Value('prod_3'),
            freeText: const Value('Outro Produto'),
            isChecked: const Value(false),
            position: 1,
            source: 'manual',
          ),
        );

    final items = [
      createDraftItem(index: 1, selected: true, withProductMatch: true),
      createDraftItem(index: 2, selected: true, withProductMatch: true),
    ];

    final draft = ReceiptDraft(
      store: StoreDraft(name: 'Mercado com Lista'),
      items: items,
      confidence: 0.9,
    );

    final options = const SaveOptions(writeOffShoppingListId: 'list_market');

    final result = await useCase.call(draft, options);

    expect(result.isOk, isTrue);

    final shoppingItemsInDb = await database
        .select(database.shoppingItems)
        .get();
    expect(shoppingItemsInDb.length, equals(2));

    final item1 = shoppingItemsInDb.firstWhere((i) => i.id == 'item_list_1');
    expect(item1.isChecked, isTrue);
    expect(item1.checkedAt, isNotNull);

    final item2 = shoppingItemsInDb.firstWhere((i) => i.id == 'item_list_2');
    expect(item2.isChecked, isFalse);
    expect(item2.checkedAt, isNull);
  });
}

class SequentialIdGenerator implements IdGenerator {
  const SequentialIdGenerator();

  @override
  String newId() => 'seq_id';
}
