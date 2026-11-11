import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/data/drift_dashboard_layout_repository.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout_repository.dart';

class _InMemoryDashboardLayoutRepository implements DashboardLayoutRepository {
  DashboardLayoutConfig _config = const DashboardLayoutConfig(
    visibleItems: DashboardLayoutConfig.defaultOrder,
  );

  @override
  Future<Result<DashboardLayoutConfig, Failure>> load() async => Ok(_config);

  @override
  Future<Result<DashboardLayoutConfig, Failure>> save(
    DashboardLayoutConfig config,
  ) async {
    _config = config;
    return Ok(config);
  }

  @override
  Future<Result<DashboardLayoutConfig, Failure>> resetToDefault() async {
    _config = const DashboardLayoutConfig(
      visibleItems: DashboardLayoutConfig.defaultOrder,
    );
    return Ok(_config);
  }
}

final dashboardLayoutRepositoryProvider = Provider<DashboardLayoutRepository>((
  ref,
) {
  try {
    final db = ref.watch(databaseProvider);
    return DriftDashboardLayoutRepository(db);
  } catch (_) {
    return _InMemoryDashboardLayoutRepository();
  }
});
