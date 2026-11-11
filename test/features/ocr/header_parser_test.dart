import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/header_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/store_draft.dart';

void main() {
  group('HeaderParser (T-04 / RF-041 / RN-193 / RN-194 / CA-2.1)', () {
    const parser = HeaderParser();

    group('validateCnpjDigits (RN-194)', () {
      test('returns true for valid formatted or clean CNPJ', () {
        // CNPJs with valid check digits (11.222.333/0001-81 and 45.543.915/0001-81)
        expect(HeaderParser.validateCnpjDigits('11222333000181'), isTrue);
        expect(HeaderParser.validateCnpjDigits('45543915000181'), isTrue);
      });

      test('returns false for CNPJ with incorrect check digits', () {
        expect(HeaderParser.validateCnpjDigits('11222333000180'), isFalse);
        expect(HeaderParser.validateCnpjDigits('45543915000199'), isFalse);
      });

      test('returns false for CNPJ with all digits identical', () {
        expect(HeaderParser.validateCnpjDigits('00000000000000'), isFalse);
        expect(HeaderParser.validateCnpjDigits('11111111111111'), isFalse);
        expect(HeaderParser.validateCnpjDigits('99999999999999'), isFalse);
      });

      test('returns false for strings of length other than 14', () {
        expect(HeaderParser.validateCnpjDigits('12345'), isFalse);
        expect(HeaderParser.validateCnpjDigits('123456789012345'), isFalse);
      });
    });

    group('parse - empty document (edge cases)', () {
      test('document without lines returns empty StoreDraft', () {
        final doc = OcrDocument(blocks: const []);
        final draft = parser.parse(doc);

        expect(draft.name, isNull);
        expect(draft.cnpj, isNull);
        expect(draft.isCnpjValid, isFalse);
        expect(draft.rawCnpj, isNull);
        expect(draft.address, isNull);
        expect(draft.confidence, 0.0);
      });
    });

    group('parse - CNPJ and store extraction', () {
      test('extracts store name and valid CNPJ (RN-193, RN-194, CA-2.1)', () {
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'CARREFOUR COMERCIO E INDUSTRIA LTDA',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 400,
                bottom: 30,
              ),
              confidence: 0.95,
            ),
            const OcrTextLine(
              text: 'RUA ORLANDO SILVA, 100 - SAO PAULO - SP',
              boundingBox: OcrBoundingBox(
                top: 35,
                left: 10,
                right: 380,
                bottom: 50,
              ),
              confidence: 0.90,
            ),
            const OcrTextLine(
              text: 'CNPJ: 45.543.915/0001-81',
              boundingBox: OcrBoundingBox(
                top: 55,
                left: 10,
                right: 250,
                bottom: 70,
              ),
              confidence: 0.98,
            ),
            const OcrTextLine(
              text: 'IE: 123.456.789.111',
              boundingBox: OcrBoundingBox(
                top: 75,
                left: 10,
                right: 200,
                bottom: 90,
              ),
              confidence: 0.92,
            ),
          ],
        );

        final draft = parser.parse(doc);

        expect(draft.name, equals('CARREFOUR COMERCIO E INDUSTRIA LTDA'));
        expect(draft.cnpj, equals('45543915000181'));
        expect(draft.isCnpjValid, isTrue);
        expect(draft.rawCnpj, equals('45.543.915/0001-81'));
        expect(draft.address, contains('RUA ORLANDO SILVA'));
        expect(draft.confidence, greaterThan(0.9));
      });

      test('CNPJ with invalid checksum becomes "unconfirmed" (RN-194)', () {
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'SUPERMERCADO SILVA LTDA',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 300,
                bottom: 30,
              ),
              confidence: 0.90,
            ),
            const OcrTextLine(
              text: 'CNPJ: 45.543.915/0001-99', // wrong check digit
              boundingBox: OcrBoundingBox(
                top: 35,
                left: 10,
                right: 250,
                bottom: 50,
              ),
              confidence: 0.85,
            ),
          ],
        );

        final draft = parser.parse(doc);

        expect(draft.name, equals('SUPERMERCADO SILVA LTDA'));
        expect(draft.cnpj, equals('45543915000199'));
        expect(draft.isCnpjValid, isFalse); // RN-194: marked as unconfirmed
        expect(draft.rawCnpj, equals('45.543.915/0001-99'));
      });

      test('ignores tax header noise (DANFE, NFC-e, VIA CONSUMIDOR)', () {
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'DANFE NFC-e - DOCUMENTO AUXILIAR',
              boundingBox: OcrBoundingBox(
                top: 5,
                left: 10,
                right: 350,
                bottom: 20,
              ),
              confidence: 0.99,
            ),
            const OcrTextLine(
              text: 'VIA CONSUMIDOR',
              boundingBox: OcrBoundingBox(
                top: 22,
                left: 10,
                right: 150,
                bottom: 35,
              ),
              confidence: 0.99,
            ),
            const OcrTextLine(
              text: 'ATACADAO S.A.',
              boundingBox: OcrBoundingBox(
                top: 40,
                left: 10,
                right: 200,
                bottom: 55,
              ),
              confidence: 0.95,
            ),
            const OcrTextLine(
              text: 'CNPJ 45543915000181',
              boundingBox: OcrBoundingBox(
                top: 60,
                left: 10,
                right: 220,
                bottom: 75,
              ),
              confidence: 0.96,
            ),
          ],
        );

        final draft = parser.parse(doc);

        expect(draft.name, equals('ATACADAO S.A.'));
        expect(draft.isCnpjValid, isTrue);
        expect(draft.cnpj, equals('45543915000181'));
      });

      test('works with StoreHeaderParser alias', () {
        const storeParser = StoreHeaderParser();
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'PADARIA REAL LTDA',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 200,
                bottom: 30,
              ),
              confidence: 0.90,
            ),
            const OcrTextLine(
              text: 'CNPJ: 45.543.915/0001-81',
              boundingBox: OcrBoundingBox(
                top: 35,
                left: 10,
                right: 250,
                bottom: 50,
              ),
              confidence: 0.95,
            ),
          ],
        );

        final draft = storeParser.parse(doc);
        expect(draft.name, equals('PADARIA REAL LTDA'));
        expect(draft.isCnpjValid, isTrue);
      });

      test('ignores greeting lines (SEJA BEM-VINDO) and selects establishment name', () {
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'SEJA BEM-VINDO',
              boundingBox: OcrBoundingBox(
                top: 5,
                left: 10,
                right: 200,
                bottom: 20,
              ),
              confidence: 0.99,
            ),
            const OcrTextLine(
              text: 'NOME FANTASIA: BARCELONA',
              boundingBox: OcrBoundingBox(
                top: 25,
                left: 10,
                right: 250,
                bottom: 40,
              ),
              confidence: 0.95,
            ),
            const OcrTextLine(
              text: 'CNPJ: 45.543.915/0001-81',
              boundingBox: OcrBoundingBox(
                top: 45,
                left: 10,
                right: 220,
                bottom: 60,
              ),
              confidence: 0.95,
            ),
          ],
        );

        final draft = parser.parse(doc);
        expect(draft.name, equals('BARCELONA'));
        expect(draft.cnpj, equals('45543915000181'));
        expect(draft.isCnpjValid, isTrue);
      });

      test('removes CNPJ concatenated to store name on the same line', () {
        final doc = OcrDocument(
          lines: [
            const OcrTextLine(
              text: 'MERCEARIA ALFA CNPJ: 45.543.915/0001-81',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 400,
                bottom: 30,
              ),
              confidence: 0.95,
            ),
          ],
        );

        final draft = parser.parse(doc);
        expect(draft.name, equals('MERCEARIA ALFA'));
        expect(draft.cnpj, equals('45543915000181'));
        expect(draft.isCnpjValid, isTrue);
      });
    });

    group('StoreDraft - serialization, equality and toString', () {
      test('round-trip toJson / fromJson', () {
        const original = StoreDraft(
          name: 'MERCADO MODELO',
          cnpj: '45543915000181',
          isCnpjValid: true,
          rawCnpj: '45.543.915/0001-81',
          address: 'RUA A, 10',
          confidence: 0.92,
        );

        final json = original.toJson();
        final restored = StoreDraft.fromJson(json);

        expect(restored, equals(original));
        expect(restored.hashCode, equals(original.hashCode));
      });

      test('toString formats information properly', () {
        const draft = StoreDraft(
          name: 'TESTE',
          cnpj: '123',
          isCnpjValid: false,
          confidence: 0.8,
        );
        expect(draft.toString(), contains('StoreDraft'));
        expect(draft.toString(), contains('TESTE'));
      });
    });
  });
}
