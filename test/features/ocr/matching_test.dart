import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_item_matcher.dart';
import 'package:my_sweet_home/features/products/domain/default_product_matcher.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

void main() {
  group('ReceiptItemMatcher (T-10, RN-197, CA-3.2)', () {
    late ReceiptItemMatcher itemMatcher;

    final productPao = Product(
      id: 'prod-pao',
      canonicalName: 'Pão Francês',
      categoryId: 'cat-padaria',
      defaultUnit: Unit.un,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final productLeite = Product(
      id: 'prod-leite',
      canonicalName: 'Leite Integral 1L',
      categoryId: 'cat-laticinios',
      defaultUnit: Unit.l,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final productCafe = Product(
      id: 'prod-cafe',
      canonicalName: 'Café Torrado e Moído 500g',
      categoryId: 'cat-matina',
      defaultUnit: Unit.g,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final aliasPaoOcr = ProductAlias(
      id: 'alias-pao-1',
      productId: 'prod-pao',
      alias: 'PAO FRANC 50G',
      normalizedAlias: 'pao franc',
      source: AliasSource.ocr,
      createdAt: DateTime(2026, 1, 1),
    );

    final aliasLeiteSeed = ProductAlias(
      id: 'alias-leite-1',
      productId: 'prod-leite',
      alias: 'Leite de Vaca',
      normalizedAlias: 'leite vaca',
      source: AliasSource.seed,
      createdAt: DateTime(2026, 1, 1),
    );

    final index = ProductIndex.from(
      [productPao, productLeite, productCafe],
      [aliasPaoOcr, aliasLeiteSeed],
      [],
    );

    setUp(() {
      itemMatcher = const ReceiptItemMatcher();
    });

    test(
      'CA-3.2: Given read text "PAO FRANC 50G", links to matching product',
      () {
        final item = ReceiptItemDraft(
          rawDescription: 'PAO FRANC 50G',
          quantity: const Quantity(6000, Unit.un),
          unitPrice: const Money(80),
          totalPrice: const Money(480),
          confidence: 0.92,
        );

        final result = itemMatcher.matchItem(item, index);

        expect(result.match, isNotNull);
        expect(result.match!.product.id, 'prod-pao');
        expect(result.match!.product.canonicalName, 'Pão Francês');
        expect(result.match!.origin, isA<ExactUserAlias>());
        expect(result.rawDescription, 'PAO FRANC 50G');
      },
    );

    test('Match by Seed alias', () {
      final item = ReceiptItemDraft(
        rawDescription: 'Leite de Vaca 1L',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(450),
        totalPrice: const Money(450),
        confidence: 0.88,
      );

      final result = itemMatcher.matchItem(item, index);

      expect(result.match, isNotNull);
      expect(result.match!.product.id, 'prod-leite');
      expect(result.match!.origin, isA<ExactSeedAlias>());
    });

    test('Match by Fuzzy Match', () {
      final item = ReceiptItemDraft(
        rawDescription: 'Leite Intgral',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(450),
        totalPrice: const Money(450),
        confidence: 0.85,
      );

      final result = itemMatcher.matchItem(item, index);

      expect(result.match, isNotNull);
      expect(result.match!.product.id, 'prod-leite');
      expect(result.match!.origin, isA<Fuzzy>());
    });

    test('Returns null match when product is not found in index (NoMatch)', () {
      final item = ReceiptItemDraft(
        rawDescription: 'DETERGENTE NEUTRO 500ML',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(220),
        totalPrice: const Money(220),
        confidence: 0.95,
      );

      final result = itemMatcher.matchItem(item, index);

      expect(result.match, isNull);
    });

    test('Returns null match for empty description or whitespace only', () {
      final item = ReceiptItemDraft(
        rawDescription: '   ',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(100),
        totalPrice: const Money(100),
        confidence: 0.50,
      );

      final result = itemMatcher.matchItem(item, index);

      expect(result.match, isNull);
    });

    test('Preserves all ReceiptItemDraft attributes (quantity, prices, confidence, selection)', () {
      final item = ReceiptItemDraft(
        rawDescription: 'PAO FRANC 50G',
        ean: '7891234567890',
        quantity: const Quantity(500, Unit.g),
        unitPrice: const Money(1200),
        totalPrice: const Money(600),
        confidence: 0.45, // unselected because < 0.6
      );

      final result = itemMatcher.matchItem(item, index);

      expect(result.match, isNotNull);
      expect(result.ean, '7891234567890');
      expect(result.quantity, const Quantity(500, Unit.g));
      expect(result.unitPrice, const Money(1200));
      expect(result.totalPrice, const Money(600));
      expect(result.confidence, 0.45);
      expect(result.selected, isFalse);
    });

    test('matchReceipt: links multiple items of a ReceiptDraft', () {
      final item1 = ReceiptItemDraft(
        rawDescription: 'PAO FRANC 50G',
        quantity: const Quantity(6000, Unit.un),
        unitPrice: const Money(80),
        totalPrice: const Money(480),
        confidence: 0.95,
      );
      final item2 = ReceiptItemDraft(
        rawDescription: 'DETERGENTE YPE 500ML',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(250),
        totalPrice: const Money(250),
        confidence: 0.90,
      );

      final draft = ReceiptDraft(
        store: const StoreDraft(
          name: 'Supermercado Central',
          cnpj: '12345678000195',
          isCnpjValid: true,
        ),
        items: [item1, item2],
        subtotal: const Money(730),
        total: const Money(730),
        confidence: 0.92,
      );

      final matchedDraft = itemMatcher.matchReceipt(draft, index);

      expect(matchedDraft.store.name, 'Supermercado Central');
      expect(matchedDraft.items.length, 2);

      expect(matchedDraft.items[0].match, isNotNull);
      expect(matchedDraft.items[0].match!.product.id, 'prod-pao');

      expect(matchedDraft.items[1].match, isNull);
    });

    test('Accepts injection of custom ProductMatcher', () {
      final customMatcher = DefaultProductMatcher();
      final customItemMatcher = ReceiptItemMatcher(matcher: customMatcher);

      final item = ReceiptItemDraft(
        rawDescription: 'PAO FRANC 50G',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(100),
        totalPrice: const Money(100),
        confidence: 0.9,
      );

      final result = customItemMatcher.matchItem(item, index);
      expect(result.match, isNotNull);
    });

    test('ReceiptDraft equality considers items list', () {
      final item1 = ReceiptItemDraft(
        rawDescription: 'Item 1',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(100),
        totalPrice: const Money(100),
        confidence: 0.9,
      );
      final item2 = ReceiptItemDraft(
        rawDescription: 'Item 2',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(200),
        totalPrice: const Money(200),
        confidence: 0.9,
      );

      final draft1 = ReceiptDraft(
        store: const StoreDraft(name: 'Loja', cnpj: null, isCnpjValid: false),
        items: [item1],
        confidence: 0.9,
      );

      final draft2 = ReceiptDraft(
        store: const StoreDraft(name: 'Loja', cnpj: null, isCnpjValid: false),
        items: [item2],
        confidence: 0.9,
      );

      final draft1Copy = ReceiptDraft(
        store: const StoreDraft(name: 'Loja', cnpj: null, isCnpjValid: false),
        items: [item1],
        confidence: 0.9,
      );

      expect(draft1 == draft2, isFalse);
      expect(draft1 == draft1Copy, isTrue);
      expect(draft1.hashCode, equals(draft1Copy.hashCode));
    });

    test('Handles AmbiguousMatch returning highest score candidate', () {
      final mockMatcher = _FakeAmbiguousMatcher();
      final matcher = ReceiptItemMatcher(matcher: mockMatcher);

      final item = ReceiptItemDraft(
        rawDescription: 'Leite',
        quantity: const Quantity(1000, Unit.l),
        unitPrice: const Money(400),
        totalPrice: const Money(400),
        confidence: 0.9,
      );

      final result = matcher.matchItem(item, index);
      expect(result.match, isNotNull);
      expect(result.match!.product.id, 'prod-ambig-1');
    });

    test('Does not generate false positives for distinct items that share only 1 word or partial prefix (Receipt 4)', () {
      final now = DateTime(2026, 1, 1);
      final batata = Product(
        id: 'prod-batata',
        canonicalName: 'Batata Lavada',
        categoryId: 'cat-horti',
        defaultUnit: Unit.kg,
        createdAt: now,
        updatedAt: now,
      );
      final cerveja = Product(
        id: 'prod-cerveja',
        canonicalName: 'Cerveja Pilsen',
        categoryId: 'cat-beb',
        defaultUnit: Unit.un,
        createdAt: now,
        updatedAt: now,
      );
      final alho = Product(
        id: 'prod-alho',
        canonicalName: 'Alho',
        categoryId: 'cat-horti',
        defaultUnit: Unit.kg,
        createdAt: now,
        updatedAt: now,
      );

      final customIndex = ProductIndex(
        products: [productLeite, batata, cerveja, alho],
        aliases: [
          ProductAlias(
            id: 'a-leite',
            productId: 'prod-leite',
            alias: 'leite',
            normalizedAlias: 'leite',
            source: AliasSource.seed,
            createdAt: now,
          ),
          ProductAlias(
            id: 'a-batata',
            productId: 'prod-batata',
            alias: 'batata',
            normalizedAlias: 'batata',
            source: AliasSource.seed,
            createdAt: now,
          ),
          ProductAlias(
            id: 'a-cerveja',
            productId: 'prod-cerveja',
            alias: 'cerveja lata',
            normalizedAlias: 'cerveja lata',
            source: AliasSource.seed,
            createdAt: now,
          ),
          ProductAlias(
            id: 'a-alho',
            productId: 'prod-alho',
            alias: 'alho kg',
            normalizedAlias: 'alho',
            source: AliasSource.seed,
            createdAt: now,
          ),
        ],
        denials: const [],
      );

      final nonMatchingDescriptions = [
        'SOBREMESA BATAVO FLAN 200G CARAMELO',
        'CHOC BIS LACTA 100,8G AO LEITE',
        'ENERG MONSTER ENERGY 473ML ULTRA LATA',
        'ESFOLIANTE LABOTRAT DIA A DIA 150G MORANGO',
        'BATATA PALHA SCRUSH 80G ORIGINAL',
      ];

      for (final desc in nonMatchingDescriptions) {
        final item = ReceiptItemDraft(
          rawDescription: desc,
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(599),
          totalPrice: const Money(599),
          confidence: 0.9,
        );
        final matched = itemMatcher.matchItem(item, customIndex);
        expect(
          matched.match,
          isNull,
          reason: '"$desc" não deve associar falsamente a produto do catálogo',
        );
      }
    });
  });
}

class _FakeAmbiguousMatcher implements ProductMatcher {
  @override
  MatchResult match(
    String rawText,
    ProductIndex index, {
    double threshold = 0.85,
  }) {
    final p1 = Product(
      id: 'prod-ambig-1',
      canonicalName: 'Leite 1',
      categoryId: 'cat',
      defaultUnit: Unit.l,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final p2 = Product(
      id: 'prod-ambig-2',
      canonicalName: 'Leite 2',
      categoryId: 'cat',
      defaultUnit: Unit.l,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    return AmbiguousMatch(
      candidates: [
        ProductMatch(
          product: p1,
          origin: const Fuzzy(score: 0.90),
          score: 0.90,
        ),
        ProductMatch(
          product: p2,
          origin: const Fuzzy(score: 0.88),
          score: 0.88,
        ),
      ],
    );
  }
}
