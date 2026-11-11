import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/prices/domain/store/cnpj.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/data/store/sqlite_store_repository.dart';

void main() {
  late db.AppDatabase database;
  late SqliteStoreRepository repo;

  setUp(() {
    database = db.AppDatabase.memory();
    repo = SqliteStoreRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SqliteStoreRepository', () {
    final now = DateTime.utc(2026, 9, 25);

    test('salva e busca loja por ID', () async {
      final store = Store(
        id: 'st-1',
        name: 'Mercado do Zé',
        address: 'Rua A',
        createdAt: now,
        updatedAt: now,
      );

      final saveRes = await repo.save(store);
      expect(saveRes.isOk, isTrue);

      final findRes = await repo.findById(store.id);
      expect(findRes.isOk, isTrue);

      final found = findRes.valueOrNull!;
      expect(found.id, store.id);
      expect(found.name, 'Mercado do Zé');
      expect(found.address, 'Rua A');
      expect(found.cnpj, isNull);
    });

    test('saves store with valid CNPJ', () async {
      final cnpj = Cnpj.create('11.222.333/0001-81').valueOrNull!;
      final store = Store(
        id: 'st-2',
        name: 'Supermercado',
        cnpj: cnpj,
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(store);

      final findRes = await repo.findByCnpj('11222333000181');
      expect(findRes.isOk, isTrue);
      expect(findRes.valueOrNull!.cnpj!.value, '11222333000181');
    });

    test(
      'returns StorageFailure when saving store with duplicate CNPJ',
      () async {
        final cnpj = Cnpj.create('11.222.333/0001-81').valueOrNull!;
        final store1 = Store(
          id: 'st-3',
          name: 'Loja 1',
          cnpj: cnpj,
          createdAt: now,
          updatedAt: now,
        );
        final store2 = Store(
          id: 'st-4',
          name: 'Loja 2',
          cnpj: cnpj,
          createdAt: now,
          updatedAt: now,
        );

        await repo.save(store1);
        final res = await repo.save(store2);

        expect(res.isErr, isTrue);
        expect(res.failureOrNull, isA<StorageFailure>());
      },
    );

    test('lists stores in alphabetical order', () async {
      final store1 = Store(
        id: 'st-5',
        name: 'Zebra Market',
        createdAt: now,
        updatedAt: now,
      );
      final store2 = Store(
        id: 'st-6',
        name: 'Apple Store',
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(store1);
      await repo.save(store2);

      final res = await repo.listAll();
      expect(res.isOk, isTrue);

      final list = res.valueOrNull!;
      expect(list.length, 2);
      expect(list[0].name, 'Apple Store');
      expect(list[1].name, 'Zebra Market');
    });
  });
}
