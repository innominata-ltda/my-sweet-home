library;

import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../sync_batch.dart';

/// Port for encryption, authentication and decryption of sync packets and batches (RN-302, RN-309, CA-4.2, CA-5.8).
abstract interface class SyncBatchCodec {
  /// Cifra e autentica o lote com AES-256-GCM usando a chave da casa.
  Future<Result<Uint8List, Failure>> seal(SyncBatch batch, HouseholdKey key);

  /// Validates authenticity, protocol version, and decrypts sync batch.
  Future<Result<SyncBatch, Failure>> open(Uint8List bytes, HouseholdKey key);
}
