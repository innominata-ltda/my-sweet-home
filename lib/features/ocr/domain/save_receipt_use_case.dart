import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';

/// Save options for receipt read via OCR.
final class SaveOptions {
  /// Associated store (if already resolved in catalog/review).
  final String? storeId;

  /// Data da compra (sobrescreve data da nota se informada).
  final DateTime? purchasedAt;

  /// Valor total da compra (sobrescreve valor total da nota se informado).
  final Money? totalOverride;

  /// Desconto total da compra (sobrescreve desconto da nota se informado).
  final Money? discountOverride;

  /// Category of generated expense (default: 'cat_market').
  final CategoryId? categoryId;

  /// If true, generates corresponding expense in wallet/budget (RN-200).
  final bool createExpense;

  /// ID opcional da compra gerada (para testes/determinismo).
  final String? purchaseId;

  /// ID opcional da despesa gerada (para testes/determinismo).
  final String? expenseId;

  /// ID opcional da lista de compras para dar baixa nos itens correspondentes (RN-201, RN-087).
  final String? writeOffShoppingListId;

  const SaveOptions({
    this.storeId,
    this.purchasedAt,
    this.totalOverride,
    this.discountOverride,
    this.categoryId,
    this.createExpense = true,
    this.purchaseId,
    this.expenseId,
    this.writeOffShoppingListId,
  });
}

/// Use case to save receipt in a transactional way.
///
/// Saves in a SINGLE database transaction:
/// 1. A compra (`Purchases`)
/// 2. Os itens selecionados (`PurchaseItems`)
/// 3. Price points for linked products (`PricePoints`)
/// 4. A despesa associada (`Expenses`)
abstract interface class SaveReceiptUseCase {
  Future<Result<Purchase, Failure>> call(
    ReceiptDraft draft,
    SaveOptions options,
  );
}
