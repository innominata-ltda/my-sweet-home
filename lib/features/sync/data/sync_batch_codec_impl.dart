library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../../core/concurrency/background_runner_port.dart';
import '../../../../core/concurrency/isolate_background_runner_adapter.dart';
import '../../../../core/result/result.dart';
import '../domain/ports/sync_batch_codec.dart';
import '../domain/sync_batch.dart';

/// [SyncBatchCodec] implementation using AES-256-GCM per ADR-0007 / ADR-0010 (RN-302, RN-309).
final class SyncBatchCodecImpl implements SyncBatchCodec {
  final AesGcm _aesGcm;
  final int supportedProtocolVersion;
  final BackgroundRunnerPort _runner;

  SyncBatchCodecImpl({
    AesGcm? aesGcm,
    this.supportedProtocolVersion = SyncBatch.currentProtocolVersion,
    BackgroundRunnerPort? runner,
  }) : _aesGcm = aesGcm ?? AesGcm.with256bits(),
       _runner = runner ?? const IsolateBackgroundRunnerAdapter();

  @override
  Future<Result<Uint8List, Failure>> seal(
    SyncBatch batch,
    HouseholdKey key,
  ) async {
    try {
      final aesGcm = _aesGcm;
      return await _runner.run(() async {
        final jsonString = jsonEncode(batch.toJson());
        final clearText = utf8.encode(jsonString);
        final secretKey = SecretKey(key.bytes);

        final secretBox = await aesGcm.encrypt(clearText, secretKey: secretKey);

        final envelope = <String, dynamic>{
          'format': 'msh_sync_batch',
          'protocol_version': batch.protocolVersion,
          'nonce': base64Encode(secretBox.nonce),
          'ciphertext': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
        };

        final envelopeBytes = utf8.encode(jsonEncode(envelope));
        return Ok(Uint8List.fromList(envelopeBytes));
      });
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao cifrar lote de sincronização: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<SyncBatch, Failure>> open(
    Uint8List bytes,
    HouseholdKey key,
  ) async {
    try {
      final aesGcm = _aesGcm;
      final maxVer = supportedProtocolVersion;
      return await _runner.run(() async {
        final envelopeJson = utf8.decode(bytes);
        final envelope = jsonDecode(envelopeJson);

        if (envelope is! Map<String, dynamic> ||
            envelope['format'] != 'msh_sync_batch') {
          return const Err(
            IntegrityFailure(detail: 'Formato de pacote inválido.'),
          );
        }

        final protocolVersion = envelope['protocol_version'] as int? ?? 1;
        if (protocolVersion > maxVer) {
          return Err(
            IncompatibleProtocolFailure(
              batchVersion: protocolVersion,
              supportedVersion: maxVer,
            ),
          );
        }

        final nonce = base64Decode(envelope['nonce'] as String);
        final cipherText = base64Decode(envelope['ciphertext'] as String);
        final macBytes = base64Decode(envelope['mac'] as String);

        final secretBox = SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        );

        final secretKey = SecretKey(key.bytes);
        final decryptedBytes = await aesGcm.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        final decryptedJson =
            jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
        final batch = SyncBatch.fromJson(decryptedJson);

        if (batch.protocolVersion > maxVer) {
          return Err(
            IncompatibleProtocolFailure(
              batchVersion: batch.protocolVersion,
              supportedVersion: maxVer,
            ),
          );
        }

        return Ok(batch);
      });
    } on SecretBoxAuthenticationError catch (e) {
      return Err(
        IntegrityFailure(
          detail: 'Pacote adulterado ou chave inválida.',
          cause: e,
        ),
      );
    } catch (e) {
      return Err(
        IntegrityFailure(detail: 'Falha ao decifrar pacote: $e', cause: e),
      );
    }
  }
}
