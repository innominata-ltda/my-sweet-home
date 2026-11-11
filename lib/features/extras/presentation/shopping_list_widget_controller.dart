// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/repositories/shopping_list_repository.dart';

class ShoppingListWidgetSummary {
  final ShoppingList list;
  final int totalItems;
  final int pendingItems;

  const ShoppingListWidgetSummary({
    required this.list,
    required this.totalItems,
    required this.pendingItems,
  });
}

sealed class ShoppingListWidgetState {}

class ShoppingListWidgetLoading extends ShoppingListWidgetState {}

class ShoppingListWidgetSuccess extends ShoppingListWidgetState {
  final List<ShoppingListWidgetSummary> lists;

  ShoppingListWidgetSuccess({required this.lists});

  bool get isEmpty => lists.isEmpty;
  int get count => lists.length;
}

class ShoppingListWidgetError extends ShoppingListWidgetState {
  final Failure failure;

  ShoppingListWidgetError(this.failure);
}

/// Controller para o widget de listas de compras (RF-102).
class ShoppingListWidgetController
    extends ValueNotifier<ShoppingListWidgetState> {
  ShoppingListWidgetController({
    required ShoppingListRepository shoppingListRepository,
  }) : _shoppingListRepository = shoppingListRepository,
       super(ShoppingListWidgetLoading()) {
    unawaited(load());
  }

  final ShoppingListRepository _shoppingListRepository;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  set value(ShoppingListWidgetState newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  Future<void> load() async {
    value = ShoppingListWidgetLoading();

    final result = await _shoppingListRepository.getAll();
    if (result is Err) {
      value = ShoppingListWidgetError((result as Err).failure);
      return;
    }

    final allLists = (result as Ok<List<ShoppingList>, Failure>).value;
    final activeLists = allLists.where((l) => !l.isArchived).toList();

    final summaries = activeLists.map((list) {
      final total = list.items.length;
      final pending = list.items.where((item) => !item.isBought).length;
      return ShoppingListWidgetSummary(
        list: list,
        totalItems: total,
        pendingItems: pending,
      );
    }).toList();

    value = ShoppingListWidgetSuccess(lists: summaries);
  }
}
