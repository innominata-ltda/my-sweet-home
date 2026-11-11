import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  final db.AppDatabase _db;
  final Clock _clock;

  DriftCategoryRepository(this._db, this._clock);

  Category _mapCategory(db.Category c) {
    return Category(
      id: CategoryId(c.id),
      name: c.name,
      kind: CategoryKind.values.firstWhere(
        (k) => k.name == c.kind,
        orElse: () => CategoryKind.expense,
      ),
      iconKey: c.iconKey,
      colorHex: c.colorHex,
      isSystem: c.isSystem,
      sortOrder: c.sortOrder,
    );
  }

  @override
  Future<Result<List<Category>, Failure>> all({
    CategoryKind kind = CategoryKind.expense,
  }) async {
    try {
      final query = _db.select(_db.categories)
        ..where((t) => t.kind.equals(kind.name));
      final rows = await query.get();
      return Ok(rows.map(_mapCategory).toList());
    } catch (e, st) {
      return Err(StorageFailure(detail: e.toString(), cause: st));
    }
  }

  @override
  Future<Result<Category, Failure>> upsert(Category c) async {
    try {
      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            db.CategoriesCompanion(
              id: Value(c.id.value),
              name: Value(c.name),
              kind: Value(c.kind.name),
              iconKey: Value(c.iconKey),
              colorHex: Value(c.colorHex),
              isSystem: Value(c.isSystem),
              sortOrder: Value(c.sortOrder),
            ),
          );
      return Ok(c);
    } catch (e, st) {
      return Err(StorageFailure(detail: e.toString(), cause: st));
    }
  }

  @override
  Future<Result<void, Failure>> deactivate(CategoryId id) async {
    try {
      final expensesCountQuery = _db.select(_db.expenses)
        ..where((t) => t.categoryId.equals(id.value));
      final expensesCount = (await expensesCountQuery.get()).length;
      if (expensesCount > 0) {
        return const Err(
          StorageFailure(detail: 'Category is in use and cannot be deleted'),
        );
      } else {
        await (_db.delete(
          _db.categories,
        )..where((t) => t.id.equals(id.value))).go();
        return const Ok(null);
      }
    } catch (e, st) {
      return Err(StorageFailure(detail: e.toString(), cause: st));
    }
  }

  @override
  Future<Result<int, Failure>> ensureDefaults() async {
    try {
      final query = _db.select(_db.settings)
        ..where((t) => t.key.equals('default_categories_version'));
      final row = await query.getSingleOrNull();
      final version = int.tryParse(row?.value ?? '0') ?? 0;

      if (version >= 1) return const Ok(0);

      final defaultCategories = [
        db.CategoriesCompanion.insert(
          id: 'cat_housing',
          name: 'Moradia',
          kind: CategoryKind.expense.name,
          iconKey: 'catHousing',
          isSystem: const Value(true),
          sortOrder: const Value(1),
          colorHex: const Value('#F44336'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_food',
          name: 'Alimentação',
          kind: CategoryKind.expense.name,
          iconKey: 'catFood',
          isSystem: const Value(true),
          sortOrder: const Value(2),
          colorHex: const Value('#FF9800'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_transport',
          name: 'Transporte',
          kind: CategoryKind.expense.name,
          iconKey: 'catTransport',
          isSystem: const Value(true),
          sortOrder: const Value(3),
          colorHex: const Value('#FFEB3B'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_health',
          name: 'Saúde',
          kind: CategoryKind.expense.name,
          iconKey: 'catHealth',
          isSystem: const Value(true),
          sortOrder: const Value(4),
          colorHex: const Value('#4CAF50'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_education',
          name: 'Educação',
          kind: CategoryKind.expense.name,
          iconKey: 'catEducation',
          isSystem: const Value(true),
          sortOrder: const Value(5),
          colorHex: const Value('#2196F3'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_entertainment',
          name: 'Lazer',
          kind: CategoryKind.expense.name,
          iconKey: 'catEntertainment',
          isSystem: const Value(true),
          sortOrder: const Value(6),
          colorHex: const Value('#9C27B0'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_personal',
          name: 'Pessoal',
          kind: CategoryKind.expense.name,
          iconKey: 'catPersonal',
          isSystem: const Value(true),
          sortOrder: const Value(7),
          colorHex: const Value('#E91E63'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_pets',
          name: 'Pets',
          kind: CategoryKind.expense.name,
          iconKey: 'catPets',
          isSystem: const Value(true),
          sortOrder: const Value(8),
          colorHex: const Value('#795548'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_taxes',
          name: 'Impostos',
          kind: CategoryKind.expense.name,
          iconKey: 'catTaxes',
          isSystem: const Value(true),
          sortOrder: const Value(9),
          colorHex: const Value('#607D8B'),
        ),
        db.CategoriesCompanion.insert(
          id: 'cat_other',
          name: 'Outros',
          kind: CategoryKind.expense.name,
          iconKey: 'catOther',
          isSystem: const Value(true),
          sortOrder: const Value(10),
          colorHex: const Value('#9E9E9E'),
        ),
      ];

      int insertedCount = 0;
      await _db.transaction(() async {
        for (final c in defaultCategories) {
          final existing = await (_db.select(
            _db.categories,
          )..where((t) => t.id.equals(c.id.value))).getSingleOrNull();
          if (existing == null) {
            await _db.into(_db.categories).insert(c);
            insertedCount++;
          }
        }
        await _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              db.SettingsCompanion(
                key: const Value('default_categories_version'),
                value: const Value('1'),
                updatedAt: Value(_clock.nowUtc().toIso8601String()),
              ),
            );
      });
      return Ok(insertedCount);
    } catch (e, st) {
      return Err(StorageFailure(detail: e.toString(), cause: st));
    }
  }
}
