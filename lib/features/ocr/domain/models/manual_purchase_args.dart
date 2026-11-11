import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';

/// Arguments to navigate to manual purchase entry screen (/purchases/new)
/// after total or partial OCR failure (RF-047, RN-203, CA-7.1).
final class ManualPurchaseArgs {
  /// Attached receipt photo path (mandatory if provided).
  final String? attachedImagePath;

  /// Partial draft extracted before failure (if any).
  final ReceiptDraft? partialDraft;

  /// Friendly message for user (no technical jargon).
  final String userFriendlyMessage;

  /// Indica se ocorreu falha total do OCR.
  final bool isTotalFailure;

  /// Default navigation route for manual entry.
  static const String targetRoute = '/compras/nova';

  const ManualPurchaseArgs({
    this.attachedImagePath,
    this.partialDraft,
    required this.userFriendlyMessage,
    this.isTotalFailure = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualPurchaseArgs &&
          runtimeType == other.runtimeType &&
          attachedImagePath == other.attachedImagePath &&
          partialDraft == other.partialDraft &&
          userFriendlyMessage == other.userFriendlyMessage &&
          isTotalFailure == other.isTotalFailure;

  @override
  int get hashCode => Object.hash(
    attachedImagePath,
    partialDraft,
    userFriendlyMessage,
    isTotalFailure,
  );

  @override
  String toString() =>
      'ManualPurchaseArgs(attachedImagePath: $attachedImagePath, '
      'isTotalFailure: $isTotalFailure, message: "$userFriendlyMessage")';
}
