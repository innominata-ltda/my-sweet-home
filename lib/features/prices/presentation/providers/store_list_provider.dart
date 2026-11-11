import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

part 'store_list_provider.g.dart';

@riverpod
Future<List<Store>> storeList(Ref ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  final result = await repo.listAll();
  return result.valueOrNull ?? [];
}
