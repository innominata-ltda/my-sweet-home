import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchase_registration_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchase_registration_state.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/widgets/create_product_dialog.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';

class PurchaseRegistrationPage extends ConsumerStatefulWidget {
  const PurchaseRegistrationPage({super.key, this.initialItems});

  final List<InitialPurchaseItemDraft>? initialItems;

  @override
  ConsumerState<PurchaseRegistrationPage> createState() =>
      _PurchaseRegistrationPageState();
}

class _PurchaseRegistrationPageState
    extends ConsumerState<PurchaseRegistrationPage> {
  bool _initializedItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShoppingItemsIfNeeded();
    });
  }

  void _initShoppingItemsIfNeeded() async {
    if (_initializedItems) return;
    final items = widget.initialItems;
    if (items != null && items.isNotEmpty) {
      _initializedItems = true;
      final products = await ref.read(productListProvider.future);
      ref
          .read(purchaseRegistrationProvider.notifier)
          .loadInitialItems(items, products);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRegistrationProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen(purchaseRegistrationProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(purchaseRegistrationProvider.notifier).clearError();
      }
      if (prev?.isSaving == true && !next.isSaving && next.error == null) {
        // Sucesso
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseNew),
        actions: [
          if (state.isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Semantics(
              label: 'Salvar compra',
              button: true,
              child: IconButton(
                icon: const Icon(AppIcons.check),
                tooltip: 'Salvar compra',
                onPressed: state.isValid
                    ? () =>
                          ref.read(purchaseRegistrationProvider.notifier).save()
                    : null,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StoreSelector(
              selectedStore: state.store,
              onChanged: (store) {
                if (store != null) {
                  ref
                      .read(purchaseRegistrationProvider.notifier)
                      .setStore(store);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('${l10n.purchaseDate} *'),
              subtitle: Text(state.date.toLocal().toString().split(' ')[0]),
              trailing: const Icon(AppIcons.calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.date,
                  firstDate: DateTime(2000),
                  lastDate: const SystemClock().nowLocal().add(
                    const Duration(days: 365),
                  ),
                );
                if (date != null) {
                  ref.read(purchaseRegistrationProvider.notifier).setDate(date);
                }
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            Text(
              l10n.purchaseItemsSection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...state.items.map((item) => _DraftItemCard(item: item)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.add),
              label: Text(l10n.purchaseAddItem),
              onPressed: () {
                ref.read(purchaseRegistrationProvider.notifier).addEmptyItem();
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            _TotalsSection(state: state, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _StoreSelector extends ConsumerWidget {
  const _StoreSelector({required this.selectedStore, required this.onChanged});

  final Store? selectedStore;
  final ValueChanged<Store?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeListProvider);
    final l10n = AppLocalizations.of(context);

    return storesAsync.when(
      data: (stores) {
        if (stores.isEmpty) {
          return Text(l10n.purchaseNoStores);
        }
        final matchedStore = stores
            .where((s) => s.id == selectedStore?.id)
            .firstOrNull;
        return DropdownButtonFormField<Store>(
          key: ValueKey(matchedStore?.id),
          isExpanded: true,
          decoration: InputDecoration(labelText: '${l10n.storeTitle} *'),
          initialValue: matchedStore,
          items: stores
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text(l10n.purchaseLoadStoresError(err.toString())),
    );
  }
}

class _DraftItemCard extends ConsumerWidget {
  const _DraftItemCard({required this.item});
  final DraftPurchaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: productsAsync.when(
                    data: (products) {
                      final matchedProduct = products
                          .where((p) => p.id == item.product?.id)
                          .firstOrNull;
                      return DropdownButtonFormField<Product>(
                        key: ValueKey(matchedProduct?.id),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: '${l10n.purchaseProductLabel} *',
                        ),
                        initialValue: matchedProduct,
                        items: products
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.canonicalName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (p) {
                          if (p != null) {
                            ref
                                .read(purchaseRegistrationProvider.notifier)
                                .updateItem(
                                  item.copyWith(
                                    product: p,
                                    quantity: Quantity(1000, p.defaultUnit),
                                  ),
                                );
                          }
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text(l10n.purchaseLoadProductsError),
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.add),
                  tooltip: 'Novo produto',
                  onPressed: () async {
                    final created = await showCreateProductDialog(context, ref);
                    if (created != null) {
                      ref
                          .read(purchaseRegistrationProvider.notifier)
                          .updateItem(
                            item.copyWith(
                              product: created,
                              quantity: Quantity(1000, created.defaultUnit),
                            ),
                          );
                    }
                  },
                ),
                Semantics(
                  label: 'Remover item',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      AppIcons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Remover item',
                    onPressed: () {
                      ref
                          .read(purchaseRegistrationProvider.notifier)
                          .removeItem(item.id);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '${l10n.purchaseQuantityLabel} *',
                      suffixText: item.product?.defaultUnit.name ?? '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    initialValue: item.quantity != null
                        ? (item.quantity!.valueMilli / 1000.0).toString()
                        : null,
                    onChanged: (val) {
                      final v = double.tryParse(val.replaceAll(',', '.'));
                      if (v != null && item.product != null) {
                        ref
                            .read(purchaseRegistrationProvider.notifier)
                            .updateItem(
                              item.copyWith(
                                quantity: Quantity(
                                  (v * 1000).round(),
                                  item.product!.defaultUnit,
                                ),
                              ),
                            );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '${l10n.purchaseTotalPriceLabel} *',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val.replaceAll(',', '.'));
                      if (v != null) {
                        final total = Money((v * 100).round());
                        Money? unit;
                        if (item.quantity != null &&
                            item.quantity!.valueMilli > 0) {
                          unit = Money(
                            (total.cents / (item.quantity!.valueMilli / 1000.0))
                                .round(),
                          );
                        }
                        ref
                            .read(purchaseRegistrationProvider.notifier)
                            .updateItem(
                              item.copyWith(totalPrice: total, unitPrice: unit),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsSection extends ConsumerWidget {
  const _TotalsSection({required this.state, required this.l10n});
  final PurchaseRegistrationState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          decoration: InputDecoration(labelText: l10n.purchaseDiscountLabel),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final v = double.tryParse(val.replaceAll(',', '.'));
            if (v != null) {
              ref
                  .read(purchaseRegistrationProvider.notifier)
                  .setDiscountAmount(Money((v * 100).round()));
            }
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            labelText: l10n.purchaseDeclaredTotalLabel,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final v = double.tryParse(val.replaceAll(',', '.'));
            if (v != null) {
              ref
                  .read(purchaseRegistrationProvider.notifier)
                  .setTotalAmount(Money((v * 100).round()));
            }
          },
        ),
        const SizedBox(height: 8),
        Text(l10n.purchaseItemsSum(state.expectedTotal.formatPtBr())),
        if (state.hasDivergence)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              l10n.purchaseTotalMismatch(state.divergence.formatPtBr()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
