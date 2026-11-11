import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_detail_provider.dart';

import 'stock_providers.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  Unit _selectedUnit = Unit.un;

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showAddStockDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar no Estoque'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Nome do Produto *',
                    hint: 'Ex: Arroz Tipo 1',
                    controller: _productNameController,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Quantidade aproximada *',
                    hint: 'Ex: 4',
                    keyboardType: TextInputType.number,
                    controller: _quantityController,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<Unit>(
                    value: _selectedUnit,
                    isExpanded: true,
                    items: Unit.values.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedUnit = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                AppButton(
                  label: 'Salvar',
                  onPressed: () async {
                    final name = _productNameController.text.trim();
                    final qtyVal = int.tryParse(_quantityController.text) ?? 1;
                    if (name.isNotEmpty) {
                      final productRepo = ref.read(productRepositoryProvider);
                      final searchRes = await productRepo.search(name);
                      final existing = searchRes.valueOrNull
                          ?.where(
                            (p) =>
                                p.canonicalName.toLowerCase() ==
                                name.toLowerCase(),
                          )
                          .firstOrNull;

                      final String productId;
                      if (existing != null) {
                        productId = existing.id;
                      } else {
                        final created = await productRepo.create(
                          NewProduct(
                            canonicalName: name,
                            categoryId: 'cat_food',
                            defaultUnit: _selectedUnit,
                          ),
                        );
                        productId = created.valueOrNull?.id ?? name;
                      }

                      final quantity = Quantity(qtyVal * 1000, _selectedUnit);
                      await ref
                          .read(stockControllerProvider)
                          .updateQuantity(
                            productId: productId,
                            quantity: quantity,
                          );
                      ref.invalidate(productDetailProvider(productId));
                      _productNameController.clear();
                      _quantityController.clear();
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(stockControllerProvider);

    return AppScaffold(
      title: 'Estoque Doméstico',
      actions: [
        IconButton(
          key: const Key('add_stock_button'),
          icon: const Icon(AppIcons.add),
          tooltip: 'Adicionar produto',
          onPressed: _showAddStockDialog,
        ),
      ],
      body: ValueListenableBuilder<StockState>(
        valueListenable: controller,
        builder: (context, stockState, child) {
          if (stockState.isLoading && stockState.items.isEmpty) {
            return const AppLoading();
          }

          if (stockState.failure != null && stockState.items.isEmpty) {
            return Center(
              child: Text('Erro ao carregar estoque: ${stockState.failure}'),
            );
          }

          if (stockState.items.isEmpty) {
            return AppEmptyState(
              icon: AppIcons.stock,
              title: 'Estoque vazio',
              description: 'Nenhum produto registrado no estoque doméstico.',
              actionLabel: 'Adicionar produto',
              onAction: _showAddStockDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stockState.items.length,
            itemBuilder: (context, index) {
              final item = stockState.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final productAsync = ref.watch(
                                    productDetailProvider(item.productId),
                                  );
                                  final displayName =
                                      productAsync.value?.canonicalName ??
                                      'Produto: ${item.productId}';
                                  return Text(
                                    displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(AppIcons.delete, size: 20),
                              onPressed: () {
                                ref
                                    .read(stockControllerProvider)
                                    .deleteItem(item.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantidade informada: ${item.quantity.displayValue.toStringAsFixed(1)} ${item.quantity.unit.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final estimateAsync = ref.watch(
                              stockEstimateProvider(item.productId),
                            );
                            return estimateAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (estimate) {
                                // RN-251 / CA-2.2: If fewer than 3 purchases, do not display estimate!
                                if (!estimate.hasEnoughHistory) {
                                  return Text(
                                    'Sem estimativa de consumo (compras no histórico: ${estimate.purchaseCount}, mínimo: 3)',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Intervalo médio de compra: ${estimate.averageIntervalDays?.toStringAsFixed(1)} dias',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    if (estimate.estimatedDaysRemaining != null)
                                      Text(
                                        'Estimativa restante: ~${estimate.estimatedDaysRemaining} dias',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    if (estimate.isLowStock) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Está acabando',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
