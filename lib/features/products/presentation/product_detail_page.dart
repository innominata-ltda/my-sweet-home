import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/text/normalizer.dart';

import 'package:my_sweet_home/features/products/presentation/providers/product_detail_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final productAsync = ref.watch(productDetailProvider(productId));
    final aliasesAsync = ref.watch(productAliasesProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsTitle),
        actions: [
          if (productAsync.asData?.value != null) ...[
            IconButton(
              icon: const Icon(AppIcons.priceHistory),
              tooltip: 'Acompanhar preços',
              onPressed: () {
                context.push('/compras/historico-precos?productId=$productId');
              },
            ),
            IconButton(
              icon: const Icon(AppIcons.merge),
              tooltip: 'Unir com outro produto',
              onPressed: () => _showMergeDialog(
                context,
                ref,
                productAsync.asData!.value!,
                l10n,
              ),
            ),
          ],
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(child: Text(l10n.productDetailError));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                product.canonicalName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('${l10n.productCategory}: ${product.categoryId}'),
              Text('${l10n.productUnit}: ${product.defaultUnit.name}'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.priceHistory),
                label: const Text('Acompanhar histórico de preços'),
                onPressed: () {
                  context.push(
                    '/compras/historico-precos?productId=$productId',
                  );
                },
              ),
              const Divider(),
              Text(
                l10n.productAliases,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              aliasesAsync.when(
                data: (aliases) {
                  if (aliases.isEmpty) {
                    return Text(l10n.productAliasesEmpty);
                  }
                  final canonicalNormalized = normalizeProductName(
                    product.canonicalName,
                  );
                  return Wrap(
                    spacing: 8,
                    children: aliases.map((alias) {
                      final isDefault =
                          normalizeProductName(alias.alias) ==
                          canonicalNormalized;
                      return InputChip(
                        label: Text(alias.alias),
                        selected: isDefault,
                        onPressed: isDefault
                            ? null
                            : () async {
                                await ref
                                    .read(
                                      productAliasControllerProvider.notifier,
                                    )
                                    .setPreferredName(productId, alias.alias);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '"${alias.alias}" definido como nome padrão de exibição.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        deleteButtonTooltipMessage: l10n.productRemoveAliasA11y(
                          alias.alias,
                        ),
                        onDeleted: isDefault
                            ? null
                            : () async {
                                final action = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.productRemoveAliasConfirm),
                                    content: Text(
                                      'Você pode separar "${alias.alias}" como um produto independente (com seu próprio histórico de preços) ou apenas remover o apelido.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'cancel'),
                                        child: Text(l10n.productCancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'separate'),
                                        child: const Text(
                                          'Separar como outro produto',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'remove'),
                                        child: Text(l10n.productSave),
                                      ),
                                    ],
                                  ),
                                );
                                if (action == 'separate') {
                                  final created = await ref
                                      .read(
                                        productAliasControllerProvider.notifier,
                                      )
                                      .separateAlias(productId, alias.id);
                                  if (context.mounted && created != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '"${created.canonicalName}" separado como um novo produto.',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (action == 'remove') {
                                  await ref
                                      .read(
                                        productAliasControllerProvider.notifier,
                                      )
                                      .removeAlias(productId, alias.id);
                                }
                              },
                      );
                    }).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text(l10n.productDetailError),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(AppIcons.add),
                label: Text(l10n.productAddAlias),
                onPressed: () =>
                    _showAddAliasDialog(context, ref, productId, l10n),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.productDetailError)),
      ),
    );
  }

  void _showAddAliasDialog(
    BuildContext context,
    WidgetRef ref,
    String productId,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.productAddAlias),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '${l10n.productAddAlias} *',
            hintText: l10n.productAliasPlaceholder,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.productCancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(productAliasControllerProvider.notifier)
                    .addAlias(productId, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text(l10n.productSave),
          ),
        ],
      ),
    );
  }

  Future<void> _showMergeDialog(
    BuildContext context,
    WidgetRef ref,
    Product currentProduct,
    AppLocalizations l10n,
  ) async {
    final allProducts = await ref.read(productListProvider.future);
    final candidates = allProducts
        .where((p) => p.id != currentProduct.id)
        .toList();

    if (!context.mounted) return;

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum outro produto disponível para união.'),
        ),
      );
      return;
    }

    final queryCtrl = TextEditingController();

    final targetProduct = await showDialog<Product>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = queryCtrl.text.trim().toLowerCase();
            final normalizedQuery = normalizeProductName(query);
            final filtered = query.isEmpty
                ? candidates
                : candidates.where((p) {
                    if (p.canonicalName.toLowerCase().contains(query)) {
                      return true;
                    }
                    if (normalizedQuery.isNotEmpty &&
                        normalizeProductName(p.canonicalName)
                            .contains(normalizedQuery)) {
                      return true;
                    }
                    return false;
                  }).toList();

            return AlertDialog(
              title: const Text('Unir com outro produto'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: queryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar produto destino',
                        prefixIcon: Icon(AppIcons.search),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nenhum produto encontrado.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (ctx, idx) {
                                final prod = filtered[idx];
                                return ListTile(
                                  title: Text(prod.canonicalName),
                                  subtitle: Text(
                                    '${prod.categoryId} • ${prod.defaultUnit.name}',
                                  ),
                                  onTap: () =>
                                      Navigator.of(dialogCtx).pop(prod),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l10n.productCancel),
                ),
              ],
            );
          },
        );
      },
    );

    if (targetProduct == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('Confirmar união'),
        content: Text(
          'Deseja unir "${currentProduct.canonicalName}" com "${targetProduct.canonicalName}"?\n\n'
          'Todas as compras, itens, preços e sinônimos serão transferidos para "${targetProduct.canonicalName}" e este produto será arquivado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(false),
            child: Text(l10n.productCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(confirmCtx).pop(true),
            child: const Text('Unir produtos'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final receipt = await ref
          .read(productAliasControllerProvider.notifier)
          .mergeProduct(loserId: currentProduct.id, winnerId: targetProduct.id);

      if (receipt != null && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produto unido com "${targetProduct.canonicalName}".',
            ),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                ref
                    .read(productAliasControllerProvider.notifier)
                    .undoMerge(receipt.id, currentProduct.id, targetProduct.id);
              },
            ),
          ),
        );
      }
    }
  }
}
