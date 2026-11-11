import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_global_search_repository.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/global_search_repository.dart';

final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>((ref) {
  return DriftGlobalSearchRepository(ref.watch(databaseProvider));
});
