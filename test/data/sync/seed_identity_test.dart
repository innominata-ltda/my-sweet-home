import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/seed_loader.dart';
import 'package:my_sweet_home/data/sync/natural_key_merger.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase dbA;
  late AppDatabase dbB;
  late FakeClock clock;
  const merger = NaturalKeyMerger();

  setUp(() {
    rootBundle.evict('assets/seed/synonyms.json');
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 10, 23, 10, 0));

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
    await dbA.close();
    await dbB.close();
  });

  group('T-10 / CA-5.5 — Deterministic identity of catalog seeds', () {
    test(
      'Data A and B installed separately with products base, '
      'when B joins A household, no base product appears duplicated (CA-5.5)',
      () async {
        final loaderA = SeedLoader(
          dbA,
          SequentialIdGenerator(prefix: 'seed_a'),
          clock,
          deterministicIdGen: const UuidV5DeterministicIdGenerator(),
        );

        final loaderB = SeedLoader(
          dbB,
          SequentialIdGenerator(prefix: 'seed_b'),
          clock,
          deterministicIdGen: const UuidV5DeterministicIdGenerator(),
        );

        // 1. Installations A and B load seed independently
        final resA = await loaderA.loadIfNeeded();
        final resB = await loaderB.loadIfNeeded();
        expect(resA.isOk, isTrue);
        expect(resB.isOk, isTrue);

        final productsA = await dbA.select(dbA.products).get();
        final productsB = await dbB.select(dbB.products).get();

        expect(productsA.isNotEmpty, isTrue);
        expect(productsB.length, equals(productsA.length));

        // 2. Base product IDs MUST be identical between installations (deterministic UUIDv5)
        for (var i = 0; i < productsA.length; i++) {
          expect(productsA[i].id, equals(productsB[i].id));
          expect(
            productsA[i].canonicalName,
            equals(productsB[i].canonicalName),
          );
        }

        final aliasesA = await dbA.select(dbA.productAliases).get();
        final aliasesB = await dbB.select(dbB.productAliases).get();
        expect(aliasesA.isNotEmpty, isTrue);
        expect(aliasesB.length, equals(aliasesA.length));

        for (var i = 0; i < aliasesA.length; i++) {
          expect(aliasesA[i].id, equals(aliasesB[i].id));
          expect(aliasesA[i].productId, equals(aliasesB[i].productId));
          expect(
            aliasesA[i].normalizedAlias,
            equals(aliasesB[i].normalizedAlias),
          );
        }

        // 3. On deterministic merge no duplication occurs
        final report = await merger.mergeAll(dbB);
        expect(report.mergedProductsCount, 0);

        final productsAfterMerge = await dbB.select(dbB.products).get();
        expect(productsAfterMerge.length, equals(productsA.length));
      },
    );
  });
}
