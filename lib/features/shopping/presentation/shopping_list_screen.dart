import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/components/app_scaffold.dart';
import 'package:my_sweet_home/design_system/components/app_text_field.dart';
import 'package:my_sweet_home/design_system/components/app_undo_snack_bar.dart';
import 'package:my_sweet_home/design_system/components/cute_checkbox.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';
import 'package:my_sweet_home/features/shopping/domain/models/list_estimate.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';
import 'package:my_sweet_home/features/shopping/presentation/providers/shopping_providers.dart';
import 'package:my_sweet_home/features/shopping/presentation/widgets/shopping_item_tile.dart';

part 'widgets/shopping_list_sheets.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.listId,
    this.onRegisterPurchase,
    this.onRegisterItems,
  });

  final String listId;
  final VoidCallback? onRegisterPurchase;
  final ValueChanged<List<ShoppingItem>>? onRegisterItems;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final TextEditingController _addItemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final FocusNode _addItemFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Unit _selectedUnit = Unit.un;
  List<Product> _productSuggestions = const [];
  Product? _selectedProduct;
  int _searchToken = 0;

  @override
  void dispose() {
    _addItemController.dispose();
    _quantityController.dispose();
    _addItemFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onItemTextChanged(String text) async {
    final trimmed = text.trim();
    if (_selectedProduct != null &&
        _selectedProduct!.canonicalName.trim().toLowerCase() !=
            trimmed.toLowerCase()) {
      _selectedProduct = null;
    }

    if (trimmed.isEmpty) {
      final token = ++_searchToken;
      if (_productSuggestions.isNotEmpty || _selectedProduct != null) {
        if (mounted && token == _searchToken) {
          setState(() {
            _productSuggestions = const [];
            _selectedProduct = null;
          });
        }
      }
      return;
    }

    final token = ++_searchToken;
    final suggestions = await ref
        .read(shoppingListDetailProvider(widget.listId))
        .searchProducts(trimmed);

    if (mounted && token == _searchToken) {
      setState(() {
        _productSuggestions = suggestions;
      });
    }
  }

  void _onSelectProductSuggestion(Product product) {
    _searchToken++;
    _addItemController.value = TextEditingValue(
      text: product.canonicalName,
      selection: TextSelection.collapsed(offset: product.canonicalName.length),
    );
    setState(() {
      _selectedProduct = product;
      _selectedUnit = product.defaultUnit;
      _productSuggestions = const [];
    });
    _addItemFocusNode.requestFocus();
  }

  String _unitLabel(Unit unit) => switch (unit) {
    Unit.un => 'Un',
    Unit.pack => 'pct',
    Unit.kg => 'kg',
    Unit.g => 'g',
    Unit.l => 'L',
    Unit.ml => 'ml',
  };

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int attempts = 0;
      while (mounted &&
          _scrollController.hasClients &&
          attempts < 10 &&
          (_scrollController.position.maxScrollExtent -
                  _scrollController.position.pixels >
              1.0)) {
        attempts++;
        final target = _scrollController.position.maxScrollExtent;
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onAddItem() async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;

    final productId =
        (_selectedProduct != null &&
            _selectedProduct!.canonicalName.trim().toLowerCase() ==
                text.toLowerCase())
        ? _selectedProduct!.id
        : null;

    final qtyStr = _quantityController.text.trim().replaceAll(',', '.');
    final qty = double.tryParse(qtyStr) ?? 1.0;
    final displayQty = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    final unitStr = switch (_selectedUnit) {
      Unit.un => 'un',
      Unit.pack => 'pc',
      Unit.kg => 'kg',
      Unit.g => 'g',
      Unit.l => 'L',
      Unit.ml => 'ml',
    };
    final rawText = '$displayQty $unitStr $text';

    _searchToken++;
    _addItemController.clear();
    _quantityController.text = '1';
    setState(() {
      _selectedUnit = Unit.un;
      _selectedProduct = null;
      _productSuggestions = const [];
    });

    // T-B09: Manter foco na entrada de texto e teclado ativo
    _addItemFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _addItemFocusNode.requestFocus();
      }
    });

    await ref
        .read(shoppingListDetailProvider(widget.listId))
        .addItem(rawText, productId: productId);

    // T-B10: Auto-scroll to new item after real rendering in ListView
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _registerPurchase(
    ShoppingList list, [
    List<ShoppingItem>? specificItems,
  ]) {
    final bought = list.items.where((i) => i.isBought).toList();
    final itemsToPass =
        specificItems ?? (bought.isNotEmpty ? bought : list.items);
    if (widget.onRegisterItems != null) {
      widget.onRegisterItems!(itemsToPass);
    } else if (widget.onRegisterPurchase != null) {
      widget.onRegisterPurchase!();
    } else {
      context.push('/compras/nova', extra: itemsToPass);
    }
  }

  void _onToggleItem(ShoppingItem item, bool isBought) {
    final detailController = ref.read(
      shoppingListDetailProvider(widget.listId),
    );
    final currentList = detailController.value.list;
    final wasAllBought =
        currentList != null &&
        currentList.items.isNotEmpty &&
        currentList.items.every((i) => i.isBought);

    detailController.toggleItem(itemId: item.id, isBought: isBought);

    final updatedList = detailController.value.list;
    final isNowAllBought =
        updatedList != null &&
        updatedList.items.isNotEmpty &&
        updatedList.items.every((i) => i.isBought);

    if (isBought && !wasAllBought && isNowAllBought) {
      CelebrationOverlay.show(
        context,
        message: 'Você completou a lista de compras! 💕',
      );
    }

    if (isBought) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      AppUndoSnackBar.show(
        context,
        message: l10n.shoppingListMarkAsBought(item.parsedName),
        undoLabel: l10n.shoppingListUndo,
        onUndo: () {
          ref
              .read(shoppingListDetailProvider(widget.listId))
              .toggleItem(itemId: item.id, isBought: false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.watch(shoppingListDetailProvider(widget.listId));

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final state = notifier.state;

        if (state.isLoading && state.list == null) {
          return AppScaffold(
            title: l10n.shoppingListsTitle,
            body: const AppLoading(),
          );
        }

        if (state.errorMessage != null && state.list == null) {
          return AppScaffold(
            title: l10n.shoppingListsTitle,
            body: AppEmptyState(
              title: l10n.shoppingListError,
              description: state.errorMessage,
              actionLabel: l10n.shoppingListRetry,
              onAction: notifier.retry,
            ),
          );
        }

        final list = state.list;
        final titleText = list?.name ?? l10n.shoppingListsTitle;
        final bool isEmpty = list == null || list.items.isEmpty;

        final allBought = !isEmpty && list.items.every((item) => item.isBought);

        // Separate unpurchased items (top) and purchased (bottom) - RN-090
        final unboughtItems = isEmpty
            ? <ShoppingItem>[]
            : list.items.where((i) => !i.isBought).toList();
        final boughtItems = isEmpty
            ? <ShoppingItem>[]
            : list.items.where((i) => i.isBought).toList();
        final sortedItems = [...unboughtItems, ...boughtItems];

        return AppScaffold(
          title: titleText,
          actions: [
            if (!isEmpty)
              IconButton(
                icon: const Icon(AppIcons.purchase),
                tooltip: 'Registrar compra',
                onPressed: () => _registerPurchase(
                  list,
                  boughtItems.isNotEmpty ? boughtItems : null,
                ),
              ),
            IconButton(
              icon: const Icon(AppIcons.checklist),
              tooltip: 'Gerenciar listas',
              onPressed: _showManageListsSheet,
            ),
            if (!isEmpty && boughtItems.isNotEmpty)
              IconButton(
                icon: const Icon(AppIcons.delete),
                tooltip: 'Limpar comprados',
                onPressed: () {
                  ref
                      .read(shoppingListDetailProvider(widget.listId))
                      .clearPurchasedItems();
                },
              ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSubmoduleShortcuts(context),
                if (!isEmpty && state.estimate != null)
                  _buildEstimateHeader(l10n, state.estimate!),
                if (boughtItems.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  Container(
                    key: const Key('shopping_register_purchase_banner'),
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(Radius.md),
                    ),
                    child: Column(
                      children: [
                        Text(
                          allBought
                              ? l10n.shoppingListAllDone
                              : '${boughtItems.length} de ${list!.items.length} itens marcados',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: Spacing.sm),
                        AppButton.primary(
                          label: l10n.shoppingListRegisterPurchase,
                          onPressed: () => _registerPurchase(list, boughtItems),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isEmpty) const SizedBox(height: Spacing.sm),
                Expanded(
                  child: isEmpty
                      ? AppEmptyState.mascot(
                          title: l10n.shoppingListEmpty,
                          description: 'Adicione itens para não esquecer nada no mercado.',
                          mascotExpression: MascotExpression.shopping,
                          mascotSemanticLabel: l10n.momoEmptyShoppingList,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: sortedItems.length,
                          itemBuilder: (context, index) {
                            final item = sortedItems[index];
                            return ShoppingItemTile(
                              item: item,
                              onToggle: (isBought) =>
                                  _onToggleItem(item, isBought),
                              onDelete: () {
                                ref
                                    .read(
                                      shoppingListDetailProvider(widget.listId),
                                    )
                                    .removeItem(item.id);
                              },
                              onRegisterSingle: () =>
                                  _registerPurchase(list, [item]),
                            );
                          },
                        ),
                ),
                if (_productSuggestions.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  _buildProductSuggestions(),
                ],
                const SizedBox(height: Spacing.sm),
                _buildAddItemInput(l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmoduleShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              key: const Key('shortcut_purchases'),
              avatar: const Icon(AppIcons.purchase, size: 18),
              label: const Text('Compras'),
              onPressed: () => context.push('/compras'),
            ),
            const SizedBox(width: Spacing.xs),
            ActionChip(
              key: const Key('shortcut_prices'),
              avatar: const Icon(AppIcons.priceHistory, size: 18),
              label: const Text('Preços'),
              onPressed: () => context.push('/compras/historico-precos'),
            ),
            const SizedBox(width: Spacing.xs),
            ActionChip(
              key: const Key('shortcut_stock'),
              avatar: const Icon(AppIcons.product, size: 18),
              label: const Text('Estoque'),
              onPressed: () => context.push('/estoque'),
            ),
            const SizedBox(width: Spacing.xs),
            ActionChip(
              key: const Key('shortcut_recipes'),
              avatar: const Icon(AppIcons.recipes, size: 18),
              label: const Text('Receitas'),
              onPressed: () => context.push('/receitas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSuggestions() {
    final theme = Theme.of(context);
    return Card(
      key: const Key('shopping_product_suggestions'),
      margin: EdgeInsets.zero,
      elevation: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _productSuggestions.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = _productSuggestions[index];
            final unitText = _unitLabel(product.defaultUnit);
            return Semantics(
              button: true,
              label:
                  'Autocompletar produto ${product.canonicalName}, unidade $unitText',
              child: InkWell(
                key: Key('product_suggestion_${product.id}'),
                onTap: () => _onSelectProductSuggestion(product),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.xs,
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.shopping, size: 18),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            product.canonicalName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(Radius.sm),
                          ),
                          child: Text(
                            unitText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddItemInput(AppLocalizations l10n) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = textScale >= 1.5 && constraints.maxWidth < 450;

        final quantityField = ConstrainedBox(
          key: const Key('shopping_quantity_field'),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: SizedBox(
            width: shouldStack ? 72 : 48,
            child: Semantics(
              label: 'Quantidade',
              child: TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Qtd',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        );

        final unitDropdown = ConstrainedBox(
          key: const Key('shopping_unit_dropdown'),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(Radius.sm),
            ),
            child: Semantics(
              label: 'Unidade de medida',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Unit>(
                  value: _selectedUnit,
                  items: const [
                    DropdownMenuItem(value: Unit.un, child: Text('Un')),
                    DropdownMenuItem(value: Unit.kg, child: Text('kg')),
                    DropdownMenuItem(value: Unit.g, child: Text('g')),
                    DropdownMenuItem(value: Unit.l, child: Text('L')),
                    DropdownMenuItem(value: Unit.ml, child: Text('ml')),
                    DropdownMenuItem(value: Unit.pack, child: Text('pct')),
                  ],
                  onChanged: (u) {
                    if (u != null) {
                      setState(() => _selectedUnit = u);
                    }
                  },
                ),
              ),
            ),
          ),
        );

        final addButton = IconButton(
          icon: const Icon(AppIcons.add, size: 36),
          color: Theme.of(context).colorScheme.primary,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _onAddItem,
          tooltip: l10n.shoppingListAddItemLabel,
        );

        if (shouldStack) {
          return Container(
            key: const Key('shopping_add_input_row'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _addItemController,
                  focusNode: _addItemFocusNode,
                  label: l10n.shoppingListAddItemLabel,
                  hint: l10n.shoppingListAddItemHint,
                  textInputAction: TextInputAction.next,
                  onChanged: _onItemTextChanged,
                  onFieldSubmitted: (_) => _onAddItem(),
                ),
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    quantityField,
                    const SizedBox(width: Spacing.xs),
                    unitDropdown,
                    const Spacer(),
                    addButton,
                  ],
                ),
              ],
            ),
          );
        }

        return Row(
          key: const Key('shopping_add_input_row'),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 4,
              child: AppTextField(
                controller: _addItemController,
                focusNode: _addItemFocusNode,
                label: l10n.shoppingListAddItemLabel,
                hint: l10n.shoppingListAddItemHint,
                textInputAction: TextInputAction.done,
                onChanged: _onItemTextChanged,
                onFieldSubmitted: (_) => _onAddItem(),
              ),
            ),
            const SizedBox(width: Spacing.xs),
            quantityField,
            const SizedBox(width: Spacing.xs),
            unitDropdown,
            const SizedBox(width: Spacing.xs),
            addButton,
          ],
        );
      },
    );
  }

  Widget _buildEstimateHeader(AppLocalizations l10n, ListEstimate estimate) {
    final theme = Theme.of(context);
    String estimateText;

    if (estimate.itemsWithoutPrice == 0) {
      estimateText = l10n.shoppingListEstimateExact(
        estimate.known.formatPtBr(),
      );
    } else if (estimate.itemsWithoutPrice == 1) {
      estimateText = l10n.shoppingListEstimateWithOneUnknown(
        estimate.known.formatPtBr(),
      );
    } else {
      estimateText = l10n.shoppingListEstimateWithUnknowns(
        estimate.known.formatPtBr(),
        estimate.itemsWithoutPrice,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            const Icon(AppIcons.info, size: 20),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                estimateText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
