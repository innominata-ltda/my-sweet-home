import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/ocr/domain/header_parser.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_point.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';

/// SQLite/Drift implementation for [SaveReceiptUseCase] (RN-200, RF-046, RN-201, CA-5.1, CA-5.2).
///
/// Saves in a SINGLE atomic db transaction: purchase, items, price points, expense and list write-off.
class SqliteSaveReceiptUseCase implements SaveReceiptUseCase {
  final db.AppDatabase _db;
  final Clock _clock;
  final IdGenerator _idGenerator;

  SqliteSaveReceiptUseCase(
    this._db, {
    this._clock = const SystemClock(),
    this._idGenerator = const UuidV7Generator(),
  });

  @override
  Future<Result<Purchase, Failure>> call(
    ReceiptDraft draft,
    SaveOptions options,
  ) async {
    final selectedItems = draft.items.where((i) => i.selected).toList();
    if (selectedItems.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'items': 'Nenhum item selecionado para salvar a compra.'},
        ),
      );
    }

    try {
      late final Purchase createdPurchase;

      await _db.transaction(() async {
        final nowIso = _clock.nowUtc().toIso8601String();
        final purchaseDate =
            (options.purchasedAt ?? draft.purchasedAt ?? _clock.nowUtc())
                .toUtc();

        // 1. Resolver ou criar o Estabelecimento (Store)
        late final String storeId;
        final rawCnpjStr = draft.store.cnpj ?? draft.store.rawCnpj;
        final cleanCnpj = rawCnpjStr?.replaceAll(RegExp(r'[^0-9]'), '');
        final isCnpjValid =
            draft.store.isCnpjValid ||
            (cleanCnpj != null &&
                cleanCnpj.length == 14 &&
                HeaderParser.validateCnpjDigits(cleanCnpj));
        final cnpjToSave =
            (isCnpjValid && cleanCnpj != null && cleanCnpj.length == 14)
            ? cleanCnpj
            : null;

        if (options.storeId != null && options.storeId!.isNotEmpty) {
          storeId = options.storeId!;
          final existing = await (_db.select(
            _db.stores,
          )..where((s) => s.id.equals(storeId))).getSingleOrNull();
          if (existing == null) {
            final storeName = (draft.store.name?.trim().isNotEmpty ?? false)
                ? draft.store.name!.trim()
                : 'Estabelecimento';
            await _db
                .into(_db.stores)
                .insert(
                  db.StoresCompanion.insert(
                    id: storeId,
                    name: storeName,
                    cnpj: Value(cnpjToSave),
                    createdAt: Value(nowIso),
                    updatedAt: Value(nowIso),
                  ),
                );
          }
        } else {
          db.Store? existingStore;

          if (cnpjToSave != null) {
            existingStore = await (_db.select(
              _db.stores,
            )..where((s) => s.cnpj.equals(cnpjToSave))).getSingleOrNull();
          }

          if (existingStore == null &&
              draft.store.name != null &&
              draft.store.name!.trim().isNotEmpty) {
            existingStore =
                await (_db.select(_db.stores)
                      ..where((s) => s.name.equals(draft.store.name!.trim())))
                    .getSingleOrNull();
          }

          if (existingStore != null) {
            storeId = existingStore.id;
          } else {
            storeId = _idGenerator.newId();
            final storeName = (draft.store.name?.trim().isNotEmpty ?? false)
                ? draft.store.name!.trim()
                : 'Estabelecimento';
            await _db
                .into(_db.stores)
                .insert(
                  db.StoresCompanion.insert(
                    id: storeId,
                    name: storeName,
                    cnpj: Value(cnpjToSave),
                    createdAt: Value(nowIso),
                    updatedAt: Value(nowIso),
                  ),
                );
          }
        }

        // 2. Definir totais e IDs
        final totalAmount =
            options.totalOverride ?? draft.total ?? draft.itemsSum;
        final discountAmount =
            options.discountOverride ?? draft.discount ?? Money.zero;
        final purchaseId = options.purchaseId ?? _idGenerator.newId();
        final expenseId = options.createExpense
            ? (options.expenseId ?? _idGenerator.newId())
            : null;

        // 3. Salvar a Compra (`Purchases`) sem expenseId inicialmente para respeitar a FK
        await _db
            .into(_db.purchases)
            .insert(
              db.PurchasesCompanion.insert(
                id: purchaseId,
                storeId: Value(storeId),
                purchasedAt: purchaseDate.toIso8601String(),
                totalCents: totalAmount.cents,
                discountCents: Value(discountAmount.cents),
                paymentMethod: Value(draft.paymentMethod),
                receiptKey: Value(draft.accessKey),
                source: 'ocr',
                expenseId: const Value(null),
                createdAt: Value(nowIso),
                updatedAt: Value(nowIso),
              ),
            );

        // 4. Salvar os Itens (`PurchaseItems`)
        final domainItems = <PurchaseItem>[];
        for (var position = 0; position < selectedItems.length; position++) {
          final draftItem = selectedItems[position];
          final itemId = '${purchaseId}_item_$position';
          final productId = draftItem.match?.product.id;

          if (productId != null &&
              productId.isNotEmpty &&
              draftItem.match?.product != null) {
            final prod = draftItem.match!.product;

            // Ensure custom product created during review exists in database
            final existingProd = await (_db.select(
              _db.products,
            )..where((p) => p.id.equals(productId))).getSingleOrNull();

            if (existingProd == null) {
              if (prod.categoryId.isNotEmpty) {
                final existingCat =
                    await (_db.select(_db.categories)
                          ..where((c) => c.id.equals(prod.categoryId)))
                        .getSingleOrNull();
                if (existingCat == null) {
                  await _db
                      .into(_db.categories)
                      .insertOnConflictUpdate(
                        db.CategoriesCompanion.insert(
                          id: prod.categoryId,
                          name: prod.categoryId,
                          kind: 'product',
                          iconKey: 'inventory',
                        ),
                      );
                }
              }

              await _db
                  .into(_db.products)
                  .insertOnConflictUpdate(
                    db.ProductsCompanion.insert(
                      id: prod.id,
                      canonicalName: prod.canonicalName,
                      categoryId: Value(
                        prod.categoryId.isNotEmpty ? prod.categoryId : null,
                      ),
                      defaultUnit: prod.defaultUnit.name,
                      createdAt: Value(nowIso),
                      updatedAt: Value(nowIso),
                    ),
                  );

              // Insert canonical name alias for new product (RN-023)
              final canonicalNorm = normalizeProductName(prod.canonicalName);
              if (canonicalNorm.isNotEmpty) {
                final canonicalAliasExists =
                    await (_db.select(_db.productAliases)..where(
                          (a) =>
                              a.productId.equals(prod.id) &
                              a.normalizedAlias.equals(canonicalNorm),
                        ))
                        .getSingleOrNull();

                if (canonicalAliasExists == null) {
                  await _db
                      .into(_db.productAliases)
                      .insert(
                        db.ProductAliasesCompanion.insert(
                          id: '${_idGenerator.newId()}_canonical_$position',
                          productId: prod.id,
                          alias: prod.canonicalName,
                          normalizedAlias: canonicalNorm,
                          source: 'user',
                          createdAt: Value(nowIso),
                        ),
                      );
                }
              }
            }

            // Record OCR text (rawDescription) as product synonym/alias (RN-199, CA-3.3)
            final rawAlias = draftItem.rawDescription.trim();
            final normalizedAlias = normalizeProductName(rawAlias);
            if (normalizedAlias.isNotEmpty) {
              final aliasExistsForProduct =
                  await (_db.select(_db.productAliases)..where(
                        (a) =>
                            a.productId.equals(productId) &
                            a.normalizedAlias.equals(normalizedAlias),
                      ))
                      .getSingleOrNull();

              if (aliasExistsForProduct == null) {
                final aliasConflict =
                    await (_db.select(_db.productAliases)..where(
                          (a) => a.normalizedAlias.equals(normalizedAlias),
                        ))
                        .getSingleOrNull();

                if (aliasConflict == null) {
                  await _db
                      .into(_db.productAliases)
                      .insert(
                        db.ProductAliasesCompanion.insert(
                          id: '${_idGenerator.newId()}_$position',
                          productId: productId,
                          alias: rawAlias,
                          normalizedAlias: normalizedAlias,
                          source: 'ocr',
                          createdAt: Value(nowIso),
                        ),
                      );
                }
              }
            }
          }

          await _db
              .into(_db.purchaseItems)
              .insert(
                db.PurchaseItemsCompanion.insert(
                  id: itemId,
                  purchaseId: purchaseId,
                  productId: Value(productId),
                  rawDescription: draftItem.rawDescription,
                  quantityMilli: draftItem.quantity.valueMilli,
                  unit: draftItem.quantity.unit.name,
                  unitPriceCents: draftItem.unitPrice.cents,
                  totalPriceCents: draftItem.totalPrice.cents,
                  ean: Value(draftItem.ean),
                  position: position,
                ),
              );

          domainItems.add(
            PurchaseItem(
              id: itemId,
              productId: productId ?? '',
              rawDescription: draftItem.rawDescription,
              quantity: draftItem.quantity,
              unitPrice: draftItem.unitPrice,
              totalPrice: draftItem.totalPrice,
            ),
          );
        }

        // 5. Save Price Points (`PricePoints`)
        for (final item in domainItems) {
          if (item.productId.isEmpty) continue;
          final pricePointId = '${purchaseId}_pp_${item.id}';
          final pp = PricePoint.fromPurchaseItem(
            id: pricePointId,
            storeId: storeId,
            date: purchaseDate,
            item: item,
          );

          await _db
              .into(_db.pricePoints)
              .insert(
                db.PricePointsCompanion.insert(
                  id: pp.id,
                  productId: Value(pp.productId),
                  storeId: Value(pp.storeId),
                  observedAt: pp.date.toIso8601String(),
                  unitPriceCents: item.unitPrice.cents,
                  normalizedPriceCents: pp.normalizedPrice.cents,
                  quantityMilli: item.quantity.valueMilli,
                  unit: pp.unit.name,
                  purchaseItemId: Value(item.id),
                  source: pp.source.name,
                ),
              );
        }

        // 6. Save Expense (`Expenses`) if requested (RN-200) and link to Purchase
        if (options.createExpense && expenseId != null) {
          final categoryIdStr = options.categoryId?.value ?? 'cat_food';

          // Garantir que a categoria existe no banco para respeitar a FK
          final existingCat = await (_db.select(
            _db.categories,
          )..where((c) => c.id.equals(categoryIdStr))).getSingleOrNull();

          if (existingCat == null) {
            await _db
                .into(_db.categories)
                .insertOnConflictUpdate(
                  db.CategoriesCompanion.insert(
                    id: categoryIdStr,
                    name: 'Alimentação',
                    kind: 'expense',
                    iconKey: 'catFood',
                  ),
                );
          }

          final storeRow = await (_db.select(
            _db.stores,
          )..where((s) => s.id.equals(storeId))).getSingleOrNull();
          final desc = storeRow?.name ?? 'Nota Fiscal (OCR)';

          await _db
              .into(_db.expenses)
              .insert(
                db.ExpensesCompanion.insert(
                  id: expenseId,
                  amountCents: totalAmount.cents,
                  occurredOn: purchaseDate.toIso8601String().substring(0, 10),
                  categoryId: Value(categoryIdStr),
                  description: Value(desc),
                  purchaseId: Value(purchaseId),
                  createdAt: Value(nowIso),
                ),
              );

          // Atualizar Purchases com expenseId agora que a expense existe
          await (_db.update(_db.purchases)
                ..where((p) => p.id.equals(purchaseId)))
              .write(db.PurchasesCompanion(expenseId: Value(expenseId)));
        }

        // 7. Dar baixa nos itens correspondentes da lista de compras (RN-201, RN-087)
        if (options.writeOffShoppingListId != null) {
          final listId = options.writeOffShoppingListId!;
          final purchaseProductIds = domainItems
              .map((i) => i.productId)
              .toSet();

          if (purchaseProductIds.isNotEmpty) {
            final itemsToUpdate =
                await (_db.select(_db.shoppingItems)..where(
                      (i) =>
                          i.listId.equals(listId) &
                          i.productId.isIn(purchaseProductIds) &
                          i.isChecked.equals(false),
                    ))
                    .get();

            for (final item in itemsToUpdate) {
              await (_db.update(
                _db.shoppingItems,
              )..where((i) => i.id.equals(item.id))).write(
                db.ShoppingItemsCompanion(
                  isChecked: const Value(true),
                  checkedAt: Value(purchaseDate.toIso8601String()),
                ),
              );
            }
          }
        }

        createdPurchase = Purchase(
          id: purchaseId,
          storeId: storeId,
          date: purchaseDate,
          items: domainItems,
          totalAmount: totalAmount,
          discountAmount: discountAmount,
        );
      });

      return Ok(createdPurchase);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao salvar nota fiscal em transação',
          cause: e,
        ),
      );
    }
  }
}
