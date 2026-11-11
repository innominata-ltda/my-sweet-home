import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';

final purchasesListProvider = FutureProvider.autoDispose<List<Purchase>>((
  ref,
) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  final res = await repo.getAll();
  return res.fold((purchases) => purchases, (failure) => <Purchase>[]);
});
