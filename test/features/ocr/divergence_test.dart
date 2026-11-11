import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';

void main() {
  group('ReceiptDraft - Divergence between items sum and total (T-09 / RN-196 / CA-4.1)', () {
    const store = StoreDraft(
      name: 'Mercado Exemplo',
      cnpj: '12.345.678/0001-95',
      isCnpjValid: true,
    );

    test('CA-4.1 - Items sum of R\$ 84,40 and scanned total R\$ 87,40 computes R\$ 3,00 divergence', () {
      final items = [
        ReceiptItemDraft(
          rawDescription: 'ARROZ 5KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(3440),
          totalPrice: const Money(3440),
          confidence: 0.95,
          selected: true,
        ),
        ReceiptItemDraft(
          rawDescription: 'FEIJAO 1KG',
          quantity: const Quantity(5000, Unit.un),
          unitPrice: const Money(1000),
          totalPrice: const Money(5000),
          confidence: 0.95,
          selected: true,
        ),
      ];

      final draft = ReceiptDraft(
        store: store,
        items: items,
        total: const Money(8740),
        confidence: 0.95,
      );

      expect(draft.itemsSum, equals(const Money(8440)));
      expect(draft.total, equals(const Money(8740)));
      expect(draft.divergence, equals(const Money(-300)));
      expect(draft.absoluteDivergence, equals(const Money(300)));
      expect(draft.hasDivergence, isTrue);
      expect(draft.isDivergent(), isTrue);
    });

    test('no divergence when items sum matches total', () {
      final items = [
        ReceiptItemDraft(
          rawDescription: 'LEITE 1L',
          quantity: const Quantity(2000, Unit.un),
          unitPrice: const Money(500),
          totalPrice: const Money(1000),
          confidence: 0.99,
          selected: true,
        ),
      ];

      final draft = ReceiptDraft(
        store: store,
        items: items,
        total: const Money(1000),
        confidence: 0.99,
      );

      expect(draft.itemsSum, equals(const Money(1000)));
      expect(draft.divergence, equals(const Money(0)));
      expect(draft.absoluteDivergence, equals(const Money(0)));
      expect(draft.hasDivergence, isFalse);
      expect(draft.isDivergent(), isFalse);
    });

    test('calculates divergence considering discount (itemsSum - discount - total)', () {
      final items = [
        ReceiptItemDraft(
          rawDescription: 'PRODUTO A',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(9040),
          totalPrice: const Money(9040),
          confidence: 0.90,
          selected: true,
        ),
      ];

      final draft = ReceiptDraft(
        store: store,
        items: items,
        subtotal: const Money(9040),
        discount: const Money(300),
        total: const Money(8740),
        confidence: 0.90,
      );

      // 9040 - 300 - 8740 = 0
      expect(draft.itemsSum, equals(const Money(9040)));
      expect(draft.divergence, equals(const Money(0)));
      expect(draft.hasDivergence, isFalse);
      expect(draft.isDivergent(), isFalse);
    });

    test('unselecting items (selected = false) recalculates itemsSum and divergence (RN-195)', () {
      final item1 = ReceiptItemDraft(
        rawDescription: 'ITEM 1',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(5000),
        totalPrice: const Money(5000),
        confidence: 0.90,
        selected: true,
      );
      final item2 = ReceiptItemDraft(
        rawDescription: 'ITEM 2 DUDOSO',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(2000),
        totalPrice: const Money(2000),
        confidence: 0.40, // < 0.6 unselected by default
        selected: false,
      );

      final draft = ReceiptDraft(
        store: store,
        items: [item1, item2],
        total: const Money(5000),
        confidence: 0.80,
      );

      // Only item1 (selected = true) is included in itemsSum
      expect(draft.itemsSum, equals(const Money(5000)));
      expect(draft.divergence, equals(const Money(0)));
      expect(draft.isDivergent(), isFalse);

      // If item2 is selected by the user
      final draftComItem2 = ReceiptDraft(
        store: store,
        items: [item1, item2.copyWith(selected: true)],
        total: const Money(5000),
        confidence: 0.80,
      );

      expect(draftComItem2.itemsSum, equals(const Money(7000)));
      expect(draftComItem2.divergence, equals(const Money(2000)));
      expect(draftComItem2.absoluteDivergence, equals(const Money(2000)));
      expect(draftComItem2.hasDivergence, isTrue);
      expect(draftComItem2.isDivergent(), isTrue);
    });

    test('respects 1 cent tolerance threshold per item (RN-196)', () {
      // 10 items with accumulated rounding of 5 cents in total
      final items = List.generate(
        10,
        (i) => ReceiptItemDraft(
          rawDescription: 'ITEM $i',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(1000),
          totalPrice: const Money(1000),
          confidence: 0.90,
          selected: true,
        ),
      );

      // itemsSum = 10000 (R$ 100,00), scanned total = 9995 (R$ 99,95), div = 5 cents
      final draftTolerado = ReceiptDraft(
        store: store,
        items: items,
        total: const Money(9995),
        confidence: 0.90,
      );

      expect(draftTolerado.divergence, equals(const Money(5)));
      expect(draftTolerado.absoluteDivergence, equals(const Money(5)));
      expect(draftTolerado.hasDivergence, isTrue);
      // 5 cents <= 10 cents (10 items * 1 cent/item) -> not considered divergent by RN-196
      expect(draftTolerado.isDivergent(maxCentsPerItem: 1), isFalse);

      // Case with 15 cents divergence (outside 10 cents tolerance)
      final draftForaDaTolerancia = ReceiptDraft(
        store: store,
        items: items,
        total: const Money(9985),
        confidence: 0.90,
      );

      expect(draftForaDaTolerancia.divergence, equals(const Money(15)));
      expect(draftForaDaTolerancia.isDivergent(maxCentsPerItem: 1), isTrue);
    });

    test(
      'returns null divergence and isDivergent false when total is null',
      () {
        final items = [
          ReceiptItemDraft(
            rawDescription: 'ITEM',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(1000),
            totalPrice: const Money(1000),
            confidence: 0.90,
            selected: true,
          ),
        ];

        final draftWithoutTotal = ReceiptDraft(
          store: store,
          items: items,
          total: null,
          confidence: 0.90,
        );

        expect(draftWithoutTotal.divergence, isNull);
        expect(draftWithoutTotal.absoluteDivergence, isNull);
        expect(draftWithoutTotal.hasDivergence, isFalse);
        expect(draftWithoutTotal.isDivergent(), isFalse);
      },
    );

    test('empty items list with total present is considered divergent', () {
      final draftEmptyItems = ReceiptDraft(
        store: store,
        items: const [],
        total: const Money(5000),
        confidence: 0.50,
      );

      expect(draftEmptyItems.itemsSum, equals(const Money(0)));
      expect(draftEmptyItems.divergence, equals(const Money(-5000)));
      expect(draftEmptyItems.absoluteDivergence, equals(const Money(5000)));
      expect(draftEmptyItems.hasDivergence, isTrue);
      expect(draftEmptyItems.isDivergent(), isTrue);
    });
  });
}
