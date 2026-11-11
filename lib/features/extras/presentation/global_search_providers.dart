import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/features/extras/data/global_search_repository_provider.dart';
import 'package:my_sweet_home/features/extras/presentation/global_search_controller.dart';

final globalSearchControllerProvider = Provider<GlobalSearchController>((ref) {
  final repository = ref.watch(globalSearchRepositoryProvider);
  final limits = ref.watch(securityLimitsProvider);
  final controller = GlobalSearchController(
    repository,
    debounce: limits.searchDebounce,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
