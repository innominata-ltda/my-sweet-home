import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchase_registration_state.dart';

part 'purchase_registration_provider.g.dart';

@riverpod
class PurchaseRegistration extends _$PurchaseRegistration {
  @override
  PurchaseRegistrationState build() {
    return PurchaseRegistrationState(date: ref.read(clockProvider).nowLocal());
  }

  void loadInitialItems(
    List<InitialPurchaseItemDraft> items,
    List<Product> products,
  ) {
    final drafts = items.map((item) {
      Product? matched;
      if (item.productId != null) {
        matched = products.where((p) => p.id == item.productId).firstOrNull;
      }
      matched ??= products
          .where(
            (p) => p.canonicalName.toLowerCase() == item.name.toLowerCase(),
          )
          .firstOrNull;
      return DraftPurchaseItem(
        id: ref.read(idGeneratorProvider).newId(),
        product: matched,
        quantity:
            item.quantity ??
            (matched != null ? Quantity(1000, matched.defaultUnit) : null),
      );
    }).toList();
    state = state.copyWith(items: drafts);
  }

  void setStore(Store store) {
    state = state.copyWith(store: store);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void addEmptyItem() {
    final id = ref.read(idGeneratorProvider).newId();
    state = state.copyWith(
      items: [
        ...state.items,
        DraftPurchaseItem(id: id),
      ],
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  void updateItem(DraftPurchaseItem item) {
    final index = state.items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final newItems = List<DraftPurchaseItem>.from(state.items);
    newItems[index] = item;

    state = state.copyWith(items: newItems);
  }

  void setTotalAmount(Money total) {
    state = state.copyWith(totalAmount: total);
  }

  void setDiscountAmount(Money discount) {
    state = state.copyWith(discountAmount: discount);
  }

  Future<void> save() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Preencha todos os campos corretamente');
      return;
    }

    state = state.copyWith(isSaving: true);

    final purchaseItems = state.items
        .map(
          (draft) => PurchaseItem(
            id: draft.id,
            productId: draft.product!.id,
            rawDescription: draft.product!.canonicalName,
            quantity: draft.quantity!,
            unitPrice: draft.unitPrice!,
            totalPrice: draft.totalPrice!,
          ),
        )
        .toList();

    final purchaseId = ref.read(idGeneratorProvider).newId();

    final purchase = Purchase(
      id: purchaseId,
      storeId: state.store!.id,
      date: state.date,
      items: purchaseItems,
      totalAmount: state.totalAmount,
      discountAmount: state.discountAmount,
    );

    final repo = ref.read(purchaseRepositoryProvider);
    final result = await repo.save(purchase);

    if (result.isErr) {
      final failure = result.failureOrNull;
      final msg = failure != null
          ? userMessageFor(failure)
          : 'Erro ao salvar compra';
      state = state.copyWith(isSaving: false, error: msg);
    } else {
      state = state.copyWith(isSaving: false);
      // Navigation could pop() using an event or ref.read(routerProvider).pop()
    }
  }

  void clearError() {
    state = state.clearError();
  }
}
