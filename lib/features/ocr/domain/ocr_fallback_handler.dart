import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/ocr/domain/models/manual_purchase_args.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';

/// Avaliador e manipulador de falhas no fluxo de OCR (RF-047, RN-203, CA-7.1).
///
/// When OCR completely fails (empty document or processing error),
/// this component prepares arguments to open manual entry
/// with attached photo without displaying technical error messages to user.
final class OcrFallbackHandler {
  const OcrFallbackHandler();

  /// Default friendly message displayed on total OCR failure (CA-7.1).
  static const String defaultUserMessage =
      'Não foi possível ler os dados da nota fiscal. '
      'Você pode fazer o lançamento manualmente com a foto anexada.';

  /// Evaluates an [OcrDocument] and determines if total failure.
  ///
  /// A document is considered total failure if it has no lines
  /// reconhecida ([doc.lines.isEmpty]) ou tiver [averageConfidence] igual a 0.0.
  ManualPurchaseArgs evaluateDocument(
    OcrDocument doc, {
    String? imagePath,
    ReceiptDraft? partialDraft,
  }) {
    final isTotal = doc.lines.isEmpty || doc.averageConfidence == 0.0;

    return ManualPurchaseArgs(
      attachedImagePath: imagePath,
      partialDraft: partialDraft,
      userFriendlyMessage: defaultUserMessage,
      isTotalFailure: isTotal,
    );
  }

  /// Avalia o resultado de um [Result<OcrDocument, OcrFailure>].
  ///
  /// If result is [Err], considered total failure, returning
  /// [ManualPurchaseArgs] with friendly message (without exposing technical message).
  ManualPurchaseArgs evaluateResult(
    Result<OcrDocument, OcrFailure> result, {
    String? imagePath,
    ReceiptDraft? partialDraft,
  }) {
    return result.fold(
      (doc) => evaluateDocument(
        doc,
        imagePath: imagePath,
        partialDraft: partialDraft,
      ),
      (failure) => ManualPurchaseArgs(
        attachedImagePath: imagePath,
        partialDraft: partialDraft,
        userFriendlyMessage: defaultUserMessage,
      ),
    );
  }

  /// Avalia um [ReceiptDraft] para determinar se o parsing resultou em falha total.
  ManualPurchaseArgs evaluateDraft(ReceiptDraft? draft, {String? imagePath}) {
    if (draft == null) {
      return ManualPurchaseArgs(
        attachedImagePath: imagePath,
        userFriendlyMessage: defaultUserMessage,
      );
    }

    final isTotal =
        draft.items.isEmpty &&
        (draft.confidence < 0.3 ||
            ((draft.store.name == null || draft.store.name!.isEmpty) &&
                draft.total == null));

    return ManualPurchaseArgs(
      attachedImagePath: imagePath,
      partialDraft: draft,
      userFriendlyMessage: defaultUserMessage,
      isTotalFailure: isTotal,
    );
  }
}
