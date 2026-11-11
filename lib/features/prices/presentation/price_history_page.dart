import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/price_history_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/widgets/price_chart_widget.dart';

import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

class PriceHistoryPage extends ConsumerStatefulWidget {
  const PriceHistoryPage({super.key, this.productId, this.storeId});

  final String? productId;
  final String? storeId;

  @override
  ConsumerState<PriceHistoryPage> createState() => _PriceHistoryPageState();
}

class _PriceHistoryPageState extends ConsumerState<PriceHistoryPage> {
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null &&
        widget.productId!.isNotEmpty &&
        widget.productId != 'default') {
      _selectedProductId = widget.productId;
    }
  }

  @override
  void didUpdateWidget(covariant PriceHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId &&
        widget.productId != null &&
        widget.productId!.isNotEmpty &&
        widget.productId != 'default') {
      _selectedProductId = widget.productId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pricesTitle)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(l10n.pricesLoadError)),
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Text(l10n.pricesEmpty));
          }

          final String activeProductId;
          if (_selectedProductId != null &&
              products.any((p) => p.id == _selectedProductId)) {
            activeProductId = _selectedProductId!;
          } else if (widget.productId != null &&
              products.any((p) => p.id == widget.productId)) {
            activeProductId = widget.productId!;
          } else {
            activeProductId = products.first.id;
          }

          final activeProduct = products.firstWhere(
            (p) => p.id == activeProductId,
            orElse: () => products.first,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Autocomplete<Product>(
                  key: ValueKey(activeProductId),
                  initialValue: TextEditingValue(
                    text: activeProduct.canonicalName,
                  ),
                  displayStringForOption: (Product p) => p.canonicalName,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return products;
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return products.where(
                      (p) => p.canonicalName.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (Product selection) {
                    setState(() {
                      _selectedProductId = selection.id;
                    });
                  },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<Product> onSelected,
                        Iterable<Product> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 250,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 32,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final product = options.elementAt(index);
                                  final isSelected =
                                      product.id == activeProductId;
                                  return ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    leading: const Icon(AppIcons.product),
                                    title: Text(product.canonicalName),
                                    subtitle: Text(
                                      '${product.categoryId} • ${product.defaultUnit.name}',
                                    ),
                                    onTap: () => onSelected(product),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Pesquisar produto',
                            hintText: 'Digite para buscar um produto...',
                            prefixIcon: const Icon(AppIcons.search),
                            suffixIcon: textEditingController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(AppIcons.close),
                                    tooltip: 'Limpar busca',
                                    onPressed: () {
                                      textEditingController.clear();
                                      focusNode.requestFocus();
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onFieldSubmitted: (String value) {
                            onFieldSubmitted();
                          },
                        );
                      },
                ),
              ),
              Expanded(
                child: PriceHistoryWidget(
                  productId: activeProductId,
                  storeId: widget.storeId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PriceHistoryWidget extends ConsumerWidget {
  const PriceHistoryWidget({super.key, required this.productId, this.storeId});

  final String productId;
  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(
      priceHistoryProvider((productId: productId, storeId: storeId)),
    );
    final statsAsync = ref.watch(priceStatsProvider(productId));
    final storesAsync = ref.watch(storeListProvider);
    final rankingsAsync = ref.watch(cheapestStoresProvider(productId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.pricesLoadError),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  priceHistoryProvider((
                    productId: productId,
                    storeId: storeId,
                  )),
                );
                ref.invalidate(priceStatsProvider(productId));
                ref.invalidate(cheapestStoresProvider(productId));
              },
              child: Text(l10n.pricesRetry),
            ),
          ],
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return Center(child: Text(l10n.pricesEmpty));
        }

        return statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(l10n.pricesLoadError)),
          data: (stats) {
            // Builds storeId -> Store map for name lookup in chart.
            final Map<String, Store> storeMap = {
              for (final s in storesAsync.value ?? <Store>[]) s.id: s,
            };

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.priceAverage(stats.averagePrice.formatPtBr()),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          l10n.priceAverageObservations(
                            stats.observationsCount,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (stats.observationsCount < 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.pricesFewData,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PriceChartWidget(
                      history: history,
                      stats: stats,
                      stores: storeMap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  rankingsAsync.maybeWhen(
                    data: (rankings) {
                      if (rankings.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.pricesRankingTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...rankings.map((ranking) {
                              final isWinner =
                                  ranking == rankings.first &&
                                  !ranking.hasLittleData;
                              return Card(
                                key: Key('store_ranking_${ranking.store.id}'),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    isWinner ? AppIcons.trophy : AppIcons.store,
                                    color: isWinner ? Colors.amber : null,
                                  ),
                                  title: Text(ranking.store.name),
                                  subtitle: Text(
                                    l10n.priceAverageObservations(
                                      ranking.observations,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        ranking.averageNormalized.formatPtBr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: isWinner
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                      ),
                                      if (ranking.hasLittleData)
                                        Text(
                                          l10n.notEnoughData,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
