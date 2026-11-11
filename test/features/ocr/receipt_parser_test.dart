import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';

void main() {
  group('DefaultReceiptParser (T-11)', () {
    const parser = DefaultReceiptParser();

    test('returns ReceiptDraft with null values for empty OcrDocument', () {
      final doc = OcrDocument();
      final draft = parser.parse(doc);

      expect(draft.store.name, isNull);
      expect(draft.store.cnpj, isNull);
      expect(draft.purchasedAt, isNull);
      expect(draft.items, isEmpty);
      expect(draft.subtotal, isNull);
      expect(draft.discount, isNull);
      expect(draft.total, isNull);
      expect(draft.confidence, equals(0.0));
    });

    test(
      'integrates sub-parsers to extract complete receipt draft from document',
      () {
        final doc = OcrDocument(
          lines: [
            OcrTextLine(
              text: 'CARREFOUR COMERCIO E INDUSTRIA LTDA',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 380,
                bottom: 30,
              ),
              confidence: 0.98,
            ),
            OcrTextLine(
              text: 'CNPJ: 45.543.915/0001-81',
              boundingBox: OcrBoundingBox(
                top: 35,
                left: 10,
                right: 250,
                bottom: 50,
              ),
              confidence: 0.99,
            ),
            OcrTextLine(
              text: 'DATA: 21/09/2026 14:30:00',
              boundingBox: OcrBoundingBox(
                top: 55,
                left: 10,
                right: 250,
                bottom: 70,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'CÓDIGO DESCRIÇÃO QTD VL UN VL TOTAL',
              boundingBox: OcrBoundingBox(
                top: 80,
                left: 10,
                right: 380,
                bottom: 95,
              ),
              confidence: 0.96,
            ),
            OcrTextLine(
              text: '001 ARROZ BRANCO 5KG 1 UN X 25,90 25,90',
              boundingBox: OcrBoundingBox(
                top: 100,
                left: 10,
                right: 380,
                bottom: 120,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'SUBTOTAL R\$ 25,90',
              boundingBox: OcrBoundingBox(
                top: 150,
                left: 10,
                right: 380,
                bottom: 170,
              ),
              confidence: 0.96,
            ),
            OcrTextLine(
              text: 'TOTAL R\$ 25,90',
              boundingBox: OcrBoundingBox(
                top: 180,
                left: 10,
                right: 380,
                bottom: 200,
              ),
              confidence: 0.98,
            ),
            OcrTextLine(
              text: 'CARTAO DE DEBITO',
              boundingBox: OcrBoundingBox(
                top: 210,
                left: 10,
                right: 250,
                bottom: 230,
              ),
              confidence: 0.94,
            ),
          ],
          imageWidth: 400,
          imageHeight: 600,
        );

        final draft = parser.parse(doc);

        expect(draft.store.name, equals('CARREFOUR COMERCIO E INDUSTRIA LTDA'));
        expect(draft.store.cnpj, equals('45543915000181'));
        expect(draft.store.isCnpjValid, isTrue);
        expect(draft.purchasedAt, equals(DateTime.utc(2026, 9, 21, 14, 30)));
        expect(draft.items.length, equals(1));
        expect(draft.items.first.rawDescription, equals('ARROZ BRANCO 5KG'));
        expect(draft.items.first.totalPrice, equals(const Money(2590)));
        expect(draft.subtotal, equals(const Money(2590)));
        expect(draft.total, equals(const Money(2590)));
        expect(draft.paymentMethod, equals('CARTÃO DE DÉBITO'));
        expect(draft.confidence, greaterThan(0.9));
      },
    );
  });
}
