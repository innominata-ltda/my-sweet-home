import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/regionalization/regionalization_models.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_format_registry.dart';
import 'package:my_sweet_home/features/ocr/domain/receipt_parser.dart';
import 'package:my_sweet_home/features/ocr/presentation/providers/ocr_providers.dart';

import '../../fakes/fake_settings_repository.dart';

final class _StubReceiptParser implements ReceiptParser {
  final ReceiptDraft draft;
  _StubReceiptParser(this.draft);

  @override
  ReceiptDraft parse(OcrDocument doc) => draft;
}

void main() {
  final sampleDoc = OcrDocument(
    lines: const [
      OcrTextLine(
        text: 'SUPERMARKET',
        confidence: 0.9,
        boundingBox: OcrBoundingBox(top: 0, left: 0, right: 100, bottom: 10),
      ),
    ],
  );

  group('ReceiptFormatRegistry & CompositeReceiptParser', () {
    test('single-parser fast path delegates directly without overhead', () {
      final expected = ReceiptDraft(
        store: const StoreDraft(name: 'Store A', confidence: 0.8),
        items: const [],
        confidence: 0.8,
      );
      final composite = CompositeReceiptParser([_StubReceiptParser(expected)]);

      expect(composite.parse(sampleDoc), same(expected));
    });

    test('auto mode selects highest-scoring ReceiptDraft across parsers', () {
      final weakDraft = ReceiptDraft(
        store: const StoreDraft(name: 'Weak', confidence: 0.4),
        items: const [],
        confidence: 0.4,
      );
      final strongDraft = ReceiptDraft(
        store: const StoreDraft(name: 'Strong Store', confidence: 0.9),
        total: const Money(1500),
        items: [
          ReceiptItemDraft(
            rawDescription: 'MILK',
            quantity: const Quantity(1000, Unit.un),
            unitPrice: const Money(1500),
            totalPrice: const Money(1500),
            confidence: 0.95,
          ),
        ],
        confidence: 0.95,
      );
      final registry = ReceiptFormatRegistry(
        parsers: {
          'fmt_weak': _StubReceiptParser(weakDraft),
          'fmt_strong': _StubReceiptParser(strongDraft),
        },
      );

      final resolved = registry.resolve(ReceiptFormatCatalog.autoFormatId);
      expect(resolved.parse(sampleDoc), same(strongDraft));
    });

    test(
      'explicit format ID returns exact parser and unknown falls back to auto',
      () {
        final draftA = ReceiptDraft(
          store: const StoreDraft(name: 'Format A', confidence: 0.5),
          items: const [],
          confidence: 0.5,
        );
        final draftB = ReceiptDraft(
          store: const StoreDraft(name: 'Format B', confidence: 0.9),
          total: const Money(500),
          items: const [],
          confidence: 0.9,
        );
        final registry = ReceiptFormatRegistry(
          parsers: {
            'fmt_a': _StubReceiptParser(draftA),
            'fmt_b': _StubReceiptParser(draftB),
          },
        );

        expect(registry.resolve('fmt_a').parse(sampleDoc), same(draftA));
        expect(registry.resolve('unknown_id').parse(sampleDoc), same(draftB));
      },
    );

    test(
      'receiptParserProvider reacts to receiptFormatProvider changes',
      () async {
        final fakeRepo = FakeSettingsRepository(receiptFormat: 'fmt_a');
        final draftA = ReceiptDraft(
          store: const StoreDraft(name: 'Format A'),
          items: const [],
          confidence: 0.5,
        );
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            receiptFormatRegistryProvider.overrideWithValue(
              ReceiptFormatRegistry(
                parsers: {'fmt_a': _StubReceiptParser(draftA)},
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(receiptFormatProvider.notifier).setFormat('fmt_a');
        final parser = container.read(receiptParserProvider);
        expect(parser.parse(sampleDoc), same(draftA));
      },
    );
  });
}
