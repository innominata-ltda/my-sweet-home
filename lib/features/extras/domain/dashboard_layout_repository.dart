import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';

/// Persistence port for customized Dashboard layout (RN-375).
/// Fake required in `test/fakes/fake_dashboard_layout_repository.dart`.
abstract interface class DashboardLayoutRepository {
  /// Loads current Dashboard layout configuration.
  /// If no previous record exists or if corrupted, returns `DashboardLayoutConfig.defaultOrder` (RN-371, RN-375).
  Future<Result<DashboardLayoutConfig, Failure>> load();

  /// Persists layout configuration to local database (RN-375).
  Future<Result<DashboardLayoutConfig, Failure>> save(
    DashboardLayoutConfig config,
  );

  /// Restores configuration to default order and items of the app (RN-371, RN-375).
  Future<Result<DashboardLayoutConfig, Failure>> resetToDefault();
}
