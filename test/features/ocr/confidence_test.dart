import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/items_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';

void main() {
  group('Confidence per item (T-08 / RN-195, CA-3.1)', () {
    const parser = ItemsParser();

    group('ReceiptItemDraft - Confidence threshold rule', () {
      test('CA-3.1 - item with confidence 0.45 comes unselected (selected = false) and isLowConfidence = true', () {
        final item = ReceiptItemDraft(
          rawDescription: 'AÇÚCAR REFINADO 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(450),
          totalPrice: const Money(450),
          confidence: 0.45,
        );

        expect(item.confidence, equals(0.45));
        expect(
          item.selected,
          isFalse,
          reason: 'Confidence < 0.6 MUST be unselected by default (RN-195)',
        );
        expect(item.isLowConfidence, isTrue);
      });

      test('item at exact threshold 0.60 comes selected (selected = true) and isLowConfidence = false', () {
        final item = ReceiptItemDraft(
          rawDescription: 'FEIJÃO CARIOCA 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(790),
          totalPrice: const Money(790),
          confidence: 0.60,
        );

        expect(item.confidence, equals(0.60));
        expect(item.selected, isTrue);
        expect(item.isLowConfidence, isFalse);
      });

      test('item right below threshold (0.59) comes unselected (selected = false) and isLowConfidence = true', () {
        final item = ReceiptItemDraft(
          rawDescription: 'ÓLEO DE SOJA 900ML',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(650),
          totalPrice: const Money(650),
          confidence: 0.59,
        );

        expect(item.selected, isFalse);
        expect(item.isLowConfidence, isTrue);
      });

      test(
        'item with high confidence (0.95) comes selected (selected = true)',
        () {
          final item = ReceiptItemDraft(
            rawDescription: 'LEITE INTEGRAL 1L',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(520),
            totalPrice: const Money(520),
            confidence: 0.95,
          );

          expect(item.selected, isTrue);
          expect(item.isLowConfidence, isFalse);
        },
      );

      test('allows explicit manual override in constructor (selected: true for low confidence item)', () {
        final item = ReceiptItemDraft(
          rawDescription: 'SAL REFINADO 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(200),
          totalPrice: const Money(200),
          confidence: 0.40,
          selected: true,
        );

        expect(item.confidence, equals(0.40));
        expect(item.selected, isTrue);
        expect(item.isLowConfidence, isTrue);
      });

      test('allows explicit manual override in constructor (selected: false for high confidence item)', () {
        final item = ReceiptItemDraft(
          rawDescription: 'ARROZ 5KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(2500),
          totalPrice: const Money(2500),
          confidence: 0.95,
          selected: false,
        );

        expect(item.selected, isFalse);
        expect(item.isLowConfidence, isFalse);
      });

      test(
        'copyWith preserva ou atualiza a marcação selected e a confiança',
        () {
          final initial = ReceiptItemDraft(
            rawDescription: 'CAFÉ 500G',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(1500),
            totalPrice: const Money(1500),
            confidence: 0.45,
          );

          expect(initial.selected, isFalse);

          final updated = initial.copyWith(selected: true);
          expect(updated.selected, isTrue);
          expect(updated.confidence, equals(0.45));
          expect(updated.isLowConfidence, isTrue);
        },
      );

      test('JSON serialization without selected infers unselected when confidence < 0.6', () {
        final json = {
          'rawDescription': 'MACARRÃO 500G',
          'quantity': {'valueMilli': 1000, 'unit': 'un'},
          'unitPrice': 400,
          'totalPrice': 400,
          'confidence': 0.45,
        };

        final restored = ReceiptItemDraft.fromJson(json);
        expect(restored.confidence, equals(0.45));
        expect(restored.selected, isFalse);
        expect(restored.isLowConfidence, isTrue);
      });

      test('JSON serialization preserves selected = true even for confidence < 0.6 when explicit', () {
        final json = {
          'rawDescription': 'MACARRÃO 500G',
          'quantity': {'valueMilli': 1000, 'unit': 'un'},
          'unitPrice': 400,
          'totalPrice': 400,
          'confidence': 0.45,
          'selected': true,
        };

        final restored = ReceiptItemDraft.fromJson(json);
        expect(restored.confidence, equals(0.45));
        expect(restored.selected, isTrue);
        expect(restored.isLowConfidence, isTrue);
      });
    });

    group('ReceiptDraft - Low confidence metrics in receipt', () {
      test('evaluates lowConfidenceItems, hasLowConfidenceItems and lowConfidenceItemsCount correctly', () {
        final itemStrong = ReceiptItemDraft(
          rawDescription: 'ARROZ 5KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(2500),
          totalPrice: const Money(2500),
          confidence: 0.95,
        );
        final itemWeak1 = ReceiptItemDraft(
          rawDescription: 'FEIJÃO 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(800),
          totalPrice: const Money(800),
          confidence: 0.45,
        );
        final itemWeak2 = ReceiptItemDraft(
          rawDescription: 'ÓLEO 900ML',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(700),
          totalPrice: const Money(700),
          confidence: 0.55,
        );

        final receipt = ReceiptDraft(
          store: const StoreDraft(name: 'Mercado Fictício'),
          items: [itemStrong, itemWeak1, itemWeak2],
          total: const Money(4000),
          confidence: 0.65,
        );

        expect(receipt.hasLowConfidenceItems, isTrue);
        expect(receipt.lowConfidenceItemsCount, equals(2));
        expect(receipt.lowConfidenceItems, equals([itemWeak1, itemWeak2]));
      });

      test('itemsSum excludes unselected (low confidence) items from initial calculation', () {
        final itemStrong = ReceiptItemDraft(
          rawDescription: 'ARROZ 5KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(2500),
          totalPrice: const Money(2500),
          confidence: 0.95, // selected = true
        );
        final itemWeak = ReceiptItemDraft(
          rawDescription: 'SABÃO 1KG',
          quantity: const Quantity(1000, Unit.un),
          unitPrice: const Money(1500),
          totalPrice: const Money(1500),
          confidence: 0.45, // selected = false by default
        );

        final receipt = ReceiptDraft(
          store: const StoreDraft(name: 'Mercado Fictício'),
          items: [itemStrong, itemWeak],
          total: const Money(4000),
          confidence: 0.70,
        );

        expect(
          receipt.itemsSum,
          equals(const Money(2500)),
          reason: 'Unselected low confidence item should not be in items sum by default',
        );
      });
    });

    group('ItemsParser - Extraction with confidence variation in OcrDocument', () {
      test('OCR line with confidence 0.45 extracts item with selected = false (CA-3.1)', () {
        const line = OcrTextLine(
          text: '001 MANTEIGA 200G 1 UN X 12,90 12,90',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.45,
        );
        final doc = OcrDocument(lines: [line], imageWidth: 400);

        final items = parser.parseItems(doc);

        expect(items.length, equals(1));
        final item = items.first;
        expect(item.rawDescription, equals('MANTEIGA 200G'));
        expect(item.totalPrice, equals(const Money(1290)));
        expect(item.confidence, equals(0.45));
        expect(
          item.selected,
          isFalse,
          reason:
              'Confidence 0.45 (< 0.6) must be extracted with selected = false',
        );
        expect(item.isLowConfidence, isTrue);
      });

      test('extracts mix of items with high and low confidence and sets selected individually', () {
        const lineStrong = OcrTextLine(
          text: '001 REFRIGERANTE 2L 1 UN X 8,00 8,00',
          boundingBox: OcrBoundingBox(
            top: 100,
            left: 10,
            right: 380,
            bottom: 120,
          ),
          confidence: 0.92,
        );
        const lineWeak = OcrTextLine(
          text: '002 BISCOITO RECHEADO 1 UN X 3,50 3,50',
          boundingBox: OcrBoundingBox(
            top: 130,
            left: 10,
            right: 380,
            bottom: 150,
          ),
          confidence: 0.50,
        );

        final doc = OcrDocument(lines: [lineStrong, lineWeak], imageWidth: 400);

        final items = parser.parseItems(doc);

        expect(items.length, equals(2));
        expect(items[0].selected, isTrue);
        expect(items[0].isLowConfidence, isFalse);

        expect(items[1].selected, isFalse);
        expect(items[1].isLowConfidence, isTrue);
      });
    });
  });
}
