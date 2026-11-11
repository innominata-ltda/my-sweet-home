import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/shopping/data/drift_shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/shopping/presentation/providers/shopping_providers.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return DriftShoppingListRepository(
    ref.watch(databaseProvider),
    ref.watch(shoppingItemParserProvider),
    ref.watch(clockProvider),
  );
});
