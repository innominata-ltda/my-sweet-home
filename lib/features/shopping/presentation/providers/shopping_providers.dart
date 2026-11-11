import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/domain/services/estimate_policy.dart';
import 'package:my_sweet_home/features/shopping/domain/services/shopping_item_parser.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/add_shopping_item_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/archive_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/create_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/duplicate_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/get_list_estimate_usecase.dart';
import 'package:my_sweet_home/features/shopping/domain/usecases/toggle_shopping_item_usecase.dart';

import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';

final shoppingItemParserProvider = Provider<ShoppingItemParser>((ref) {
  return const DefaultShoppingItemParser();
});

final estimatePolicyProvider = Provider<EstimatePolicy>((ref) {
  return const DefaultEstimatePolicy();
});

final toggleShoppingItemUseCaseProvider = Provider<ToggleShoppingItemUseCase>((
  ref,
) {
  return ToggleShoppingItemUseCase(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(clockProvider),
  );
});

final addShoppingItemUseCaseProvider = Provider<AddShoppingItemUseCase>((ref) {
  return AddShoppingItemUseCase(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(shoppingItemParserProvider),
  );
});

final getListEstimateUseCaseProvider = Provider<GetListEstimateUseCase>((ref) {
  return GetListEstimateUseCase(
    priceRepository: ref.watch(pricePointRepositoryProvider),
    policy: ref.watch(estimatePolicyProvider),
    clock: ref.watch(clockProvider),
  );
});

