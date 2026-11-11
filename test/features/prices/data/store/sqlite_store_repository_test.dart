import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/data/store/sqlite_store_repository.dart';
import 'package:my_sweet_home/features/prices/domain/store/cnpj.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

void main() {
  late db.AppDatabase database;
  late SqliteStoreRepository repository;

  setUp(() {
    database = db.AppDatabase.memory();
    repository = SqliteStoreRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Salva e busca uma loja por ID e CNPJ', () async {
    final cnpj = Cnpj.create('12.345.678/0001-95').valueOrNull!;
    final store = Store(
      id: 'store1',
      name: 'Supermercado Teste',
      cnpj: cnpj,
      address: 'Rua Teste, 123',
      latitude: -23.55052,
      longitude: -46.633308,
      createdAt: DateTime.utc(2026, 9, 25),
      updatedAt: DateTime.utc(2026, 9, 25),
    );

    // Salva
    final saveResult = await repository.save(store);
    expect(saveResult.isOk, isTrue);

    // Busca por ID
    final findByIdResult = await repository.findById('store1');
    expect(findByIdResult.isOk, isTrue);
    final loadedById = findByIdResult.valueOrNull!;
    expect(loadedById.id, 'store1');
    expect(loadedById.name, 'Supermercado Teste');
    expect(loadedById.cnpj?.value, cnpj.value);
    expect(loadedById.createdAt, DateTime.utc(2026, 9, 25));

    // Busca por CNPJ
    final findByCnpjResult = await repository.findByCnpj(cnpj.value);
    expect(findByCnpjResult.isOk, isTrue);
    final loadedByCnpj = findByCnpjResult.valueOrNull!;
    expect(loadedByCnpj.id, 'store1');
  });

  test('Lista todas as lojas ordenadas por nome', () async {
    final store1 = Store(
      id: 'store1',
      name: 'Zaffari',
      createdAt: DateTime.utc(2026, 9, 25),
      updatedAt: DateTime.utc(2026, 9, 25),
    );
    final store2 = Store(
      id: 'store2',
      name: 'Atacadão',
      createdAt: DateTime.utc(2026, 9, 25),
      updatedAt: DateTime.utc(2026, 9, 25),
    );

    await repository.save(store1);
    await repository.save(store2);

    final listResult = await repository.listAll();
    expect(listResult.isOk, isTrue);

    final stores = listResult.valueOrNull!;
    expect(stores, hasLength(2));
    expect(stores[0].name, 'Atacadão');
    expect(stores[1].name, 'Zaffari');
  });

  test('Error when saving store with duplicate CNPJ', () async {
    final cnpj = Cnpj.create('12.345.678/0001-95').valueOrNull!;
    final store1 = Store(
      id: 'store1',
      name: 'Loja 1',
      cnpj: cnpj,
      createdAt: DateTime.utc(2026, 9, 25),
      updatedAt: DateTime.utc(2026, 9, 25),
    );
    final store2 = Store(
      id: 'store2',
      name: 'Loja 2',
      cnpj: cnpj,
      createdAt: DateTime.utc(2026, 9, 25),
      updatedAt: DateTime.utc(2026, 9, 25),
    );

    await repository.save(store1);
    final saveResult2 = await repository.save(store2);

    expect(saveResult2.isErr, isTrue);
    expect(
      (saveResult2.failureOrNull as StorageFailure).detail,
      contains('CNPJ já cadastrado'),
    );
  });
}
