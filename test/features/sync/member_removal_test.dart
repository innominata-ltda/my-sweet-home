import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/features/sync/data/key_rotation.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/remove_member_usecase.dart';

import '../../fakes/fake_household_key_store.dart';
import '../../fakes/fake_household_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T-14 / RF-126 / CA-7.1 — Member Removal and Key Rotation', () {
    late FakeHouseholdRepository repository;
    late FakeHouseholdKeyStore keyStore;
    late RemoveMemberUseCase useCase;

    final initialKeyBytes = Uint8List.fromList(List.generate(32, (_) => 1));
    final rotatedKeyBytes = Uint8List.fromList(List.generate(32, (_) => 2));

    final now = DateTime.utc(2026, 10, 23, 10, 0);

    setUp(() async {
      repository = FakeHouseholdRepository(
        initialHousehold: Household(
          id: 'house-1',
          name: 'Nossa Casa',
          localSiteId: 'site-a',
          sharedAreas: const {},
          createdAt: now,
          joinedAt: now,
          active: true,
        ),
        initialMembers: [
          Member(
            id: 'member-a',
            householdId: 'house-1',
            siteId: 'site-a',
            name: 'Aparelho A (Eu)',
            joinedAt: now,
          ),
          Member(
            id: 'member-b',
            householdId: 'house-1',
            siteId: 'site-b',
            name: 'Aparelho B (Colega)',
            joinedAt: now,
          ),
        ],
      );

      keyStore = FakeHouseholdKeyStore(HouseholdKey(initialKeyBytes));

      useCase = RemoveMemberUseCase(
        repository: repository,
        keyStore: keyStore,
        keyGenerator: () => List<int>.from(rotatedKeyBytes),
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test(
      'remover o próprio aparelho é recusado com explicação amigável',
      () async {
        final result = await useCase.execute(memberId: 'member-a');
        expect(result.isErr, isTrue);
        final failure = result.failureOrNull;
        expect(failure, isA<HouseholdFailure>());
        expect(
          (failure! as HouseholdFailure).message,
          contains('sair da casa'),
        );
        final currentKeyRes = await keyStore.read();
        expect(currentKeyRes.valueOrNull!.bytes, equals(initialKeyBytes));
      },
    );

    test('removing non-existent member fails with error', () async {
      final result = await useCase.execute(memberId: 'member-inexistente');
      expect(result.isErr, isTrue);
      final failure = result.failureOrNull;
      expect(failure, isA<HouseholdFailure>());
      expect(
        (failure! as HouseholdFailure).message,
        contains('não encontrado'),
      );
    });

    test('CA-7.1: A removes B, key is rotated and B cannot decrypt new batch from A', () async {
      // 1. A remove B
      final result = await useCase.execute(memberId: 'member-b');
      expect(result.isOk, isTrue);

      final newKey = result.valueOrNull!;
      expect(newKey.bytes, equals(rotatedKeyBytes));
      final currentKeyRes = await keyStore.read();
      expect(currentKeyRes.valueOrNull!.bytes, equals(rotatedKeyBytes));

      // 2. Member B is no longer in active list
      final membersResult = await repository.getMembers();
      expect(membersResult.valueOrNull!.length, 1);
      expect(membersResult.valueOrNull!.first.id, 'member-a');

      // 3. A makes changes and encrypts batch with new key K2
      final codec = SyncBatchCodecImpl();
      final hlc = Hlc.parse('2026-10-23T10:00:00.000Z:00001:site-a');
      final batchFromA = SyncBatch(
        householdId: 'house-1',
        fromSiteId: 'site-a',
        senderVector: VersionVector({'site-a': hlc}),
        changes: [
          ColumnVersion(
            table: 'tasks',
            rowId: 'task-1',
            column: 'title',
            value: 'Comprar pão',
            hlc: hlc,
          ),
        ],
      );

      final encryptedPayloadResult = await codec.seal(batchFromA, newKey);
      expect(encryptedPayloadResult.isOk, isTrue);
      final payloadBytes = encryptedPayloadResult.valueOrNull!;

      // 4. B attempts to decrypt using old key K1 held prior to removal
      final oldKeyOfB = HouseholdKey(initialKeyBytes);
      final decodeAttemptByB = await codec.open(payloadBytes, oldKeyOfB);

      // B is completely unable to read new content (CA-7.1)
      expect(decodeAttemptByB.isErr, isTrue);
      expect(decodeAttemptByB.failureOrNull, isA<IntegrityFailure>());
    });

    test(
      'KeyRotationService isolado gera nova chave e salva no keystore',
      () async {
        final rotationService = KeyRotationService(
          keyStore: keyStore,
          keyGenerator: () => List<int>.from(rotatedKeyBytes),
        );

        final res = await rotationService.rotateKey();
        expect(res.isOk, isTrue);
        expect(res.valueOrNull!.bytes, equals(rotatedKeyBytes));
        final currentKeyRes = await keyStore.read();
        expect(currentKeyRes.valueOrNull!.bytes, equals(rotatedKeyBytes));
      },
    );
  });
}
