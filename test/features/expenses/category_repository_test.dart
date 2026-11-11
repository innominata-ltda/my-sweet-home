import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/expenses/data/repositories/drift_category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

void main() {
  late db.AppDatabase database;
  late DriftCategoryRepository repository;
  late Clock clock;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    clock = SystemClock();
    repository = DriftCategoryRepository(database, clock);
  });

  tearDown(() async {
    await database.close();
  });

  test('ensureDefaults inserts 10 categories and does not run twice', () async {
    final result = await repository.ensureDefaults();
    expect(result, isA<Ok<int, Failure>>());
    expect((result as Ok<int, Failure>).value, 10);

    final catsResult = await repository.all();
    expect((catsResult as Ok<List<Category>, Failure>).value.length, 10);

    final result2 = await repository.ensureDefaults();
    expect((result2 as Ok<int, Failure>).value, 0); // idempotente
  });

  test('upsert creates or updates category', () async {
    final cat = const Category(
      id: CategoryId('my_cat'),
      name: 'Custom',
      kind: CategoryKind.expense,
      iconKey: 'catOther',
      isSystem: false,
    );
    final result = await repository.upsert(cat);
    expect(result, isA<Ok<Category, Failure>>());

    final all = (await repository.all() as Ok<List<Category>, Failure>).value;
    expect(all.length, 1);
    expect(all.first.name, 'Custom');

    // Update
    final catUpdated = const Category(
      id: CategoryId('my_cat'),
      name: 'Custom updated',
      kind: CategoryKind.expense,
      iconKey: 'catOther',
      isSystem: false,
    );
    await repository.upsert(catUpdated);

    final allUpdated =
        (await repository.all() as Ok<List<Category>, Failure>).value;
    expect(allUpdated.first.name, 'Custom updated');
  });

  test('deactivate deletes category if empty', () async {
    final cat = const Category(
      id: CategoryId('my_cat'),
      name: 'Custom',
      kind: CategoryKind.expense,
      iconKey: 'catOther',
      isSystem: false,
    );
    await repository.upsert(cat);

    final delResult = await repository.deactivate(cat.id);
    expect(delResult, isA<Ok<void, Failure>>());

    final all = (await repository.all() as Ok<List<Category>, Failure>).value;
    expect(all, isEmpty);
  });

  test('deactivate fails if category is used', () async {
    final cat = const Category(
      id: CategoryId('my_cat'),
      name: 'Custom',
      kind: CategoryKind.expense,
      iconKey: 'catOther',
      isSystem: false,
    );
    await repository.upsert(cat);

    // Insert expense
    await database
        .into(database.expenses)
        .insert(
          db.ExpensesCompanion.insert(
            id: 'exp1',
            categoryId: const Value('my_cat'),
            amountCents: 1000,
            occurredOn: '2026-09-23',
          ),
        );

    final delResult = await repository.deactivate(cat.id);
    expect(delResult, isA<Err<void, Failure>>());

    final all = (await repository.all() as Ok<List<Category>, Failure>).value;
    expect(all.length, 1);
  });
}
