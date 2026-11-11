import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/seed_loader.dart';

import '../fakes/fake_clock.dart';
import '../fakes/sequential_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SequentialIdGenerator idGen;
  late FakeClock clock;
  late SeedLoader loader;

  setUp(() {
    rootBundle.evict('assets/seed/synonyms.json');
    db = AppDatabase.memory();
    idGen = SequentialIdGenerator(prefix: 'seed');
    clock = FakeClock(DateTime.utc(2026, 10, 14, 12, 0));
    loader = SeedLoader(db, idGen, clock);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (
      ByteData? message,
    ) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (key == 'assets/seed/synonyms.json') {
        final bytes = File('assets/seed/synonyms.json').readAsBytesSync();
        return ByteData.sublistView(bytes);
      }
      return null;
    });
  });

  tearDown(() async {
    rootBundle.evict('assets/seed/synonyms.json');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', null);
    await db.close();
  });

  test('loadIfNeeded populates database when setting is absent', () async {
    final result = await loader.loadIfNeeded();
    expect(result, isA<Ok<void, Failure>>());

    // Verify categories seeded
    final categories = await db.select(db.categories).get();
    expect(categories, isNotEmpty);
    expect(categories.any((c) => c.id == 'cat_housing'), isTrue);

    // Verify default shopping list created
    final lists = await db.select(db.shoppingLists).get();
    expect(lists.any((l) => l.id == 'default'), isTrue);

    // Verify products and aliases seeded (at least 120 product groups)
    final products = await db.select(db.products).get();
    expect(products.length, greaterThanOrEqualTo(120));
    expect(products.any((p) => p.canonicalName == 'Mandioca'), isTrue);
    final aliases = await db.select(db.productAliases).get();
    expect(aliases, isNotEmpty);
    expect(aliases.any((a) => a.alias == 'Macaxeira'), isTrue);
    expect(aliases.any((a) => a.alias == 'Aipim'), isTrue);

    // Verify seed_version setting is '1'
    final setting = await (db.select(
      db.settings,
    )..where((tbl) => tbl.key.equals('seed_version'))).getSingleOrNull();
    expect(setting?.value, '1');
  });

  test('loadIfNeeded returns early when seed_version is already 1', () async {
    // Seed once
    final firstResult = await loader.loadIfNeeded();
    expect(firstResult, isA<Ok<void, Failure>>());

    // Call second time
    final secondResult = await loader.loadIfNeeded();
    expect(secondResult, isA<Ok<void, Failure>>());
  });

  test('loadIfNeeded upgrades catalog when seed_version is 1 but seed_catalog_version is absent (RN-029)', () async {
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'seed_version', value: '1'));

    final result = await loader.loadIfNeeded();
    expect(result, isA<Ok<void, Failure>>());

    final products = await db.select(db.products).get();
    expect(products.length, greaterThanOrEqualTo(120));
    expect(products.any((p) => p.canonicalName == 'Mandioca'), isTrue);
  });

  test(
    'loadIfNeeded upgrades catalog when seed_catalog_version is outdated',
    () async {
      await db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: 'seed_version', value: '1'));
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(key: 'seed_catalog_version', value: '0'),
          );

      final result = await loader.loadIfNeeded();
      expect(result, isA<Ok<void, Failure>>());

      final setting = await (db.select(
        db.settings,
      )..where((tbl) => tbl.key.equals('seed_catalog_version'))).getSingle();
      expect(setting.value, SeedLoader.currentCatalogVersion);
    },
  );

  test('loadIfNeeded handles parse failure and returns Err', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (
      ByteData? message,
    ) async {
      return ByteData.sublistView(utf8.encode('{invalid json: true'));
    });

    rootBundle.evict('assets/seed/synonyms.json');
    await db.delete(db.settings).go();
    final result = await loader.loadIfNeeded();
    expect(result, isA<Err<void, Failure>>());
  });

  test(
    'loadIfNeeded handles pre-existing custom alias and seed alias promotion',
    () async {
      final nowIso = clock.nowUtc().toIso8601String();
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_test',
              name: 'Test',
              kind: 'product',
              iconKey: 'cart',
            ),
          );
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'prod_custom',
              categoryId: const Value('cat_test'),
              canonicalName: 'Costela Especial',
              defaultUnit: 'kg',
              createdAt: Value(nowIso),
              updatedAt: Value(nowIso),
            ),
          );
      await db
          .into(db.productAliases)
          .insert(
            ProductAliasesCompanion.insert(
              id: 'alias_user',
              productId: 'prod_custom',
              alias: 'Arroz Branco Agulhinha',
              normalizedAlias: 'arroz branco agulhinha',
              source: 'user',
              createdAt: Value(nowIso),
            ),
          );

      final result = await loader.loadIfNeeded();
      expect(result, isA<Ok<void, Failure>>());

      final aliases = await db.select(db.productAliases).get();
      expect(aliases.any((a) => a.id == 'alias_user'), isTrue);
    },
  );
}
