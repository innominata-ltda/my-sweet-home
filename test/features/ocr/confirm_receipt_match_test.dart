import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Product;
import 'package:my_sweet_home/features/ocr/domain/confirm_receipt_match_use_case.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/default_product_matcher.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';

class _FakeFailureRepository implements ProductRepository {
  @override
  Future<Result<Product, Failure>> addAlias(
    ProductId id,
    String alias,
    AliasSource source,
  ) async {
    return const Err(StorageFailure(detail: 'Simulated database error'));
  }

  @override
  Future<Result<Product, Failure>> create(NewProduct p) =>
      throw UnimplementedError();
  @override
  Future<Result<Product, Failure>> setCanonicalName(
    ProductId id,
    String canonicalName,
  ) => throw UnimplementedError();
  @override
  Future<Result<Product, Failure>> separateAlias(String aliasId) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> removeAlias(String aliasId) =>
      throw UnimplementedError();
  @override
  Future<Result<AliasConflict?, Failure>> checkAliasConflict(String alias) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> registerDenial(ProductId id, String rawText) =>
      throw UnimplementedError();
  @override
  Future<Result<List<Product>, Failure>> search(
    String query, {
    int limit = 50,
  }) => throw UnimplementedError();
  @override
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  }) => throw UnimplementedError();
  @override
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id) =>
      throw UnimplementedError();
  @override
  Future<Result<ProductIndex, Failure>> buildIndex() =>
      throw UnimplementedError();
  @override
  Future<Result<bool, Failure>> hasHistory(ProductId id) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> archive(ProductId id) =>
      throw UnimplementedError();
  @override
  Future<Result<void, Failure>> delete(ProductId id) =>
      throw UnimplementedError();
}

