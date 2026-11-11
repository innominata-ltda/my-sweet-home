import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/expenses/data/repositories/drift_category_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart'
    as domain;

void main() {
  group('DriftCategoryRepository', () {
    late AppDatabase db;
    late DriftCategoryRepository repo;
    late Clock clock;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      clock = const SystemClock();
      repo = DriftCategoryRepository(db, clock);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'ensureDefaults inserts 10 categories and does not run twice',
      () async {
        final r1 = await repo.ensureDefaults();
        expect(r1.isOk, isTrue);
        expect(r1.valueOrNull, 10);

        final catsResult = await repo.all();
        expect(catsResult.valueOrNull!.length, 10);

        final r2 = await repo.ensureDefaults();
        expect(r2.valueOrNull, 0); // idempotent
      },
    );

    test('upsert creates or updates category', () async {
      final cat = const domain.Category(
        id: domain.CategoryId('my_cat'),
        name: 'Custom',
        kind: domain.CategoryKind.expense,
        iconKey: 'catOther',
        isSystem: false,
      );
      final r1 = await repo.upsert(cat);
      expect(r1.isOk, isTrue);

      final all = await repo.all();
      expect(all.valueOrNull!.length, 1);
      expect(all.valueOrNull!.first.name, 'Custom');

      final catUpdated = const domain.Category(
        id: domain.CategoryId('my_cat'),
        name: 'Custom updated',
        kind: domain.CategoryKind.expense,
        iconKey: 'catOther',
        isSystem: false,
      );
      await repo.upsert(catUpdated);

      final allUpdated = await repo.all();
      expect(allUpdated.valueOrNull!.first.name, 'Custom updated');
    });

    test('deactivate deletes category if not used', () async {
      final cat = const domain.Category(
        id: domain.CategoryId('my_cat'),
        name: 'Custom',
        kind: domain.CategoryKind.expense,
        iconKey: 'catOther',
        isSystem: false,
      );
      await repo.upsert(cat);

      final delResult = await repo.deactivate(cat.id);
      expect(delResult.isOk, isTrue);

      final all = await repo.all();
      expect(all.valueOrNull!, isEmpty);
    });
  });
}
