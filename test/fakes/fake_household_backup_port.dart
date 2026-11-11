library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_backup_port.dart';

/// Fake of [HouseholdBackupPort] for unit and widget tests.
class FakeHouseholdBackupPort implements HouseholdBackupPort {
  int exportCallCount = 0;
  bool shouldFail = false;

  @override
  Future<Result<void, Failure>> exportBackup() async {
    exportCallCount++;
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Disk error'));
    }
    return const Ok(null);
  }
}
