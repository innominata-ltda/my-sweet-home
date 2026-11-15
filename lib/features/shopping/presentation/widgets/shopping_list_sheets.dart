part of '../shopping_list_screen.dart';

extension _ShoppingListSheets on _ShoppingListScreenState {
  void _showManageListsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx);
          final listsAsync = ref.watch(allShoppingListsProvider);
          final lists = listsAsync.asData?.value ?? [];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.shoppingSheetsMyListsTitle,
                          style: Theme.of(ctx).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(AppIcons.add, size: 20),
                        label: Text(l10n.shoppingSheetsNewList),
                        onPressed: () => _showCreateListDialog(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (lists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Text(l10n.shoppingSheetsNoLists),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final l = lists[index];
                          final isCurrent = l.id == widget.listId;
                          return ListTile(
                            leading: Icon(
                              isCurrent ? AppIcons.check : AppIcons.shopping,
                              color: isCurrent
                                  ? Theme.of(ctx).colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              l.name,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              l.isArchived
                                  ? l10n.shoppingSheetsArchivedCount(
                                      l.items.length,
                                    )
                                  : l10n.shoppingSheetsItemsCount(
                                      l.items.length,
                                    ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent)
                                  const Padding(
                                    padding: EdgeInsets.only(right: Spacing.xs),
                                    child: Icon(
                                      AppIcons.check,
                                      color: Colors.green,
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  key: ValueKey('list-menu-${l.id}'),
                                  icon: const Icon(AppIcons.more),
                                  tooltip: l10n.shoppingSheetsListOptions,
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'duplicate':
                                        _duplicateList(l.id, modalCtx);
                                        break;
                                      case 'rename':
                                        _showRenameListDialog(ctx, l);
                                        break;
                                      case 'archive':
                                        _toggleArchiveList(l, modalCtx);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: Row(
                                        children: [
                                          const Icon(AppIcons.copy, size: 20),
                                          const SizedBox(width: Spacing.sm),
                                          Text(l10n.shoppingSheetsDuplicate),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          const Icon(AppIcons.edit, size: 20),
                                          const SizedBox(width: Spacing.sm),
                                          Text(l10n.shoppingSheetsRename),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            AppIcons.archive,
                                            size: 20,
                                          ),
                                          const SizedBox(width: Spacing.sm),
                                          Text(
                                            l.isArchived
                                                ? 'Desarquivar'
                                                : 'Arquivar',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(modalCtx).pop();
                              if (!isCurrent) {
                                context.go('/listas/${l.id}');
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _duplicateList(String listId, BuildContext sheetContext) async {
    final l10n = AppLocalizations.of(context);
    final useCase = ref.read(duplicateShoppingListUseCaseProvider);
    final result = await useCase(listId);
    if (result.isOk) {
      ref.invalidate(allShoppingListsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shoppingSheetsDuplicateSuccess)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shoppingSheetsDuplicateError)),
        );
      }
    }
  }

  Future<void> _showRenameListDialog(
    BuildContext parentContext,
    ShoppingList list,
  ) async {
    final l10n = AppLocalizations.of(parentContext);
    final textController = TextEditingController(text: list.name);
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (diagCtx) => AlertDialog(
        title: Text(l10n.shoppingSheetsRenameTitle),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.shoppingSheetsListNameLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(diagCtx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(diagCtx).pop(true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    if (confirmed == true && textController.text.trim().isNotEmpty) {
      final newName = textController.text.trim();
      final repo = ref.read(shoppingListRepositoryProvider);
      await repo.save(list.copyWith(name: newName));
      ref.invalidate(allShoppingListsProvider);
      ref.invalidate(shoppingListDetailProvider(list.id));
      if (mounted && list.id == widget.listId) {
        await ref.read(shoppingListDetailProvider(widget.listId)).loadList();
      }
    }
  }

  Future<void> _toggleArchiveList(
    ShoppingList list,
    BuildContext sheetContext,
  ) async {
    final repo = ref.read(shoppingListRepositoryProvider);
    final newArchived = !list.isArchived;
    await repo.save(list.copyWith(isArchived: newArchived));
    ref.invalidate(allShoppingListsProvider);
    ref.invalidate(shoppingListDetailProvider(list.id));

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newArchived
                ? l10n.shoppingSheetsArchivedSuccess
                : l10n.shoppingSheetsUnarchivedSuccess,
          ),
        ),
      );
      if (newArchived && list.id == widget.listId) {
        await ref.read(shoppingListDetailProvider(widget.listId)).loadList();
      }
    }
  }

  Future<void> _showCreateListDialog(BuildContext parentContext) async {
    final l10n = AppLocalizations.of(parentContext);
    final textController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (diagCtx) => AlertDialog(
        title: Text(l10n.shoppingSheetsCreateTitle),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.shoppingSheetsListNameLabel,
            hintText: l10n.shoppingSheetsCreateHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(diagCtx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(diagCtx).pop(true),
            child: Text(l10n.shoppingSheetsCreateButton),
          ),
        ],
      ),
    );

    if (confirmed == true && textController.text.trim().isNotEmpty) {
      final name = textController.text.trim();
      final useCase = ref.read(createShoppingListUseCaseProvider);
      final result = await useCase(name);
      if (result.isOk) {
        final newList = result.valueOrNull!;
        ref.invalidate(allShoppingListsProvider);
        if (mounted) {
          if (parentContext.mounted) {
            Navigator.of(parentContext).pop();
          }
          context.go('/listas/${newList.id}');
        }
      }
    }
  }
}
