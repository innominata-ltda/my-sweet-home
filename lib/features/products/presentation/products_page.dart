import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/components/app_error_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/products/presentation/widgets/create_product_dialog.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  void _showCreateProductDialog(BuildContext context, WidgetRef ref) async {
    await showCreateProductDialog(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: l10n.productSearchHint,
              onChanged: (value) {
                ref.read(productSearchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),
        ),
      ),
      body: listAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Text(l10n.productEmptyState));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.canonicalName),
                subtitle: Text(
                  '${l10n.productCategory}: ${product.categoryId} | ${l10n.productUnit}: ${product.defaultUnit.name}',
                ),
                trailing: IconButton(
                  icon: const Icon(AppIcons.priceHistory),
                  tooltip: 'Acompanhar preços',
                  onPressed: () {
                    context.push(
                      '/compras/historico-precos?productId=${product.id}',
                    );
                  },
                ),
                onTap: () {
                  context.push('/produtos/${product.id}');
                },
              );
            },
          );
        },
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          message: l10n.productError,
          retryLabel: 'Tentar de novo',
          onRetry: () => ref.invalidate(productListProvider),
        ),
      ),
      floatingActionButton: Semantics(
        label: l10n.productNew,
        button: true,
        child: FloatingActionButton(
          tooltip: l10n.productNew,
          onPressed: () => _showCreateProductDialog(context, ref),
          child: const Icon(AppIcons.add),
        ),
      ),
    );
  }
}
