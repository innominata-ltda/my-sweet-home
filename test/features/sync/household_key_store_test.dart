import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/features/sync/data/secure_household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

import '../../../test/fakes/fake_household_key_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureHouseholdKeyStore', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureHouseholdKeyStore keyStore;
    final testKey = HouseholdKey(List.generate(32, (i) => i));

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      keyStore = SecureHouseholdKeyStore(storage: mockStorage);
    });

    test('returns null when no key stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await keyStore.read();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('saves and reads key correctly', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => testKey.toBase64());

      final writeResult = await keyStore.write(testKey);
      expect(writeResult.isOk, isTrue);

      final readResult = await keyStore.read();
      expect(readResult.isOk, isTrue);
      expect(readResult.valueOrNull, equals(testKey));
    });

    test('apaga chave corretamente', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final wipeResult = await keyStore.wipe();
      expect(wipeResult.isOk, isTrue);
      verify(() => mockStorage.delete(key: SecureHouseholdKeyStore.keyName))
          .called(1);
    });

    test('returns KeyStoreFailure on I/O exception', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('Disk error'));

      final result = await keyStore.read();
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<KeyStoreFailure>());
    });
  });

  group('FakeHouseholdKeyStore', () {
    test('stores, reads and deletes key in memory', () async {
      final fake = FakeHouseholdKeyStore();
      final testKey = HouseholdKey(List.generate(32, (i) => 255 - i));

      expect((await fake.read()).valueOrNull, isNull);

      await fake.write(testKey);
      expect((await fake.read()).valueOrNull, equals(testKey));

      await fake.wipe();
      expect((await fake.read()).valueOrNull, isNull);
    });
  });
}
