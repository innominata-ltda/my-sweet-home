import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/extras/data/checklist_repository_provider.dart';
import 'package:my_sweet_home/features/extras/domain/models/checklist_item.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/checklist_repository.dart';
import 'package:my_sweet_home/features/extras/domain/usecases/convert_checklist_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';

final convertChecklistToShoppingListUseCaseProvider =
    Provider<ConvertChecklistToShoppingListUseCase>((ref) {
      final shoppingListRepo = ref.watch(shoppingListRepositoryProvider);
      final idGen = ref.watch(idGeneratorProvider);
      final clock = ref.watch(clockProvider);
      return ConvertChecklistToShoppingListUseCase(
        shoppingListRepository: shoppingListRepo,
        idGenerator: idGen,
        clock: clock,
      );
    });

class ChecklistState {
  const ChecklistState({
    this.isLoading = false,
    this.items = const [],
    this.selectedCategory,
    this.failure,
  });

  final bool isLoading;
  final List<ChecklistItem> items;
  final String? selectedCategory;
  final Failure? failure;

  List<ChecklistItem> get filteredItems {
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      return items;
    }
    return items.where((i) => i.roomCategory == selectedCategory).toList();
  }

  List<String> get roomCategories {
    final set = items.map((i) => i.roomCategory).toSet();
    final list = set.toList()..sort();
    return list;
  }

  int get totalCount => items.length;
  int get markedCount => items.where((i) => i.isMarked).length;
  int get unmarkedCount => totalCount - markedCount;
  double get progress => totalCount == 0 ? 0.0 : markedCount / totalCount;

  int get filteredTotalCount => filteredItems.length;
  int get filteredMarkedCount => filteredItems.where((i) => i.isMarked).length;
  int get filteredUnmarkedCount => filteredTotalCount - filteredMarkedCount;
  double get filteredProgress =>
      filteredTotalCount == 0 ? 0.0 : filteredMarkedCount / filteredTotalCount;

  ChecklistState copyWith({
    bool? isLoading,
    List<ChecklistItem>? items,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ChecklistState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class ChecklistController extends ValueNotifier<ChecklistState> {
  ChecklistController(this._repository, {this._convertToShoppingListUseCase})
    : super(const ChecklistState()) {
    load();
  }

  final ChecklistRepository _repository;
  final ConvertChecklistToShoppingListUseCase? _convertToShoppingListUseCase;

  ChecklistState get state => value;

  Future<void> load() async {
    value = value.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getItems();
    if (result is Ok<List<ChecklistItem>, Failure>) {
      value = value.copyWith(isLoading: false, items: result.value);
    } else if (result is Err<List<ChecklistItem>, Failure>) {
      value = value.copyWith(isLoading: false, failure: result.failure);
    }
  }

  void selectCategory(String? category) {
    if (category == null || category.isEmpty) {
      value = value.copyWith(clearSelectedCategory: true);
    } else {
      value = value.copyWith(selectedCategory: category);
    }
  }

  Future<void> toggleItem(String id) async {
    final result = await _repository.toggleItemMarked(id);
    if (result is Ok<ChecklistItem, Failure>) {
      final updatedItem = result.value;
      final updatedList = value.items.map((i) {
        return i.id == id ? updatedItem : i;
      }).toList();
      value = value.copyWith(items: updatedList);
    } else if (result is Err<ChecklistItem, Failure>) {
      value = value.copyWith(failure: result.failure);
    }
  }

  Future<void> addItem({
    required String roomCategory,
    required String title,
  }) async {
    final result = await _repository.addItem(
      roomCategory: roomCategory,
      title: title,
    );
    if (result is Ok<ChecklistItem, Failure>) {
      final newItem = result.value;
      final updatedList = [...value.items, newItem];
      value = value.copyWith(items: updatedList);
    } else if (result is Err<ChecklistItem, Failure>) {
      value = value.copyWith(failure: result.failure);
    }
  }

  Future<void> updateItemTitle(String id, String newTitle) async {
    final result = await _repository.updateItemTitle(id, newTitle);
    if (result is Ok<ChecklistItem, Failure>) {
      final updatedItem = result.value;
      final updatedList = value.items.map((i) {
        return i.id == id ? updatedItem : i;
      }).toList();
      value = value.copyWith(items: updatedList);
    } else if (result is Err<ChecklistItem, Failure>) {
      value = value.copyWith(failure: result.failure);
    }
  }

  Future<void> deleteItem(String id) async {
    final result = await _repository.deleteItem(id);
    if (result is Ok<void, Failure>) {
      final updatedList = value.items.where((i) => i.id != id).toList();
      value = value.copyWith(items: updatedList);
    } else if (result is Err<void, Failure>) {
      value = value.copyWith(failure: result.failure);
    }
  }

  Future<Result<ShoppingList, Failure>> convertUnmarkedToShoppingList({
    String? listName,
    String? targetListId,
    bool onlyFiltered = false,
  }) async {
    final useCase = _convertToShoppingListUseCase;
    if (useCase == null) {
      const failure = ValidationFailure(
        fields: {'useCase': 'UseCase não fornecido.'},
      );
      value = value.copyWith(failure: failure);
      return const Err(failure);
    }
    final targetItems = onlyFiltered ? state.filteredItems : state.items;
    final result = await useCase.call(
      items: targetItems,
      listName: listName,
      targetListId: targetListId,
    );
    if (result is Err<ShoppingList, Failure>) {
      value = value.copyWith(failure: result.failure);
    }
    return result;
  }
}

final checklistControllerProvider = Provider.autoDispose<ChecklistController>((
  ref,
) {
  final repo = ref.watch(checklistRepositoryProvider);
  final useCase = ref.watch(convertChecklistToShoppingListUseCaseProvider);
  final controller = ChecklistController(
    repo,
    convertToShoppingListUseCase: useCase,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