final createShoppingListUseCaseProvider = Provider<CreateShoppingListUseCase>((
  ref,
) {
  return CreateShoppingListUseCase(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
});

final duplicateShoppingListUseCaseProvider =
    Provider<DuplicateShoppingListUseCase>((ref) {
      return DuplicateShoppingListUseCase(
        ref.watch(shoppingListRepositoryProvider),
        ref.watch(idGeneratorProvider),
        ref.watch(clockProvider),
      );
    });

final archiveShoppingListUseCaseProvider = Provider<ArchiveShoppingListUseCase>(
  (ref) {
    return ArchiveShoppingListUseCase(
      ref.watch(shoppingListRepositoryProvider),
    );
  },
);

class ShoppingListDetailState {
  const ShoppingListDetailState({
    this.isLoading = false,
    this.list,
    this.estimate,
    this.errorMessage,
  });

  final bool isLoading;
  final ShoppingList? list;
  final ListEstimate? estimate;
  final String? errorMessage;

  ShoppingListDetailState copyWith({
    bool? isLoading,
    ShoppingList? list,
    ListEstimate? estimate,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShoppingListDetailState(
      isLoading: isLoading ?? this.isLoading,
      list: list ?? this.list,
      estimate: estimate ?? this.estimate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ShoppingListDetailNotifier
    extends ValueNotifier<ShoppingListDetailState> {
  ShoppingListDetailNotifier(this.ref, this.listId)
    : super(const ShoppingListDetailState(isLoading: true)) {
    loadList();
  }

  final Ref ref;
  final String listId;

  ShoppingListDetailState get state => value;

  Future<void> retry() => loadList(fallbackOnRetry: true);

  Future<void> loadList({
    bool fallbackOnRetry = false,
    bool silent = false,
  }) async {
    if (!silent) {
      value = value.copyWith(isLoading: true, clearError: true);
    }

    final repo = ref.read(shoppingListRepositoryProvider);
    var result = await repo.getById(listId);

    if (result.isErr && fallbackOnRetry) {
      // T-B01: Se a lista falhar ao recarregar, recupera buscando uma lista existente
      // or provisioning a default list to avoid leaving user stuck in error.
      final allResult = await repo.getAll();
      if (allResult.isOk && allResult.valueOrNull!.isNotEmpty) {
        result = Ok(allResult.valueOrNull!.first);
      } else {
        final fallbackList = ShoppingList(
          id: listId,
          name: 'Lista de Compras',
          createdAt: ref.read(clockProvider).nowUtc(),
        );
        final saveRes = await repo.save(fallbackList);
        if (saveRes.isOk) {
          result = Ok(fallbackList);
        }
      }
    }

    if (result.isErr) {
      value = value.copyWith(
        isLoading: false,
        errorMessage: 'Falha ao carregar lista de compras.',
      );
      return;
    }

    final list = result.valueOrNull!;
    final estimateUseCase = ref.read(getListEstimateUseCaseProvider);
    final estimateResult = await estimateUseCase(list);

    value = ShoppingListDetailState(
      list: list,
      estimate: estimateResult.valueOrNull,
    );
  }

  Future<void> toggleItem({
    required String itemId,
    required bool isBought,
  }) async {
    final currentList = value.list;
    if (currentList == null) return;

    // Optimistic local mark
    final now = ref.read(clockProvider).nowUtc();
    final updatedItems = currentList.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          boughtAt: isBought ? now : null,
          clearBoughtAt: !isBought,
        );
      }
      return item;
    }).toList();

    final updatedList = currentList.copyWith(items: updatedItems);
    value = value.copyWith(list: updatedList);

    final useCase = ref.read(toggleShoppingItemUseCaseProvider);
    final result = await useCase(
      listId: listId,
      itemId: itemId,
      isBought: isBought,
    );

    if (result.isErr) {
      value = value.copyWith(errorMessage: 'Falha ao salvar alteração');
    }
  }

  Future<void> addItem(String rawText, {String? productId}) async {
    if (rawText.trim().isEmpty) return;

    final useCase = ref.read(addShoppingItemUseCaseProvider);
    final result = await useCase(
      listId: listId,
      rawText: rawText,
      productId: productId,
    );

    if (result.isOk) {
      await loadList(silent: true);
    } else {
      value = value.copyWith(errorMessage: 'Falha ao adicionar item');
    }
  }

  Future<List<Product>> searchProducts(String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return const [];

    final parsedName = ref.read(shoppingItemParserProvider).parse(trimmed).name;
    final query = parsedName.trim().isNotEmpty ? parsedName.trim() : trimmed;

    try {
      final productRepo = ref.read(productRepositoryProvider);
      final result = await productRepo.search(query, limit: 5);
      return result.valueOrNull ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> removeItem(String itemId) async {
    final currentList = value.list;
    if (currentList == null) return;

    final updatedItems = currentList.items
        .where((i) => i.id != itemId)
        .toList();
    final updatedList = currentList.copyWith(items: updatedItems);
    value = value.copyWith(list: updatedList);

    final repo = ref.read(shoppingListRepositoryProvider);
    final result = await repo.save(updatedList);
    if (result.isErr) {
      value = value.copyWith(errorMessage: 'Falha ao remover item');
    } else {
      await loadList(silent: true);
    }
  }

  Future<void> clearPurchasedItems() async {
    final currentList = value.list;
    if (currentList == null) return;

    final updatedItems = currentList.items.where((i) => !i.isBought).toList();
    final updatedList = currentList.copyWith(items: updatedItems);
    value = value.copyWith(list: updatedList);

    final repo = ref.read(shoppingListRepositoryProvider);
    final result = await repo.save(updatedList);
    if (result.isErr) {
      value = value.copyWith(errorMessage: 'Falha ao limpar itens concluídos');
    } else {
      await loadList(silent: true);
    }
  }
}

final shoppingListDetailProvider =
    Provider.family<ShoppingListDetailNotifier, String>((ref, listId) {
      final notifier = ShoppingListDetailNotifier(ref, listId);
      ref.onDispose(notifier.dispose);
      return notifier;
    });

final allShoppingListsProvider = FutureProvider<List<ShoppingList>>((
  ref,
) async {
  final repo = ref.watch(shoppingListRepositoryProvider);
  final result = await repo.getAll();
  return result.valueOrNull ?? [];
});
