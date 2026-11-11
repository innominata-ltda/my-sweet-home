import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import '../fakes/fake_clock.dart';
import '../fakes/sequential_id_generator.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator idGen;
  late ProductDao dao;

  setUp(() async {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 9, 23, 10, 0));
    idGen = SequentialIdGenerator();
    dao = ProductDao(db, idGen, clock);

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-001',
            name: 'Comida',
            kind: 'product',
            iconKey: 'food',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('CA-5.1: Product search must be <= 100ms with 5,000 products', () async {
    // Gerar 5.000 produtos
    late String targetProductId;
    for (var i = 0; i < 5000; i++) {
      final res = await dao.create(
        NewProduct(
          canonicalName: 'Produto $i',
          categoryId: 'cat-001',
          defaultUnit: Unit.un,
        ),
      );
      if (i == 2500) {
        targetProductId = res.valueOrNull!.id;
      }
    }

    // Add specific alias for search
    await dao.addAlias(
      targetProductId,
      'Apelido Secreto do Produto',
      AliasSource.user,
    );

    // Warm-up query
    await dao.search('Produto');

    // Medir tempo
    final stopwatch = Stopwatch()..start();

    final result = await dao.search('secreto');

    stopwatch.stop();

    expect(result.isOk, isTrue);
    final list = result.valueOrNull!;
    expect(list.length, 1);
    expect(list.first.canonicalName, 'Produto 2500');

    expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(100));
  });
}