void main() {
  group('ConfirmReceiptMatchUseCase (T-17, RN-199, CA-3.3)', () {
    late AppDatabase db;
    late FakeClock clock;
    late SequentialIdGenerator idGen;
    late ProductDao productDao;
    late ConfirmReceiptMatchUseCase useCase;

    setUp(() async {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 9, 30, 12, 0));
      idGen = SequentialIdGenerator();
      productDao = ProductDao(db, idGen, clock);
      useCase = ConfirmReceiptMatchUseCase(productDao);

      // Criar categoria base
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-padaria',
              name: 'Padaria',
              kind: 'product',
              iconKey: 'bread',
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-laticinios',
              name: 'Laticínios',
              kind: 'product',
              iconKey: 'milk',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('confirmSingleMatch grava apelido com source = ocr (RN-199)', () async {
      // 1. Create canonical product
      final pResult = await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      );
      expect(pResult.isOk, isTrue);
      final product = pResult.valueOrNull!;

      // 2. Confirm link for OCR text "PAO FRANC 50G"
      final confirmResult = await useCase.confirmSingleMatch(
        productId: product.id,
        rawText: 'PAO FRANC 50G',
      );

      expect(confirmResult.isOk, isTrue);

      // 3. Verificar no banco que o apelido foi gravado com source = 'ocr'
      final aliases = await db.select(db.productAliases).get();
      final ocrAlias = aliases.firstWhere((a) => a.alias == 'PAO FRANC 50G');
      expect(ocrAlias.productId, product.id);
      expect(ocrAlias.normalizedAlias, 'pao franc');
      expect(ocrAlias.source, 'ocr');

      // 4. Verificar que novo matching com o texto lido encontra ExactUserAlias
      final indexResult = await productDao.buildIndex();
      final index = indexResult.valueOrNull!;
      const matcher = DefaultProductMatcher();

      final matchResult = matcher.match('PAO FRANC 50G', index);
      expect(matchResult, isA<SingleMatch>());
      final singleMatch = matchResult as SingleMatch;
      expect(singleMatch.match.product.id, product.id);
      expect(singleMatch.match.origin, isA<ExactUserAlias>());
      expect(singleMatch.needsConfirmation, isFalse);
    });

    test('CA-3.3: Given user confirms match, when saving, "pao franc" becomes alias with source = ocr', () async {
      // 1. Create canonical products
      final paoRes = await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      );
      final leiteRes = await productDao.create(
        const NewProduct(
          canonicalName: 'Leite Integral 1L',
          categoryId: 'cat-laticinios',
          defaultUnit: Unit.l,
        ),
      );
      final pao = paoRes.valueOrNull!;
      final leite = leiteRes.valueOrNull!;

      // 2. Montar ReceiptDraft com itens selecionados e vinculados
      final itemPao = ReceiptItemDraft(
        rawDescription: 'PAO FRANC 50G',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(100),
        totalPrice: const Money(100),
        confidence: 0.95,
        selected: true,
        match: ProductMatch(
          product: pao,
          origin: const Fuzzy(score: 0.88),
          score: 0.88,
        ),
      );

      final itemLeite = ReceiptItemDraft(
        rawDescription: 'LEITE INT 1L',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(450),
        totalPrice: const Money(450),
        confidence: 0.90,
        selected: true,
        match: ProductMatch(
          product: leite,
          origin: const Fuzzy(score: 0.86),
          score: 0.86,
        ),
      );

      final itemDesmarcado = ReceiptItemDraft(
        rawDescription: 'DETERGENTE YPE',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(200),
        totalPrice: const Money(200),
        confidence: 0.40,
        selected: false, // unselected due to low confidence
        match: null,
      );

      final draft = ReceiptDraft(
        store: const StoreDraft(
          name: 'Mercado Local',
          cnpj: null,
          isCnpjValid: false,
        ),
        items: [itemPao, itemLeite, itemDesmarcado],
        confidence: 0.90,
      );

      // 3. Executar confirmDraftMatches
      final result = await useCase.confirmDraftMatches(draft);
      expect(result.isOk, isTrue);

      // 4. Validate that only selected items with link generate aliases with source = 'ocr'
      final allAliases = await db.select(db.productAliases).get();

      final paoAliases = allAliases
          .where((a) => a.productId == pao.id && a.source == 'ocr')
          .toList();
      expect(paoAliases, hasLength(1));
      expect(paoAliases.first.alias, 'PAO FRANC 50G');
      expect(paoAliases.first.normalizedAlias, 'pao franc');

      final leiteAliases = allAliases
          .where((a) => a.productId == leite.id && a.source == 'ocr')
          .toList();
      expect(leiteAliases, hasLength(1));
      expect(leiteAliases.first.alias, 'LEITE INT 1L');
      expect(leiteAliases.first.normalizedAlias, 'leite int');

      // No entry for unselected/unlinked item
      final detergentAliases = allAliases
          .where((a) => a.normalizedAlias == 'detergente ype')
          .toList();
      expect(detergentAliases, isEmpty);
    });

    test('confirmSingleMatch is idempotent when alias already exists for same product', () async {
      final pResult = await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      );
      final product = pResult.valueOrNull!;

      // Call twice for same alias and product
      final r1 = await useCase.confirmSingleMatch(
        productId: product.id,
        rawText: 'PAO FRANC 50G',
      );
      final r2 = await useCase.confirmSingleMatch(
        productId: product.id,
        rawText: 'PAO FRANC 50G',
      );

      expect(r1.isOk, isTrue);
      expect(r2.isOk, isTrue);

      final aliases = await db.select(db.productAliases).get();
      final ocrAliases = aliases
          .where((a) => a.normalizedAlias == 'pao franc')
          .toList();
      expect(ocrAliases, hasLength(1));
    });

    test(
      'confirmDraftMatches propagates error if ProductRepository fails',
      () async {
        final failRepo = _FakeFailureRepository();
        final failUseCase = ConfirmReceiptMatchUseCase(failRepo);

        final dummyProduct = Product(
          id: 'prod-dummy',
          canonicalName: 'Dummy',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final item = ReceiptItemDraft(
          rawDescription: 'PAO FRANC',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(100),
          totalPrice: const Money(100),
          confidence: 0.90,
          selected: true,
          match: ProductMatch(
            product: dummyProduct,
            origin: const Fuzzy(score: 0.90),
            score: 0.90,
          ),
        );

        final draft = ReceiptDraft(
          store: const StoreDraft(name: 'Loja', cnpj: null, isCnpjValid: false),
          items: [item],
          confidence: 0.90,
        );

        final result = await failUseCase.confirmDraftMatches(draft);

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      },
    );

    test('confirmSingleMatch returns ValidationFailure when rawText is empty or whitespace only', () async {
      final pResult = await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      );
      final product = pResult.valueOrNull!;

      final result = await useCase.confirmSingleMatch(
        productId: product.id,
        rawText: '   ',
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('confirmSingleMatch trims whitespace in rawText', () async {
      final pResult = await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      );
      final product = pResult.valueOrNull!;

      final result = await useCase.confirmSingleMatch(
        productId: product.id,
        rawText: '  PAO FRANC 50G  ',
      );

      expect(result.isOk, isTrue);
      final aliases = await db.select(db.productAliases).get();
      final ocrAlias = aliases.firstWhere(
        (a) => a.normalizedAlias == 'pao franc',
      );
      expect(ocrAlias.alias, 'PAO FRANC 50G');
    });

    test('confirmSingleMatch returns ValidationFailure when alias belongs to another product', () async {
      final p1 = (await productDao.create(
        const NewProduct(
          canonicalName: 'Pão Francês',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      final p2 = (await productDao.create(
        const NewProduct(
          canonicalName: 'Pão de Forma',
          categoryId: 'cat-padaria',
          defaultUnit: Unit.un,
        ),
      )).valueOrNull!;

      // Atribuir "PAO FRANC" ao produto 1
      await useCase.confirmSingleMatch(productId: p1.id, rawText: 'PAO FRANC');

      // Tentar atribuir o mesmo "PAO FRANC" ao produto 2
      final conflictResult = await useCase.confirmSingleMatch(
        productId: p2.id,
        rawText: 'PAO FRANC',
      );

      expect(conflictResult.isErr, isTrue);
      expect(conflictResult.failureOrNull, isA<ValidationFailure>());
    });
  });
}
