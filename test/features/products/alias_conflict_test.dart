import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  late AppDatabase db;
  late ProductDao dao;
  late SequentialIdGenerator idGen;
  late FakeClock clock;

  setUp(() async {
    db = AppDatabase.memory();
    idGen = SequentialIdGenerator();
    clock = FakeClock(DateTime.utc(2026, 9, 23, 10, 0));
    dao = ProductDao(db, idGen, clock);

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat_1',
            name: 'Comida',
            kind: 'product',
            iconKey: 'food',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('CA-3.1: Conflito de apelido com outro produto existente', () async {
    // 1. Criar o produto "Aipim"
    final aipimResult = await dao.create(
      const NewProduct(
        canonicalName: 'Aipim',
        categoryId: 'cat_1',
        defaultUnit: Unit.un,
      ),
    );
    expect(aipimResult.isOk, isTrue);
    final aipim = aipimResult.valueOrNull!;

    // 2. Criar o produto "Mandioca"
    final mandiocaResult = await dao.create(
      const NewProduct(
        canonicalName: 'Mandioca',
        categoryId: 'cat_1',
        defaultUnit: Unit.un,
      ),
    );
    expect(mandiocaResult.isOk, isTrue);
    final mandioca = mandiocaResult.valueOrNull!;

    // 3. Try to add "aipim" to Mandioca
    final result = await dao.addAlias(mandioca.id, 'aipim', AliasSource.user);
    expect(result.isErr, isTrue);

    // O sistema DEVE apresentar o conflito
    final failure = result.failureOrNull;
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure as ValidationFailure).fields['alias'],
      'Este apelido já pertence a outro produto.',
    );

    // 4. Testar checkAliasConflict diretamente
    final conflictResult = await dao.checkAliasConflict('aipim');
    expect(conflictResult.isOk, isTrue);
    final conflict = conflictResult.valueOrNull;
    expect(conflict, isNotNull);
    expect(conflict!.alias, 'aipim');
    expect(conflict.existingProductId, aipim.id);
  });

  test('Adicionar apelido com sucesso', () async {
    final mandiocaResult = await dao.create(
      const NewProduct(
        canonicalName: 'Mandioca',
        categoryId: 'cat_1',
        defaultUnit: Unit.un,
      ),
    );
    final mandioca = mandiocaResult.valueOrNull!;

    final addResult = await dao.addAlias(
      mandioca.id,
      'macaxeira',
      AliasSource.user,
    );
    expect(addResult.isOk, isTrue);

    // Check in database
    final aliases = await db.select(db.productAliases).get();
    expect(aliases.length, 2); // 'Mandioca' and 'macaxeira'
    expect(
      aliases.any((a) => a.alias == 'macaxeira' && a.productId == mandioca.id),
      isTrue,
    );
  });

  test('Remove alias that is not canonical name', () async {
    final mandiocaResult = await dao.create(
      const NewProduct(
        canonicalName: 'Mandioca',
        categoryId: 'cat_1',
        defaultUnit: Unit.un,
      ),
    );
    final mandioca = mandiocaResult.valueOrNull!;

    await dao.addAlias(mandioca.id, 'macaxeira', AliasSource.user);
    final aliasesBefore = await db.select(db.productAliases).get();
    final aliasId = aliasesBefore.firstWhere((a) => a.alias == 'macaxeira').id;

    final removeResult = await dao.removeAlias(aliasId);
    expect(removeResult.isOk, isTrue);

    final aliasesAfter = await db.select(db.productAliases).get();
    expect(aliasesAfter.length, 1);
    expect(aliasesAfter.first.alias, 'Mandioca');
  });

  test('Prevents removing canonical alias', () async {
    await dao.create(
      const NewProduct(
        canonicalName: 'Mandioca',
        categoryId: 'cat_1',
        defaultUnit: Unit.un,
      ),
    );

    final aliasesBefore = await db.select(db.productAliases).get();
    final canonicalAliasId = aliasesBefore
        .firstWhere((a) => a.alias == 'Mandioca')
        .id;

    final removeResult = await dao.removeAlias(canonicalAliasId);
    expect(removeResult.isErr, isTrue);
    final failure = removeResult.failureOrNull;
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure as ValidationFailure).fields['alias'],
      'Não é possível remover o apelido principal do produto.',
    );

    final aliasesAfter = await db.select(db.productAliases).get();
    expect(aliasesAfter.length, 1); // Still there
  });
}
