import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/date_time_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

void main() {
  const parser = DateTimeParser();

  group('DateTimeParser - date and time extraction (T-05 / RN-193 / CA-2.1)', () {
    group('dd/MM/yyyy date formats', () {
      test(
        'extracts dd/MM/yyyy HH:mm:ss date and time with EMISSAO keyword',
        () {
          final result = parser.parseText('EMISSAO 21/09/2026 14:30:15');
          expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
        },
      );

      test('extracts dd/MM/yyyy HH:mm:ss date and time with DATA:', () {
        final result = parser.parseText('DATA: 21/09/2026 14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('extracts dd/MM/yyyy HH:mm date and time without seconds', () {
        final result = parser.parseText('EMISSAO: 21/09/2026 14:30');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });

      test('extracts dd/MM/yyyy date only without time', () {
        final result = parser.parseText('EMISSAO 21/09/2026');
        expect(result, DateTime.utc(2026, 9, 21, 0, 0, 0));
      });

      test('extracts date with single digit in day or month (d/M/yyyy)', () {
        final result = parser.parseText('DATA EMISSAO: 5/9/2026 9:05:01');
        expect(result, DateTime.utc(2026, 9, 5, 9, 5, 1));
      });
    });

    group('dd/MM/yy date formats (2-digit year)', () {
      test('extracts dd/MM/yy HH:mm:ss', () {
        final result = parser.parseText('21/09/26 14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('extracts dd/MM/yy only', () {
        final result = parser.parseText('DT EMISSAO 21/09/26');
        expect(result, DateTime.utc(2026, 9, 21, 0, 0, 0));
      });
    });

    group('Dash formats (dd-MM-yyyy / yyyy-MM-dd)', () {
      test('extracts dd-MM-yyyy HH:mm:ss', () {
        final result = parser.parseText('EMISSAO: 21-09-2026 14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('extracts ISO format yyyy-MM-ddTHH:mm:ss', () {
        final result = parser.parseText('2026-09-21T14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('extracts ISO format yyyy-MM-dd HH:mm', () {
        final result = parser.parseText('2026-09-21 14:30');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });
    });

    group('Dot formats (dd.MM.yyyy)', () {
      test('extracts dd.MM.yyyy HH.mm.ss', () {
        final result = parser.parseText('EMISSAO 21.09.2026 14.30.15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Custom hour formats (h/hs/m/s)', () {
      test('extracts date with 14h30 time format', () {
        final result = parser.parseText('21/09/2026 às 14h30');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });

      test('extracts date with 14h30m15s time format', () {
        final result = parser.parseText('21/09/2026 14h30m15s');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Tolerance to OCR noise', () {
      test('extracts date with spaces between components (21 / 09 / 2026)', () {
        final result = parser.parseText('EMISSAO 21 / 09 / 2026 14 : 30 : 15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('replaces letter O with zero in numeric date context', () {
        final result = parser.parseText('EMISSAO 21/O9/2O26 14:3O:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('replaces letters I and l with 1 in numeric date context', () {
        final result = parser.parseText('EMISSAO 2I/09/2026 14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Full and abbreviated months in PT-BR', () {
      test('extracts date with abbreviated month 21/SET/2026', () {
        final result = parser.parseText('EMISSAO 21/SET/2026 14:30');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });

      test('extracts date with full month "21 DE SETEMBRO DE 2026"', () {
        final result = parser.parseText(
          'DATA COMPRA: 21 DE SETEMBRO DE 2026 14:30:15',
        );
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Hour formats with suffixes (hs, hrs, min)', () {
      test('extracts date with 14:30hs time', () {
        final result = parser.parseText('21/09/2026 14:30hs');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });

      test('extracts date with 14h30min time', () {
        final result = parser.parseText('21/09/2026 14h30min');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });
    });

    group('CNPJ filtering and document noise lines', () {
      test('ignores false positive dates derived from CNPJ', () {
        final doc = OcrDocument(
          lines: const [
            OcrTextLine(
              text: 'SUPERMERCADO BOM PRECO',
              boundingBox: OcrBoundingBox(
                top: 10,
                left: 10,
                right: 300,
                bottom: 30,
              ),
              confidence: 0.9,
            ),
            OcrTextLine(
              text: 'CNPJ: 12.345.151/0120-01',
              boundingBox: OcrBoundingBox(
                top: 40,
                left: 10,
                right: 300,
                bottom: 60,
              ),
              confidence: 0.9,
            ),
            OcrTextLine(
              text: '21/09/2026 14:30',
              boundingBox: OcrBoundingBox(
                top: 70,
                left: 10,
                right: 300,
                bottom: 90,
              ),
              confidence: 0.9,
            ),
          ],
        );
        final result = parser.parseDocument(doc);
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
      });

      test(
        'processes line with EMISSAO even if it contains generic validity term',
        () {
          final result = parser.parseText(
            'EMISSAO 21/09/2026 14:30:00 (VAL: 30 DIAS)',
          );
          expect(result, DateTime.utc(2026, 9, 21, 14, 30, 0));
        },
      );
    });

    group('Emission keywords and prioritization', () {
      test('prioritizes emission line over product expiration line', () {
        final doc = OcrDocument(
          lines: const [
            OcrTextLine(
              text: 'LEITE INTEGRAL 1L VAL: 25/12/2026',
              boundingBox: OcrBoundingBox(
                top: 100,
                left: 10,
                right: 300,
                bottom: 120,
              ),
              confidence: 0.9,
            ),
            OcrTextLine(
              text: 'EMISSAO: 21/09/2026 14:30:15',
              boundingBox: OcrBoundingBox(
                top: 200,
                left: 10,
                right: 300,
                bottom: 220,
              ),
              confidence: 0.9,
            ),
          ],
        );
        final result = parser.parseDocument(doc);
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });

      test('recognizes DATA DA COMPRA, DT EMISSAO, EMITIDO EM prefixes', () {
        expect(
          parser.parseText('DATA DA COMPRA: 21/09/2026 10:00:00'),
          DateTime.utc(2026, 9, 21, 10, 0, 0),
        );
        expect(
          parser.parseText('DT EMISSAO 21/09/2026 10:00:00'),
          DateTime.utc(2026, 9, 21, 10, 0, 0),
        );
        expect(
          parser.parseText('EMITIDO EM 21/09/2026'),
          DateTime.utc(2026, 9, 21, 0, 0, 0),
        );
      });
    });

    group('Date and time in separate lines', () {
      test('combines date from one line with time from the following line', () {
        final doc = OcrDocument(
          lines: const [
            OcrTextLine(
              text: 'DATA DE EMISSAO: 21/09/2026',
              boundingBox: OcrBoundingBox(
                top: 100,
                left: 10,
                right: 300,
                bottom: 120,
              ),
              confidence: 0.95,
            ),
            OcrTextLine(
              text: 'HORA DE EMISSAO: 14:30:15',
              boundingBox: OcrBoundingBox(
                top: 130,
                left: 10,
                right: 300,
                bottom: 150,
              ),
              confidence: 0.95,
            ),
          ],
        );
        final result = parser.parseDocument(doc);
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Parsing from OcrRow (ColumnDetector)', () {
      test('parseRows extracts date/time from grouped visual rows', () {
        const detector = ColumnDetector();
        final doc = OcrDocument(
          lines: const [
            OcrTextLine(
              text: 'EMISSAO: 21/09/2026 14:30:15',
              boundingBox: OcrBoundingBox(
                top: 50,
                left: 10,
                right: 400,
                bottom: 70,
              ),
              confidence: 0.98,
            ),
          ],
        );
        final rows = detector.detectRows(doc);
        final result = parser.parseRows(rows);
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });

    group('Safety validations and invalid dates', () {
      test('returns null for invalid day (31/02/2026)', () {
        final result = parser.parseText('EMISSAO 31/02/2026 14:30:00');
        expect(result, isNull);
      });

      test('returns null for invalid month (15/13/2026)', () {
        final result = parser.parseText('EMISSAO 15/13/2026 14:30:00');
        expect(result, isNull);
      });

      test('returns null for empty document or text without date', () {
        expect(parser.parseDocument(OcrDocument()), isNull);
        expect(parser.parseText('CARREFOUR COMERCIO E INDUSTRIA LTDA'), isNull);
        expect(parser.parseText(''), isNull);
      });
    });

    group('DatetimeParser alias', () {
      test('DatetimeParser alias works exactly like DateTimeParser', () {
        const DatetimeParser aliasParser = DatetimeParser();
        final result = aliasParser.parseText('21/09/2026 14:30:15');
        expect(result, DateTime.utc(2026, 9, 21, 14, 30, 15));
      });
    });
  });
}
