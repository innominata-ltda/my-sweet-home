import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/text_recognizer_port.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_container.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/ocr/data/ocr_data_providers.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';

class MockTextRecognizerPort implements TextRecognizerPort {
  final Result<OcrDocument, OcrFailure> result;

  MockTextRecognizerPort({required this.result});

  @override
  Future<Result<OcrDocument, OcrFailure>> recognize(Uint8List bytes) async {
    return result;
  }

  @override
  Future<Result<OcrDocument, OcrFailure>> recognizeFile(String filePath) async {
    return result;
  }

  @override
  Future<void> close() async {}
}

class MockSaveReceiptUseCase implements SaveReceiptUseCase {
  final Result<Purchase, Failure> result;

  MockSaveReceiptUseCase({required this.result});

  @override
  Future<Result<Purchase, Failure>> call(
    ReceiptDraft draft,
    SaveOptions options,
  ) async {
    return result;
  }
}

void main() {
  testWidgets('OcrReviewContainer shows loading and then screen', (
    tester,
  ) async {
    final mockDoc = OcrDocument(blocks: [], imageWidth: 100, imageHeight: 100);
    final mockPort = MockTextRecognizerPort(result: Ok(mockDoc));
    final mockSave = MockSaveReceiptUseCase(
      result: Ok(
        Purchase(
          id: '1',
          storeId: 's1',
          date: DateTime.now(),
          items: [],
          totalAmount: Money.zero,
          discountAmount: Money.zero,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          textRecognizerProvider.overrideWithValue(mockPort),
          saveReceiptUseCaseProvider.overrideWithValue(mockSave),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OcrReviewContainer(imagePath: 'dummy.jpg'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(OcrReviewScreen), findsOneWidget);
  });
}
