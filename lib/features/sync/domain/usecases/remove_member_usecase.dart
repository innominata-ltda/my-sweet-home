library;

import 'dart:math' as math;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Use case to remove a device member from household and rotate key.
///
/// 1. Remove o aparelho da lista de membros ativos da casa.
/// 2. Rotaciona a chave AES-256 no armazenamento seguro local.
/// 3. Ensures new batches cannot be read or forged by removed member.
class RemoveMemberUseCase {
  final HouseholdRepository repository;
  final HouseholdKeyStore keyStore;
  final List<int> Function() _keyGenerator;

  RemoveMemberUseCase({
    required this.repository,
    required this.keyStore,
    List<int> Function()? keyGenerator,
  }) : _keyGenerator = keyGenerator ?? _defaultKeyGenerator;

  static List<int> _defaultKeyGenerator() {
    final random = math.Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Remove o membro com identificador [memberId] e rotaciona a chave da casa.
  Future<Result<HouseholdKey, Failure>> execute({
    required String memberId,
  }) async {
    final householdResult = await repository.getHousehold();
    if (householdResult.isErr) {
      return Err(householdResult.failureOrNull!);
    }
    final household = householdResult.valueOrNull;
    if (household == null) {
      return const Err(HouseholdFailure('Nenhuma casa ativa encontrada.'));
    }

    final membersResult = await repository.getMembers();
    if (membersResult.isErr) {
      return Err(membersResult.failureOrNull!);
    }
    final members = membersResult.valueOrNull ?? [];
    final targetMember = members.where((m) => m.id == memberId).firstOrNull;

    if (targetMember == null) {
      return const Err(HouseholdFailure('Membro não encontrado na casa.'));
    }

    if (targetMember.siteId == household.localSiteId) {
      return const Err(
        HouseholdFailure(
          'Para remover este aparelho, use a opção de sair da casa.',
        ),
      );
    }

    // 1. Remove member in repository
    final removeResult = await repository.removeMember(memberId);
    if (removeResult.isErr) {
      return Err(removeResult.failureOrNull!);
    }

    // 2. Rotaciona a chave AES-256 no armazenamento seguro
    final newBytes = _keyGenerator();
    final newKey = HouseholdKey(newBytes);
    final keyResult = await keyStore.write(newKey);
    if (keyResult.isErr) {
      return Err(keyResult.failureOrNull!);
    }

    return Ok(newKey);
  }
}
