library;

import 'package:my_sweet_home/core/result/result.dart';

/// Port for safety backup export prior to joining a household (RN-314).
abstract interface class HouseholdBackupPort {
  /// Performs automatic prior safety export.
  Future<Result<void, Failure>> exportBackup();
}
