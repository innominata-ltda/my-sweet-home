library;

import 'dart:math' as math;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Key rotation service for shared household (RF-126, CA-7.1, T-14).
///
/// Gera uma nova chave AES-256 e substitui a chave anterior no armazenamento seguro,
/// impedindo que membros removidos descriptografem ou cifrem novos lotes.
class KeyRotationService {
  final HouseholdKeyStore keyStore;
  final List<int> Function() _keyGenerator;

  KeyRotationService({
    required this.keyStore,
    List<int> Function()? keyGenerator,
  }) : _keyGenerator = keyGenerator ?? _defaultKeyGenerator;

  static List<int> _defaultKeyGenerator() {
    final random = math.Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Gera e persiste uma nova chave de 256 bits no armazenamento seguro.
  Future<Result<HouseholdKey, Failure>> rotateKey() async {
    final newBytes = _keyGenerator();
    final newKey = HouseholdKey(newBytes);
    final writeResult = await keyStore.write(newKey);
    if (writeResult.isErr) {
      return Err(writeResult.failureOrNull!);
    }
    return Ok(newKey);
  }
}
