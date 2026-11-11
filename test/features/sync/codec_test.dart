import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/sync_batch_codec_impl.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HouseholdKey keyA;
  late HouseholdKey keyB;
  late SyncBatchCodecImpl codec;

  setUp(() {
    // Chaves de 256 bits (32 bytes)
    keyA = HouseholdKey(Uint8List.fromList(List.generate(32, (i) => i + 1)));
    keyB = HouseholdKey(Uint8List.fromList(List.generate(32, (i) => i + 100)));
    codec = SyncBatchCodecImpl();
  });

  group('SyncBatchCodecImpl — Cifragem AES-256-GCM e Autenticidade (ADR-0007, RN-302, CA-4.2)', () {
    test('cifra e decifra lote perfeitamente (round-trip)', () async {
      final hlc = Hlc.parse('2026-10-22T12:00:00.000Z:00001:device-a');
      final batch = SyncBatch(
        householdId: 'hh-uuid-1234',
        fromSiteId: 'device-a',
        senderVector: VersionVector({'device-a': hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-1',
            column: 'canonical_name',
            value: 'Arroz Agulhinha',
            hlc: hlc,
          ),
          ColumnVersion(
            table: 'products',
            rowId: 'prod-1',
            column: 'default_unit',
            value: 'kg',
            hlc: hlc,
          ),
        ],
        purged: [
          RowTombstone(
            id: 'tb-1',
            table: 'stores',
            rowId: 'store-old',
            hlc: hlc,
            purgedAt: '2026-10-22T12:00:00.000Z',
          ),
        ],
      );

      final sealResult = await codec.seal(batch, keyA);
      expect(sealResult.isOk, isTrue);

      final sealedBytes = sealResult.valueOrNull!;
      expect(sealedBytes, isNotEmpty);

      // Encrypted payload does not contain product name in plaintext
      expect(
        utf8.decode(sealedBytes, allowMalformed: true),
        isNot(contains('Arroz Agulhinha')),
      );

      final openResult = await codec.open(sealedBytes, keyA);
      expect(openResult.isOk, isTrue);

      final openedBatch = openResult.valueOrNull!;
      expect(openedBatch.householdId, equals(batch.householdId));
      expect(openedBatch.fromSiteId, equals(batch.fromSiteId));
      expect(openedBatch.changes, hasLength(2));
      expect(openedBatch.changes.first.value, equals('Arroz Agulhinha'));
      expect(openedBatch.purged, hasLength(1));
      expect(openedBatch.purged.first.rowId, equals('store-old'));
    });

    test('CA-4.2 — Pacote gerado por outra casa (outra chave) falha com IntegrityFailure', () async {
      final hlc = Hlc.parse('2026-10-22T12:00:00.000Z:00001:device-a');
      final batch = SyncBatch(
        householdId: 'hh-casa-a',
        fromSiteId: 'device-a',
        senderVector: VersionVector({'device-a': hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-1',
            column: 'canonical_name',
            value: 'Feijão',
            hlc: hlc,
          ),
        ],
      );

      // Cifrado com a chave da casa A
      final sealed = (await codec.seal(batch, keyA)).valueOrNull!;

      // Household B attempts to open with its own key
      final openResult = await codec.open(sealed, keyB);

      expect(openResult.isErr, isTrue);
      expect(openResult.failureOrNull, isA<IntegrityFailure>());
    });

    test('CA-4.2 — Pacote adulterado em 1 byte no ciphertext falha com IntegrityFailure', () async {
      final hlc = Hlc.parse('2026-10-22T12:00:00.000Z:00001:device-a');
      final batch = SyncBatch(
        householdId: 'hh-casa-a',
        fromSiteId: 'device-a',
        senderVector: VersionVector({'device-a': hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-1',
            column: 'canonical_name',
            value: 'Café',
            hlc: hlc,
          ),
        ],
      );

      final sealed = (await codec.seal(batch, keyA)).valueOrNull!;

      // Adulterar envelope decodificando e invertendo 1 caractere no ciphertext
      final envelopeJson = utf8.decode(sealed);
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
      final cipherText = envelope['ciphertext'] as String;

      // Inverte primeiro caractere do ciphertext
      final tamperedCipher =
          (cipherText[0] == 'A' ? 'B' : 'A') + cipherText.substring(1);
      envelope['ciphertext'] = tamperedCipher;

      final tamperedBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(envelope)),
      );

      final openResult = await codec.open(tamperedBytes, keyA);
      expect(openResult.isErr, isTrue);
      expect(openResult.failureOrNull, isA<IntegrityFailure>());
    });

    test('random byte corruption returns IntegrityFailure without throwing exception', () async {
      final garbage = Uint8List.fromList([0, 1, 2, 3, 255, 254, 253]);
      final openResult = await codec.open(garbage, keyA);

      expect(openResult.isErr, isTrue);
      expect(openResult.failureOrNull, isA<IntegrityFailure>());
    });
  });

  group('CA-5.8 / RN-329 — Protocol version checked', () {
    test('unsupported protocolVersion returns IncompatibleProtocolFailure with user message', () async {
      final hlc = Hlc.parse('2026-10-22T12:00:00.000Z:00001:device-v2');

      // Batch generated with future protocol version (protocolVersion = 2)
      final batchV2 = SyncBatch(
        protocolVersion: 2,
        householdId: 'hh-casa-a',
        fromSiteId: 'device-v2',
        senderVector: VersionVector({'device-v2': hlc}),
        changes: [
          ColumnVersion(
            table: 'products',
            rowId: 'prod-v2',
            column: 'canonical_name',
            value: 'Açúcar Orgânico',
            hlc: hlc,
          ),
        ],
      );

      // Codec v2 cria o pacote
      final codecFuture = SyncBatchCodecImpl(supportedProtocolVersion: 2);
      final sealedBytes = (await codecFuture.seal(batchV2, keyA)).valueOrNull!;

      // Codec atual do app (v1) tenta abrir o pacote
      final currentCodec = SyncBatchCodecImpl(supportedProtocolVersion: 1);
      final openResult = await currentCodec.open(sealedBytes, keyA);

      expect(openResult.isErr, isTrue);
      final failure = openResult.failureOrNull;
      expect(failure, isA<IncompatibleProtocolFailure>());

      final protoFailure = failure as IncompatibleProtocolFailure;
      expect(protoFailure.batchVersion, equals(2));
      expect(protoFailure.supportedVersion, equals(1));
      expect(
        protoFailure.message.toLowerCase(),
        contains('atualize o app para sincronizar com a casa'),
      );
    });
  });
}
