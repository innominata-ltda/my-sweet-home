import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/purchases_history_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

class PurchasesHistoryScreen extends ConsumerWidget {
  const PurchasesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    final purchasesAsync = ref.watch(purchasesListProvider);
    final storesAsync = ref.watch(storeListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchasesHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.priceHistory),
            tooltip: l10n.purchasesPriceHistoryTooltip,
            onPressed: () => context.push('/compras/historico-precos'),
          ),
          IconButton(
            icon: const Icon(AppIcons.camera),
            tooltip: l10n.navScanReceipt,
            onPressed: () async {
              await context.push('/ocr');
              ref.invalidate(purchasesListProvider);
            },
          ),
        ],
      ),
      body: purchasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.purchasesLoadError('$err'))),
        data: (purchases) {
          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.shopping,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.purchasesEmptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.purchasesRegisterButton),
                    onPressed: () async {
                      await context.push('/compras/nova');
                      ref.invalidate(purchasesListProvider);
                    },
                  ),
                ],
              ),
            );
          }

          final stores = storesAsync.asData?.value ?? [];
          final storeMap = {for (final s in stores) s.id: s.name};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(purchasesListProvider);
              await ref.read(purchasesListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: purchases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                final storeName =
                    storeMap[purchase.storeId] ??
                    (purchase.storeId.isNotEmpty
                        ? purchase.storeId
                        : 'Estabelecimento');
                final dateStr =
                    '${purchase.date.day.toString().padLeft(2, '0')}/${purchase.date.month.toString().padLeft(2, '0')}/${purchase.date.year}';

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(AppIcons.shopping),
                    ),
                    title: Text(storeName, style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      '$dateStr • ${purchase.items.length} ${purchase.items.length == 1 ? 'item' : 'itens'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          purchase.totalAmount.formatPtBr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Semantics(
                          label: l10n.purchasesDeleteTooltip,
                          button: true,
                          child: IconButton(
                            icon: const Icon(AppIcons.delete),
                            tooltip: l10n.purchasesDeleteTooltip,
                            onPressed: () =>
                                _confirmDelete(context, ref, purchase),
                          ),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _showDetails(context, ref, purchase, storeName),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Semantics(
        label: l10n.purchasesNewTooltip,
        button: true,
        child: FloatingActionButton(
          tooltip: l10n.purchasesNewTooltip,
          onPressed: () async {
            await context.push('/compras/nova');
            ref.invalidate(purchasesListProvider);
          },
          child: const Icon(AppIcons.add),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Purchase purchase) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('pt'));
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.purchasesDeleteDialogTitle),
        content: Text(l10n.purchasesDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final repo = ref.read(purchaseRepositoryProvider);
        final res = await repo.delete(purchase.id);
        if (context.mounted) {
          if (res.isOk) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.purchasesDeleteSuccess)),
            );
            ref.invalidate(purchasesListProvider);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.purchasesDeleteError)));
          }
        }
      }
    });
  }

  void _showDetails(
    BuildContext context,
    WidgetRef ref,
    Purchase purchase,
    String storeName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _PurchaseDetailsSheet(purchase: purchase, storeName: storeName),
    );
  }
}

class _PurchaseDetailsSheet extends ConsumerWidget {
  const _PurchaseDetailsSheet({
    required this.purchase,
    required this.storeName,
  });

  final Purchase purchase;
  final String storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productListProvider);
    final products = productsAsync.asData?.value ?? [];
    final productMap = {for (final p in products) p.id: p.canonicalName};

    final dateStr =
        '${purchase.date.day.toString().padLeft(2, '0')}/${purchase.date.month.toString().padLeft(2, '0')}/${purchase.date.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(storeName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            ) ??
                            lookupAppLocalizations(const Locale('pt')))
                        .purchasesTotalLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    purchase.totalAmount.formatPtBr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (purchase.discountAmount.cents > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (Localizations.of<AppLocalizations>(
                                context,
                                AppLocalizations,
                              ) ??
                              lookupAppLocalizations(const Locale('pt')))
                          .purchasesDiscountLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '- ${purchase.discountAmount.formatPtBr()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              Text(
                (Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        ) ??
                        lookupAppLocalizations(const Locale('pt')))
                    .purchasesItemsCount(purchase.items.length),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (purchase.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    (Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            ) ??
                            lookupAppLocalizations(const Locale('pt')))
                        .purchasesNoDetailedItems,
                  ),
                )
              else
                ...purchase.items.map((item) {
                  final canonical = item.productId.isNotEmpty
                      ? productMap[item.productId]
                      : null;
                  final productName = item.rawDescription.isNotEmpty
                      ? item.rawDescription
                      : (canonical ??
                            (item.productId.isNotEmpty
                                ? item.productId
                                : (Localizations.of<AppLocalizations>(
                                            context,
                                            AppLocalizations,
                                          ) ??
                                          lookupAppLocalizations(
                                            const Locale('pt'),
                                          ))
                                      .purchasesProductFallback));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.productId.isNotEmpty &&
                                  canonical != null &&
                                  canonical.toLowerCase() !=
                                      productName.toLowerCase())
                                Text(
                                  canonical,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              Text(
                                '${item.quantity.valueMilli / 1000} ${item.quantity.unit.name} x ${item.unitPrice.formatPtBr()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.productId.isNotEmpty)
                          Semantics(
                            label:
                                (Localizations.of<AppLocalizations>(
                                          context,
                                          AppLocalizations,
                                        ) ??
                                        lookupAppLocalizations(
                                          const Locale('pt'),
                                        ))
                                    .purchasesItemPriceHistoryTooltip,
                            button: true,
                            child: IconButton(
                              icon: const Icon(AppIcons.priceHistory, size: 20),
                              tooltip:
                                  (Localizations.of<AppLocalizations>(
                                            context,
                                            AppLocalizations,
                                          ) ??
                                          lookupAppLocalizations(
                                            const Locale('pt'),
                                          ))
                                      .purchasesItemPriceHistoryTooltip,
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push(
                                  '/compras/historico-precos?productId=${item.productId}',
                                );
                              },
                            ),
                          ),
                        Text(
                          item.totalPrice.formatPtBr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
