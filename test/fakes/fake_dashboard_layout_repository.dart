import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout_repository.dart';

/// In-memory fake for Dashboard layout repository tests (RN-375).
class FakeDashboardLayoutRepository implements DashboardLayoutRepository {
  FakeDashboardLayoutRepository({DashboardLayoutConfig? initialConfig})
    : _config = initialConfig;

  DashboardLayoutConfig? _config;
  bool shouldFail = false;
  Failure? customFailure;

  @override
  Future<Result<DashboardLayoutConfig, Failure>> load() async {
    if (shouldFail) {
      return Err(
        customFailure ?? const StorageFailure(detail: 'Fake load error'),
      );
    }
    return Ok(
      _config ??
          const DashboardLayoutConfig(
            visibleItems: DashboardLayoutConfig.defaultOrder,
          ),
    );
  }

  @override
  Future<Result<DashboardLayoutConfig, Failure>> save(
    DashboardLayoutConfig config,
  ) async {
    if (shouldFail) {
      return Err(
        customFailure ?? const StorageFailure(detail: 'Fake save error'),
      );
    }
    _config = config;
    return Ok(config);
  }

  @override
  Future<Result<DashboardLayoutConfig, Failure>> resetToDefault() async {
    if (shouldFail) {
      return Err(
        customFailure ?? const StorageFailure(detail: 'Fake reset error'),
      );
    }
    const defaultConfig = DashboardLayoutConfig(
      visibleItems: DashboardLayoutConfig.defaultOrder,
    );
    _config = defaultConfig;
    return const Ok(defaultConfig);
  }
}
