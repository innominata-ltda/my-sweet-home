import 'dart:math' as math;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Use case to create a new shared household.
///
/// Registra o consentimento `household_sync`, gera a chave AES-256 no armazenamento
/// seguro, cadastra o aparelho como primeiro membro e executa o backfill inicial.
class CreateHouseholdUseCase {
  final HouseholdRepository repository;
  final List<int> Function() _keyGenerator;

  CreateHouseholdUseCase({
    required this.repository,
    List<int> Function()? keyGenerator,
  }) : _keyGenerator = keyGenerator ?? _defaultKeyGenerator;

  static List<int> _defaultKeyGenerator() {
    final random = math.Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  Future<Result<Household, Failure>> execute({
    required String householdName,
    required String deviceName,
    Set<SyncArea> sharedAreas = const {SyncArea.home, SyncArea.finance},
  }) async {
    final cleanHouseName = householdName.trim();
    if (cleanHouseName.isEmpty) {
      return const Err(HouseholdFailure('O nome da casa não pode ser vazio.'));
    }

    final cleanDeviceName = deviceName.trim();
    if (cleanDeviceName.isEmpty) {
      return const Err(
        HouseholdFailure('O nome do aparelho não pode ser vazio.'),
      );
    }

    if (sharedAreas.isEmpty) {
      return const Err(
        HouseholdFailure('Selecione pelo menos uma área para compartilhar.'),
      );
    }

    final keyBytes = _keyGenerator();
    final key = HouseholdKey(keyBytes);

    return repository.createHousehold(
      name: cleanHouseName,
      deviceName: cleanDeviceName,
      sharedAreas: sharedAreas,
      key: key,
    );
  }
}
