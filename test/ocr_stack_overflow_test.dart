import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';

void main() {
  test('OcrDocument low quality huge lines', () {
    final parser = const DefaultReceiptParser();
    final lines = List.generate(
      5000,
      (i) => OcrTextLine(
        text: 'noise $i',
        boundingBox: OcrBoundingBox(
          top: i.toDouble(),
          left: 0,
          right: 10,
          bottom: i.toDouble() + 10,
        ),
        confidence: 0.1,
      ),
    );
    final doc = OcrDocument(lines: lines);
    parser.parse(doc);
  });
}
