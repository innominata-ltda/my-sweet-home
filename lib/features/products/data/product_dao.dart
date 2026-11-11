library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Product;
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/domain/product_repository.dart';

class ProductDao implements ProductRepository {
  const ProductDao(this._db, this._idGen, this._clock);

  final AppDatabase _db;
  final IdGenerator _idGen;
  final Clock _clock;

  @override
  Future<Result<Product, Failure>> create(NewProduct p) async {
    final normalized = normalizeProductName(p.canonicalName);
    if (normalized.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'canonicalName': 'Nome não pode ser vazio.'},
        ),
      );
    }

    try {
      return await _db.transaction(() async {
        // Check if product with same normalized name already exists (as alias or canonical name)
        // RN-020: "Two products MUST NOT have the same normalized canonical name."
        // RN-022: "A single normalized alias MUST NOT point to two products."

        final existingAlias =
            await (_db.select(_db.productAliases)
                  ..where((tbl) => tbl.normalizedAlias.equals(normalized)))
                .getSingleOrNull();
        if (existingAlias != null) {
          return const Err(
            ValidationFailure(
              fields: {'canonicalName': 'Produto já existe com este nome.'},
            ),
          );
        }

        final now = _clock.nowUtc().toIso8601String();
        final productId = _idGen.newId();

        // 1. Inserir o produto
        await _db
            .into(_db.products)
            .insert(
              ProductsCompanion(
                id: Value(productId),
                canonicalName: Value(p.canonicalName),
                categoryId: Value(p.categoryId),
                defaultUnit: Value(p.defaultUnit.name),
                packageSizeMilli: Value(p.packageSizeMilli),
                isArchived: const Value(false),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // 2. Insert canonical name alias (RN-023)
        final aliasId = _idGen.newId();
        await _db
            .into(_db.productAliases)
            .insert(
              ProductAliasesCompanion(
                id: Value(aliasId),
                productId: Value(productId),
                alias: Value(p.canonicalName),
                normalizedAlias: Value(normalized),
                source: const Value('user'),
                createdAt: Value(now),
              ),
            );

        return Ok(
          Product(
            id: productId,
            canonicalName: p.canonicalName,
            categoryId: p.categoryId,
            defaultUnit: p.defaultUnit,
            packageSizeMilli: p.packageSizeMilli,
            createdAt: DateTime.parse(now),
            updatedAt: DateTime.parse(now),
          ),
        );
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao criar produto', cause: e));
    }
  }

  @override
  Future<Result<Product, Failure>> addAlias(
    ProductId id,
    String alias,
    AliasSource source,
  ) async {
    final normalized = normalizeProductName(alias);
    if (normalized.isEmpty) {
      return const Err(
        ValidationFailure(fields: {'alias': 'Apelido não pode ser vazio.'}),
      );
    }

    try {
      return await _db.transaction(() async {
        final conflictResult = await checkAliasConflict(alias);
        if (conflictResult.isErr) return Err(conflictResult.failureOrNull!);
        final conflict = conflictResult.valueOrNull;

        if (conflict != null) {
          if (conflict.existingProductId != id) {
            return const Err(
              ValidationFailure(
                fields: {'alias': 'Este apelido já pertence a outro produto.'},
              ),
            );
          } else {
            // Already has this alias on this product
            final p = await _getProduct(id);
            if (p == null) {
              return const Err(
                NotFoundFailure(what: 'Produto não encontrado.'),
              );
            }
            return Ok(p);
          }
        }

        final now = _clock.nowUtc().toIso8601String();
        final aliasId = _idGen.newId();

        await _db
            .into(_db.productAliases)
            .insert(
              ProductAliasesCompanion(
                id: Value(aliasId),
                productId: Value(id),
                alias: Value(alias),
                normalizedAlias: Value(normalized),
                source: Value(source.name),
                createdAt: Value(now),
              ),
            );

        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id)))
            .write(ProductsCompanion(updatedAt: Value(now)));

        final p = await _getProduct(id);
        if (p == null) {
          return const Err(NotFoundFailure(what: 'Produto não encontrado.'));
        }
        return Ok(p);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao adicionar apelido', cause: e));
    }
  }

  @override
  Future<Result<Product, Failure>> setCanonicalName(
    ProductId id,
    String canonicalName,
  ) async {
    final trimmed = canonicalName.trim();
    final normalized = normalizeProductName(trimmed);
    if (trimmed.isEmpty || normalized.isEmpty) {
      return const Err(
        ValidationFailure(
          fields: {'canonicalName': 'O nome padrão não pode ser vazio.'},
        ),
      );
    }

    try {
      return await _db.transaction(() async {
        final productRow = await (_db.select(
          _db.products,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        if (productRow == null) {
          return const Err(NotFoundFailure(what: 'Produto não encontrado.'));
        }

        final existingAlias =
            await (_db.select(_db.productAliases)
                  ..where((tbl) => tbl.normalizedAlias.equals(normalized)))
                .getSingleOrNull();

        if (existingAlias != null && existingAlias.productId != id) {
          return const Err(
            ValidationFailure(
              fields: {'alias': 'Este apelido já pertence a outro produto.'},
            ),
          );
        }

        final now = _clock.nowUtc().toIso8601String();

        // Preserve previous canonical name as an alias (RN-023, RN-035)
        final prevNormalized = normalizeProductName(productRow.canonicalName);
        if (prevNormalized.isNotEmpty) {
          final prevAliasRow =
              await (_db.select(
                    _db.productAliases,
                  )..where((tbl) => tbl.normalizedAlias.equals(prevNormalized)))
                  .getSingleOrNull();
          if (prevAliasRow == null) {
            await _db
                .into(_db.productAliases)
                .insert(
                  ProductAliasesCompanion(
                    id: Value(_idGen.newId()),
                    productId: Value(id),
                    alias: Value(productRow.canonicalName),
                    normalizedAlias: Value(prevNormalized),
                    source: Value(AliasSource.user.name),
                    createdAt: Value(now),
                  ),
                );
          }
        }

        // Ensure new canonical name is also present in product_aliases (RN-023)
        if (existingAlias == null) {
          await _db
              .into(_db.productAliases)
              .insert(
                ProductAliasesCompanion(
                  id: Value(_idGen.newId()),
                  productId: Value(id),
                  alias: Value(trimmed),
                  normalizedAlias: Value(normalized),
                  source: Value(AliasSource.user.name),
                  createdAt: Value(now),
                ),
              );
        } else if (existingAlias.alias != trimmed) {
          await (_db.update(_db.productAliases)
                ..where((tbl) => tbl.id.equals(existingAlias.id)))
              .write(ProductAliasesCompanion(alias: Value(trimmed)));
        }

        await (_db.update(
          _db.products,
        )..where((tbl) => tbl.id.equals(id))).write(
          ProductsCompanion(
            canonicalName: Value(trimmed),
            updatedAt: Value(now),
          ),
        );

        final updated = await _getProduct(id);
        if (updated == null) {
          return const Err(NotFoundFailure(what: 'Produto não encontrado.'));
        }
        return Ok(updated);
      });
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao definir nome padrão', cause: e),
      );
    }
  }

  @override
  Future<Result<Product, Failure>> separateAlias(String aliasId) async {
    try {
      return await _db.transaction(() async {
        final aliasRow = await (_db.select(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(aliasId))).getSingleOrNull();
        if (aliasRow == null) {
          return const Err(NotFoundFailure(what: 'Apelido não encontrado.'));
        }

        final productRow = await (_db.select(
          _db.products,
        )..where((tbl) => tbl.id.equals(aliasRow.productId))).getSingleOrNull();
        if (productRow == null) {
          return const Err(NotFoundFailure(what: 'Produto não encontrado.'));
        }

        final canonicalNorm = normalizeProductName(productRow.canonicalName);
        if (canonicalNorm == aliasRow.normalizedAlias) {
          return const Err(
            ValidationFailure(
              fields: {
                'alias': 'Defina outro apelido como nome padrão antes de separar este item.',
              },
            ),
          );
        }

        final now = _clock.nowUtc().toIso8601String();
        final newProductId = _idGen.newId();

        // 1. Create new independent product inheriting category and default unit
        await _db
            .into(_db.products)
            .insert(
              ProductsCompanion(
                id: Value(newProductId),
                canonicalName: Value(aliasRow.alias),
                categoryId: Value(productRow.categoryId),
                defaultUnit: Value(productRow.defaultUnit),
                packageSizeMilli: Value(productRow.packageSizeMilli),
                isArchived: const Value(false),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // 2. Migrar o apelido para ser o apelido principal do novo produto
        await (_db.update(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(aliasId))).write(
          ProductAliasesCompanion(
            productId: Value(newProductId),
            source: Value(AliasSource.user.name),
          ),
        );

        // 3. Register negation in original product (RN-028, RN-036)
        final existingDenial =
            await (_db.select(_db.productDenials)
                  ..where((tbl) => tbl.productId.equals(productRow.id))
                  ..where(
                    (tbl) =>
                        tbl.normalizedText.equals(aliasRow.normalizedAlias),
                  ))
                .getSingleOrNull();
        if (existingDenial == null) {
          await _db
              .into(_db.productDenials)
              .insert(
                ProductDenialsCompanion(
                  id: Value(_idGen.newId()),
                  productId: Value(productRow.id),
                  rawText: Value(aliasRow.alias),
                  normalizedText: Value(aliasRow.normalizedAlias),
                  createdAt: Value(now),
                ),
              );
        }

        // 4. Migrar purchase_items e price_points correspondentes a este apelido
        final aliasTokens = aliasRow.normalizedAlias
            .split(' ')
            .where((t) => t.isNotEmpty)
            .toList();
        final items = await (_db.select(
          _db.purchaseItems,
        )..where((tbl) => tbl.productId.equals(productRow.id))).get();

        final migratedItemIds = <String>[];
        for (final item in items) {
          final itemNorm = normalizeProductName(item.rawDescription);
          if (itemNorm.isEmpty || itemNorm == canonicalNorm) continue;
          final matchesAlias =
              itemNorm == aliasRow.normalizedAlias ||
              (aliasTokens.isNotEmpty &&
                  aliasTokens.every(
                    (token) => itemNorm.split(' ').contains(token),
                  ));
          if (matchesAlias) {
            migratedItemIds.add(item.id);
          }
        }

        if (migratedItemIds.isNotEmpty) {
          await (_db.update(_db.purchaseItems)
                ..where((tbl) => tbl.id.isIn(migratedItemIds)))
              .write(PurchaseItemsCompanion(productId: Value(newProductId)));

          await (_db.update(_db.pricePoints)
                ..where((tbl) => tbl.purchaseItemId.isIn(migratedItemIds)))
              .write(PricePointsCompanion(productId: Value(newProductId)));
        }

        await (_db.update(_db.products)
              ..where((tbl) => tbl.id.equals(productRow.id)))
            .write(ProductsCompanion(updatedAt: Value(now)));

        final created = await _getProduct(newProductId);
        if (created == null) {
          return const Err(
            NotFoundFailure(what: 'Novo produto não encontrado.'),
          );
        }
        return Ok(created);
      });
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao separar apelido em novo produto',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> removeAlias(String aliasId) async {
    try {
      return await _db.transaction(() async {
        final aliasRow = await (_db.select(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(aliasId))).getSingleOrNull();
        if (aliasRow == null) return const Ok(null);

        final productRow = await (_db.select(
          _db.products,
        )..where((tbl) => tbl.id.equals(aliasRow.productId))).getSingleOrNull();
        if (productRow != null) {
          if (normalizeProductName(productRow.canonicalName) ==
              aliasRow.normalizedAlias) {
            return const Err(
              ValidationFailure(
                fields: {
                  'alias':
                      'Não é possível remover o apelido principal do produto.',
                },
              ),
            );
          }

          final now = _clock.nowUtc().toIso8601String();
          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(productRow.id)))
              .write(ProductsCompanion(updatedAt: Value(now)));
        }

        await (_db.delete(
          _db.productAliases,
        )..where((tbl) => tbl.id.equals(aliasId))).go();
        return const Ok(null);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao remover apelido', cause: e));
    }
  }

  @override
  Future<Result<AliasConflict?, Failure>> checkAliasConflict(
    String alias,
  ) async {
    final normalized = normalizeProductName(alias);
    if (normalized.isEmpty) return const Ok(null);

    try {
      final existing =
          await (_db.select(_db.productAliases)
                ..where((tbl) => tbl.normalizedAlias.equals(normalized)))
              .getSingleOrNull();
      if (existing != null) {
        return Ok(
          AliasConflict(alias: alias, existingProductId: existing.productId),
        );
      }
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao checar conflito de apelido', cause: e),
      );
    }
  }

  @override
  Future<Result<void, Failure>> registerDenial(
    ProductId id,
    String rawText,
  ) async {
    final normalized = normalizeProductName(rawText);
    if (normalized.isEmpty) {
      return const Err(
        ValidationFailure(fields: {'rawText': 'Texto não pode ser vazio.'}),
      );
    }

    try {
      return await _db.transaction(() async {
        final existing =
            await (_db.select(_db.productDenials)
                  ..where((tbl) => tbl.productId.equals(id))
                  ..where((tbl) => tbl.normalizedText.equals(normalized)))
                .getSingleOrNull();

        if (existing != null) {
          return const Ok(null);
        }

        final now = _clock.nowUtc().toIso8601String();
        final denialId = _idGen.newId();

        await _db
            .into(_db.productDenials)
            .insert(
              ProductDenialsCompanion(
                id: Value(denialId),
                productId: Value(id),
                rawText: Value(rawText),
                normalizedText: Value(normalized),
                createdAt: Value(now),
              ),
            );

        return const Ok(null);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao registrar negação', cause: e));
    }
  }

  Future<Product?> _getProduct(String id) async {
    final row = await (_db.select(
      _db.products,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return Product(
      id: row.id,
      canonicalName: row.canonicalName,
      categoryId: row.categoryId ?? '',
      defaultUnit: Unit.values.firstWhere((u) => u.name == row.defaultUnit),
      packageSizeMilli: row.packageSizeMilli,
      isArchived: row.isArchived,
      createdAt: row.createdAt != null
          ? DateTime.parse(row.createdAt!)
          : _clock.nowUtc(),
      updatedAt: row.updatedAt != null
          ? DateTime.parse(row.updatedAt!)
          : _clock.nowUtc(),
    );
  }

  @override
  Future<Result<List<Product>, Failure>> search(
    String query, {
    int limit = 50,
  }) async {
    final normalizedQuery = normalizeProductName(query);
    if (normalizedQuery.isEmpty) {
      try {
        final effectiveLimit = limit == 50 ? 500 : limit;
        final q = _db.select(_db.products)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..limit(effectiveLimit);

        final rows = await q.get();

        final products = rows
            .map(
              (row) => Product(
                id: row.id,
                canonicalName: row.canonicalName,
                categoryId: row.categoryId ?? '',
                defaultUnit: Unit.values.firstWhere(
                  (u) => u.name == row.defaultUnit,
                ),
                packageSizeMilli: row.packageSizeMilli,
                isArchived: row.isArchived,
                createdAt: row.createdAt != null
                    ? DateTime.parse(row.createdAt!)
                    : _clock.nowUtc(),
                updatedAt: row.updatedAt != null
                    ? DateTime.parse(row.updatedAt!)
                    : _clock.nowUtc(),
              ),
            )
            .toList();

        return Ok(products);
      } catch (e) {
        return Err(
          StorageFailure(detail: 'Erro na busca de produtos', cause: e),
        );
      }
    }

    try {
      final searchPattern = '%$normalizedQuery%';

      final matchingProductIds = _db.selectOnly(_db.productAliases)
        ..addColumns([_db.productAliases.productId])
        ..where(_db.productAliases.normalizedAlias.like(searchPattern));

      final q = _db.select(_db.products)
        ..where((tbl) => tbl.id.isInQuery(matchingProductIds))
        ..where((tbl) => tbl.isArchived.equals(false))
        ..limit(limit);

      final rows = await q.get();

      final products = rows
          .map(
            (row) => Product(
              id: row.id,
              canonicalName: row.canonicalName,
              categoryId: row.categoryId ?? '',
              defaultUnit: Unit.values.firstWhere(
                (u) => u.name == row.defaultUnit,
              ),
              packageSizeMilli: row.packageSizeMilli,
              isArchived: row.isArchived,
              createdAt: row.createdAt != null
                  ? DateTime.parse(row.createdAt!)
                  : _clock.nowUtc(),
              updatedAt: row.updatedAt != null
                  ? DateTime.parse(row.updatedAt!)
                  : _clock.nowUtc(),
            ),
          )
          .toList();

      return Ok(products);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro na busca de produtos', cause: e));
    }
  }

  @override
  Future<Result<MergeReceipt, Failure>> merge({
    required ProductId from,
    required ProductId into,
  }) async {
    try {
      return await _db.transaction(() async {
        final now = _clock.nowUtc().toIso8601String();

        // 1. Get migrated IDs to save in receipt
        final aliasRows = await (_db.select(
          _db.productAliases,
        )..where((tbl) => tbl.productId.equals(from))).get();
        final aliasIds = aliasRows.map((e) => e.id).toList();

        final purchaseItemRows = await (_db.select(
          _db.purchaseItems,
        )..where((tbl) => tbl.productId.equals(from))).get();
        final purchaseItemIds = purchaseItemRows.map((e) => e.id).toList();

        final pricePointRows = await (_db.select(
          _db.pricePoints,
        )..where((tbl) => tbl.productId.equals(from))).get();
        final pricePointIds = pricePointRows.map((e) => e.id).toList();

        final recipeIngredientRows = await (_db.select(
          _db.recipeIngredients,
        )..where((tbl) => tbl.productId.equals(from))).get();
        final recipeIngredientIds = recipeIngredientRows
            .map((e) => e.id)
            .toList();

        final shoppingItemRows = await (_db.select(
          _db.shoppingItems,
        )..where((tbl) => tbl.productId.equals(from))).get();
        final shoppingItemIds = shoppingItemRows.map((e) => e.id).toList();

        // 2. Update references to new product
        if (aliasIds.isNotEmpty) {
          await (_db.update(_db.productAliases)
                ..where((tbl) => tbl.productId.equals(from)))
              .write(ProductAliasesCompanion(productId: Value(into)));
        }
        if (purchaseItemIds.isNotEmpty) {
          await (_db.update(_db.purchaseItems)
                ..where((tbl) => tbl.productId.equals(from)))
              .write(PurchaseItemsCompanion(productId: Value(into)));
        }
        if (pricePointIds.isNotEmpty) {
          await (_db.update(_db.pricePoints)
                ..where((tbl) => tbl.productId.equals(from)))
              .write(PricePointsCompanion(productId: Value(into)));
        }
        if (recipeIngredientIds.isNotEmpty) {
          await (_db.update(_db.recipeIngredients)
                ..where((tbl) => tbl.productId.equals(from)))
              .write(RecipeIngredientsCompanion(productId: Value(into)));
        }
        if (shoppingItemIds.isNotEmpty) {
          await (_db.update(_db.shoppingItems)
                ..where((tbl) => tbl.productId.equals(from)))
              .write(ShoppingItemsCompanion(productId: Value(into)));
        }

        // 3. Archive the loser and touch winner
        await (_db.update(
          _db.products,
        )..where((tbl) => tbl.id.equals(from))).write(
          ProductsCompanion(
            isArchived: const Value(true),
            updatedAt: Value(now),
          ),
        );
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(into)))
            .write(ProductsCompanion(updatedAt: Value(now)));

        // 4. Save receipt in Settings
        final receiptId = _idGen.newId();
        final receiptData = {
          'from': from,
          'into': into,
          'aliases': aliasIds,
          'purchaseItems': purchaseItemIds,
          'pricePoints': pricePointIds,
          'recipeIngredients': recipeIngredientIds,
          'shoppingItems': shoppingItemIds,
          'timestamp': now,
        };

        // Needed import dart:convert for jsonEncode, we'll import it at the top or assume it's in core
        // Since we cannot easily add import without replacing top, we'll just use jsonEncode if dart:convert is imported, else we'll need to add it.
        // Let's add the import.
        await _db
            .into(_db.settings)
            .insert(
              SettingsCompanion(
                key: Value('merge_receipt_$receiptId'),
                value: Value(jsonEncode(receiptData)),
                updatedAt: Value(now),
              ),
            );

        return Ok(
          MergeReceipt(
            id: receiptId,
            mergedProductId: into,
            archivedProductId: from,
          ),
        );
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao mesclar produtos', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> undoMerge(MergeReceiptId id) async {
    try {
      return await _db.transaction(() async {
        final setting =
            await (_db.select(_db.settings)
                  ..where((tbl) => tbl.key.equals('merge_receipt_$id')))
                .getSingleOrNull();
        if (setting == null) {
          return const Err(
            NotFoundFailure(what: 'Recibo de mesclagem não encontrado'),
          );
        }

        final data = jsonDecode(setting.value) as Map<String, dynamic>;
        final String from = data['from'] as String;
        final List<String> aliasIds =
            (data['aliases'] as List<dynamic>?)?.cast<String>() ?? [];
        final List<String> purchaseItemIds =
            (data['purchaseItems'] as List<dynamic>?)?.cast<String>() ?? [];
        final List<String> pricePointIds =
            (data['pricePoints'] as List<dynamic>?)?.cast<String>() ?? [];
        final List<String> recipeIngredientIds =
            (data['recipeIngredients'] as List<dynamic>?)?.cast<String>() ?? [];
        final List<String> shoppingItemIds =
            (data['shoppingItems'] as List<dynamic>?)?.cast<String>() ?? [];

        if (aliasIds.isNotEmpty) {
          await (_db.update(_db.productAliases)
                ..where((tbl) => tbl.id.isIn(aliasIds)))
              .write(ProductAliasesCompanion(productId: Value(from)));
        }
        if (purchaseItemIds.isNotEmpty) {
          await (_db.update(_db.purchaseItems)
                ..where((tbl) => tbl.id.isIn(purchaseItemIds)))
              .write(PurchaseItemsCompanion(productId: Value(from)));
        }
        if (pricePointIds.isNotEmpty) {
          await (_db.update(_db.pricePoints)
                ..where((tbl) => tbl.id.isIn(pricePointIds)))
              .write(PricePointsCompanion(productId: Value(from)));
        }
        if (recipeIngredientIds.isNotEmpty) {
          await (_db.update(_db.recipeIngredients)
                ..where((tbl) => tbl.id.isIn(recipeIngredientIds)))
              .write(RecipeIngredientsCompanion(productId: Value(from)));
        }
        if (shoppingItemIds.isNotEmpty) {
          await (_db.update(_db.shoppingItems)
                ..where((tbl) => tbl.id.isIn(shoppingItemIds)))
              .write(ShoppingItemsCompanion(productId: Value(from)));
        }

        final now = _clock.nowUtc().toIso8601String();
        // Unarchive loser
        await (_db.update(
          _db.products,
        )..where((tbl) => tbl.id.equals(from))).write(
          ProductsCompanion(
            isArchived: const Value(false),
            updatedAt: Value(now),
          ),
        );
        // Touch winner
        final String into = data['into'] as String;
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(into)))
            .write(ProductsCompanion(updatedAt: Value(now)));

        // Remove receipt
        await (_db.delete(
          _db.settings,
        )..where((tbl) => tbl.key.equals('merge_receipt_$id'))).go();

        return const Ok(null);
      });
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao desfazer mesclagem', cause: e),
      );
    }
  }

  @override
  Future<Result<ProductIndex, Failure>> buildIndex() async {
    try {
      final productRows = await (_db.select(
        _db.products,
      )..where((tbl) => tbl.isArchived.equals(false))).get();
      final aliasRows = await _db.select(_db.productAliases).get();
      final denialRows = await _db.select(_db.productDenials).get();

      final products = productRows
          .map(
            (row) => Product(
              id: row.id,
              canonicalName: row.canonicalName,
              categoryId: row.categoryId ?? '',
              defaultUnit: Unit.values.firstWhere(
                (u) => u.name == row.defaultUnit,
              ),
              packageSizeMilli: row.packageSizeMilli,
              isArchived: row.isArchived,
              createdAt: row.createdAt != null
                  ? DateTime.parse(row.createdAt!)
                  : _clock.nowUtc(),
              updatedAt: row.updatedAt != null
                  ? DateTime.parse(row.updatedAt!)
                  : _clock.nowUtc(),
            ),
          )
          .toList();

      final aliases = aliasRows
          .map(
            (row) => ProductAlias(
              id: row.id,
              productId: row.productId,
              alias: row.alias,
              normalizedAlias: row.normalizedAlias,
              source: AliasSource.values.firstWhere(
                (s) => s.name == row.source,
              ),
              createdAt: row.createdAt != null
                  ? DateTime.parse(row.createdAt!)
                  : _clock.nowUtc(),
            ),
          )
          .toList();

      final denials = denialRows
          .map(
            (row) => DeniedPair(rawText: row.rawText, productId: row.productId),
          )
          .toList();

      return Ok(
        ProductIndex(products: products, aliases: aliases, denials: denials),
      );
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao construir índice de produtos',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<bool, Failure>> hasHistory(ProductId id) async {
    try {
      final purchaseCount = await (_db.select(
        _db.purchaseItems,
      )..where((tbl) => tbl.productId.equals(id))).get().then((r) => r.length);
      if (purchaseCount > 0) return const Ok(true);

      final priceCount = await (_db.select(
        _db.pricePoints,
      )..where((tbl) => tbl.productId.equals(id))).get().then((r) => r.length);
      if (priceCount > 0) return const Ok(true);

      final recipeCount = await (_db.select(
        _db.recipeIngredients,
      )..where((tbl) => tbl.productId.equals(id))).get().then((r) => r.length);
      if (recipeCount > 0) return const Ok(true);

      final shoppingCount = await (_db.select(
        _db.shoppingItems,
      )..where((tbl) => tbl.productId.equals(id))).get().then((r) => r.length);
      if (shoppingCount > 0) return const Ok(true);

      return const Ok(false);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao verificar histÃ³rico do produto',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> archive(ProductId id) async {
    try {
      final now = _clock.nowUtc().toIso8601String();
      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
        ProductsCompanion(isArchived: const Value(true), updatedAt: Value(now)),
      );
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao arquivar produto', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> delete(ProductId id) async {
    try {
      return await _db.transaction(() async {
        await (_db.delete(
          _db.productAliases,
        )..where((tbl) => tbl.productId.equals(id))).go();
        await (_db.delete(
          _db.productDenials,
        )..where((tbl) => tbl.productId.equals(id))).go();
        await (_db.delete(
          _db.products,
        )..where((tbl) => tbl.id.equals(id))).go();
        return const Ok(null);
      });
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao excluir produto', cause: e));
    }
  }
}
