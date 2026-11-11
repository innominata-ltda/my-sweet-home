import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/ocr/data/sqlite_save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/sequential_id_generator.dart';

void main() {
  late db.AppDatabase database;
  late SqliteSaveReceiptUseCase useCase;
  late Clock clock;

  setUp(() async {
    database = db.AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 10, 16, 12, 0, 0));
    useCase = SqliteSaveReceiptUseCase(
      database,
      clock: clock,
      idGenerator: SequentialIdGenerator(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SqliteSaveReceiptUseCase - Registering new products and synonyms (T-B11, RF-044, RF-045, RN-199)', () {
    test('Saves new product created in review and persists canonical name and OCR synonym in transaction', () async {
      final newProduct = Product(
        id: 'prod_custom_suco_uva',
        canonicalName: 'Suco de Uva Integral 1L',
        categoryId: 'cat_bebidas',
        defaultUnit: Unit.l,
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      );

      final item = ReceiptItemDraft(
        rawDescription: 'SUCO UVA INT 1L',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(1290),
        totalPrice: const Money(1290),
        confidence: 0.95,
        selected: true,
        match: ProductMatch(
          product: newProduct,
          origin: const ExactUserAlias(),
          score: 1.0,
        ),
      );

      final draft = ReceiptDraft(
        store: const StoreDraft(
          name: 'Supermercado Nova Era',
          cnpj: '45.543.915/0001-81',
          isCnpjValid: true,
        ),
        purchasedAt: clock.nowUtc(),
        items: [item],
        subtotal: const Money(1290),
        discount: const Money(0),
        total: const Money(1290),
        confidence: 0.95,
      );

      final result = await useCase(draft, const SaveOptions());
      expect(result.isOk, isTrue);

      // 1. O novo produto deve estar salvo na tabela Products
      final savedProduct = await (database.select(
        database.products,
      )..where((p) => p.id.equals('prod_custom_suco_uva'))).getSingleOrNull();
      expect(savedProduct, isNotNull);
      expect(savedProduct!.canonicalName, equals('Suco de Uva Integral 1L'));
      expect(savedProduct.categoryId, equals('cat_bebidas'));
      expect(savedProduct.defaultUnit, equals('l'));

      // 2. Category must have been created automatically to preserve referential integrity
      final savedCat = await (database.select(
        database.categories,
      )..where((c) => c.id.equals('cat_bebidas'))).getSingleOrNull();
      expect(savedCat, isNotNull);

      // 3. Synonyms/aliases must be persisted in ProductAliases table
      final aliases = await (database.select(
        database.productAliases,
      )..where((a) => a.productId.equals('prod_custom_suco_uva'))).get();

      // Must contain canonical alias (source: 'user')
      final userAlias = aliases.firstWhere((a) => a.source == 'user');
      expect(userAlias.alias, equals('Suco de Uva Integral 1L'));
      expect(userAlias.normalizedAlias, equals('suco uva integral'));

      // Deve conter o alias lido do OCR (source: 'ocr')
      final ocrAlias = aliases.firstWhere((a) => a.source == 'ocr');
      expect(ocrAlias.alias, equals('SUCO UVA INT 1L'));
      expect(ocrAlias.normalizedAlias, equals('suco uva int'));
    });

    test('Links read receipt text as new synonym (source = ocr) for existing product', () async {
      // 1. Pre-register an existing product in catalog
      await database
          .into(database.products)
          .insert(
            db.ProductsCompanion.insert(
              id: 'prod_arroz_5kg',
              canonicalName: 'Arroz Agulhinha 5kg',
              defaultUnit: 'kg',
            ),
          );

      // 2. Draft with unknown description linked to existing product
      final item = ReceiptItemDraft(
        rawDescription: 'ARROZ SUBMARINO 5KG',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(2390),
        totalPrice: const Money(2390),
        confidence: 0.90,
        selected: true,
        match: ProductMatch(
          product: Product(
            id: 'prod_arroz_5kg',
            canonicalName: 'Arroz Agulhinha 5kg',
            categoryId: 'alimentos',
            defaultUnit: Unit.kg,
            createdAt: clock.nowUtc(),
            updatedAt: clock.nowUtc(),
          ),
          origin: const ExactUserAlias(),
          score: 1.0,
        ),
      );

      final draft = ReceiptDraft(
        store: const StoreDraft(name: 'Hipermercado'),
        purchasedAt: clock.nowUtc(),
        items: [item],
        total: const Money(2390),
        confidence: 0.90,
      );

      final result = await useCase(draft, const SaveOptions());
      expect(result.isOk, isTrue);

      // 3. Verify new synonym was recorded for existing product with source = 'ocr'
      final aliases = await (database.select(
        database.productAliases,
      )..where((a) => a.productId.equals('prod_arroz_5kg'))).get();

      final ocrAlias = aliases.firstWhere(
        (a) => a.alias == 'ARROZ SUBMARINO 5KG',
      );
      expect(ocrAlias.source, equals('ocr'));
      expect(ocrAlias.normalizedAlias, equals('arroz submarino'));
    });

    test('Unselected items do not record new synonyms nor create unselected products', () async {
      final unselectedProduct = Product(
        id: 'prod_desmarcado',
        canonicalName: 'Item Ignorado',
        categoryId: 'geral',
        defaultUnit: Unit.un,
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      );

      final itemUnselected = ReceiptItemDraft(
        rawDescription: 'ITEM IGNORADO PELO USUARIO',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(500),
        totalPrice: const Money(500),
        confidence: 0.30,
        selected: false, // Unchecked during review
        match: ProductMatch(
          product: unselectedProduct,
          origin: const ExactUserAlias(),
          score: 1.0,
        ),
      );

      // Item selecionado para permitir salvar compra
      final itemSelected = ReceiptItemDraft(
        rawDescription: 'ITEM VALIDO',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(1000),
        totalPrice: const Money(1000),
        confidence: 0.95,
        selected: true,
      );

      final draft = ReceiptDraft(
        store: const StoreDraft(name: 'Mercado'),
        purchasedAt: clock.nowUtc(),
        items: [itemUnselected, itemSelected],
        total: const Money(1000),
        confidence: 0.95,
      );

      final result = await useCase(draft, const SaveOptions());
      expect(result.isOk, isTrue);

      final prod = await (database.select(
        database.products,
      )..where((p) => p.id.equals('prod_desmarcado'))).getSingleOrNull();
      expect(prod, isNull);

      final alias =
          await (database.select(database.productAliases)
                ..where((a) => a.alias.equals('ITEM IGNORADO PELO USUARIO')))
              .getSingleOrNull();
      expect(alias, isNull);
    });
  });
}
