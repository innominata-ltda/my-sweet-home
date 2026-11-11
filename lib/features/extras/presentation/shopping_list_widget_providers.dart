import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:my_sweet_home/features/extras/presentation/shopping_list_widget_controller.dart';

final shoppingListWidgetControllerProvider =
    Provider.family<ShoppingListWidgetController, ShoppingListWidgetParams>((
      ref,
      params,
    ) {
      final controller = ShoppingListWidgetController(
        shoppingListRepository: params.shoppingListRepository,
      );

      try {
        final db = ref.watch(databaseProvider);
        final sub1 = db
            .select(db.shoppingLists)
            .watch()
            .listen((_) => controller.load());
        final sub2 = db
            .select(db.shoppingItems)
            .watch()
            .listen((_) => controller.load());
        ref.onDispose(() {
          sub1.cancel();
          sub2.cancel();
        });
      } catch (_) {}

      ref.onDispose(controller.dispose);
      return controller;
    });

class ShoppingListWidgetParams {
  final ShoppingListRepository shoppingListRepository;
  final Clock? clock;

  const ShoppingListWidgetParams({
    required this.shoppingListRepository,
    this.clock,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListWidgetParams &&
          runtimeType == other.runtimeType &&
          shoppingListRepository == other.shoppingListRepository &&
          clock == other.clock;

  @override
  int get hashCode => shoppingListRepository.hashCode ^ clock.hashCode;
}
