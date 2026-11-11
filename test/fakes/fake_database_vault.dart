import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';

/// Fake de [DatabaseVaultPort] para testes (004-testing §3).
final class FakeDatabaseVault implements DatabaseVaultPort {
  FakeDatabaseVault({VaultOpening? initialOpening})
    : openingToReturn = initialOpening ?? VaultKeyUnavailable();

  VaultOpening openingToReturn;
  int openCallCount = 0;
  bool destroyCalled = false;
  bool simulateDestroyFailure = false;

  @override
  Future<VaultOpening> open() async {
    openCallCount++;
    return openingToReturn;
  }

  @override
  Future<Result<void, Failure>> destroy() async {
    destroyCalled = true;
    if (simulateDestroyFailure) {
      return const Err(
        StorageFailure(detail: 'Falha simulada ao destruir vault'),
      );
    }
    return const Ok(null);
  }
}
