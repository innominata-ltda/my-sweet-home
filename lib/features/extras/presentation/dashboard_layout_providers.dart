import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/features/extras/data/dashboard_layout_repository_provider.dart';
import 'package:my_sweet_home/features/extras/presentation/dashboard_layout_controller.dart';

export 'package:my_sweet_home/features/extras/data/dashboard_layout_repository_provider.dart';

final dashboardLayoutControllerProvider = Provider<DashboardLayoutController>((
  ref,
) {
  final repository = ref.watch(dashboardLayoutRepositoryProvider);
  final controller = DashboardLayoutController(repository: repository);
  ref.onDispose(controller.dispose);
  return controller;
});
