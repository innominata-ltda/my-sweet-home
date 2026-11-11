library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/text/normalizer.dart';
import '../../core/time/clock.dart';
import '../database/database.dart';

/// Ambiguous alias conflict pointing to two or more distinct products (INV-6, RN-326).
final class PendingAliasConflict {
  final String alias;
  final String normalizedAlias;
  final List<String> candidateProductIds;
  final String detectedAt;

  const PendingAliasConflict({
    required this.alias,
    required this.normalizedAlias,
    required this.candidateProductIds,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'alias': alias,
    'normalized_alias': normalizedAlias,
    'candidate_product_ids': candidateProductIds,
    'detected_at': detectedAt,
  };

  factory PendingAliasConflict.fromJson(Map<String, dynamic> json) =>
      PendingAliasConflict(
        alias: json['alias'] as String,
        normalizedAlias: json['normalized_alias'] as String,
        candidateProductIds: (json['candidate_product_ids'] as List)
            .map((e) => e.toString())
            .toList(),
        detectedAt: json['detected_at'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingAliasConflict &&
          runtimeType == other.runtimeType &&
          alias == other.alias &&
          normalizedAlias == other.normalizedAlias &&
          _listEquals(candidateProductIds, other.candidateProductIds) &&
          detectedAt == other.detectedAt;

  @override
  int get hashCode => Object.hash(
    alias,
    normalizedAlias,
    Object.hashAll(candidateProductIds),
    detectedAt,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Report of performed natural identity merges (RN-326, CA-5.6).
final class MergeReport {
  final int mergedProductsCount;
  final int mergedStoresCount;
  final int mergedBudgetsCount;
  final List<PendingAliasConflict> pendingAliasConflicts;

  const MergeReport({
    this.mergedProductsCount = 0,
    this.mergedStoresCount = 0,
    this.mergedBudgetsCount = 0,
    this.pendingAliasConflicts = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeReport &&
          runtimeType == other.runtimeType &&
          mergedProductsCount == other.mergedProductsCount &&
          mergedStoresCount == other.mergedStoresCount &&
          mergedBudgetsCount == other.mergedBudgetsCount &&
          _listEquals(pendingAliasConflicts, other.pendingAliasConflicts);

  @override
  int get hashCode => Object.hash(
    mergedProductsCount,
    mergedStoresCount,
    mergedBudgetsCount,
    Object.hashAll(pendingAliasConflicts),
  );

  static bool _listEquals(
    List<PendingAliasConflict> a,
    List<PendingAliasConflict> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Deterministic merger of natural identities (RN-326, CA-5.6).
///
/// Handled collisions:
/// 1. Products with the same normalized canonical name (`normalizeProductName`).
/// 2. Establishments with the same normalized CNPJ.
/// 3. Budgets with the same year/month and category.
/// 4. Ambiguous aliases pointing to two distinct products (INV-6) become
///    user prompts stored in settings without blocking sync.
final class NaturalKeyMerger {
  static const String aliasConflictsSettingsKey =
      'sync_pending_alias_conflicts';

  final Clock clock;

  const NaturalKeyMerger({this.clock = const SystemClock()});

  /// Executes all required merges and conflict detections.
  Future<MergeReport> mergeAll(AppDatabase db) async {
    final mergedProducts = await mergeProducts(db);
    final mergedStores = await mergeStores(db);
    final mergedBudgets = await mergeBudgets(db);
    final conflicts = await detectAndRecordAliasConflicts(db);

    return MergeReport(
      mergedProductsCount: mergedProducts,
      mergedStoresCount: mergedStores,
      mergedBudgetsCount: mergedBudgets,
      pendingAliasConflicts: conflicts,
    );
  }

  /// Deterministic merge of products with the same normalized canonical name (RF-025, RN-326, CA-5.6).
  Future<int> mergeProducts(AppDatabase db) async {
    final products = await (db.select(
      db.products,
    )..where((tbl) => tbl.isArchived.equals(false))).get();

    final grouped = <String, List<Product>>{};
    for (final p in products) {
      final norm = normalizeProductName(p.canonicalName);
      if (norm.isEmpty) continue;
      grouped.putIfAbsent(norm, () => []).add(p);
    }

    var mergedCount = 0;

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length <= 1) continue;

      // Deterministic sort: earliest created_at (oldest), then lowest id
      list.sort((a, b) {
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        if (aCreated != null && bCreated != null) {
          final cmp = aCreated.compareTo(bCreated);
          if (cmp != 0) return cmp;
        } else if (aCreated != null) {
          return -1;
        } else if (bCreated != null) {
          return 1;
        }
        return a.id.compareTo(b.id);
      });

      final survivor = list.first;
      final losers = list.skip(1).toList();

      for (final loser in losers) {
        await _mergeProductInto(db, fromId: loser.id, intoId: survivor.id);
        mergedCount++;
      }
    }

    return mergedCount;
  }

  Future<void> _mergeProductInto(
    AppDatabase db, {
    required String fromId,
    required String intoId,
  }) async {
    // 1. Aliases: avoid violating UNIQUE(normalized_alias, product_id) constraint
    final loserAliases = await (db.select(
      db.productAliases,
    )..where((tbl) => tbl.productId.equals(fromId))).get();

    final winnerAliases = await (db.select(
      db.productAliases,
    )..where((tbl) => tbl.productId.equals(intoId))).get();

    final winnerNormAliases = winnerAliases
        .map((a) => a.normalizedAlias)
        .toSet();

    for (final alias in loserAliases) {
      if (winnerNormAliases.contains(alias.normalizedAlias)) {
        // Winner already has this exact alias; delete the loser's
        await (db.delete(
          db.productAliases,
        )..where((tbl) => tbl.id.equals(alias.id))).go();
      } else {
        // Repoint to winner product
        await (db.update(db.productAliases)
              ..where((tbl) => tbl.id.equals(alias.id)))
            .write(ProductAliasesCompanion(productId: Value(intoId)));
        winnerNormAliases.add(alias.normalizedAlias);
      }
    }

    // 2. Denials (OCR denials): avoid violating UNIQUE(normalized_text, product_id) constraint
    final loserDenials = await (db.select(
      db.productDenials,
    )..where((tbl) => tbl.productId.equals(fromId))).get();

    final winnerDenials = await (db.select(
      db.productDenials,
    )..where((tbl) => tbl.productId.equals(intoId))).get();

    final winnerNormDenials = winnerDenials
        .map((d) => d.normalizedText)
        .toSet();

    for (final denial in loserDenials) {
      if (winnerNormDenials.contains(denial.normalizedText)) {
        await (db.delete(
          db.productDenials,
        )..where((tbl) => tbl.id.equals(denial.id))).go();
      } else {
        await (db.update(db.productDenials)
              ..where((tbl) => tbl.id.equals(denial.id)))
            .write(ProductDenialsCompanion(productId: Value(intoId)));
        winnerNormDenials.add(denial.normalizedText);
      }
    }

    // 3. Purchase items
    await (db.update(db.purchaseItems)
          ..where((tbl) => tbl.productId.equals(fromId)))
        .write(PurchaseItemsCompanion(productId: Value(intoId)));

    // 4. Price points (preserves price history of both - CA-5.6)
    await (db.update(db.pricePoints)
          ..where((tbl) => tbl.productId.equals(fromId)))
        .write(PricePointsCompanion(productId: Value(intoId)));

    // 5. Recipe ingredients
    await (db.update(db.recipeIngredients)
          ..where((tbl) => tbl.productId.equals(fromId)))
        .write(RecipeIngredientsCompanion(productId: Value(intoId)));

    // 6. Shopping items
    await (db.update(db.shoppingItems)
          ..where((tbl) => tbl.productId.equals(fromId)))
        .write(ShoppingItemsCompanion(productId: Value(intoId)));

    // 7. Stock items
    await (db.update(db.stockItems)
          ..where((tbl) => tbl.productId.equals(fromId)))
        .write(StockItemsCompanion(productId: Value(intoId)));

    // 8. Clean up column versions of loser row
    await (db.delete(db.syncColumnVersions)..where(
          (tbl) =>
              tbl.tableNameCol.equals('products') & tbl.rowId.equals(fromId),
        ))
        .go();

    // 9. Delete loser product
    await (db.delete(db.products)..where((tbl) => tbl.id.equals(fromId))).go();
  }

  /// Deterministic merge of establishments with the same CNPJ (RN-326).
  Future<int> mergeStores(AppDatabase db) async {
    final stores = await db.select(db.stores).get();

    final grouped = <String, List<Store>>{};
    for (final s in stores) {
      final cnpj = s.cnpj?.replaceAll(RegExp(r'\D'), '');
      if (cnpj == null || cnpj.isEmpty) continue;
      grouped.putIfAbsent(cnpj, () => []).add(s);
    }

    var mergedCount = 0;

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length <= 1) continue;

      list.sort((a, b) {
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        if (aCreated != null && bCreated != null) {
          final cmp = aCreated.compareTo(bCreated);
          if (cmp != 0) return cmp;
        } else if (aCreated != null) {
          return -1;
        } else if (bCreated != null) {
          return 1;
        }
        return a.id.compareTo(b.id);
      });

      final survivor = list.first;
      final losers = list.skip(1).toList();

      for (final loser in losers) {
        // Repoint purchases, price points, and shopping lists
        await (db.update(db.purchases)
              ..where((tbl) => tbl.storeId.equals(loser.id)))
            .write(PurchasesCompanion(storeId: Value(survivor.id)));

        await (db.update(db.pricePoints)
              ..where((tbl) => tbl.storeId.equals(loser.id)))
            .write(PricePointsCompanion(storeId: Value(survivor.id)));

        await (db.update(db.shoppingLists)
              ..where((tbl) => tbl.storeId.equals(loser.id)))
            .write(ShoppingListsCompanion(storeId: Value(survivor.id)));

        await (db.delete(db.syncColumnVersions)..where(
              (tbl) =>
                  tbl.tableNameCol.equals('stores') &
                  tbl.rowId.equals(loser.id),
            ))
            .go();

        await (db.delete(
          db.stores,
        )..where((tbl) => tbl.id.equals(loser.id))).go();

        mergedCount++;
      }
    }

    return mergedCount;
  }

  /// Deterministic merge of budgets with the same year/month and category (RN-326).
  Future<int> mergeBudgets(AppDatabase db) async {
    final budgets = await db.select(db.budgets).get();

    final grouped = <String, List<Budget>>{};
    for (final b in budgets) {
      final key = '${b.yearMonth}:${b.categoryId ?? 'total'}';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    var mergedCount = 0;

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length <= 1) continue;

      list.sort((a, b) => a.id.compareTo(b.id));

      final losers = list.skip(1).toList();

      for (final loser in losers) {
        await (db.delete(db.syncColumnVersions)..where(
              (tbl) =>
                  tbl.tableNameCol.equals('budgets') &
                  tbl.rowId.equals(loser.id),
            ))
            .go();

        await (db.delete(
          db.budgets,
        )..where((tbl) => tbl.id.equals(loser.id))).go();

        mergedCount++;
      }
    }

    return mergedCount;
  }

  /// Detects aliases pointing to more than one product and records as prompt (INV-6, RN-326).
  Future<List<PendingAliasConflict>> detectAndRecordAliasConflicts(
    AppDatabase db,
  ) async {
    final aliases = await (db.select(db.productAliases).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.productAliases.productId) &
            db.products.isArchived.equals(false),
      ),
    ])).get();

    final byNormalized =
        <String, Map<String, String>>{}; // norm -> {prodId: rawAlias}
    for (final row in aliases) {
      final aliasRow = row.readTable(db.productAliases);
      final norm = aliasRow.normalizedAlias;
      if (norm.isEmpty) continue;

      byNormalized.putIfAbsent(norm, () => {});
      byNormalized[norm]![aliasRow.productId] = aliasRow.alias;
    }

    final conflicts = <PendingAliasConflict>[];
    final nowIso = clock.nowUtc().toIso8601String();

    for (final entry in byNormalized.entries) {
      final norm = entry.key;
      final prodMap = entry.value;

      if (prodMap.keys.length > 1) {
        // Conflict detected! Alias points to more than 1 active product.
        conflicts.add(
          PendingAliasConflict(
            alias: prodMap.values.first,
            normalizedAlias: norm,
            candidateProductIds: prodMap.keys.toList()..sort(),
            detectedAt: nowIso,
          ),
        );
      }
    }

    // Persist in settings for UI query or future resolution
    final conflictsJson = jsonEncode(conflicts.map((c) => c.toJson()).toList());
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(aliasConflictsSettingsKey),
            value: Value(conflictsJson),
            updatedAt: Value(nowIso),
          ),
        );

    return conflicts;
  }

  /// Retrieves pending alias conflicts recorded in settings.
  Future<List<PendingAliasConflict>> getPendingAliasConflicts(
    AppDatabase db,
  ) async {
    final setting =
        await (db.select(db.settings)
              ..where((tbl) => tbl.key.equals(aliasConflictsSettingsKey)))
            .getSingleOrNull();

    if (setting == null || setting.value.isEmpty) return const [];

    try {
      final list = jsonDecode(setting.value) as List<dynamic>;
      return list
          .map((e) => PendingAliasConflict.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Resolves an alias conflict keeping the link for [chosenProductId]
  /// and removing others (INV-6).
  Future<void> resolveAliasConflict(
    AppDatabase db, {
    required String normalizedAlias,
    required String chosenProductId,
  }) async {
    // 1. Delete competing aliases that do not belong to the chosen product
    await (db.delete(db.productAliases)..where(
          (tbl) =>
              tbl.normalizedAlias.equals(normalizedAlias) &
              tbl.productId.equals(chosenProductId).not(),
        ))
        .go();

    // 2. Update pending conflict list
    final current = await getPendingAliasConflicts(db);
    final remaining = current
        .where((c) => c.normalizedAlias != normalizedAlias)
        .toList();

    final nowIso = clock.nowUtc().toIso8601String();
    final conflictsJson = jsonEncode(remaining.map((c) => c.toJson()).toList());

    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(aliasConflictsSettingsKey),
            value: Value(conflictsJson),
            updatedAt: Value(nowIso),
          ),
        );
  }
}
